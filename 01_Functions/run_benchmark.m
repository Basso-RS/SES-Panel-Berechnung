function [Summary, BenchmarkResults] = run_benchmark(varargin)
% RUN_BENCHMARK Validiert Simulationsmodelle direkt gegen reale Prüfstands-Rohdaten.
%
% Syntax:
%   run_benchmark()
%   run_benchmark('reload')       % Erzwingt Neuauswertung der Excel-Rohdaten
%   [Summary, Results] = run_benchmark(...)
%
% Beschreibung:
%   Liest die Panel-Konfiguration (Layup, Kerndicke, gemessene Dicke) aus dem
%   Reiter 'Panels' der Datei 'Pruefstand_Rohdaten_24_27.xlsx'.
%   Die Prüfstandskurven werden live mit 'evaluate_test_curve' ausgewertet
%   (Gradient, Peak-Kraft, Energie bis 12.7 mm) und gegen die Simulationsmodelle
%   (CLT, Schub, Deflection, Energy_calc) abgeglichen.
%
%   Nutzt einen In-Memory-Cache (persistent), sodass Folgeläufe in < 0.05 s starten.

this_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'));
addpath(fullfile(project_root, '01_Functions'));
addpath(fullfile(project_root, '02_Data'));

% Prüfstands-Excel-Pfad
raw_excel = fullfile(project_root, '02_Data', 'Pruefstand_Rohdaten_Benchmark.xlsx');
if ~isfile(raw_excel)
    error('Rohdaten-Excel nicht gefunden: %s', raw_excel);
end

% Prüfen, ob Neuladen erzwungen werden soll
force_reload = false;
for a = 1:nargin
    if ischar(varargin{a}) || isstring(varargin{a})
        if strcmpi(varargin{a}, 'reload') || strcmpi(varargin{a}, 'force')
            force_reload = true;
        end
    end
end

% In-Memory Cache für Prüfstandsauswertungen (spart Wartezeit bei Wiederholung)
persistent TestDataCache;
if isempty(TestDataCache) || force_reload
    TestDataCache = containers.Map();
    fprintf('Initialisiere Live-Auswertung aus Rohdaten (%s)...\n', raw_excel);
else
    fprintf('Verwende vorberechnete Prüfstandsdaten aus In-Memory-Cache.\n');
end

% 1. Lagenaufbauten & Metadaten direkt aus dem Excel-Reiter 'Panels' einlesen
T_panels = readtable(raw_excel, 'Sheet', 'Panels');

fprintf('%s\n', repmat('=', 1, 102));
fprintf('                 BENCHMARK: SIMULATION vs. REALE PRÜFSTANDS-ROHDATEN (ASTM C393)                  \n');
fprintf('%s\n\n', repmat('=', 1, 102));

fprintf('%-5s | %-25s | %-19s | %-19s | %-19s\n', ...
    'Panel', 'Dicke oben/unten [mm]', 'Gradient [N/mm]', 'Bruchkraft Fmax [N]', 'SES-Energie [J]');
fprintf('%-5s | %-25s | %-19s | %-19s | %-19s\n', ...
    '', '   Test       Calc     Diff', ' Test   Calc   Diff', '  Test   Calc   Diff', ' Test   Calc   Diff');
fprintf('%s\n', repmat('-', 1, 102));

diff_t_24 = []; diff_grad_24 = []; diff_fmax_24 = []; diff_energy_24 = [];
diff_t_26 = []; diff_grad_26 = []; diff_fmax_26 = []; diff_energy_26 = [];
diff_t_27 = []; diff_grad_27 = []; diff_fmax_27 = []; diff_energy_27 = [];
BenchmarkResults = struct([]);
t_start_total = tic;

