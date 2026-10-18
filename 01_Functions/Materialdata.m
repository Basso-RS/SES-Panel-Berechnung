function Mdata = Materialdata(Scenario, Calib)
% MATERIALDATA Erstellt das Materialdaten-Struct für die Berechnung.

if nargin < 1 || isempty(Scenario)
    Scenario = Scenariodata();
end

if nargin < 2 || isempty(Calib)
    Calib = Calibration();
end

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
csv_path = fullfile(project_root, '02_Data', 'materials.csv');

calc_energy = true;
if isfield(Scenario, 'calc_energy')
    calc_energy = Scenario.calc_energy;
end

% Kompaktierungsfaktor
t_factor = 1.0;
if isfield(Calib, 'thickness_factor')
    t_factor = Calib.thickness_factor;
elseif isfield(Calib, 'layup_thickness_factor')
    t_factor = Calib.layup_thickness_factor;
elseif isfield(Scenario, 't_factor')
    t_factor = Scenario.t_factor;
end

% Bruchdehnung der Deckhaut (optional)
failure_strain = [];
if isfield(Calib, 'failure_strain') && ~isempty(Calib.failure_strain)
    failure_strain = Calib.failure_strain;
end

use_lpf = false;
if isfield(Calib, 'use_lpf') && ~isempty(Calib.use_lpf)
    use_lpf = Calib.use_lpf;
end

% KLT-Berechnung der Deckhäute
if ~isfield(Scenario, 'layup') || isempty(Scenario.layup)
    cfk_props.E_top = 80000;
    cfk_props.t_top = 1.0;
    cfk_props.E_lower = 80000;
    cfk_props.t_lower = 1.0;
    cfk_props.UTS = 300;
    cfk_props.core_t = 18;
    cfk_props.core_dir = '';
else
    cfk_props = calc_cfk_properties(Scenario.layup, csv_path, calc_energy, t_factor, failure_strain, use_lpf);
end

Mdata = struct();
Mdata.cfk.E_top      = cfk_props.E_top;
Mdata.cfk.t_top      = cfk_props.t_top;
Mdata.cfk.E_lower    = cfk_props.E_lower;
Mdata.cfk.t_lower    = cfk_props.t_lower;
Mdata.cfk.UTS        = cfk_props.UTS;

% Kerneigenschaften (dynamisch aus Materialdatenbank oder Fallback Plascore PAMG-XR1-5056)
core_mat = 'core';
if isfield(cfk_props, 'core_mat') && ~isempty(cfk_props.core_mat)
    core_mat = cfk_props.core_mat;
elseif isfield(Scenario, 'core_mat') && ~isempty(Scenario.core_mat)
    core_mat = Scenario.core_mat;
end

core_dir = 'L';
if isfield(cfk_props, 'core_dir') && ~isempty(cfk_props.core_dir)
    core_dir = upper(cfk_props.core_dir);
end
if isfield(Scenario, 'core_dir') && ~isempty(Scenario.core_dir)
    core_dir = upper(Scenario.core_dir);
end
if isfield(Calib, 'core_dir') && ~isempty(Calib.core_dir)
    core_dir = upper(Calib.core_dir);
end

mat_dict = load_materials(csv_path);
if strcmpi(core_mat, 'core')
    % Standard Plascore PAMG-XR1-5056 Aluminium-Wabenkern (kalibriert)
    Mdata.core.name = 'Aluminium 5056 Wabe';
    Mdata.core.rho  = 7.5e-11;
    if isfield(mat_dict, 'core') && isfield(mat_dict.core, 'rho') && mat_dict.core.rho > 0
        Mdata.core.rho = mat_dict.core.rho;
    end
    Mdata.core.mat  = 'core';
    if startsWith(core_dir, 'W')
        Mdata.core.G       = 230;   % MPa (W-Richtung)
        Mdata.core.tau_max = 2.03;  % MPa
        Mdata.core.dir     = 'W';
    else
        Mdata.core.G       = 550;   % MPa (L-Richtung)
        Mdata.core.tau_max = 2.97;  % MPa
        Mdata.core.dir     = 'L';
    end
elseif isfield(mat_dict, core_mat)
    % Benutzerdefinierter Kern aus materials.csv (z.B. Rohacell, Nomex)
    c_entry = mat_dict.(core_mat);
    Mdata.core.name = c_entry.Name;
    Mdata.core.rho  = c_entry.rho;
    Mdata.core.mat  = core_mat;
    
    if startsWith(core_dir, 'W')
        if isfield(c_entry, 'G23') && c_entry.G23 > 0
            Mdata.core.G = c_entry.G23;
        elseif isfield(c_entry, 'G12') && c_entry.G12 > 0
            Mdata.core.G = c_entry.G12;
        else
            Mdata.core.G = 230;
        end
        if isfield(c_entry, 'S') && c_entry.S > 0 && c_entry.S < 1000
            Mdata.core.tau_max = c_entry.S;
        else
            Mdata.core.tau_max = 2.03;
        end
        Mdata.core.dir = 'W';
    else
        if isfield(c_entry, 'G13') && c_entry.G13 > 0
            Mdata.core.G = c_entry.G13;
        elseif isfield(c_entry, 'G12') && c_entry.G12 > 0
            Mdata.core.G = c_entry.G12;
        else
            Mdata.core.G = 550;
        end
        if isfield(c_entry, 'S') && c_entry.S > 0 && c_entry.S < 1000
            Mdata.core.tau_max = c_entry.S;
        else
            Mdata.core.tau_max = 2.97;
        end
        Mdata.core.dir = 'L';
    end
else
    Mdata.core.name = 'Aluminium 5056 Wabe';
    Mdata.core.rho  = 7.5e-11;
    Mdata.core.mat  = 'core';
    if startsWith(core_dir, 'W')
        Mdata.core.G       = 230;
        Mdata.core.tau_max = 2.03;
        Mdata.core.dir     = 'W';
    else
        Mdata.core.G       = 550;
        Mdata.core.tau_max = 2.97;
        Mdata.core.dir     = 'L';
    end
end

if isfield(cfk_props, 'core_t') && ~isempty(cfk_props.core_t) && ~isnan(cfk_props.core_t)
    Mdata.core.t = cfk_props.core_t;
elseif isfield(Scenario, 'core_t')
    Mdata.core.t = Scenario.core_t;
else
    Mdata.core.t = 18;
end

% Kernschub-Option
if isfield(Calib, 'include_core_shear')
    Mdata.include_core_shear = Calib.include_core_shear;
end

% Prüfstands- & Vorrichtungssteifigkeit
if isfield(Calib, 'fixture_stiffness')
    Mdata.fixture_stiffness = Calib.fixture_stiffness;
else
    Mdata.fixture_stiffness = Inf;
end

% Bruchlast- & Modellparameter
if isfield(Calib, 'post_fail_factor')
    Mdata.post_fail_factor = Calib.post_fail_factor;
else
    Mdata.post_fail_factor = 0.262;
end

Mdata.failure_strain = failure_strain;

if isfield(Calib, 'softening_factor') && ~isempty(Calib.softening_factor)
    Mdata.softening_factor = Calib.softening_factor;
else
    Mdata.softening_factor = 0.52;
end

if isfield(Calib, 'indentation_depth') && ~isempty(Calib.indentation_depth)
    Mdata.indentation_depth = Calib.indentation_depth;
else
    Mdata.indentation_depth = 1.0;
end

if isfield(Calib, 'energy_mode') && ~isempty(Calib.energy_mode)
    Mdata.energy_mode = Calib.energy_mode;
else
    Mdata.energy_mode = 'to_peak';
end

end
