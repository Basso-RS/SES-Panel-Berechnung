function [Best, TopList, Baseline] = optimize_laminate(Scenario, Calib, Targets, OptSettings)
% OPTIMIZE_LAMINATE Optimiert Material, Lagenanzahl und Winkel eines CFK-Sandwich-Panels.
%
% Syntax:
%   [Best, TopList, Baseline] = optimize_laminate(Scenario, Calib, Targets, OptSettings)

if nargin < 1 || isempty(Scenario)
    Scenario = Scenariodata();
end
if nargin < 2 || isempty(Calib)
    Calib = Calibration();
end
if nargin < 3 || isempty(Targets)
    Targets = struct();
end
if nargin < 4 || isempty(OptSettings)
    OptSettings = struct();
end

% Standardwerte Targets
if isfield(Targets, 'SF') && Targets.SF > 0 && (~isfield(Targets, 'safety_factor') || Targets.safety_factor <= 0)
    Targets.safety_factor = Targets.SF;
end
if ~isfield(Targets, 'safety_factor') || Targets.safety_factor <= 0
    Targets.safety_factor = 1.0;
end
SF = Targets.safety_factor;

if ~isfield(Targets, 'Gradient'),   Targets.Gradient = 0;   end
if ~isfield(Targets, 'Energy'),     Targets.Energy = 0;     end
if ~isfield(Targets, 'EI'),         Targets.EI = 0;         end
if ~isfield(Targets, 'UTS'),        Targets.UTS = 0;        end
if ~isfield(Targets, 'E'),          Targets.E = 0;          end
if ~isfield(Targets, 'F_max'),      Targets.F_max = 0;      end
if ~isfield(Targets, 't_skin_max'), Targets.t_skin_max = 0; end

% Standardwerte OptSettings
if ~isfield(OptSettings, 'min_plies'),     OptSettings.min_plies = 4; end
if ~isfield(OptSettings, 'max_plies'),     OptSettings.max_plies = 8; end
if ~isfield(OptSettings, 'angle_mode'),    OptSettings.angle_mode = 'simple'; end
if ~isfield(OptSettings, 'material_pool'), OptSettings.material_pool = 'all'; end
if ~isfield(OptSettings, 'core_interface_fabric'), OptSettings.core_interface_fabric = true; end
if ~isfield(OptSettings, 'verbose'),       OptSettings.verbose = true; end

% Sichtlagen-Option
if ~isfield(OptSettings, 'sichtlage_active')
    if isfield(OptSettings, 'sichtlage') && isfield(OptSettings.sichtlage, 'active')
        OptSettings.sichtlage_active = OptSettings.sichtlage.active;
    elseif isfield(OptSettings, 'fixed_outer_ply')
        OptSettings.sichtlage_active = OptSettings.fixed_outer_ply;
    else
        OptSettings.sichtlage_active = false;
    end
end
if ischar(OptSettings.sichtlage_active) || isstring(OptSettings.sichtlage_active)
    OptSettings.sichtlage_active = strcmpi(OptSettings.sichtlage_active, 'on') || ...
                                   strcmpi(OptSettings.sichtlage_active, 'true') || ...
                                   strcmp(OptSettings.sichtlage_active, '1');
end

if ~isfield(OptSettings, 'sichtlage_material')
    if isfield(OptSettings, 'sichtlage') && isfield(OptSettings.sichtlage, 'material')
        OptSettings.sichtlage_material = OptSettings.sichtlage.material;
    elseif isfield(OptSettings, 'outer_ply_material')
        OptSettings.sichtlage_material = OptSettings.outer_ply_material;
    else
        OptSettings.sichtlage_material = 't7';
    end
end

if ~isfield(OptSettings, 'sichtlage_angle')
    if isfield(OptSettings, 'sichtlage') && isfield(OptSettings.sichtlage, 'angle')
        OptSettings.sichtlage_angle = OptSettings.sichtlage.angle;
    elseif isfield(OptSettings, 'outer_ply_angle')
        OptSettings.sichtlage_angle = OptSettings.outer_ply_angle;
    else
        OptSettings.sichtlage_angle = 45;
    end
end

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
csv_path = fullfile(project_root, '02_Data', 'materials.csv');

%% 1. Materialdaten über Singleton-Loader laden
[mat_dict, ~, ~] = load_materials(csv_path);

