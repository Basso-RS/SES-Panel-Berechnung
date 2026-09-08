%% Skript zur Vorauslegung von SES Panels 

clearvars
close all
clc

this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'), fullfile(project_root, '01_Functions'), fullfile(project_root, '02_Data'));

tic;

%% Load Data
Scenariodata;
Calib = Calibration();
Mdata = Materialdata(Scenario, Calib);


%% Results
Results = struct();

Results = EI_calc (Mdata,Results,Scenario); % 10.2e9 N/mm2 2x tubes
Results = Shearstiff_calc (Results,Mdata,Scenario); % Shear stiffness
[Results, Curve] = Deflection (Results,Scenario,Mdata); % max force at 12.7mm and max deflection 
Results = Energy_calc (Results, Curve, Scenario, Mdata); % absorbed energy calculation

%% Zeitausgabe
t_calc = toc;
fprintf('>> Berechnung erfolgreich abgeschlossen in %.2f ms (%.4f s).\n', t_calc * 1000, t_calc);
clearvars t_calc


