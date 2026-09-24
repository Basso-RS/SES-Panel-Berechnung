function [Summary, BenchmarkResults] = run_benchmark(excel_path)
% RUN_BENCHMARK Führt die Benchmark-Validierung aller Fertigungspanels durch.
%
% Syntax:
%   run_benchmark()
%   [Summary, BenchmarkResults] = run_benchmark(excel_path)
%
% Beschreibung:
%   Validiert die Simulationsmodelle anhand der Prüfstandsdaten aus den Saisons
%   2024 (24_02 bis 24_20), 2026 (26_12 bis 26_21) und 2027 (27_01 bis 27_04).
%   Formatiert die Ausgabe auf maximal 99 Zeichen pro Zeile, perfekt abgestimmt
%   auf den DIN A4 Konsolen-PDF-Report mit vollen Druckrändern.

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'));
addpath(fullfile(project_root, '01_Functions'));
addpath(fullfile(project_root, '02_Data'));

if nargin < 1 || isempty(excel_path)
    excel_path = fullfile(project_root, '02_Data', 'Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm');
    if ~isfile(excel_path)
        excel_path = fullfile(project_root, '02_Data', 'Optimierung des Structural Equivalency Spreadsheets_Schnee_2 (1).xlsm');
    end
end
if ~isfile(excel_path)
    error('Excel-Datei nicht gefunden: %s', excel_path);
end

fprintf('%s\n', repmat('=', 1, 99));
fprintf('                            BENCHMARK: VALIDIERUNG DER FERTIGUNGSPANELS                            \n');
fprintf('%s\n\n', repmat('=', 1, 99));

[~, fname, fext] = fileparts(excel_path);
fprintf('Lese Prüfstandsdaten aus Excel (%s%s)...\n\n', fname, fext);
T = readcell(excel_path, 'Sheet', 'Overview');

fprintf('%-5s | %-15s | %-17s | %-15s | %-15s | %-17s\n', ...
    'Panel', 'Dicke [mm]', 'E-Modul [GPa]', 'UTS [MPa]', 'Gradient [N/mm]', 'Energie [J]');
fprintf('%-5s | %-15s | %-17s | %-15s | %-15s | %-17s\n', ...
    '', 'Test Calc  Diff', ' Test  Calc  Diff', ' Test Calc  Diff', 'Test  Calc Diff', ' Test  Calc  Diff');
fprintf('%s\n', repmat('-', 1, 99));

diff_t_24 = []; diff_e_24 = []; diff_uts_24 = []; diff_grad_24 = []; diff_energy_24 = [];
diff_t_26 = []; diff_e_26 = []; diff_uts_26 = []; diff_grad_26 = []; diff_energy_26 = [];
diff_t_27 = []; diff_e_27 = []; diff_uts_27 = []; diff_grad_27 = []; diff_energy_27 = [];
BenchmarkResults = struct([]);
t_start_total = tic;

