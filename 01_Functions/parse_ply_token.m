function [angle_deg, mat_code] = parse_ply_token(token)
% PARSE_PLY_TOKEN Trennt Vorzeichen/Winkel und Materialkürzel eines Lagen-Tokens
%   [angle_deg, mat_code] = parse_ply_token('45fM40J') -> 45, 'fm40j'
%   [angle_deg, mat_code] = parse_ply_token('-21m')    -> -21, 'm'

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
