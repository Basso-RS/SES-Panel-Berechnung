function Weight = calc_panel_weight(layup_or_scenario, core_t_in, panel_b_in, panel_l_in)
%% CALC_PANEL_WEIGHT Berechnet Gesamtmasse und Flächengewichte eines SES Panels
%
% Syntax:
%   Weight = calc_panel_weight(Scenario)
%   Weight = calc_panel_weight(layup_str, [core_t], [panel_b], [panel_l])
%
% Rückgabe-Struct Weight:
%   .gsm_top        - Flächengewicht der oberen Deckhaut [g/m^2]
%   .gsm_lower      - Flächengewicht der unteren Deckhaut [g/m^2]
%   .gsm_skins      - Flächengewicht beider CFK-Deckhäute zusammen [g/m^2]
%   .gsm_core       - Flächengewicht Wabenkern [g/m^2]
%   .gsm_cp         - Flächengewicht Klebefilme [g/m^2]
%   .gsm_total      - GESAMT-Flächengewicht Panel (Sandwich komplett) [g/m^2]
%   .mass_panel     - GESAMTES Panelgewicht [g] für Prüfpanel
%   .mass_skins     - Masse beider CFK-Deckhäute [g]
%   .mass_top       - Masse obere Deckhaut [g]
%   .mass_lower     - Masse untere Deckhaut [g]
%   .mass_core      - Masse Wabenkern [g]
%   .mass_cp        - Masse Klebefilme [g]
%   .area_m2        - Prüffläche [m^2]

%% 1. Eingaben normalisieren
if isstruct(layup_or_scenario)
    Scenario = layup_or_scenario;
    layup_str = Scenario.layup;
    if isfield(Scenario, 'core_t')
        core_t = Scenario.core_t;
    else
        core_t = 18;
    end
    if isfield(Scenario, 'panel') && isfield(Scenario.panel, 'b')
        panel_b = Scenario.panel.b;
        panel_l = Scenario.panel.l;
    else
        panel_b = 275;
        panel_l = 400;
    end
else
    layup_str = layup_or_scenario;
    if nargin >= 2 && ~isempty(core_t_in), core_t = core_t_in; else, core_t = 18; end
    if nargin >= 3 && ~isempty(panel_b_in), panel_b = panel_b_in; else, panel_b = 275; end
    if nargin >= 4 && ~isempty(panel_l_in), panel_l = panel_l_in; else, panel_l = 400; end
end

%% 2. Materialdatenbank (materials.csv) laden
this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
csv_path = fullfile(project_root, '02_Data', 'materials.csv');

dict_rho = containers.Map();
dict_t   = containers.Map();

if exist(csv_path, 'file')
    opts = detectImportOptions(csv_path, 'Delimiter', ';');
    opts.VariableNamingRule = 'preserve';
    mat_table = readtable(csv_path, opts);
    for r = 1:height(mat_table)
        kname = lower(strtrim(char(string(mat_table.Kurzname(r)))));
        dict_rho(kname) = mat_table.Dichte(r);
        dict_t(kname)   = mat_table.Dicke(r);
    end
else
    % Fallback falls CSV nicht auffindbar
    dict_rho('f')     = 1.49e-9; dict_t('f')     = 0.23; % M40J Fabric
    dict_rho('m')     = 1.52e-9; dict_t('m')     = 0.21; % M40J UD
    dict_rho('t7')    = 1.51e-9; dict_t('t7')    = 0.31; % T700 Fabric
    dict_rho('z')     = 0.78e-9; dict_t('z')     = 0.38;
    dict_rho('t8')    = 1.54e-9; dict_t('t8')    = 0.15;
    dict_rho('cp')    = 1.00e-9; dict_t('cp')    = 0.15; % 150 g/m^2 Klebefilm pro Lage
    dict_rho('core')  = 7.5e-11; dict_t('core')  = 18;
end

% Umfassende Aliase
alias_pairs = {
    'ud', 'm'; 'm40jud', 'm';
    't', 't7'; 't700', 't7'; 'ft700', 't7'; 't700f', 't7'; 'ft', 't7'; 'tf', 't7';
    'fm40j', 'f'; 'm40jf', 'f'; 'mf', 'f'; 'm40jfabric', 'f'; 'm40j', 'f';
    'zz300t', 'z'; 't800', 't8'; 't800s', 't8'; 'sigapreg', 'a'
};
for a = 1:size(alias_pairs, 1)
    k_src = alias_pairs{a, 2};
    k_dst = alias_pairs{a, 1};
    if isKey(dict_rho, k_src)
        dict_rho(k_dst) = dict_rho(k_src);
        dict_t(k_dst)   = dict_t(k_src);
    end