panel_area_m2 = (Scenario.panel.b * Scenario.panel.l) / 1e6;
core_rho = 7.5e-11;
if isfield(mat_dict, 'core'), core_rho = mat_dict.core.rho; end

gsm_cp_single = 150.0;
if isfield(mat_dict, 'cp')
    gsm_cp_single = mat_dict.cp.t_ply * mat_dict.cp.rho * 1e12;
end

%% 2. Baseline berechnen
if OptSettings.verbose
    fprintf('Berechne Ausgangs-Panel (Baseline)...\n');
end
BaseMdata = Materialdata(Scenario, Calib);
BaseResults = struct();
BaseResults = EI_calc(BaseMdata, BaseResults, Scenario);
BaseResults = Shearstiff_calc(BaseResults, BaseMdata, Scenario);
[BaseResults, BaseCurve] = Deflection(BaseResults, Scenario, BaseMdata);
BaseResults = Energy_calc(BaseResults, BaseCurve, Scenario, BaseMdata);

BaseWeight = calc_panel_weight(Scenario);

Baseline = struct();
Baseline.layup      = Scenario.layup;
Baseline.E          = BaseResults.E;
Baseline.UTS        = BaseResults.UTS;
Baseline.Gradient   = BaseResults.Gradient;
Baseline.Energy     = BaseResults.Energy;
Baseline.EI         = BaseResults.EI;
Baseline.F_max      = BaseResults.F_max;
Baseline.w_max      = BaseResults.w_max;
Baseline.t_top      = BaseMdata.cfk.t_top;
Baseline.t_total    = BaseMdata.cfk.t_top + BaseMdata.core.t + BaseMdata.cfk.t_lower;
Baseline.gsm_total  = BaseWeight.gsm_total;
Baseline.gsm_skins  = BaseWeight.gsm_skins;
Baseline.gsm_skin   = BaseWeight.gsm_top;
Baseline.gsm_core   = BaseWeight.gsm_core;
Baseline.gsm_cp     = BaseWeight.gsm_cp;
Baseline.mass_panel = BaseWeight.mass_panel;
Baseline.mass_skins = BaseWeight.mass_skins;
Baseline.mass_core  = BaseWeight.mass_core;
Baseline.mass_cp    = BaseWeight.mass_cp;
Baseline.Curve      = BaseCurve;

%% 3. Generierung aller regelkonformen Kandidaten (ohne dynamisches Zellwachstum)
if OptSettings.verbose
    if OptSettings.sichtlage_active
        if iscell(OptSettings.sichtlage_material) || isstring(OptSettings.sichtlage_material)
            mat_str = upper(strjoin(cellstr(OptSettings.sichtlage_material), ', '));
        else
            mat_str = upper(char(string(OptSettings.sichtlage_material)));
        end
        ang_str = strjoin(arrayfun(@(a) sprintf('%d°', a), OptSettings.sichtlage_angle, 'UniformOutput', false), '/');
        sicht_info = sprintf('ON (%s %s)', ang_str, mat_str);
    else
        sicht_info = 'OFF (frei)';
    end
    fprintf('Generiere zulässige Laminate (%d bis %d Lagen, Modus: %s, Material: %s, Sichtlage: %s)...\n', ...
        OptSettings.min_plies, OptSettings.max_plies, OptSettings.angle_mode, OptSettings.material_pool, sicht_info);
end

n_ply_range = OptSettings.min_plies : OptSettings.max_plies;
cand_cells = cell(length(n_ply_range), 1);
for idx = 1:length(n_ply_range)
    cand_cells{idx} = generate_skin_candidates(n_ply_range(idx), OptSettings);
end
all_candidates = [cand_cells{:}];
all_candidates = unique(all_candidates);

n_total = length(all_candidates);
if OptSettings.verbose
    fprintf('-> %d regelkonforme Kandidaten im Suchraum generiert.\n', n_total);
    if SF > 1.0
        fprintf('Sicherheitsfaktor aktiv: SF = %.2f (+%.1f%% Reserve auf alle Mindestwerte)\n', SF, (SF - 1)*100);
    end
    fprintf('Starte hierarchische 2-Stufen-Optimierung...\n\n');
end

