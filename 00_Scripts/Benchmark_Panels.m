%% BENCHMARK_PANELS - Validierung aller Fertigungspanels gegen Prüfstandsdaten
% Filter:
%   - Saison 2024: Alle validen Testpanels (24_02 bis 24_20)
%   - Saison 2026: Panels ab #12 bis #21 (ohne 26_17 und 26_19)
%   - Saison 2027: Alle Panels (27_01 bis 27_04 inkl. 20 mm Wabenkern)
%
% Architektur-Grundsatz:
%   Dieses Skript führt KEINE eigenen Berechnungen und KEINE eigenen Kalibrierungen durch!
%   Es ruft für jedes Panel exakt die offiziellen Projektfunktionen auf:
%     Scenariodata -> Calibration -> Materialdata -> EI_calc -> Shearstiff_calc -> Deflection -> Energy_calc

clearvars;
close all;
clc;

this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'));
addpath(fullfile(project_root, '01_Functions'));
addpath(fullfile(project_root, '02_Data'));

%% Benchmark ausführen & Konsolenausgabe erfassen
console_text = evalc('[Summary, BenchmarkResults] = run_benchmark();');
fprintf('%s', console_text);

%% Automatischer PDF-Export in Downloads
export_pdf_report(console_text, 'benchmark');
