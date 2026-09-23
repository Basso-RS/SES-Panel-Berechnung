% Test 27_03 and 27_04 in current codebase
this_dir = fileparts(mfilename('fullpath'));
project_root = fullfile(this_dir, '..', '..');
addpath(fullfile(project_root, '00_Scripts'));
addpath(fullfile(project_root, '01_Functions'));
addpath(fullfile(project_root, '02_Data'));

Scenariodata;
Calib = Calibration();

% 27_04
Scenario.name = '27_04';
Scenario.layup = '45t7/0m/0m/0m/21m/45t7/cp/20core/cp/45t7/-21m/0m/0m/0m/45t7';
Scenario.core_t = 20;

Mdata = Materialdata(Scenario, Calib);
Results = struct();
Results = EI_calc(Mdata, Results, Scenario);
Results = Shearstiff_calc(Results, Mdata, Scenario);
[Results, Curve] = Deflection(Results, Scenario, Mdata);
Results = Energy_calc(Results, Curve, Scenario, Mdata);

fprintf('--- PANEL 27_04 EVALUATION (CURRENT CODE) ---\n');
fprintf('  Dicke:    Test = 0.60 mm,  Calc = %.2f mm,  Diff = %+.1f%%\n', Mdata.cfk.t_top, (Mdata.cfk.t_top - 0.60)/0.60*100);
fprintf('  E-Modul:  Test = 213.8 GPa, Calc = %.1f GPa, Diff = %+.1f%%\n', Results.E/1000, (Results.E/1000 - 213.8)/213.8*100);
fprintf('  UTS:      Test = 379.1 MPa, Calc = %.1f MPa, Diff = %+.1f%%\n', Results.UTS, (Results.UTS - 379.1)/379.1*100);
fprintf('  Gradient: Test = 5614 N/mm, Calc = %.0f N/mm, Diff = %+.1f%%\n', Results.Gradient, (Results.Gradient - 5614)/5614*100);
fprintf('  Energy:   Test = 32.9 J,    Calc = %.1f J,    Diff = %+.1f%%\n', Results.Energy, (Results.Energy - 32.9)/32.9*100);