for i = 1:height(T_panels)
    panel_id   = string(T_panels.Panel_ID{i});
    layup_raw  = T_panels.Layup{i};
    if isempty(layup_raw) || ismissing(string(layup_raw)), continue; end
    layup_str  = char(strtrim(string(layup_raw)));
    if isempty(layup_str), continue; end
    
    % Relevanzfilter für Benchmark-Saisons (2024, 2026, 2027)
    if startsWith(panel_id, "24_")
        % Alle 2024er Fertigungspanels (24_02 bis 24_18)
        num_part = sscanf(char(extractAfter(panel_id, "24_")), '%d');
        if isempty(num_part) || num_part < 2 || num_part > 18, continue; end
    elseif startsWith(panel_id, "26_")
        num_part = sscanf(char(extractAfter(panel_id, "26_")), '%d');
        % 2026er Fertigungspanels ab #12 bis #21, Sonderpanels 26_17/26_19 auslassen
        if isempty(num_part) || num_part < 12 || num_part > 21 || panel_id == "26_17" || panel_id == "26_19", continue; end
    elseif startsWith(panel_id, "27_")
        % 2027er Panels (27_01 bis 27_04)
        num_part = sscanf(char(extractAfter(panel_id, "27_")), '%d');
        if isempty(num_part) || num_part < 1 || num_part > 4, continue; end
    else
        continue;
    end
    
    core_t_val = double(T_panels.Kerndicke_mm(i));
    
    % Deckhautdicken (oben & unten für asymmetrische Panels)
    if ismember('Deckhautdicke_oben_mm', T_panels.Properties.VariableNames)
        t_top_test = double(T_panels.Deckhautdicke_oben_mm(i));
        t_bot_test = double(T_panels.Deckhautdicke_unten_mm(i));
    elseif ismember('Deckhautdicke_mm', T_panels.Properties.VariableNames)
        t_top_test = double(T_panels.Deckhautdicke_mm(i));
        t_bot_test = t_top_test;
    else
        t_top_test = 0;
        t_bot_test = 0;
    end
    
    % 1. Prüfstands-Kennwerte aus Cache oder Live-Auswertung des Sheets
    try
        if isKey(TestDataCache, char(panel_id))
            Metrics = TestDataCache(char(panel_id));
        else
            Metrics = evaluate_test_curve(raw_excel, char(panel_id));
            TestDataCache(char(panel_id)) = Metrics;
        end
    catch ME_eval
        fprintf('%-5s | FEHLER beim Auswerten der Rohdaten: %s\n', panel_id, ME_eval.message);
        continue;
    end
    
    grad_test = Metrics.Gradient;
    fmax_test = Metrics.F_max;
    if Metrics.reached_12_7
        e_test = Metrics.Energy_12_7;
    else
        e_test = Metrics.Energy_peak;
    end
    
    % 2. Simulation aufrufen
    Scenariodata;
    Scenario.name = char(panel_id);
    Scenario.core_t = core_t_val;
    Scenario.layup = layup_str;
    
    Calib = Calibration();
    
    try
        Mdata = Materialdata(Scenario, Calib);
        if Metrics.reached_12_7
            Mdata.energy_mode = 'ses_total';
        else
            Mdata.energy_mode = 'to_peak';
        end
        
        Results = struct();
        Results = EI_calc(Mdata, Results, Scenario);
        Results = Shearstiff_calc(Results, Mdata, Scenario);
        [Results, Curve] = Deflection(Results, Scenario, Mdata);
        Results = Energy_calc(Results, Curve, Scenario, Mdata);
        
        % Berechnete Simulationswerte
        t_top_calc  = Mdata.cfk.t_top;
        t_bot_calc  = Mdata.cfk.t_lower;
        grad_calc   = Results.Gradient;
        fmax_calc   = Results.F_max;
        energy_calc = Results.Energy;
        
        % Relative Abweichungen in Prozent (Deckhäute oben / unten)
        if t_top_test > 0
            diff_t_top = (t_top_calc - t_top_test) / t_top_test * 100;
        else
            diff_t_top = 0.0;
        end
        if t_bot_test > 0
            diff_t_bot = (t_bot_calc - t_bot_test) / t_bot_test * 100;
        else
            diff_t_bot = 0.0;
        end
        diff_t_mean = (abs(diff_t_top) + abs(diff_t_bot)) / 2;
        
        diff_grad   = (grad_calc - grad_test) / grad_test * 100;
        diff_fmax   = (fmax_calc - fmax_test) / fmax_test * 100;
        diff_energy = (energy_calc - e_test) / e_test * 100;
        
        if startsWith(panel_id, "24_")
            if t_top_test > 0, diff_t_24(end+1) = diff_t_mean; end
            diff_grad_24(end+1)   = abs(diff_grad);
            diff_fmax_24(end+1)   = abs(diff_fmax);
            diff_energy_24(end+1) = abs(diff_energy);
        elseif startsWith(panel_id, "26_")
            if t_top_test > 0, diff_t_26(end+1) = diff_t_mean; end
            diff_grad_26(end+1)   = abs(diff_grad);
            diff_fmax_26(end+1)   = abs(diff_fmax);
            diff_energy_26(end+1) = abs(diff_energy);
        elseif startsWith(panel_id, "27_")
            if t_top_test > 0, diff_t_27(end+1) = diff_t_mean; end
            diff_grad_27(end+1)   = abs(diff_grad);
            diff_fmax_27(end+1)   = abs(diff_fmax);
            diff_energy_27(end+1) = abs(diff_energy);
        end
        
        res_entry = struct('panel_id', char(panel_id), ...
            't_top_test', t_top_test, 't_top_calc', t_top_calc, 'diff_t_top', diff_t_top, ...
            't_bot_test', t_bot_test, 't_bot_calc', t_bot_calc, 'diff_t_bot', diff_t_bot, ...
            'grad_test', grad_test, 'grad_calc', grad_calc, 'diff_grad', diff_grad, ...
            'fmax_test', fmax_test, 'fmax_calc', fmax_calc, 'diff_fmax', diff_fmax, ...
            'e_test', e_test, 'energy_calc', energy_calc, 'diff_energy', diff_energy);
        BenchmarkResults = [BenchmarkResults, res_entry]; %#ok<AGROW>
        
        % Formatierung Deckhautdicke (kompakt wenn symmetrisch, detailliert wenn asymmetrisch)
        if abs(t_top_test - t_bot_test) < 0.01 && abs(t_top_calc - t_bot_calc) < 0.01
            str_t = sprintf('%4.2f      %4.2f     %+4.0f%%', t_top_test, t_top_calc, diff_t_top);
        else
            str_t = sprintf('%4.2f/%4.2f %4.2f/%4.2f %+3.0f/%+3.0f%%', ...
                t_top_test, t_bot_test, t_top_calc, t_bot_calc, diff_t_top, diff_t_bot);
        end
        
        fprintf('%-5s | %-25s | %5.0f %5.0f %+5.1f%% | %6.0f %6.0f %+5.1f%% | %5.1f %5.1f %+5.1f%%\n', ...
            panel_id, str_t, ...
            grad_test, grad_calc, diff_grad, ...
            fmax_test, fmax_calc, diff_fmax, ...
            e_test, energy_calc, diff_energy);
            
    catch ME
        fprintf('%-5s | SIMULATIONS-FEHLER: %s\n', panel_id, ME.message);
    end
