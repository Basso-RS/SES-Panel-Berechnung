function [Best, TopList, Baseline] = optimize_laminate(Scenario, Calib, Targets, OptSettings)
%% OPTIMIZE_LAMINATE Optimiert Material, Lagenanzahl und Winkel eines CFK-Sandwich-Panels
%
% Syntax:
%   [Best, TopList, Baseline] = optimize_laminate(Scenario, Calib, Targets, OptSettings)
%
% Inputs:
%   Scenario    - Struct mit Panel-Geometrie (b, l, w, core_t, layup)
%   Calib       - Struct mit Kalibrierungsfaktoren (aus Calibration.m)
%   Targets     - Struct mit Zielwerten (0 = inaktiv):
%                   .safety_factor [Faktor] (z.B. 1.15 = +15% Sicherheitsreserve)
%                   .Gradient   [N/mm]   (Mindest-Biegesteifigkeit)
%                   .Energy     [J]      (Mindest-Energieaufnahme)
%                   .EI         [N*mm^2] (Mindest-Biegesteifigkeit)
%                   .UTS        [MPa]    (Mindest-Bruchspannung)
%                   .E          [GPa]    (Mindest-E-Modul Deckhaut)
%                   .F_max      [N]      (Mindest-Bruchkraft)
%                   .t_skin_max [mm]     (Maximale Deckhautdicke)
%   OptSettings - Struct mit Suchoptionen:
%                   .min_plies     (Default: 4)
%                   .max_plies     (Default: 8)
%                   .angle_mode    ('simple' oder 'advanced', Default: 'simple')
%                   .material_pool ('all' oder 'standard', Default: 'all')
%                   .core_interface_fabric (Default: true)
%                   .verbose       (Default: true)
%
% Outputs:
%   Best        - Struct des leichtesten zulässigen Panels
%   TopList     - Array der Top-Kandidaten (sortiert nach Gewicht)
%   Baseline    - Struct des Ausgangspanels zum direkten Vergleich

if nargin < 1 || isempty(Scenario)
    Scenariodata;
end
if nargin < 2 || isempty(Calib)
    Calib = Calibration(Scenario);
end
if nargin < 3 || isempty(Targets)
    Targets = struct();
end
if nargin < 4 || isempty(OptSettings)
    OptSettings = struct();
end

% Standardwerte für Targets
if ~isfield(Targets, 'safety_factor'), Targets.safety_factor = 1.0; end
if Targets.safety_factor <= 0,          Targets.safety_factor = 1.0; end
SF = Targets.safety_factor;

if ~isfield(Targets, 'Gradient'),   Targets.Gradient = 0;   end
if ~isfield(Targets, 'Energy'),     Targets.Energy = 0;     end
if ~isfield(Targets, 'EI'),         Targets.EI = 0;         end
if ~isfield(Targets, 'UTS'),        Targets.UTS = 0;        end
if ~isfield(Targets, 'E'),          Targets.E = 0;          end
if ~isfield(Targets, 'F_max'),      Targets.F_max = 0;      end
if ~isfield(Targets, 't_skin_max'), Targets.t_skin_max = 0; end

% Standardwerte für OptSettings
if ~isfield(OptSettings, 'min_plies'),     OptSettings.min_plies = 4; end
if ~isfield(OptSettings, 'max_plies'),     OptSettings.max_plies = 8; end
if ~isfield(OptSettings, 'angle_mode'),    OptSettings.angle_mode = 'simple'; end
if ~isfield(OptSettings, 'material_pool'), OptSettings.material_pool = 'all'; end
if ~isfield(OptSettings, 'core_interface_fabric'), OptSettings.core_interface_fabric = true; end
if ~isfield(OptSettings, 'verbose'),       OptSettings.verbose = true; end

% Sichtlagen-Option (Außenlage der Deckhaut): on / off & Material
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
        OptSettings.sichtlage_material = 't7'; % Default: T700 Gewebe ('t7')
    end
end

if ~isfield(OptSettings, 'sichtlage_angle')
    if isfield(OptSettings, 'sichtlage') && isfield(OptSettings.sichtlage, 'angle')
        OptSettings.sichtlage_angle = OptSettings.sichtlage.angle;
    elseif isfield(OptSettings, 'outer_ply_angle')
        OptSettings.sichtlage_angle = OptSettings.outer_ply_angle;
    else
        OptSettings.sichtlage_angle = 45; % Default: 45°
    end
