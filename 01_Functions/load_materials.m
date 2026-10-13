function [mat_dict, E_core, G_core] = load_materials(materials_csv_path, force_reload)
% LOAD_MATERIALS Singleton Material-Datenbank Loader mit RAM-Caching
%
% Syntax:
%   [mat_dict, E_core, G_core] = load_materials(materials_csv_path, force_reload)

if nargin < 1 || isempty(materials_csv_path)
    this_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(this_dir);
    materials_csv_path = fullfile(project_root, '02_Data', 'materials.csv');
end
if nargin < 2 || isempty(force_reload)
    force_reload = false;
end

persistent cached_dict cached_path cached_E cached_G

if ~force_reload && ~isempty(cached_dict) && strcmp(cached_path, materials_csv_path)
    mat_dict = cached_dict;
    E_core   = cached_E;
    G_core   = cached_G;
    return;
end

opts = detectImportOptions(materials_csv_path, 'Delimiter', ';');
opts.VariableNamingRule = 'preserve';
for i = 1:length(opts.VariableNames)
    varName = opts.VariableNames{i};
    if ismember(varName, {'Name', 'Kurzname'})
        opts = setvartype(opts, varName, 'string');
    else
        opts = setvartype(opts, varName, 'double');
    end
end
mat_table = readtable(materials_csv_path, opts);

cached_dict = struct();
for r = 1:height(mat_table)
    kname = lower(strtrim(char(mat_table.Kurzname(r))));
    E1   = mat_table.E1(r);
    E2   = mat_table.E2(r);
    G12  = mat_table.G12(r);
    nu12 = mat_table.N12(r);
    
    t_ply = mat_table.Dicke(r);
    if isnan(t_ply) || t_ply <= 0, t_ply = 0.2; end
    
    rho = mat_table.Dichte(r);
    if isnan(rho) || rho <= 0, rho = 1.5e-9; end
    
    nu21 = 0;
    if E1 > 0, nu21 = nu12 * E2 / E1; end
    den = 1 - nu12 * nu21;
    if den == 0, den = 1; end
    
    entry = struct();
    entry.Name  = char(mat_table.Name(r));
    entry.t_ply = t_ply;
    entry.rho   = rho;
    entry.Q11   = E1 / den;
    entry.Q22   = E2 / den;
    entry.Q12   = (nu12 * E2) / den;
    entry.Q66   = G12;
    entry.Q     = [entry.Q11, entry.Q12, 0; entry.Q12, entry.Q22, 0; 0, 0, entry.Q66];
    
    entry.E1    = E1;
    entry.E2    = E2;
    entry.G12   = G12;
    entry.nu12  = nu12;
    
    Xt = mat_table.Xt(r);  if Xt <= 0, Xt = 1e6; end
    Xc = mat_table.Xc(r);  if Xc <= 0, Xc = 1e6; end
    Yt = mat_table.Yt(r);  if Yt <= 0, Yt = 1e6; end
    Yc = mat_table.Yc(r);  if Yc <= 0, Yc = 1e6; end
    S  = mat_table.S12(r); if S <= 0,  S  = 1e6; end
    
    entry.Xt = Xt;
    entry.Xc = Xc;
    entry.Yt = Yt;
    entry.Yc = Yc;
    entry.S  = S;
    
    cached_dict.(kname) = entry;
end

% Aliase zuweisen
% 'm': 'ud', 'm40jud', 'hm'
if isfield(cached_dict, 'm')
    cached_dict.ud     = cached_dict.m;
    cached_dict.m40jud = cached_dict.m;
    cached_dict.hm     = cached_dict.m;
end
% 't7': 't', 't700', 'ft700', 't700f', 'ft', 'tf'
if isfield(cached_dict, 't7')
    cached_dict.t     = cached_dict.t7;
    cached_dict.t700  = cached_dict.t7;
    cached_dict.ft700 = cached_dict.t7;
    cached_dict.t700f = cached_dict.t7;
    cached_dict.ft    = cached_dict.t7;
    cached_dict.tf    = cached_dict.t7;
end
% 'f': 'fm40j', 'm40jf', 'mf', 'm40jfabric', 'm40j'
if isfield(cached_dict, 'f')
    cached_dict.fm40j      = cached_dict.f;
    cached_dict.m40jf      = cached_dict.f;
    cached_dict.mf         = cached_dict.f;
    cached_dict.m40jfabric = cached_dict.f;
    cached_dict.m40j       = cached_dict.f;
end
% 't8': 't800', 't800s', 'u8'
if isfield(cached_dict, 't8')
    cached_dict.t800  = cached_dict.t8;
    cached_dict.t800s = cached_dict.t8;
    cached_dict.u8    = cached_dict.t8;
end
% 'z': 'zz300t'
if isfield(cached_dict, 'z')
    cached_dict.zz300t = cached_dict.z;
end
% 'a': 'aramid', 'kevlar'
if isfield(cached_dict, 'a')
    cached_dict.aramid   = cached_dict.a;
    cached_dict.kevlar   = cached_dict.a;
    cached_dict.sigapreg = cached_dict.a;
end

% E_core und G_core für 'Core' extrahieren
cached_E = NaN;
cached_G = NaN;
idx_core_mat = find(strcmpi(mat_table.Kurzname, 'Core'), 1);
if ~isempty(idx_core_mat)
    cached_E = mat_table.E3(idx_core_mat);
    if cached_E == 0 || isnan(cached_E), cached_E = mat_table.E1(idx_core_mat); end
    cached_G = mat_table.G13(idx_core_mat);
    if cached_G == 0 || isnan(cached_G), cached_G = mat_table.G12(idx_core_mat); end
end

cached_path = materials_csv_path;
mat_dict = cached_dict;
E_core   = cached_E;
G_core   = cached_G;
end
