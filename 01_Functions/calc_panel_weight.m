function Weight = calc_panel_weight(layup_or_scenario, core_t_in, panel_b_in, panel_l_in)
% CALC_PANEL_WEIGHT Berechnet Gesamtmasse und Flächengewichte eines SES Panels
%
% Syntax:
%   Weight = calc_panel_weight(Scenario)
%   Weight = calc_panel_weight(layup_str, [core_t], [panel_b], [panel_l])

% 1. Eingaben normalisieren
panel_span = 400;
if isstruct(layup_or_scenario)
    Scenario = layup_or_scenario;
    layup_str = Scenario.layup;
    if isfield(Scenario, 'core_t')
        core_t_default = Scenario.core_t;
    else
        core_t_default = 18;
    end
    if isfield(Scenario, 'panel') && isfield(Scenario.panel, 'b')
        panel_b = Scenario.panel.b;
        if isfield(Scenario.panel, 'span') && ~isempty(Scenario.panel.span)
            panel_span = Scenario.panel.span;
        elseif isfield(Scenario.panel, 'l')
            panel_span = Scenario.panel.l;
        end
        if isfield(Scenario.panel, 'l_real') && ~isempty(Scenario.panel.l_real)
            panel_l = Scenario.panel.l_real;
        elseif isfield(Scenario.panel, 'l') && Scenario.panel.l > 400
            panel_l = Scenario.panel.l;
        else
            panel_l = 500; % Reale Mindest-Panellänge nach SES-Reglement (500 x 275 mm)
        end
    else
        panel_b = 275;
        panel_l = 500;
    end
else
    layup_str = layup_or_scenario;
    if nargin >= 2 && ~isempty(core_t_in), core_t_default = core_t_in; else, core_t_default = 18; end
    if nargin >= 3 && ~isempty(panel_b_in), panel_b = panel_b_in; else, panel_b = 275; end
    if nargin >= 4 && ~isempty(panel_l_in), panel_l = panel_l_in; else, panel_l = 500; end
end

% 2. Materialdatenbank via Singleton laden
csv_path = '';
if isstruct(layup_or_scenario)
    if isfield(layup_or_scenario, 'materials_csv')
        csv_path = layup_or_scenario.materials_csv;
    elseif isfield(layup_or_scenario, 'csv_path')
        csv_path = layup_or_scenario.csv_path;
    end
end
mat_dict = load_materials(csv_path);

% 3. Lagenaufbau kanonisch parsen
[top_parts, lower_parts, detected_core_t, ~, n_cp, ~, ~, detected_core_mat] = parse_layup(layup_str, core_t_default);

has_core = ~isempty(detected_core_mat) || (~isnan(detected_core_t) && detected_core_t > 0);
if has_core
    core_t = core_t_default;
    if n_cp == 0
        n_cp = 2;
    end
else
    core_t = 0;
end

% 4. Flächengewichte der Einzelschichten berechnen
gsm_top = calc_plies_gsm(top_parts, mat_dict);

if isempty(lower_parts)
    gsm_lower = 0;
elseif isequal(top_parts, lower_parts)
    gsm_lower = gsm_top;
else
    gsm_lower = calc_plies_gsm(lower_parts, mat_dict);
end

gsm_skins = gsm_top + gsm_lower;

% Kern-Flächengewicht
core_mat_used = 'core';
if isstruct(layup_or_scenario) && isfield(layup_or_scenario, 'core_mat') && ~isempty(layup_or_scenario.core_mat)
    core_mat_used = layup_or_scenario.core_mat;
elseif ~isempty(detected_core_mat)
    core_mat_used = detected_core_mat;
end

core_rho = 7.5e-11; % t/mm^3
if isfield(mat_dict, core_mat_used) && isfield(mat_dict.(core_mat_used), 'rho')
    core_rho = mat_dict.(core_mat_used).rho;
elseif isfield(mat_dict, 'core')
    core_rho = mat_dict.core.rho;
end

if has_core
    gsm_core = core_t * core_rho * 1e12;
else
    gsm_core = 0;
end

% Klebefilm (cp) Flächengewicht
gsm_cp_single = 150.0; % g/m^2 pro Klebefilmschicht
if isfield(mat_dict, 'cp')
    gsm_cp_single = mat_dict.cp.t_ply * mat_dict.cp.rho * 1e12;
end
gsm_cp = n_cp * gsm_cp_single;

% GESAMT-Flächengewicht
gsm_total = gsm_skins + gsm_core + gsm_cp;

% 5. Panelmasse für Prüfgeometrie
area_m2 = (panel_b * panel_l) / 1e6;

mass_top   = gsm_top * area_m2;
mass_lower = gsm_lower * area_m2;
mass_skins = gsm_skins * area_m2;
mass_core  = gsm_core * area_m2;
mass_cp    = gsm_cp * area_m2;
mass_panel = gsm_total * area_m2;

% 6. Rückgabestruktur
Weight = struct();
Weight.gsm_top     = gsm_top;
Weight.gsm_lower   = gsm_lower;
Weight.gsm_skins   = gsm_skins;
Weight.gsm_core    = gsm_core;
Weight.gsm_cp      = gsm_cp;
Weight.gsm_total   = gsm_total;

Weight.mass_top    = mass_top;
Weight.mass_lower  = mass_lower;
Weight.mass_skins  = mass_skins;
Weight.mass_core   = mass_core;
Weight.mass_cp     = mass_cp;
Weight.mass_panel  = mass_panel;

Weight.area_m2     = area_m2;
Weight.panel_b     = panel_b;
Weight.panel_l     = panel_l;
Weight.span        = panel_span;
Weight.core_t      = core_t;
Weight.n_cp        = n_cp;

end

function gsm = calc_plies_gsm(plies, mat_dict)
gsm = 0;
for i = 1:length(plies)
    token = plies{i};
    if isempty(token) || strcmpi(token, 'cp')
        continue;
    end
    [~, mat_code] = parse_ply_token(token);
    
    t_ply = 0.22;
    rho_ply = 1.5e-9;
    if isfield(mat_dict, mat_code)
        t_ply = mat_dict.(mat_code).t_ply;
        rho_ply = mat_dict.(mat_code).rho;
    end
    gsm = gsm + (t_ply * rho_ply * 1e12);
end
end