%% 4. Sortierung nach Mindestgewicht
cand_weights = zeros(n_total, 1);
for i = 1:n_total
    cand_weights(i) = calc_skin_gsm(all_candidates{i}, mat_dict);
end
[~, sort_idx] = sort(cand_weights, 'ascend');
all_candidates = all_candidates(sort_idx);
cand_weights = cand_weights(sort_idx);

%% 5. Hierarchische Optimierungsschleife (preallokierte Liste)
feasible_list = cell(1, n_total);
n_feas = 0;
best_weight = inf;
t_opt_start = tic;
count_stg1_passed = 0;
count_stg2_sims = 0;

grad_target   = Targets.Gradient * SF;
ei_target     = Targets.EI * SF;
energy_target = Targets.Energy * SF;
uts_target    = Targets.UTS * SF;
e_target      = (Targets.E * 1000) * SF;
fmax_target   = Targets.F_max * SF;

for i = 1:n_total
    skin_str = all_candidates{i};
    skin_gsm = cand_weights(i);
    
    if n_feas >= 5 && skin_gsm > (1.15 * best_weight)
        continue;
    end
    
    parts = strsplit(skin_str, '/');
    rev_parts = fliplr(parts);
    full_layup = [skin_str, '/cp/', num2str(Scenario.core_t), 'core/cp/', strjoin(rev_parts, '/')];
    
    % Stufe 1: Schnelle KLT-Abschätzung
    t_factor = 0.95;
    if isfield(Calib, 'thickness_factor'), t_factor = Calib.thickness_factor; end
    
    cfk_props = calc_cfk_properties(full_layup, csv_path, false, t_factor, 0.00262);
    
    if Targets.t_skin_max > 0 && cfk_props.t_top > Targets.t_skin_max
        continue;
    end
    if e_target > 0 && cfk_props.E_top < e_target
        continue;
    end
    
    z_top = Scenario.core_t/2 + cfk_props.t_top/2;
    I_eigen = (Scenario.panel.b * cfk_props.t_top^3) / 12;
    I_steiner = Scenario.panel.b * cfk_props.t_top * z_top^2;
    I_skin = 2 * (I_eigen + I_steiner);
    EI_approx = cfk_props.E_top * I_skin;
    
    if ei_target > 0 && EI_approx < ei_target
        continue;
    end
    
    grad_approx = 48 * EI_approx / (Scenario.panel.l^3);
    
    if grad_target > 0 && grad_approx < (grad_target * 0.92)
        continue;
    end
    
    count_stg1_passed = count_stg1_passed + 1;
    
    % Stufe 2: Vollständige Simulation
    Scen_cand = Scenario;
    Scen_cand.layup = full_layup;
    Mdata = Materialdata(Scen_cand, Calib);
    Results = struct();
    Results = EI_calc(Mdata, Results, Scen_cand);
    Results = Shearstiff_calc(Results, Mdata, Scen_cand);
    [Results, Curve] = Deflection(Results, Scen_cand, Mdata);
    Results = Energy_calc(Results, Curve, Scen_cand, Mdata);
    count_stg2_sims = count_stg2_sims + 1;
    
    if grad_target > 0 && Results.Gradient < grad_target, continue; end
    if ei_target > 0 && Results.EI < ei_target, continue; end
    if energy_target > 0 && Results.Energy < energy_target, continue; end
    if uts_target > 0 && Results.UTS < uts_target, continue; end
    if e_target > 0 && Results.E < e_target, continue; end
    if fmax_target > 0 && Results.F_max < fmax_target, continue; end
    
    cand_gsm_core = Scenario.core_t * core_rho * 1e12;
    cand_gsm_cp   = 2 * gsm_cp_single;
    cand_gsm_skins = 2 * skin_gsm;
    cand_gsm_total = cand_gsm_skins + cand_gsm_core + cand_gsm_cp;
    cand_panel_mass = cand_gsm_total * panel_area_m2;
    
    entry = struct();
    entry.layup      = full_layup;
    entry.top_skin   = skin_str;
    entry.n_plies    = length(parts);
    entry.gsm_skin   = skin_gsm;
    entry.gsm_skins  = cand_gsm_skins;
    entry.gsm_core   = cand_gsm_core;
    entry.gsm_cp     = cand_gsm_cp;
    entry.gsm_total  = cand_gsm_total;
    entry.mass_panel = cand_panel_mass;
    entry.weight_saving_g   = Baseline.mass_panel - cand_panel_mass;
    entry.weight_saving_pct = (Baseline.mass_panel - cand_panel_mass) / Baseline.mass_panel * 100;
    entry.E          = Results.E;
    entry.UTS        = Results.UTS;
    entry.Gradient   = Results.Gradient;
    entry.Energy     = Results.Energy;
    entry.EI         = Results.EI;
    entry.F_max      = Results.F_max;
    entry.w_max      = Results.w_max;
    entry.t_top      = Mdata.cfk.t_top;
    entry.t_total    = Mdata.cfk.t_top + Mdata.core.t + Mdata.cfk.t_lower;
    entry.Curve      = Curve;
    
    n_feas = n_feas + 1;
    feasible_list{n_feas} = entry;
    if skin_gsm < best_weight
        best_weight = skin_gsm;
    end
