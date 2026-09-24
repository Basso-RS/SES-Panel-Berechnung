%% CALCULATE_SINGLE_PANEL - Einzelsimulation eines SES Sandwich Panels
clearvars; close all; clc;

this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'), fullfile(project_root, '01_Functions'), fullfile(project_root, '02_Data'));

tic;

%% Simulation
Scenario = Scenariodata();
Calib    = Calibration();
Mdata    = Materialdata(Scenario, Calib);

Results = struct();
Results = EI_calc(Mdata, Results, Scenario);
Results = Shearstiff_calc(Results, Mdata, Scenario);
[Results, Curve] = Deflection(Results, Scenario, Mdata);
Results = Energy_calc(Results, Curve, Scenario, Mdata);

Weight = calc_panel_weight(Scenario);
Results.Weight = Weight;

t_calc = toc;

%% Ausgabe & Automatischer PDF-Export in Downloads
console_text = evalc('print_panel_report(Results, Mdata, Scenario, Weight, t_calc * 1000);');
fprintf('%s', console_text);

export_pdf_report(console_text, 'single', Scenario);