end

%% 3. String in Top-Skin, Kern und Lower-Skin zerlegen
clean_str = strrep(layup_str, '45a0a', '45a/0a');
clean_str = regexprep(clean_str, '(\d+)/core', '$1core', 'ignorecase');
parts = strsplit(clean_str, '/');
parts = strtrim(parts);
parts(cellfun(@isempty, parts)) = [];

idx_core = find(contains(lower(parts), 'core'), 1);
has_core = ~isempty(idx_core);

n_cp = sum(strcmpi(parts, 'cp'));

if has_core
    core_token = lower(parts{idx_core});
    core_num = sscanf(core_token, '%f');
    if ~isempty(core_num) && core_num > 0
        core_t = core_num;
    end
    
    top_parts = parts(1:idx_core-1);
    lower_parts = parts(idx_core+1:end);
    
    if isempty(lower_parts) || any(contains(lower(lower_parts), 'sym'))
        lower_parts = fliplr(top_parts);
    end
    
    % Wenn im String kein explizites 'cp' steht, aber ein Kern vorhanden ist,
    % werden standardmäßig 2 Lagen Klebefilm (oben & unten) angenommen
    if n_cp == 0
        n_cp = 2;
    end
else
    top_parts = parts;
    lower_parts = {};
end

% 'cp' aus den CFK-Lagenfiltern entfernen
top_parts(strcmpi(top_parts, 'cp')) = [];
lower_parts(strcmpi(lower_parts, 'cp')) = [];

%% 4. Flächengewichte der Einzelschichten berechnen
gsm_top = calc_plies_gsm(top_parts, dict_rho, dict_t);

if ~isempty(lower_parts)
    gsm_lower = calc_plies_gsm(lower_parts, dict_rho, dict_t);
else
    % Reines Laminat ohne Kern
    gsm_lower = 0;
end

gsm_skins = gsm_top + gsm_lower;

% Kern-Flächengewicht
core_rho = 7.5e-11; % t/mm^3
if isKey(dict_rho, 'core'), core_rho = dict_rho('core'); end
if has_core
    gsm_core = core_t * core_rho * 1e12; % g/m^2 (z.B. 18 mm * 75 g/m^2/mm = 1350 g/m^2)
else
    gsm_core = 0;
end

% Klebefilm (cp) Flächengewicht
gsm_cp_single = 150.0; % g/m^2 pro Klebefilmschicht (Standard z.B. Redux 312 / Gurit SA 70)
if isKey(dict_t, 'cp') && isKey(dict_rho, 'cp')
    gsm_cp_single = dict_t('cp') * dict_rho('cp') * 1e12;
end
gsm_cp = n_cp * gsm_cp_single;

% GESAMT-Flächengewicht
gsm_total = gsm_skins + gsm_core + gsm_cp;

%% 5. Panelmasse für Prüfgeometrie
area_m2 = (panel_b * panel_l) / 1e6;

mass_top   = gsm_top * area_m2;
mass_lower = gsm_lower * area_m2;
mass_skins = gsm_skins * area_m2;
mass_core  = gsm_core * area_m2;
mass_cp    = gsm_cp * area_m2;
mass_panel = gsm_total * area_m2;

%% 6. Rückgabestruktur
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
Weight.core_t      = core_t;
Weight.n_cp        = n_cp;
end

function gsm = calc_plies_gsm(plies, dict_rho, dict_t)
gsm = 0;
for i = 1:length(plies)
    p = lower(strtrim(plies{i}));
    if isempty(p) || strcmp(p, 'cp'), continue; end
    
    % Materialcode nach Winkel extrahieren
    c = p;
    idx = 1;
    if c(1) == '-' || c(1) == '+', idx = 2; end
    while idx <= length(c) && c(idx) >= '0' && c(idx) <= '9'
        idx = idx + 1;
    end
    mat_code = c(idx:end);
    
    t_ply = 0.22;
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