end

feasible_list = feasible_list(1:n_feas);
t_opt_calc = toc(t_opt_start);

%% 6. Auswertung und Rangliste
if isempty(feasible_list)
    Best = [];
    TopList = [];
    if OptSettings.verbose
        fprintf('KEINE zulässige Lösung gefunden, die alle Targets erfüllt!\n');
    end
    return;
end

masses = cellfun(@(x) x.mass_panel, feasible_list);
[~, idx_rank] = sort(masses, 'ascend');
feasible_list = feasible_list(idx_rank);

Best = feasible_list{1};
n_top = min(5, length(feasible_list));
TopList = [feasible_list{1:n_top}];

if OptSettings.verbose
    fprintf('Optimierung abgeschlossen in %.2f s! (%d Stufe-1 Prüfungen, %d FE-Simulationen)\n\n', ...
        t_opt_calc, count_stg1_passed, count_stg2_sims);
    print_optimization_summary(Baseline, TopList, Targets, SF, OptSettings);
end

end

%% ------------------- HILFSFUNKTIONEN ------------------- %%

function cands = generate_skin_candidates(N, OptSettings)
% Generiert alle regelkonformen, balancierten Top-Skin Lagenaufbauten mit N Lagen.

if strcmpi(OptSettings.material_pool, 'all')
    fabric_opts = {'45t7', '45f', '45z'};
    ud_mats     = {'m', 't8'};
else
    fabric_opts = {'45t7'};
    ud_mats     = {'m', 't8'};
end

if strcmpi(OptSettings.angle_mode, 'advanced')
    angles = [21, 30, 45, 60];
else
    angles = 21;
end

% FSG T 3.5.7: Außenlage immer Gewebe
if OptSettings.sichtlage_active
    raw_sicht = OptSettings.sichtlage_material;
    if ischar(raw_sicht)
        raw_sicht_list = {raw_sicht};
    elseif isstring(raw_sicht)
        raw_sicht_list = cellstr(raw_sicht);
    elseif iscell(raw_sicht)
        raw_sicht_list = raw_sicht;
    else
        raw_sicht_list = {'t7'};
    end
    
    norm_sicht_mats = cell(1, length(raw_sicht_list));
    for i_s = 1:length(raw_sicht_list)
        s_mat = lower(strtrim(char(string(raw_sicht_list{i_s}))));
        if startsWith(s_mat, 't7') || strcmp(s_mat, 't') || strcmp(s_mat, 't700')
            norm_sicht_mats{i_s} = 't7';
        elseif startsWith(s_mat, 'm40') || strcmp(s_mat, 'f') || strcmp(s_mat, 'fm40j') || strcmp(s_mat, 'm40jf')
            norm_sicht_mats{i_s} = 'f';
        elseif startsWith(s_mat, 'zz') || strcmp(s_mat, 'z') || strcmp(s_mat, 'zz300t')
            norm_sicht_mats{i_s} = 'z';
        else
            norm_sicht_mats{i_s} = s_mat;
        end
    end
    norm_sicht_mats = unique(norm_sicht_mats, 'stable');
    if isempty(norm_sicht_mats)
        norm_sicht_mats = {'t7'};
    end
    
    s_angs = OptSettings.sichtlage_angle;
    if isempty(s_angs)
        s_angs = 45;
    end
    
    p1_opts = cell(1, length(s_angs) * length(norm_sicht_mats));
    k_p1 = 0;
    for i_a = 1:length(s_angs)
        ang_val = s_angs(i_a);
        for i_m = 1:length(norm_sicht_mats)
            k_p1 = k_p1 + 1;
            p1_opts{k_p1} = [num2str(ang_val), norm_sicht_mats{i_m}];
        end
    end
