function [top_plies, lower_plies, core_t, core_dir, n_cp, is_sym] = parse_layup(layup_str, default_core_t, default_core_dir)
% PARSE_LAYUP Kanonischer Parser für SES Laminataufbauten
%
% Syntax:
%   [top_plies, lower_plies, core_t, core_dir, n_cp, is_sym] = parse_layup(layup_str, default_core_t, default_core_dir)

if nargin < 2 || isempty(default_core_t)
    default_core_t = 18;
end
if nargin < 3 || isempty(default_core_dir)
    default_core_dir = 'L';
end

% Schreibweisen bereinigen
layup_str = char(layup_str);
layup_str = strrep(layup_str, '45a0a', '45a/0a');
layup_str = regexprep(layup_str, '(\d+)/core', '$1core', 'ignorecase');

% An '/' splitten und leere Elemente entfernen
parts = strsplit(layup_str, '/');
parts = strtrim(parts);
parts(cellfun(@isempty, parts)) = [];

% Nicht-tragenden Klebefilm ('cp') zählen und entfernen
is_cp = strcmpi(parts, 'cp');
n_cp = sum(is_cp);
parts(is_cp) = [];

% Kern suchen
idx_core = find(contains(lower(parts), 'core'), 1);

if isempty(idx_core)
    % Monolithisches Laminat ohne Kern
    top_plies = parts;
    lower_plies = {};
    core_t = NaN;
    core_dir = '';
    is_sym = false;
else
    core_token = lower(parts{idx_core});
    core_num = sscanf(core_token, '%f');
    if ~isempty(core_num) && core_num > 0
        core_t = core_num;
    else
        core_t = default_core_t;
    end
    
    if contains(core_token, 'w')
        core_dir = 'W';
    elseif contains(core_token, 'l')
        core_dir = 'L';
    else
        core_dir = upper(default_core_dir);
    end
    
    top_plies = parts(1:idx_core-1);
    lower_raw = parts(idx_core+1:end);
    
    % Symmetrischer Aufbau ('sym' oder leer nach Kern)
    if isempty(lower_raw) || any(contains(lower(lower_raw), 'sym'))
        is_sym = true;
        lower_plies = fliplr(top_plies);
    else
        lower_plies = lower_raw;
        is_sym = isequal(lower_plies, fliplr(top_plies));
    end
end

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