end

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'), fullfile(project_root, '01_Functions'), fullfile(project_root, '02_Data'));
csv_path = fullfile(project_root, '02_Data', 'materials.csv');

%% 1. Materialdaten und Dichten laden
mat_table = readtable(csv_path, 'Delimiter', ';');
dict_density = containers.Map();
dict_thickness = containers.Map();
for r = 1:height(mat_table)
    kname = lower(strtrim(mat_table.Kurzname{r}));
    dict_density(kname) = mat_table.Dichte(r);
    dict_thickness(kname) = mat_table.Dicke(r);
end

% Aliase
alias_pairs = {
    'ud', 'm'; 'm40jud', 'm';
    't', 't7'; 't700', 't7'; 'ft700', 't7'; 't700f', 't7'; 'ft', 't7'; 'tf', 't7';
    'fm40j', 'f'; 'm40jf', 'f'; 'mf', 'f'; 'm40jfabric', 'f'; 'm40j', 'f';
    'zz300t', 'z'; 't800', 't8'; 't800s', 't8'
};
for a = 1:size(alias_pairs, 1)
    k_src = alias_pairs{a, 2};
    k_dst = alias_pairs{a, 1};
    if isKey(dict_density, k_src)
        dict_density(k_dst) = dict_density(k_src);
        dict_thickness(k_dst) = dict_thickness(k_src);
    end
end

panel_area_m2 = (Scenario.panel.b * Scenario.panel.l) / 1e6; % 0.11 m^2
core_rho = 7.5e-11; % t/mm^3
if isKey(dict_density, 'core'), core_rho = dict_density('core'); end
gsm_cp_single = 150.0;
if isKey(dict_thickness, 'cp') && isKey(dict_density, 'cp')
    gsm_cp_single = dict_thickness('cp') * dict_density('cp') * 1e12;
end
m_cp_g   = panel_area_m2 * (2 * gsm_cp_single); % 2x CP Klebefilm (oben & unten)

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

%% 3. Generierung aller regelkonformen Kandidaten
if OptSettings.verbose
    if OptSettings.sichtlage_active
        sicht_info = sprintf('ON (%d° %s)', OptSettings.sichtlage_angle, upper(OptSettings.sichtlage_material));
    else
        sicht_info = 'OFF (frei)';
    end
    fprintf('Generiere zulässige Laminate (%d bis %d Lagen, Modus: %s, Material: %s, Sichtlage: %s)...\n', ...
        OptSettings.min_plies, OptSettings.max_plies, OptSettings.angle_mode, OptSettings.material_pool, sicht_info);
end

all_candidates = {};
for n_plies = OptSettings.min_plies : OptSettings.max_plies
    cands_n = generate_skin_candidates(n_plies, OptSettings);
    all_candidates = [all_candidates, cands_n]; %#ok<AGROW>
end
all_candidates = unique(all_candidates);

n_total = length(all_candidates);
if OptSettings.verbose
    fprintf('-> %d regelkonforme Kandidaten im Suchraum generiert.\n', n_total);
    if SF > 1.0
        fprintf('Sicherheitsfaktor aktiv: SF = %.2f (+%.1f%% Reserve auf alle Mindestwerte)\n', SF, (SF - 1)*100);
    end
    fprintf('Starte hierarchische 2-Stufen-Optimierung...\n\n');
end

%% 4. Sortierung nach theoretischem Mindestgewicht
cand_weights = zeros(n_total, 1);
for i = 1:n_total
    cand_weights(i) = calc_skin_gsm(all_candidates{i}, dict_density, dict_thickness);
end
[~, sort_idx] = sort(cand_weights, 'ascend');
all_candidates = all_candidates(sort_idx);
cand_weights = cand_weights(sort_idx);

%% 5. Hierarchische Optimierungsschleife (mit Sicherheitsfaktor)
feasible_list = {};
best_weight = inf;
t_opt_start = tic;
count_stg1_passed = 0;
count_stg2_sims = 0;