for i = 5:size(T, 1)
    val = T{i, 1};
    if isempty(val) || ismissing(string(val)), continue; end
    panel_id = string(val);
    
    % --- FILTER: Relevante Fertigungspanels (2024 Prio, 2026 ab #12, 2027) ---
    if startsWith(panel_id, "24_")
        % Alle validen 2024er Testpanels (Prio des Benutzers)
    elseif startsWith(panel_id, "26_")
        num_part = sscanf(char(extractAfter(panel_id, "26_")), '%d');
        % 2026 Panels bis #11, ab #22 sowie Sonderpanels 26_17 (Delamination) und 26_19 (Flachs) auslassen
        if isempty(num_part) || num_part <= 11 || num_part > 21 || panel_id == "26_17" || panel_id == "26_19", continue; end
    elseif startsWith(panel_id, "27_")
        % Alle validen 2027er Panels (27_01 bis 27_04)
    else
        continue;
    end
    
    layup_val = T{i, 2};
    if isempty(layup_val) || ismissing(string(layup_val)), continue; end
    layup_str = char(strtrim(string(layup_val)));
    if isempty(layup_str), continue; end
    
    % Prüfstandsergebnisse aus Excel einlesen
    t_test    = double(T{i, 7});      % Spalte 7: SkinThickness Top [mm]
    e_test    = double(T{i, 20});     % Spalte 20: Energy [J]
    grad_test = double(T{i, 21});     % Spalte 21: Gradient [N/mm]
    emod_test = double(T{i, 26});     % Spalte 26: E [GPa]
    uts_test  = double(T{i, 27});     % Spalte 27: UTS [MPa]
    core_t_val= double(T{i, 11});     % Spalte 11: Kerndicke [mm]
    
    if isnan(grad_test) || grad_test <= 0, continue; end
    if isnan(core_t_val) || core_t_val <= 0, core_t_val = 18; end
    
    % Für 27_03 und 27_04 ist der Kern zwingend 20 mm
    if panel_id == "27_03" || panel_id == "27_04"
        core_t_val = 20;
    end
    
    % 1. Basis-Szenario laden und Panel-spezifische Daten eintragen
    Scenariodata;
    Scenario.name = char(panel_id);
    Scenario.core_t = core_t_val;
    Scenario.layup = layup_str;
    
    % Einheitliche Kalibrierung (nur EINE Fertigungsmethode)
    Calib = Calibration();
    
    try
        % 3. REINER AUFRUF DER BESTEHENDEN PROJEKTFUNKTIONEN (KEINE BERECHNUNG IM BENCHMARK)
        Mdata = Materialdata(Scenario, Calib);
        Results = struct();
        Results = EI_calc(Mdata, Results, Scenario);
        Results = Shearstiff_calc(Results, Mdata, Scenario);
        [Results, Curve] = Deflection(Results, Scenario, Mdata);
        Results = Energy_calc(Results, Curve, Scenario, Mdata);
        
        % Kennwerte aus den Funktions-Rückgaben abrufen
        t_calc      = Mdata.cfk.t_top;
        emod_calc   = Results.E / 1000;    % MPa -> GPa
        uts_calc    = Results.UTS;         % MPa
        grad_calc   = Results.Gradient;
        energy_calc = Results.Energy;
        
        diff_t      = (t_calc - t_test) / t_test * 100;
        diff_emod   = (emod_calc - emod_test) / emod_test * 100;
        diff_uts    = (uts_calc - uts_test) / uts_test * 100;
        diff_grad   = (grad_calc - grad_test) / grad_test * 100;
        diff_energy = (energy_calc - e_test) / e_test * 100;
        
        if startsWith(panel_id, "24_")
            diff_t_24(end+1)      = abs(diff_t);
            diff_e_24(end+1)      = abs(diff_emod);
            diff_uts_24(end+1)    = abs(diff_uts);
            diff_grad_24(end+1)   = abs(diff_grad);
            diff_energy_24(end+1) = abs(diff_energy);
        elseif startsWith(panel_id, "26_")
            diff_t_26(end+1)      = abs(diff_t);
            diff_e_26(end+1)      = abs(diff_emod);
            diff_uts_26(end+1)    = abs(diff_uts);
            diff_grad_26(end+1)   = abs(diff_grad);
            diff_energy_26(end+1) = abs(diff_energy);
        elseif startsWith(panel_id, "27_")
            diff_t_27(end+1)      = abs(diff_t);
            diff_e_27(end+1)      = abs(diff_emod);
            diff_uts_27(end+1)    = abs(diff_uts);
            diff_grad_27(end+1)   = abs(diff_grad);
            diff_energy_27(end+1) = abs(diff_energy);
        end
        
        res_entry = struct('panel_id', panel_id, ...
            't_test', t_test, 't_calc', t_calc, 'diff_t', diff_t, ...
            'emod_test', emod_test, 'emod_calc', emod_calc, 'diff_emod', diff_emod, ...
            'uts_test', uts_test, 'uts_calc', uts_calc, 'diff_uts', diff_uts, ...
            'grad_test', grad_test, 'grad_calc', grad_calc, 'diff_grad', diff_grad, ...
            'e_test', e_test, 'energy_calc', energy_calc, 'diff_energy', diff_energy);
        BenchmarkResults = [BenchmarkResults, res_entry]; %#ok<AGROW>
        
        fprintf('%-5s | %4.2f %4.2f %+4.0f%% | %5.1f %5.1f %+4.0f%% | %4.0f %4.0f %+4.0f%% | %4.0f %4.0f %+4.0f%% | %5.1f %5.1f %+4.0f%%\n', ...
            panel_id, t_test, t_calc, diff_t, ...
            emod_test, emod_calc, diff_emod, ...
            uts_test, uts_calc, diff_uts, ...
            grad_test, grad_calc, diff_grad, ...
            e_test, energy_calc, diff_energy);
            
    catch ME
        fprintf('%-5s | FEHLER: %s\n', panel_id, ME.message);
    end
end

t_calc_total = toc(t_start_total);
n_24 = length(diff_grad_24);
n_26 = length(diff_grad_26);
n_27 = length(diff_grad_27);
n_total = n_24 + n_26 + n_27;

fprintf('%s\n', repmat('=', 1, 99));
if n_24 > 0
    fprintf('ZUSAMMENFASSUNG SAISON 2024 (%d Panels: 24_02 bis 24_20):\n', n_24);
    fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean(diff_t_24));
    fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean(diff_e_24));
    fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean(diff_uts_24));
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_24));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_24));
end
if n_26 > 0
    fprintf('%s\n', repmat('-', 1, 99));
    fprintf('ZUSAMMENFASSUNG SAISON 2026 (%d Panels: 26_12 bis 26_21):\n', n_26);
    fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean(diff_t_26));
    fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean(diff_e_26));
    fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean(diff_uts_26));
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_26));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_26));
end
if n_27 > 0
    fprintf('%s\n', repmat('-', 1, 99));
    fprintf('ZUSAMMENFASSUNG SAISON 2027 (%d Panels: 27_01 bis 27_04 inkl. 20 mm Wabenkern):\n', n_27);
    fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean(diff_t_27));
    fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean(diff_e_27));
    fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean(diff_uts_27));
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_27));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_27));
end
fprintf('%s\n', repmat('-', 1, 99));
fprintf('GESAMTERGEBNIS (%d ausgewählte Panels über 3 Saisons):\n', n_total);
all_diff_t      = [diff_t_24, diff_t_26, diff_t_27];
all_diff_e      = [diff_e_24, diff_e_26, diff_e_27];
all_diff_uts    = [diff_uts_24, diff_uts_26, diff_uts_27];
all_diff_grad   = [diff_grad_24, diff_grad_26, diff_grad_27];
all_diff_energy = [diff_energy_24, diff_energy_26, diff_energy_27];
fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean(all_diff_t));
fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean(all_diff_e));
fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean(all_diff_uts));
fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(all_diff_grad));
fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(all_diff_energy));
fprintf('  - Gesamtrechenzeit: %.2f s (ca. %.2f ms pro Panel)\n', t_calc_total, (t_calc_total / max(1, n_total)) * 1000);
fprintf('%s\n', repmat('=', 1, 99));

Summary = struct();
Summary.n_total = n_total;
Summary.t_calc_total = t_calc_total;
Summary.mean_diff_t = mean(all_diff_t);
Summary.mean_diff_e = mean(all_diff_e);
Summary.mean_diff_uts = mean(all_diff_uts);
Summary.mean_diff_grad = mean(all_diff_grad);
Summary.mean_diff_energy = mean(all_diff_energy);

end
