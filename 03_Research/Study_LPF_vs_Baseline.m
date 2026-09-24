%% STUDY: HASHIN & PROGRESSIVES LAST-PLY-FAILURE (LPF) VS. BASELINE
% Untersuchung zu:
%   - Punkt 3: Hashin-Kriterium (Trennung Faser- und Matrixversagen)
%   - Punkt 4: Progressives Last-Ply-Failure (LPF) mit Steifigkeitsdegradation
% 
% Fragestellung des Strukturberechners:
%   "Lohnt sich LPF physikalisch oder verlängert es einfach nur die Rechenzeit?"
%
% Verglichen werden:
%   1. Genauigkeit bei Bruchspannung (UTS), Maximalkraft (F_max) und Energie
%   2. Rechenzeit pro Panel (ms) und Hochrechnung auf 10.000 Laminate (Optimizer)

clearvars;
close all;
clc;

fprintf('========================================================================================================================\n');
fprintf('                 STUDIE: HASHIN & PROGRESSIVES LAST-PLY-FAILURE (LPF) VS. ANALYTISCHE BASELINE                          \n');
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

T = readcell(excel_path, 'Sheet', 'Overview');

% Repräsentative Auswahl von Panels aus allen 3 Saisons
selected_panels = ["24_02", "24_03", "24_05", "24_08", "24_11", "24_13", ...
                   "26_12", "26_13", "26_16", "26_20", "26_21", ...
                   "27_01", "27_02", "27_03", "27_04"];

n_panels = length(selected_panels);

% Tabellen-Header
fprintf('%-7s | %-24s | %-24s | %-20s | %-14s\n', ...
    'Panel', 'UTS [MPa] (Test/Base/LPF)', 'F_max [kN] (Test/Base/LPF)', 'Energie [J] (Test/B/L)', 'Rechenzeit [ms]');
fprintf('%-7s | %5s %5s %5s %6s | %5s %5s %5s %6s | %5s %5s %5s      | %5s %6s\n', ...
    '', 'Test', 'Base', 'LPF', 'Besser?', 'Test', 'Base', 'LPF', 'Besser?', 'Test', 'Base', 'LPF', 'Base', 'LPF');
fprintf('%s\n', repmat('-', 1, 115));

results_table = struct();
t_base_all = zeros(n_panels, 1);
t_lpf_all  = zeros(n_panels, 1);

err_uts_base = []; err_uts_lpf = [];
err_f_base   = []; err_f_lpf   = [];
err_e_base   = []; err_e_lpf   = [];

plot_panel_id = "26_20";
plot_data_base = struct();
plot_data_lpf  = struct();

materials_csv = fullfile(project_root, '02_Data', 'materials.csv');