% Effektive Zielvorgaben inkl. Sicherheitsfaktor
grad_target = Targets.Gradient * SF;
ei_target   = Targets.EI * SF;
energy_target = Targets.Energy * SF;
uts_target  = Targets.UTS * SF;
e_target    = (Targets.E * 1000) * SF; % GPa -> MPa
fmax_target = Targets.F_max * SF;

for i = 1:n_total
    skin_str = all_candidates{i};
    skin_gsm = cand_weights(i);
    
    % Pruning: Wenn wir schon mindestens 5 zulässige Lösungen haben,
    % können wir Kandidaten verwerfen, die mehr als 15% schwerer sind als das beste gefundene
    if length(feasible_list) >= 5 && skin_gsm > (1.15 * best_weight)
        continue;
    end
    
    % Symmetrisches Vollpanel aufbauen:
    % [TopSkin / cp / core / cp / TopSkin_reversed]
    parts = strsplit(skin_str, '/');
    rev_parts = fliplr(parts);
    full_layup = [skin_str, '/cp/', num2str(Scenario.core_t), 'core/cp/', strjoin(rev_parts, '/')];
    
    % STUFE 1: KLT Schnell-Check (ohne teure nicht-lineare Energie-Kurve)
    t_factor = 0.95;
    if isfield(Calib, 'thickness_factor'), t_factor = Calib.thickness_factor; end
    
    cfk_props = calc_cfk_properties(full_layup, csv_path, false, t_factor, 1.0, 0.00262);
    
    % Check Deckhautdicke (Geometrische Obergrenze)
    if Targets.t_skin_max > 0 && cfk_props.t_top > Targets.t_skin_max
        continue;
    end
    
    % Check E-Modul
    if e_target > 0 && cfk_props.E_top < e_target
        continue;
    end
    
    % Schnellabschätzung Biegesteifigkeit EI
    z_top = Scenario.core_t/2 + cfk_props.t_top/2;
    I_eigen = (Scenario.panel.b * cfk_props.t_top^3) / 12;
    I_steiner = Scenario.panel.b * cfk_props.t_top * z_top^2;
    I_skin = 2 * (I_eigen + I_steiner);
    EI_approx = cfk_props.E_top * I_skin;
    
    if ei_target > 0 && EI_approx < ei_target
        continue;
    end
    
    % Schnellabschätzung Gradient
    grad_factor = 1.05;
    if isfield(Calib, 'gradient_factor'), grad_factor = Calib.gradient_factor; end
    grad_approx = (48 * EI_approx / (Scenario.panel.l^3)) * grad_factor;
    
    if grad_target > 0 && grad_approx < (grad_target * 0.92) % Mit 8% Toleranz für Schubanteil
        continue;
    end
    
    count_stg1_passed = count_stg1_passed + 1;
    
    % STUFE 2: Vollständige Simulation
    Scen_cand = Scenario;
    Scen_cand.layup = full_layup;
    Mdata = Materialdata(Scen_cand, Calib);
    Results = struct();
    Results = EI_calc(Mdata, Results, Scen_cand);
    Results = Shearstiff_calc(Results, Mdata, Scen_cand);
    [Results, Curve] = Deflection(Results, Scen_cand, Mdata);
    Results = Energy_calc(Results, Curve, Scen_cand, Mdata);
    count_stg2_sims = count_stg2_sims + 1;
    
    % Überprüfung aller aktiven Targets (inklusive Sicherheitsfaktor!)
    if grad_target > 0 && Results.Gradient < grad_target, continue; end
    if ei_target > 0 && Results.EI < ei_target, continue; end
    if energy_target > 0 && Results.Energy < energy_target, continue; end
    if uts_target > 0 && Results.UTS < uts_target, continue; end
    if e_target > 0 && Results.E < e_target, continue; end
    if fmax_target > 0 && Results.F_max < fmax_target, continue; end
    
    % ZULÄSSIGE LÖSUNG GEFUNDEN!
    cand_gsm_core = Scenario.core_t * core_rho * 1e12;
    gsm_cp_single = 150.0;
    if isKey(dict_thickness, 'cp') && isKey(dict_density, 'cp')
        gsm_cp_single = dict_thickness('cp') * dict_density('cp') * 1e12;
    end
    cand_gsm_cp   = 2 * gsm_cp_single; % 2 Lagen CP Klebefilm (oben & unten)
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
    
    feasible_list{end+1} = entry; %#ok<AGROW>
    if skin_gsm < best_weight
        best_weight = skin_gsm;
    end
