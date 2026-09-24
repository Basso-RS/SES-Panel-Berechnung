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

% Faservolumenanteil-Faktor
vf_factor = 1.0;
if isfield(Calib, 'fiber_volume_factor')
    vf_factor = Calib.fiber_volume_factor;
elseif isfield(Calib, 'fasergehalt_factor')
    vf_factor = Calib.fasergehalt_factor;
elseif isfield(Calib, 'fasergehalt')
    vf_factor = Calib.fasergehalt;
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
    cfk_props = calc_cfk_properties(Scenario.layup, csv_path, calc_energy, t_factor, vf_factor, failure_strain, use_lpf);
end

Mdata = struct();
Mdata.cfk.E_top      = cfk_props.E_top;
Mdata.cfk.t_top      = cfk_props.t_top;
Mdata.cfk.E_lower    = cfk_props.E_lower;
Mdata.cfk.t_lower    = cfk_props.t_lower;
Mdata.cfk.UTS        = cfk_props.UTS;

% Kerneigenschaften (Plascore PAMG-XR1-5056)
core_dir = 'L';
if isfield(Calib, 'core_dir') && ~isempty(Calib.core_dir)
    core_dir = upper(Calib.core_dir);
elseif isfield(Scenario, 'core_dir') && ~isempty(Scenario.core_dir)
    core_dir = upper(Scenario.core_dir);
end
if isfield(cfk_props, 'core_dir') && ~isempty(cfk_props.core_dir)
    core_dir = upper(cfk_props.core_dir);
end

if startsWith(core_dir, 'W')
    Mdata.core.G       = 230;   % MPa (W-Richtung)
    Mdata.core.tau_max = 2.03;  % MPa
    Mdata.core.dir     = 'W';
else
    Mdata.core.G       = 550;   % MPa (L-Richtung)
    Mdata.core.tau_max = 2.97;  % MPa
    Mdata.core.dir     = 'L';
end

if isfield(cfk_props, 'core_t') && ~isempty(cfk_props.core_t) && ~isnan(cfk_props.core_t)
    Mdata.core.t = cfk_props.core_t;
elseif isfield(Scenario, 'core_t')
    Mdata.core.t = Scenario.core_t;
else
    Mdata.core.t = 18;
end

% Bruchlast- & Modellparameter
if isfield(Calib, 'post_fail_factor')
    Mdata.post_fail_factor = Calib.post_fail_factor;
else
    Mdata.post_fail_factor = 0.262;
end

if isfield(Calib, 'gradient_factor')
    Mdata.gradient_factor = Calib.gradient_factor;
else
    Mdata.gradient_factor = 1.0;
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