else
    p1_opts = fabric_opts;
end

if OptSettings.core_interface_fabric
    pn_opts = fabric_opts;
else
    pn_opts = [fabric_opts, cellfun(@(u) ['0', u], ud_mats, 'UniformOutput', false)];
end

n_mid = N - 2;
mid_configs = get_balanced_mids(n_mid, ud_mats, angles, fabric_opts);

total_combos = length(p1_opts) * length(pn_opts) * length(mid_configs);
cands = cell(1, total_combos);
n_valid = 0;

for i1 = 1:length(p1_opts)
    p1 = p1_opts{i1};
    for in = 1:length(pn_opts)
        pn = pn_opts{in};
        for im = 1:length(mid_configs)
            full_skin = [{p1}, mid_configs{im}, {pn}];
            if is_fsg_compliant(full_skin)
                n_valid = n_valid + 1;
                cands{n_valid} = strjoin(full_skin, '/');
            end
        end
    end
end
cands = cands(1:n_valid);

end

function mids = get_balanced_mids(n_mid, ud_mats, angles, fabric_opts)
% Erzeugt balancierte Lagenkonfigurationen für Innenlagen ohne dynamisches Zellwachstum.

if n_mid == 0
    mids = {{}};
    return;
end

if n_mid == 1
    mids = cell(1, length(ud_mats) + length(fabric_opts));
    k = 0;
    for m = 1:length(ud_mats)
        k = k + 1;
        mids{k} = {['0', ud_mats{m}]};
    end
    for f = 1:length(fabric_opts)
        k = k + 1;
        mids{k} = {fabric_opts{f}};
    end
    return;
end

if n_mid == 2
    nA = length(ud_mats)^2;
    nB = length(ud_mats) * length(angles) * 2;
    nC = length(fabric_opts) * length(ud_mats) * 2;
    mids = cell(1, nA + nB + nC);
    k = 0;
    for m1 = 1:length(ud_mats)
        for m2 = 1:length(ud_mats)
            k = k + 1;
            mids{k} = {['0', ud_mats{m1}], ['0', ud_mats{m2}]};
        end
    end
    for m = 1:length(ud_mats)
        u = ud_mats{m};
        for a = 1:length(angles)
            ang = angles(a);
            k = k + 1;
            mids{k} = {[num2str(ang), u], ['-', num2str(ang), u]};
            k = k + 1;
            mids{k} = {['-', num2str(ang), u], [num2str(ang), u]};
        end
    end
    for f = 1:length(fabric_opts)
        for m = 1:length(ud_mats)
            k = k + 1;
            mids{k} = {fabric_opts{f}, ['0', ud_mats{m}]};
            k = k + 1;
            mids{k} = {['0', ud_mats{m}], fabric_opts{f}};
        end
    end
    return;
end

if n_mid == 3
    nA = length(ud_mats)^2 * length(angles) * 6;
    nB = length(fabric_opts) * length(ud_mats) * length(angles) * 3;
    mids = cell(1, nA + nB);
    k = 0;
    for m_zero = 1:length(ud_mats)
        u0 = ['0', ud_mats{m_zero}];
        for m_p = 1:length(ud_mats)
            up = ud_mats{m_p};
            for a = 1:length(angles)
                ang = angles(a);
                pp = [num2str(ang), up]; pn = ['-', num2str(ang), up];
                k = k + 1; mids{k} = {u0, pp, pn};
                k = k + 1; mids{k} = {u0, pn, pp};
                k = k + 1; mids{k} = {pp, u0, pn};
                k = k + 1; mids{k} = {pn, u0, pp};
                k = k + 1; mids{k} = {pp, pn, u0};
                k = k + 1; mids{k} = {pn, pp, u0};
            end
        end
    end
    for f = 1:length(fabric_opts)
        fab = fabric_opts{f};
        for m_p = 1:length(ud_mats)
            up = ud_mats{m_p};
            for a = 1:length(angles)
                ang = angles(a);
                pp = [num2str(ang), up]; pn = ['-', num2str(ang), up];
                k = k + 1; mids{k} = {fab, pp, pn};
                k = k + 1; mids{k} = {pp, fab, pn};
                k = k + 1; mids{k} = {pp, pn, fab};
            end
        end
    end
    return;