end

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

% Nach Panel-Masse sortieren
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
% Generiert alle regelkonformen, balancierten Top-Skin Lagenaufbauten mit N Lagen
cands = {};

% Materialauswahl (Sigapreg und IMS ausgeschlossen)
if strcmpi(OptSettings.material_pool, 'all')
    fabric_opts = {'45t7', '45f', '45z'}; % T700 Fabric (t7), M40J Fabric (f), ZZ300T (z)
    ud_mats     = {'m', 't8'};            % M40J UD (m), T800S UD (t8)
else
    fabric_opts = {'45t7'};               % Standard: T700 Fabric (t7)
    ud_mats     = {'m', 't8'};            % Standard: M40J UD, T800S UD
end

% Winkelpalette
if strcmpi(OptSettings.angle_mode, 'advanced')
    angles = [21, 30, 45, 60];
else
    angles = [21];
end

% Sichtlage für Außenlage p1 (FSG T 3.5.7: Außenlage immer Gewebe)
if OptSettings.sichtlage_active
    s_mat = lower(strtrim(char(string(OptSettings.sichtlage_material))));
    if startsWith(s_mat, 't7') || strcmp(s_mat, 't') || strcmp(s_mat, 't700')
        s_mat = 't7'; % T700 Fabric
    elseif startsWith(s_mat, 'm40') || strcmp(s_mat, 'f') || strcmp(s_mat, 'fm40j') || strcmp(s_mat, 'm40jf')
        s_mat = 'f';  % M40J Fabric
    elseif startsWith(s_mat, 'zz') || strcmp(s_mat, 'z') || strcmp(s_mat, 'zz300t')
        s_mat = 'z';
    end
    
    s_ang = 45;
    if ~isempty(OptSettings.sichtlage_angle)
        s_ang = OptSettings.sichtlage_angle;
    end
    
    p1_opts = {[num2str(s_ang), s_mat]};
else
    p1_opts = fabric_opts; % T 3.5.7: Außenlage immer Gewebe (aus Pool)
end
if OptSettings.core_interface_fabric
    pn_opts = fabric_opts; % Kernlage bevorzugt Gewebe
else
    pn_opts = [fabric_opts, cellfun(@(u) ['0', u], ud_mats, 'UniformOutput', false)];
end

n_mid = N - 2;
mid_configs = get_balanced_mids(n_mid, ud_mats, angles, fabric_opts);

for i1 = 1:length(p1_opts)
    p1 = p1_opts{i1};
    for in = 1:length(pn_opts)
        pn = pn_opts{in};
        for im = 1:length(mid_configs)
            full_skin = [ {p1}, mid_configs{im}, {pn} ];
            if is_fsg_compliant(full_skin)
                cands{end+1} = strjoin(full_skin, '/'); %#ok<AGROW>
            end
        end
    end
end

end

function mids = get_balanced_mids(n_mid, ud_mats, angles, fabric_opts)
mids = {};

if n_mid == 0
    mids = {{}};
    return;
end

if n_mid == 1
    % 1 Innenlage: Kann nur 0-UD oder Gewebe sein (Winkel müssen balanciert sein)
    for m = 1:length(ud_mats)
        mids{end+1} = {['0', ud_mats{m}]}; %#ok<AGROW>
    end
    for f = 1:length(fabric_opts)
        mids{end+1} = {fabric_opts{f}}; %#ok<AGROW>
    end
    return;
end

