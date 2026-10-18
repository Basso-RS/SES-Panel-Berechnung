function [top_plies, lower_plies, core_t, core_dir, n_cp, is_sym, full_layup_str, core_mat] = parse_layup(layup_str, default_core_t, default_core_dir)
% PARSE_LAYUP Kanonischer Parser für SES Laminataufbauten
%
% Syntax:
%   [top_plies, lower_plies, core_t, core_dir, n_cp, is_sym, full_layup_str, core_mat] = parse_layup(layup_str, default_core_t, default_core_dir)

if nargin < 2 || isempty(default_core_t)
    default_core_t = 18;
end
if nargin < 3 || isempty(default_core_dir)
    default_core_dir = 'L';
end

% Materialdatenbank für Kern- und Gewebeerkennung laden
try
    mat_dict = load_materials();
catch
    mat_dict = struct();
end

% Schreibweisen bereinigen
layup_str = char(layup_str);
layup_str = strrep(layup_str, '45a0a', '45a/0a');
layup_str = regexprep(layup_str, '(\d+)/core', '$1core', 'ignorecase');
layup_str = regexprep(layup_str, 'sym\.', 'sym', 'ignorecase');

% An '/' splitten und leere Elemente entfernen
parts = strsplit(layup_str, '/');
parts = strtrim(parts);
parts(cellfun(@isempty, parts)) = [];

% Kern dynamisch suchen: entweder Kern-Schlüsselwort im Namen oder in mat_dict als Kern definiert
idx_core = [];
core_keywords = {'core', 'foam', 'schaum', 'wabe', 'rohacell', 'nomex', 'honeycomb'};
for p = 1:length(parts)
    part_str = lower(parts{p});
    if contains(part_str, core_keywords)
        idx_core = p;
        break;
    end
    [p_num, p_mat] = parse_ply_token(part_str);
    if isfield(mat_dict, p_mat) && isfield(mat_dict.(p_mat), 'is_core') && mat_dict.(p_mat).is_core
        idx_core = p;
        break;
    end
end

if isempty(idx_core)
    % Monolithisches Laminat ohne Kern
    core_t = NaN;
    core_dir = '';
    core_mat = '';
    
    if ~isempty(parts) && strcmpi(parts{end}, 'sym')
        is_sym = true;
        top_raw = parts(1:end-1);
        lower_raw = cell(1, length(top_raw));
        for k = 1:length(top_raw)
            lower_raw{k} = mirror_ply_token(top_raw{length(top_raw) - k + 1}, mat_dict);
        end
        all_parts = [top_raw, lower_raw];
    else
        is_sym = false;
        top_raw = parts;
        lower_raw = {};
        all_parts = parts;
    end
    
    n_cp = sum(strcmpi(all_parts, 'cp'));
    top_plies = top_raw(~strcmpi(top_raw, 'cp'));
    lower_plies = lower_raw(~strcmpi(lower_raw, 'cp'));
    full_layup_str = strjoin(all_parts, '/');
    return;
end

% Sandwich-Laminat mit Kern
core_token = lower(parts{idx_core});
[core_num, core_mat_raw] = parse_ply_token(core_token);
if core_num > 0
    core_t = core_num;
else
    core_t = default_core_t;
end

if strcmpi(core_mat_raw, 'corew')
    core_dir = 'W';
    core_mat = 'core';
elseif strcmpi(core_mat_raw, 'corel')
    core_dir = 'L';
    core_mat = 'core';
elseif endsWith(core_mat_raw, 'w') && ~isfield(mat_dict, core_mat_raw)
    core_dir = 'W';
    core_mat = core_mat_raw(1:end-1);
elseif endsWith(core_mat_raw, 'l') && ~isfield(mat_dict, core_mat_raw) && ~strcmpi(core_mat_raw, 'rohacell')
    core_dir = 'L';
    core_mat = core_mat_raw(1:end-1);
else
    core_dir = upper(default_core_dir);
    core_mat = core_mat_raw;
end