end

if n_mid == 4
    nA = length(ud_mats)^3 * length(angles) * 5;
    nB = length(ud_mats)^2 * length(angles)^2 * 2;
    mids = cell(1, nA + nB);
    k = 0;
    for m1 = 1:length(ud_mats)
        u0_1 = ['0', ud_mats{m1}];
        for m2 = 1:length(ud_mats)
            u0_2 = ['0', ud_mats{m2}];
            for m_p = 1:length(ud_mats)
                up = ud_mats{m_p};
                for a = 1:length(angles)
                    ang = angles(a);
                    pp = [num2str(ang), up]; pn = ['-', num2str(ang), up];
                    k = k + 1; mids{k} = {u0_1, u0_2, pp, pn};
                    k = k + 1; mids{k} = {u0_1, pp, u0_2, pn};
                    k = k + 1; mids{k} = {pp, u0_1, u0_2, pn};
                    k = k + 1; mids{k} = {pp, u0_1, pn, u0_2};
                    k = k + 1; mids{k} = {pp, pn, u0_1, u0_2};
                end
            end
        end
    end
    for m1 = 1:length(ud_mats)
        up1 = ud_mats{m1};
        for a1 = 1:length(angles)
            ang1 = angles(a1);
            pp1 = [num2str(ang1), up1]; pn1 = ['-', num2str(ang1), up1];
            for m2 = 1:length(ud_mats)
                up2 = ud_mats{m2};
                for a2 = 1:length(angles)
                    ang2 = angles(a2);
                    pp2 = [num2str(ang2), up2]; pn2 = ['-', num2str(ang2), up2];
                    k = k + 1; mids{k} = {pp1, pn1, pp2, pn2};
                    k = k + 1; mids{k} = {pp1, pp2, pn2, pn1};
                end
            end
        end
    end
    return;
end

if n_mid >= 5
    base_mids = get_balanced_mids(n_mid - 2, ud_mats, angles, fabric_opts);
    n_base = min(100, length(base_mids));
    n_combos = n_base * length(ud_mats) * length(angles);
    mids = cell(1, n_combos);
    k = 0;
    for b = 1:n_base
        sub = base_mids{b};
        for m = 1:length(ud_mats)
            u = ud_mats{m};
            for a = 1:length(angles)
                ang = angles(a);
                k = k + 1;
                mids{k} = [{[num2str(ang), u]}, sub, {['-', num2str(ang), u]}];
            end
        end
    end
    return;
end

end

function compliant = is_fsg_compliant(plies)
% Prüft FSG-Regelkonformität (Außenlage, Balancierung, 50%-Regel, Anti-Clumping)
compliant = false;
N = length(plies);

% 1. FSG T 3.5.7: Äußerste Lage muss Gewebe sein
p1 = plies{1};
if ~contains(p1, 'f') && ~contains(p1, 't') && ~contains(p1, 'z')
    return;
end

% 2. Balancierung: Paarweiser Winkelabgleich ohne containers.Map
ang_list = zeros(1, N);
mat_list = cell(1, N);
n_ang = 0;

for i = 1:N
    p = plies{i};
    if contains(p, 'f') || contains(p, 't') || contains(p, 'z')
        continue; % Gewebe ist eigenbalanciert
    end
    [ang, mat] = parse_ply_token(p);
    if ang == 0 || ang == 90
        continue;
    end
    n_ang = n_ang + 1;
    ang_list(n_ang) = ang;
    mat_list{n_ang} = mat;
end

if mod(n_ang, 2) ~= 0
    return; % Ungerade Anzahl an Winkellagen
end

if n_ang > 0
    matched = false(1, n_ang);
    for j = 1:n_ang
        if matched(j), continue; end
        opp_idx = 0;
        for k = j+1:n_ang
            if ~matched(k) && (ang_list(k) == -ang_list(j)) && strcmp(mat_list{k}, mat_list{j})
                opp_idx = k;
                break;
            end
        end
        if opp_idx == 0
            return;
        end
        matched(j) = true;
        matched(opp_idx) = true;
    end