if n_mid == 2
    % Option A: Zwei 0-UD
    for m1 = 1:length(ud_mats)
        for m2 = 1:length(ud_mats)
            mids{end+1} = {['0', ud_mats{m1}], ['0', ud_mats{m2}]}; %#ok<AGROW>
        end
    end
    % Option B: Ein balanciertes Winkelpaar (+ang, -ang)
    for m = 1:length(ud_mats)
        u = ud_mats{m};
        for a = 1:length(angles)
            ang = angles(a);
            mids{end+1} = {[num2str(ang), u], ['-', num2str(ang), u]}; %#ok<AGROW>
            mids{end+1} = {['-', num2str(ang), u], [num2str(ang), u]}; %#ok<AGROW>
        end
    end
    % Option C: Gewebe + 0-UD
    for f = 1:length(fabric_opts)
        for m = 1:length(ud_mats)
            mids{end+1} = {fabric_opts{f}, ['0', ud_mats{m}]}; %#ok<AGROW>
            mids{end+1} = {['0', ud_mats{m}], fabric_opts{f}}; %#ok<AGROW>
        end
    end
    return;
end

if n_mid == 3
    % 1x 0-UD + 1 balanciertes Paar
    for m_zero = 1:length(ud_mats)
        u0 = ['0', ud_mats{m_zero}];
        for m_p = 1:length(ud_mats)
            up = ud_mats{m_p};
            for a = 1:length(angles)
                ang = angles(a);
                pp = [num2str(ang), up]; pn = ['-', num2str(ang), up];
                mids{end+1} = {u0, pp, pn}; %#ok<AGROW>
                mids{end+1} = {u0, pn, pp}; %#ok<AGROW>
                mids{end+1} = {pp, u0, pn}; %#ok<AGROW>
                mids{end+1} = {pn, u0, pp}; %#ok<AGROW>
                mids{end+1} = {pp, pn, u0}; %#ok<AGROW>
                mids{end+1} = {pn, pp, u0}; %#ok<AGROW>
            end
        end
    end
    % 1x Gewebe + 1 balanciertes Paar
    for f = 1:length(fabric_opts)
        fab = fabric_opts{f};
        for m_p = 1:length(ud_mats)
            up = ud_mats{m_p};
            for a = 1:length(angles)
                ang = angles(a);
                pp = [num2str(ang), up]; pn = ['-', num2str(ang), up];
                mids{end+1} = {fab, pp, pn}; %#ok<AGROW>
                mids{end+1} = {pp, fab, pn}; %#ok<AGROW>
                mids{end+1} = {pp, pn, fab}; %#ok<AGROW>
            end
        end
    end
    return;
end

if n_mid == 4
    % 2x 0-UD + 1 balanciertes Paar
    for m1 = 1:length(ud_mats)
        u0_1 = ['0', ud_mats{m1}];
        for m2 = 1:length(ud_mats)
            u0_2 = ['0', ud_mats{m2}];
            for m_p = 1:length(ud_mats)
                up = ud_mats{m_p};
                for a = 1:length(angles)
                    ang = angles(a);
                    pp = [num2str(ang), up]; pn = ['-', num2str(ang), up];
                    mids{end+1} = {u0_1, u0_2, pp, pn}; %#ok<AGROW>
                    mids{end+1} = {u0_1, pp, u0_2, pn}; %#ok<AGROW>
                    mids{end+1} = {pp, u0_1, u0_2, pn}; %#ok<AGROW>
                    mids{end+1} = {pp, u0_1, pn, u0_2}; %#ok<AGROW>
                    mids{end+1} = {pp, pn, u0_1, u0_2}; %#ok<AGROW>
                end
            end
        end
    end
    % 2 balancierte Paare
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
                    mids{end+1} = {pp1, pn1, pp2, pn2}; %#ok<AGROW>
                    mids{end+1} = {pp1, pp2, pn2, pn1}; %#ok<AGROW>
                end
            end
        end
    end
    return;
end

if n_mid >= 5
    % Rekursiver Fallback mit automatischem Clumping-Filter
    base_mids = get_balanced_mids(n_mid - 2, ud_mats, angles, fabric_opts);
    for b = 1:min(100, length(base_mids))
        sub = base_mids{b};
        for m = 1:length(ud_mats)
            u = ud_mats{m};
            for a = 1:length(angles)
                ang = angles(a);
                mids{end+1} = [{[num2str(ang), u]}, sub, {['-', num2str(ang), u]}]; %#ok<AGROW>
            end
        end
    end
end

end

function compliant = is_fsg_compliant(plies)
compliant = false;
N = length(plies);