if isempty(core_mat) || strcmpi(core_mat, 'core')
    core_mat = 'core';
end

top_raw = parts(1:idx_core-1);
lower_raw = parts(idx_core+1:end);

% Symmetrischer Aufbau ('sym' oder leer nach Kern)
if isempty(lower_raw) || any(strcmpi(lower_raw, 'sym')) || any(contains(lower(lower_raw), 'sym'))
    is_sym = true;
    % Alle Token vor dem Kern (inkl. cp und Winkellagen) spiegelbildlich umkehren
    lower_raw = cell(1, length(top_raw));
    for k = 1:length(top_raw)
        lower_raw{k} = mirror_ply_token(top_raw{length(top_raw) - k + 1}, mat_dict);
    end
else
    % Prüfen, ob manuell eingegebene Unterseite symmetrisch ist
    mirrored_expected = cell(1, length(top_raw));
    for k = 1:length(top_raw)
        mirrored_expected{k} = mirror_ply_token(top_raw{length(top_raw) - k + 1}, mat_dict);
    end
    is_sym = isequal(lower_raw, mirrored_expected);
end

% Vollständigen Lagenaufbau-String zusammensetzen
full_parts = [top_raw, parts(idx_core), lower_raw];
full_layup_str = strjoin(full_parts, '/');

% CP zählen (über alle Teile inkl. gespiegelter Seite)
n_cp = sum(strcmpi(full_parts, 'cp'));

% Tragende CFK-Lagen extrahieren (ohne CP)
top_plies = top_raw(~strcmpi(top_raw, 'cp'));
lower_plies = lower_raw(~strcmpi(lower_raw, 'cp'));

end

function mirrored_token = mirror_ply_token(token, mat_dict)
% MIRROR_PLY_TOKEN Spiegelt ein Einzellagen-Token inkl. cp und Winkelinvertierung
token = strtrim(char(token));
if isempty(token)
    mirrored_token = '';
    return;
end

% Klebefilm bleibt Klebefilm
if strcmpi(token, 'cp')
    mirrored_token = 'cp';
    return;
end

[angle_deg, mat_code] = parse_ply_token(token);

% Bei 0 Grad oder leerem Material keine Vorzeichenänderung nötig
if angle_deg == 0 || isempty(mat_code)
    mirrored_token = token;
    return;
end

% Prüfen, ob Material ein Gewebe (Fabric) ist
is_fab = false;
if nargin >= 2 && isstruct(mat_dict) && isfield(mat_dict, mat_code)
    if isfield(mat_dict.(mat_code), 'is_fabric')
        is_fab = mat_dict.(mat_code).is_fabric;
    end
end
if ~is_fab
    fabric_codes = {'f', 't7', 'z', 'a'};
    is_fab = ismember(lower(mat_code), fabric_codes);
end

% Gewebe bei 45 Grad bleibt 45 Grad
if is_fab && abs(angle_deg) == 45
    mirrored_token = token;
    return;
end

% Für UD-Lagen Vorzeichen umkehren (+21 -> -21, -21 -> 21)
new_angle = -angle_deg;
mirrored_token = sprintf('%g%s', new_angle, mat_code);

end

function [angle_deg, mat_code] = parse_ply_token(token)
% PARSE_PLY_TOKEN Trennt Vorzeichen/Winkel und Materialkürzel
token = strtrim(char(token));
if isempty(token)
    angle_deg = 0;
    mat_code = '';
    return;
end

c = token;
idx = 1;
if c(1) == '-' || c(1) == '+'
    idx = 2;
end
while idx <= length(c) && ((c(idx) >= '0' && c(idx) <= '9') || c(idx) == '.')
    idx = idx + 1;
end

if idx > 1 && (idx > 2 || (c(1) ~= '-' && c(1) ~= '+'))
    angle_deg = sscanf(c(1:idx-1), '%f');
    if isempty(angle_deg), angle_deg = 0; end
else
    angle_deg = 0;
end
mat_code = lower(strtrim(c(idx:end)));
end