end

% 3. FSG T 3.5.3: Max. 50% 0°-Lagen
count_zero = 0;
for i = 1:N
    p = plies{i};
    if p(1) == '0'
        count_zero = count_zero + 1;
    end
end
if (count_zero / N) > 0.50
    return;
end

% 4. Anti-Clumping: Max. 2 identische Lagen hintereinander
consec = 1;
for i = 2:N
    if strcmp(plies{i}, plies{i-1})
        consec = consec + 1;
        if consec >= 3
            return;
        end
    else
        consec = 1;
    end
end

compliant = true;
end

function gsm = calc_skin_gsm(layup_str, mat_dict)
% Berechnet das Flächengewicht (g/m^2) einer Deckhaut (Top Skin).
top_plies = parse_layup(layup_str);
gsm = 0;
for i = 1:length(top_plies)
    p = top_plies{i};
    if isempty(p) || strcmpi(p, 'cp'), continue; end
    [~, mat_code] = parse_ply_token(p);
    t_ply = 0.22;
    rho_ply = 1.5e-9;
    if isfield(mat_dict, mat_code)
        t_ply = mat_dict.(mat_code).t_ply;
        rho_ply = mat_dict.(mat_code).rho;
    end
    gsm = gsm + (t_ply * rho_ply * 1e12);
end
end

function print_optimization_summary(Base, TopList, Targets, SF, OptSettings)
fprintf('====================================================================================================\n');
fprintf('                           ERGEBNIS DER LAMINAT-OPTIMIERUNG                                         \n');
fprintf('====================================================================================================\n');
fprintf('Aktive Zielvorgaben (Targets):\n');
if SF > 1.0
    fprintf('  - Sicherheitsfaktor (SF):  %5.2f (+%.1f%% Auslegungs-Reserve)\n', SF, (SF - 1)*100);
end
if Targets.Gradient > 0
    fprintf('  - Gradient:        >= %6.0f N/mm   (inkl. SF: >= %6.0f N/mm)\n', Targets.Gradient, Targets.Gradient * SF);
end
if Targets.Energy > 0
    fprintf('  - Energie:         >= %6.1f J      (inkl. SF: >= %6.1f J)\n', Targets.Energy, Targets.Energy * SF);
end
if Targets.EI > 0
    fprintf('  - Biegesteifigkeit >= %6.2e N*mm^2 (inkl. SF: >= %6.2e N*mm^2)\n', Targets.EI, Targets.EI * SF);
end
if Targets.UTS > 0
    fprintf('  - Festigkeit UTS:  >= %6.1f MPa    (inkl. SF: >= %6.1f MPa)\n', Targets.UTS, Targets.UTS * SF);
end
if Targets.E > 0
    fprintf('  - E-Modul Deckhaut:>= %6.1f GPa    (inkl. SF: >= %6.1f GPa)\n', Targets.E, Targets.E * SF);
end
if Targets.F_max > 0
    fprintf('  - Maximalkraft:    >= %6.0f N      (inkl. SF: >= %6.0f N)\n', Targets.F_max, Targets.F_max * SF);
end
if Targets.t_skin_max > 0
    fprintf('  - Max. Deckhaut:   <= %6.2f mm\n', Targets.t_skin_max);
end
if nargin >= 5 && isfield(OptSettings, 'sichtlage_active')
    if OptSettings.sichtlage_active
        if iscell(OptSettings.sichtlage_material) || isstring(OptSettings.sichtlage_material)
            mat_disp = upper(strjoin(cellstr(OptSettings.sichtlage_material), ', '));
        else
            mat_disp = upper(char(string(OptSettings.sichtlage_material)));
        end
        ang_disp = strjoin(arrayfun(@(a) sprintf('%d°', a), OptSettings.sichtlage_angle, 'UniformOutput', false), '/');
        fprintf('  - Sichtlage:       ON  (Material: %s, Winkel: %s)\n', mat_disp, ang_disp);
    else
        fprintf('  - Sichtlage:       OFF (freie Materialoptimierung)\n');
    end
end
fprintf('----------------------------------------------------------------------------------------------------\n');

