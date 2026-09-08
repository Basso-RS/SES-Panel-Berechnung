%% Benchmark-Skript: Validierung der Fertigungspanels (2026 ab #11 & alle 2027er Panels)
% Filter:
%   - Saison 2026: Die ersten 10 Panels (26_01 bis 26_10) sowie 26_19 (Flachs) werden ausgelassen.
%   - Saison 2027: Alle Panels (27_01 bis 27_04) mit den neu gemessenen Lagendicken werden geprüft.
%
% Architektur-Grundsatz:
%   Dieses Skript führt KEINE eigenen Berechnungen und KEINE eigenen Kalibrierungen durch!
%   Es ruft für jedes Panel exakt die offiziellen Projektfunktionen auf:
%     Scenariodata -> Calibration -> Materialdata -> EI_calc -> Shearstiff_calc -> Deflection -> Energy_calc

clearvars;
close all;
clc;

fprintf('========================================================================================================================\n');
fprintf('                                   BENCHMARK: VALIDIERUNG DER FERTIGUNGSPANELS                                          \n');
fprintf('========================================================================================================================\n\n');

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'));
addpath(fullfile(project_root, '01_Functions'));
addpath(fullfile(project_root, '02_Data'));

excel_path = fullfile(project_root, '02_Data', 'Optimierung des Structural Equivalency Spreadsheets_Schnee_2.xlsm');
if ~isfile(excel_path)
    excel_path = fullfile(project_root, '02_Data', 'Optimierung des Structural Equivalency Spreadsheets_Schnee_2 (1).xlsm');
end
if ~isfile(excel_path)
    error('Excel-Datei nicht gefunden: %s', excel_path);
end

[~, fname, fext] = fileparts(excel_path);
fprintf('Lese Prüfstandsdaten aus Excel (%s%s)...\n\n', fname, fext);
T = readcell(excel_path, 'Sheet', 'Overview');

fprintf('%-6s | %-19s | %-19s | %-19s | %-20s | %-19s\n', ...
    'Panel', 'Dicke [mm]', 'E-Modul [GPa]', 'UTS [MPa]', 'Gradient [N/mm]', 'Energie [J]');
fprintf('%-6s | %5s %5s %6s | %5s %5s %6s | %5s %5s %6s | %6s %6s %6s | %5s %5s %6s\n', ...
    '', 'Test', 'Calc', 'Diff', 'Test', 'Calc', 'Diff', 'Test', 'Calc', 'Diff', 'Test', 'Calc', 'Diff', 'Test', 'Calc', 'Diff');
fprintf('%s\n', repmat('-', 1, 120));

diff_t_26 = []; diff_e_26 = []; diff_uts_26 = []; diff_grad_26 = []; diff_energy_26 = [];
diff_t_27 = []; diff_e_27 = []; diff_uts_27 = []; diff_grad_27 = []; diff_energy_27 = [];
t_start_total = tic;

for i = 5:size(T, 1)
    val = T{i, 1};
    if isempty(val) || ismissing(string(val)), continue; end
    panel_id = string(val);
    
    % --- FILTER LOGIK ---
    if startsWith(panel_id, "26_")
        num_part = sscanf(char(extractAfter(panel_id, "26_")), '%d');
        % 2026 Panels bis #11 sowie Sonderpanels 26_17 und 26_19 komplett auslassen
        if isempty(num_part) || num_part <= 11 || panel_id == "26_17" || panel_id == "26_19", continue; end
    elseif startsWith(panel_id, "27_")
        % Von 2027 die Panels 27_03 und 27_04 auslassen
        if panel_id == "27_03" || panel_id == "27_04", continue; end
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
    
    % 1. Basis-Szenario und offizielle Kalibrierungsfunktion laden
    Scenariodata;
    Calib = Calibration();
    
    % 2. Nur die spezifischen Panel-Daten überschreiben:
    Scenario.layup  = layup_str;
    Scenario.core_t = core_t_val;
    
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
        
        if startsWith(panel_id, "26_")
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
        
        fprintf('%-6s | %5.2f %5.2f %+5.1f%% | %5.1f %5.1f %+5.1f%% | %5.1f %5.1f %+5.1f%% | %6.0f %6.0f %+5.1f%% | %5.1f %5.1f %+5.1f%%\n', ...
            panel_id, t_test, t_calc, diff_t, ...
            emod_test, emod_calc, diff_emod, ...
            uts_test, uts_calc, diff_uts, ...
            grad_test, grad_calc, diff_grad, ...
            e_test, energy_calc, diff_energy);
            
    catch ME
        fprintf('%-6s | FEHLER: %s\n', panel_id, ME.message);
    end
end

t_calc_total = toc(t_start_total);
n_26 = length(diff_grad_26);
n_27 = length(diff_grad_27);
n_total = n_26 + n_27;

fprintf('%s\n', repmat('=', 1, 120));
if n_26 > 0
    fprintf('ZUSAMMENFASSUNG SAISON 2026 (%d Panels: 26_12 bis 26_21):\n', n_26);
    fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean(diff_t_26));
    fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean(diff_e_26));
    fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean(diff_uts_26));
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_26));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_26));
end
if n_27 > 0
    fprintf('%s\n', repmat('-', 1, 120));
    fprintf('ZUSAMMENFASSUNG SAISON 2027 (%d Panels: 27_01 & 27_02):\n', n_27);
    fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean(diff_t_27));
    fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean(diff_e_27));
    fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean(diff_uts_27));
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_27));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_27));
end
fprintf('%s\n', repmat('-', 1, 120));
fprintf('GESAMTERGEBNIS (%d ausgewählte Panels):\n', n_total);
fprintf('  - Mittlere absolute Abweichung Dicke:       %5.1f %%\n', mean([diff_t_26, diff_t_27]));
fprintf('  - Mittlere absolute Abweichung E-Modul:     %5.1f %%\n', mean([diff_e_26, diff_e_27]));
fprintf('  - Mittlere absolute Abweichung UTS:         %5.1f %%\n', mean([diff_uts_26, diff_uts_27]));
fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean([diff_grad_26, diff_grad_27]));
fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean([diff_energy_26, diff_energy_27]));
fprintf('  - Gesamtrechenzeit: %.2f s (ca. %.2f ms pro Panel)\n', t_calc_total, (t_calc_total / max(1, n_total)) * 1000);
fprintf('%s\n', repmat('=', 1, 120));