for p = 1:n_panels
    target_id = selected_panels(p);
    
    % Panel in Excel-Tabelle suchen
    row_idx = -1;
    for i = 5:size(T, 1)
        val = string(T{i, 1});
        if val == target_id
            row_idx = i;
            break;
        end
    end
    if row_idx < 0, continue; end
    
    layup_str = char(strtrim(string(T{row_idx, 2})));
    t_test    = double(T{row_idx, 7});
    e_test    = double(T{row_idx, 20});
    grad_test = double(T{row_idx, 21});
    emod_test = double(T{row_idx, 26});
    uts_test  = double(T{row_idx, 27});
    core_t_val= double(T{row_idx, 11});
    if isnan(core_t_val) || core_t_val <= 0, core_t_val = 18; end
    if target_id == "27_03" || target_id == "27_04", core_t_val = 20; end
    
    % F_max aus Test ableiten: F_test = sqrt(2 * grad_test * e_test * 1000) ca.
    % Oder direkt aus Gradient und Biegeweg:
    % Wir berechnen F_max_test aus UTS_test und Querschnittswerten der Prüfung:
    
    % -------------------------------------------------------------
    % 1. BASELINE BERECHNUNG (Aktueller Code)
    % -------------------------------------------------------------
    Scenariodata;
    Scenario.name = char(target_id);
    Scenario.core_t = core_t_val;
    Scenario.layup = layup_str;
    Calib = Calibration();
    
    t_start = tic;
    Mdata_base = Materialdata(Scenario, Calib);
    Res_base = struct();
    Res_base = EI_calc(Mdata_base, Res_base, Scenario);
    Res_base = Shearstiff_calc(Res_base, Mdata_base, Scenario);
    [Res_base, Curve_base] = Deflection(Res_base, Scenario, Mdata_base);
    Res_base = Energy_calc(Res_base, Curve_base, Scenario, Mdata_base);
    t_base_all(p) = toc(t_start) * 1000; % in ms
    
    % -------------------------------------------------------------
    % 2. LPF BERECHNUNG (Punkt 3 & 4: Hashin + Last-Ply-Failure)
    % -------------------------------------------------------------
    t_start_lpf = tic;
    % LPF-Eigenschaften der Deckhäute berechnen
    cfk_lpf = calc_cfk_properties(layup_str, materials_csv, true, Calib.thickness_factor, Calib.fiber_volume_factor, [], true);
    
    Mdata_lpf = Mdata_base;
    Mdata_lpf.cfk = cfk_lpf;
    
    Res_lpf = struct();
    Res_lpf = EI_calc(Mdata_lpf, Res_lpf, Scenario);
    Res_lpf = Shearstiff_calc(Res_lpf, Mdata_lpf, Scenario);
    
    % Deflection mit LPF-Deckhautfestigkeit und physikalischer Kurve
    % Mdata_lpf.softening_factor = cfk_lpf.softening_phys; % Physikalische Entfestigung
    [Res_lpf, Curve_lpf] = Deflection(Res_lpf, Scenario, Mdata_lpf);
    Res_lpf = Energy_calc(Res_lpf, Curve_lpf, Scenario, Mdata_lpf);
    t_lpf_all(p) = toc(t_start_lpf) * 1000; % in ms
    
    % Werte erfassen
    uts_base = Res_base.UTS;
    uts_lpf  = Res_lpf.UTS;
    
    f_base = Res_base.F_max / 1000;
    f_lpf  = Res_lpf.F_max / 1000;
    
    % Test F_max Schätzung aus UTS_test:
    f_test = (uts_test * 4 * Res_base.I) / (Scenario.panel.l * Res_base.y_max) / 1000;
    
    e_base = Res_base.Energy;
    e_lpf  = Res_lpf.Energy;
    
    % Abweichungen berechnen
    d_uts_base = abs(uts_base - uts_test) / uts_test * 100;
    d_uts_lpf  = abs(uts_lpf - uts_test) / uts_test * 100;
    err_uts_base(end+1) = d_uts_base;
    err_uts_lpf(end+1)  = d_uts_lpf;
    
    d_f_base = abs(f_base - f_test) / f_test * 100;
    d_f_lpf  = abs(f_lpf - f_test) / f_test * 100;
    err_f_base(end+1) = d_f_base;
    err_f_lpf(end+1)  = d_f_lpf;
    
    d_e_base = abs(e_base - e_test) / e_test * 100;
    d_e_lpf  = abs(e_lpf - e_test) / e_test * 100;
    err_e_base(end+1) = d_e_base;
    err_e_lpf(end+1)  = d_e_lpf;
    
    better_uts = "Base";
    if d_uts_lpf < d_uts_base, better_uts = "LPF"; end
    if abs(d_uts_lpf - d_uts_base) < 1.0, better_uts = "Gleich"; end
    
    better_f = "Base";
    if d_f_lpf < d_f_base, better_f = "LPF"; end
    if abs(d_f_lpf - d_f_base) < 0.5, better_f = "Gleich"; end
    
    fprintf('%-7s | %5.0f %5.0f %5.0f %6s | %5.1f %5.1f %5.1f %6s | %5.1f %5.1f %5.1f      | %5.2f %6.2f\n', ...
        target_id, uts_test, uts_base, uts_lpf, better_uts, ...
        f_test, f_base, f_lpf, better_f, ...
        e_test, e_base, e_lpf, ...
        t_base_all(p), t_lpf_all(p));
        
    if target_id == plot_panel_id
        plot_data_base.Curve = Curve_base;
        plot_data_base.Res   = Res_base;
        plot_data_lpf.Curve  = Curve_lpf;
        plot_data_lpf.Res    = Res_lpf;
        plot_data_lpf.cfk    = cfk_lpf;
        plot_data_lpf.e_test = e_test;
        plot_data_lpf.f_test = f_test;
    end
end

fprintf('%s\n', repmat('-', 1, 115));
mean_uts_b = mean(err_uts_base); mean_uts_l = mean(err_uts_lpf);
mean_f_b   = mean(err_f_base);   mean_f_l   = mean(err_f_lpf);
mean_e_b   = mean(err_e_base);   mean_e_l   = mean(err_e_lpf);
mean_t_b   = mean(t_base_all);   mean_t_l   = mean(t_lpf_all);

fprintf('MITTELWERT ABWEICHUNGEN:\n');
fprintf('  - Mittlerer Fehler UTS:       Baseline = %5.1f %%  |  LPF = %5.1f %%   (Delta = %+4.1f %%)\n', ...
    mean_uts_b, mean_uts_l, mean_uts_l - mean_uts_b);
fprintf('  - Mittlerer Fehler F_max:     Baseline = %5.1f %%  |  LPF = %5.1f %%   (Delta = %+4.1f %%)\n', ...
    mean_f_b, mean_f_l, mean_f_l - mean_f_b);