Best = TopList(1);
delta_mass_g = Best.mass_panel - Base.mass_panel;
delta_mass_pct = (delta_mass_g / Base.mass_panel) * 100;
fprintf('VORHER / NACHHER VERGLEICH:\n');
fprintf('  %-26s | %-28s | %-28s | %-10s\n', 'Eigenschaft', 'Ausgangspanel (Baseline)', 'Optimum (Leichtestes)', 'Delta');
fprintf('  %s\n', repmat('-', 1, 98));
fprintf('  %-26s | %-28s | %-28s | \n', 'Voll-Lagenaufbau (mit CP)', Base.layup(1:min(28, length(Base.layup))), Best.layup);
fprintf('  %-26s | %8.1f g                 | %8.1f g                 | %+6.1f%% (%+5.1f g)\n', ...
    'Panel-Gesamtmasse', Base.mass_panel, Best.mass_panel, delta_mass_pct, delta_mass_g);
fprintf('  %-26s | %8.0f g/m^2             | %8.0f g/m^2             | %+6.1f%%\n', ...
    'Gesamt-Flächengewicht', Base.gsm_total, Best.gsm_total, (Best.gsm_total - Base.gsm_total)/Base.gsm_total*100);
fprintf('  %-26s | %8.0f g/m^2             | %8.0f g/m^2             | %+6.1f%%\n', ...
    '  -> CFK-Deckhäute (2x)', Base.gsm_skins, Best.gsm_skins, (Best.gsm_skins - Base.gsm_skins)/Base.gsm_skins*100);
fprintf('  %-26s | %8.0f g/m^2             | %8.0f g/m^2             | %+6.1f%%\n', ...
    '  -> Wabenkern (18 mm)', Base.gsm_core, Best.gsm_core, 0.0);
fprintf('  %-26s | %8.0f g/m^2             | %8.0f g/m^2             | %+6.1f%%\n', ...
    '  -> Klebefilm (2x CP)', Base.gsm_cp, Best.gsm_cp, 0.0);
fprintf('  %-26s | %8.2f mm                | %8.2f mm                | %+6.2f mm\n', ...
    'Deckhautdicke (Top)', Base.t_top, Best.t_top, Best.t_top - Base.t_top);
fprintf('  %-26s | %8.0f N/mm              | %8.0f N/mm              | %+6.1f%%\n', ...
    'Gradient (Steifigkeit)', Base.Gradient, Best.Gradient, (Best.Gradient - Base.Gradient)/Base.Gradient*100);
fprintf('  %-26s | %8.1f J                 | %8.1f J                 | %+6.1f%%\n', ...
    'Absorbierte Energie', Base.Energy, Best.Energy, (Best.Energy - Base.Energy)/Base.Energy*100);
fprintf('  %-26s | %8.1f GPa               | %8.1f GPa               | %+6.1f%%\n', ...
    'E-Modul Deckhaut', Base.E/1000, Best.E/1000, (Best.E - Base.E)/Base.E*100);
fprintf('  %-26s | %8.1f MPa               | %8.1f MPa               | %+6.1f%%\n', ...
    'Bruchspannung (UTS)', Base.UTS, Best.UTS, (Best.UTS - Base.UTS)/Base.UTS*100);
fprintf('----------------------------------------------------------------------------------------------------\n\n');

fprintf('TOP-%d LEICHTESTE REGELKONFORME LAMINATE:\n', length(TopList));
fprintf('%-4s | %-8s | %-12s | %-8s | %-11s | %-9s | %s\n', ...
    'Rang', 'Masse', 'Gesamt-GSM', 'Delta', 'Gradient', 'Energie', 'Lagenaufbau (Halbschale)');
fprintf('%-4s | %-8s | %-12s | %-8s | %-11s | %-9s | %s\n', ...
    '', '[g]', '[g/m^2]', '[%]', '[N/mm]', '[J]', '');
fprintf('%s\n', repmat('-', 1, 100));
for r = 1:length(TopList)
    cand = TopList(r);
    cand_delta_pct = ((cand.mass_panel - Base.mass_panel) / Base.mass_panel) * 100;
    fprintf('#%-3d | %6.1f g | %6.0f g/m^2 | %+6.1f%% | %5.0f N/mm | %5.1f J   | %s\n', ...
        r, cand.mass_panel, cand.gsm_total, cand_delta_pct, cand.Gradient, cand.Energy, cand.top_skin);
end
fprintf('====================================================================================================\n\n');
end