end

t_calc_total = toc(t_start_total);
n_24 = length(diff_grad_24);
n_26 = length(diff_grad_26);
n_27 = length(diff_grad_27);
n_total = n_24 + n_26 + n_27;

fprintf('%s\n', repmat('=', 1, 102));
if n_24 > 0
    fprintf('ZUSAMMENFASSUNG SAISON 2024 (%d Panels: 24_02 bis 24_18):\n', n_24);
    if ~isempty(diff_t_24), fprintf('  - Mittlere absolute Abweichung Dicke (o/u): %5.1f %%\n', mean(diff_t_24)); end
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_24));
    fprintf('  - Mittlere absolute Abweichung F_max:       %5.1f %%\n', mean(diff_fmax_24));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_24));
end
if n_26 > 0
    fprintf('%s\n', repmat('-', 1, 102));
    fprintf('ZUSAMMENFASSUNG SAISON 2026 (%d Panels: 26_12 bis 26_21):\n', n_26);
    if ~isempty(diff_t_26), fprintf('  - Mittlere absolute Abweichung Dicke (o/u): %5.1f %%\n', mean(diff_t_26)); end
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_26));
    fprintf('  - Mittlere absolute Abweichung F_max:       %5.1f %%\n', mean(diff_fmax_26));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_26));
end
if n_27 > 0
    fprintf('%s\n', repmat('-', 1, 102));
    fprintf('ZUSAMMENFASSUNG SAISON 2027 (%d Panels: 27_01 bis 27_04 inkl. 20 mm Wabenkern):\n', n_27);
    if ~isempty(diff_t_27), fprintf('  - Mittlere absolute Abweichung Dicke (o/u): %5.1f %%\n', mean(diff_t_27)); end
    fprintf('  - Mittlere absolute Abweichung Gradient:    %5.1f %%\n', mean(diff_grad_27));
    fprintf('  - Mittlere absolute Abweichung F_max:       %5.1f %%\n', mean(diff_fmax_27));
    fprintf('  - Mittlere absolute Abweichung Energie:     %5.1f %%\n', mean(diff_energy_27));
end
fprintf('%s\n', repmat('=', 1, 102));
fprintf('GESAMTERGEBNIS ÜBER ALLE %d PANELS (Rechenzeit: %.2f s):\n', n_total, t_calc_total);
all_grad = [diff_grad_24, diff_grad_26, diff_grad_27];
all_fmax = [diff_fmax_24, diff_fmax_26, diff_fmax_27];
all_energy = [diff_energy_24, diff_energy_26, diff_energy_27];
fprintf('  --> Gesamt MAE Gradient: %5.1f %%\n', mean(all_grad));
fprintf('  --> Gesamt MAE F_max:    %5.1f %%\n', mean(all_fmax));
fprintf('  --> Gesamt MAE Energie:  %5.1f %%\n', mean(all_energy));
fprintf('%s\n\n', repmat('=', 1, 102));

Summary = struct();
Summary.n_total = n_total;
Summary.calc_time = t_calc_total;
Summary.mae_gradient = mean(all_grad);
Summary.mae_fmax = mean(all_fmax);
Summary.mae_energy = mean(all_energy);

end