fprintf('  - Mittlerer Fehler Energie:   Baseline = %5.1f %%  |  LPF = %5.1f %%   (Delta = %+4.1f %%)\n', ...
    mean_e_b, mean_e_l, mean_e_l - mean_e_b);
fprintf('------------------------------------------------------------------------------------------------------------------------\n');
fprintf('RECHENZEIT-ANALYSE:\n');
fprintf('  - Mittlere Rechenzeit Baseline:  %6.2f ms / Panel\n', mean_t_b);
fprintf('  - Mittlere Rechenzeit LPF:       %6.2f ms / Panel\n', mean_t_l);
slowdown = mean_t_l / max(0.001, mean_t_b);
fprintf('  - Laufzeit-Verlangsamung (Faktor):  %5.1fx langsamer\n', slowdown);
fprintf('------------------------------------------------------------------------------------------------------------------------\n');
fprintf('HOCHRECHNUNG AUF OPTIMIERUNG (10.000 LAMINAT-EVALUIERUNGEN IN Optimize_Panel.m):\n');
t_opt_base = (mean_t_b * 10000) / 1000; % in s
t_opt_lpf  = (mean_t_l * 10000) / 1000; % in s
fprintf('  - Geschätzte Optimizer-Dauer mit Baseline:    %6.1f Sekunden  (%4.1f Minuten)\n', t_opt_base, t_opt_base/60);
fprintf('  - Geschätzte Optimizer-Dauer mit LPF:         %6.1f Sekunden  (%4.1f Minuten)\n', t_opt_lpf, t_opt_lpf/60);
fprintf('========================================================================================================================\n\n');

% -------------------------------------------------------------
% DIAGNOSE-PLOT FÜR REFERENZPANEL 26_20
% -------------------------------------------------------------
figure('Name', 'Studie: LPF vs Baseline', 'Color', 'w', 'Position', [100, 100, 1000, 450]);

% Subplot 1: Spannungs-Dehnungs-Kurve der Deckhaut (LPF Progression)
subplot(1, 2, 1);
if isfield(plot_data_lpf, 'cfk') && isfield(plot_data_lpf.cfk, 'curve_top')
    c = plot_data_lpf.cfk.curve_top;
    plot(c.eps * 100, c.sigma, 'b-', 'LineWidth', 2); hold on; grid on;
    yline(plot_data_lpf.cfk.FPF_top, 'r--', 'First-Ply Failure (Matrix)', 'LineWidth', 1.2);
    yline(plot_data_lpf.cfk.LPF_top, 'g--', 'Last-Ply Failure (Faser)', 'LineWidth', 1.2);
    yline(plot_data_lpf.cfk.UTS_top, 'm-.', 'Effektiv UTS (Wrinkling)', 'LineWidth', 1.5);
    xlabel('Deckhaut-Druckdehnung |\epsilon_x| [%]');
    ylabel('Deckhaut-Druckspannung \sigma_x [MPa]');
    title(sprintf('Deckhaut-Verhalten LPF (%s)', plot_panel_id));
    legend('LPF Spannungsverlauf', 'FPF (Matrixriss)', 'LPF (Faserversagen)', 'Wrinkling-Schranke', 'Location', 'SouthEast');
end

% Subplot 2: Kraft-Weg-Verlauf des 3-Punkt-Biegebalkens
subplot(1, 2, 2);
if isfield(plot_data_base, 'Curve') && isfield(plot_data_lpf, 'Curve')
    plot(plot_data_base.Curve.w, plot_data_base.Curve.F / 1000, 'r--', 'LineWidth', 1.8); hold on; grid on;
    plot(plot_data_lpf.Curve.w, plot_data_lpf.Curve.F / 1000, 'b-', 'LineWidth', 2.0);
    yline(plot_data_lpf.f_test, 'k:', sprintf('Test F_{max} (%.1f kN)', plot_data_lpf.f_test), 'LineWidth', 1.5);
    xlabel('Durchbiegung w [mm]');
    ylabel('Kraft F [kN]');
    title(sprintf('3-Punkt-Biegung Kraft-Weg-Vergleich (%s)', plot_panel_id));
    legend('Baseline (Empirisch softening=0.52)', 'LPF Prototyp (Hashin)', 'Test-Grenzlast', 'Location', 'SouthEast');
end

plot_out = fullfile('C:\Users\lauri\.gemini\antigravity\brain\56bb63c7-ffa7-4342-917d-ef5a604452b5\scratch', 'study_lpf_comparison.png');
saveas(gcf, plot_out);
fprintf('Vergleichsplot gespeichert unter: %s\n', plot_out);