% 1. FSG T 3.5.7: Äußerste Lage MUSS Gewebe sein
p1 = plies{1};
if ~contains(p1, 'f') && ~contains(p1, 't') && ~contains(p1, 'z')
    return;
end

% 2. Balance: Für jedes +Winkel muss ein -Winkel des gleichen Materials existieren
counts_map = containers.Map();
for i = 1:N
    p = plies{i};
    if contains(p, 'f') || contains(p, 't') || contains(p, 'z')
        continue; % Gewebe ist von sich aus balanciert
    end
    c = p; idx = 1;
    if c(1) == '-' || c(1) == '+', idx = 2; end
    while idx <= length(c) && c(idx) >= '0' && c(idx) <= '9'
        idx = idx + 1;
    end
    ang = sscanf(c(1:idx-1), '%f');
    mat = c(idx:end);
    if ang == 0 || ang == 90, continue; end
    
    key = [num2str(abs(ang)), '_', mat];
    sign_val = sign(ang);
    if isKey(counts_map, key)
        counts_map(key) = counts_map(key) + sign_val;
    else
        counts_map(key) = sign_val;
    end
end

keys_all = keys(counts_map);
for k = 1:length(keys_all)
    if counts_map(keys_all{k}) ~= 0
        return; % Unbalanciertes Winkelpaar
    end
end

% 3. FSG T 3.5.3: 50%-Regel für 0°-Lagen
count_zero = sum(cellfun(@(x) startsWith(x, '0'), plies));
if (count_zero / N) > 0.50
    return;
end

% 4. Ply-Clumping: Nicht mehr als 2 gleiche Lagen hintereinander
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

function gsm = calc_skin_gsm(layup_str, dict_rho, dict_t)
% Berechnet das Flächengewicht (g/m^2) einer Deckhaut (Top Skin)
parts = strsplit(layup_str, '/');
% Wenn ein Kern enthalten ist, nur die obere Deckhaut (vor dem Kern) betrachten
idx_core = find(contains(lower(parts), 'core'), 1);
if ~isempty(idx_core)
    parts = parts(1:idx_core-1);
end

gsm = 0;
for i = 1:length(parts)
    p = lower(strtrim(parts{i}));
    if isempty(p) || strcmp(p, 'cp'), continue; end
    
    % Material extrahieren (nach Winkel)
    c = p;
    idx = 1;
    if c(1) == '-' || c(1) == '+', idx = 2; end
    while idx <= length(c) && c(idx) >= '0' && c(idx) <= '9'
        idx = idx + 1;
    end
    mat_code = c(idx:end);
    
    t_ply = 0.22; % Default
    rho_ply = 1.5e-9;
    
    if isKey(dict_t, mat_code)
        t_ply = dict_t(mat_code);
    end
    if isKey(dict_rho, mat_code)
        rho_ply = dict_rho(mat_code);
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
        fprintf('  - Sichtlage:       ON  (Material: %s, Winkel: %d°)\n', ...
            upper(OptSettings.sichtlage_material), OptSettings.sichtlage_angle);
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
fprintf('%-4s | %-7s | %-10s | %-8s | %-12s | %-10s | %-24s | %-45s\n', ...
    'Rang', 'Masse', 'Gesamt-GSM', 'Delta', 'Gradient', 'Energie', 'Top-Skin', 'Voll-Lagenaufbau (inkl. CP & Kern)');
fprintf('%-4s | %-7s | %-10s | %-8s | %-12s | %-10s | %-24s | %-45s\n', ...
    '', '[g]', '[g/m^2]', '[%]', '[N/mm]', '[J]', '', '');
fprintf('%s\n', repmat('-', 1, 140));
for r = 1:length(TopList)
    cand = TopList(r);
    cand_delta_pct = ((cand.mass_panel - Base.mass_panel) / Base.mass_panel) * 100;
    fprintf('#%-3d | %6.1f  | %6.0f     | %+6.1f%% | %6.0f N/mm | %6.1f J   | %-24s | %s\n', ...
        r, cand.mass_panel, cand.gsm_total, cand_delta_pct, cand.Gradient, cand.Energy, cand.top_skin, cand.layup);
end
fprintf('====================================================================================================\n\n');
end
