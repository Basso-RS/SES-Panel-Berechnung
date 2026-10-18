
%% OPTIMIZE_PANEL - Zielwertbasierte Laminat-Optimierung für SES Panels
clearvars; close all; clc;

this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'), fullfile(project_root, '01_Functions'), fullfile(project_root, '02_Data'));

%% Konfiguration
% Zielwerte & Sicherheitsfaktor (Targets)
Targets = struct();
Targets.safety_factor = 1.0;    % Sicherheitsfaktor auf Zielwerte (z.B. 1.0 = keine Reserve, 1.1 = +10%)
Targets.Gradient      = 3000;   % Mindest-Gradient [N/mm]
Targets.Energy        = 60;     % Mindest-Energieaufnahme [J]
Targets.EI            = 0;      % Mindest-Biegesteifigkeit [N*mm^2]
Targets.UTS           = 0;      % Mindest-Deckhautfestigkeit [MPa]
Targets.E             = 0;      % Mindest-E-Modul Deckhaut [GPa]
Targets.F_max         = 0;      % Mindest-Bruchkraft [N]
Targets.t_skin_max    = 0;      % Max. Deckhautdicke [mm]

% Optimierungseinstellungen
OptSettings = struct();
OptSettings.min_plies              = 4;           % Mindestanzahl Lagen
OptSettings.max_plies              = 8;           % Maximalanzahl Lagen
OptSettings.angle_mode             = 'simple';    % 'simple' ([0, +/-21, 45]) oder 'advanced'
OptSettings.material_pool          = 'all';       % 'all' oder 'standard'
OptSettings.core_thicknesses       = [10, 20];    % Erlaubte Kerndicken [mm] (z.B. [10, 20] oder 20)
OptSettings.core_materials         = {'core'};    % Erlaubte Kernmaterialien (z.B. {'core'}, {'core', 'rohacell'}, oder 'all')
OptSettings.unique_recipes         = true;        % Nur einzigartige Materialrezepte in Top-5 anzeigen (Permutationen filtern)
OptSettings.sichtlage_active       = true;        % Sichtlage aktiv
OptSettings.sichtlage_material     = {'t7'};      % Erlaubte Sichtlagen-Materialien
OptSettings.sichtlage_angle        = 45;          % Winkel der Sichtlage [Grad]
OptSettings.core_interface_fabric  = true;        % Gewebelage am Kern
OptSettings.plot_curve             = true;        % Vergleichsplot erzeugen
OptSettings.verbose                = true;        % Konsolenausgabe

%% Simulation & Optimierung
Scenario = Scenariodata();
Calib    = Calibration();

console_text = evalc('[Best, TopList, Baseline] = optimize_laminate(Scenario, Calib, Targets, OptSettings);');
fprintf('%s', console_text);

%% Visualisierung (Baseline vs. Optimum)
if OptSettings.plot_curve && ~isempty(Best) && isfield(Best, 'Curve')
    try
        figure('Name', 'SES Panel Optimierung: Baseline vs. Optimum', 'Color', 'w', 'Position', [150, 150, 920, 520]);
        hold on; grid on; box on;
        
        BaseCurve = Baseline.Curve;
        if isempty(BaseCurve) || ~isfield(BaseCurve, 'w')
            BaseMdata = Materialdata(Scenario, Calib);
            [~, BaseCurve] = Deflection(Baseline, Scenario, BaseMdata);
        end
        
        plot(BaseCurve.w, BaseCurve.F / 1000, 'LineWidth', 2.0, 'Color', [0.75, 0.2, 0.2], ...
            'DisplayName', sprintf('Baseline: %s (%.1f g, %.0f g/m^2, %.0f N/mm, %.1f J)', ...
            Scenario.name, Baseline.mass_panel, Baseline.gsm_total, Baseline.Gradient, Baseline.Energy));
            
        plot(Best.Curve.w, Best.Curve.F / 1000, 'LineWidth', 2.5, 'Color', [0.1, 0.65, 0.25], ...
            'DisplayName', sprintf('Optimum: #1 %s [%.0fmm %s] (%.1f g, %.0f g/m^2, %.0f N/mm, %.1f J)', ...
            Best.top_skin, Best.core_t, Best.core_mat, Best.mass_panel, Best.gsm_total, Best.Gradient, Best.Energy));
            
        if isfield(Baseline, 'w_max') && isfield(Baseline, 'F_max')
            plot(Baseline.w_max, Baseline.F_max / 1000, 'ro', 'MarkerFaceColor', [0.75, 0.2, 0.2], 'MarkerSize', 8, ...
                'DisplayName', sprintf('F_{max,Base} = %.1f kN @ %.1f mm', Baseline.F_max/1000, Baseline.w_max));
        end
        if isfield(Best, 'w_max') && isfield(Best, 'F_max')
            plot(Best.w_max, Best.F_max / 1000, 'gs', 'MarkerFaceColor', [0.1, 0.65, 0.25], 'MarkerSize', 8, ...
                'DisplayName', sprintf('F_{max,Opt}  = %.1f kN @ %.1f mm', Best.F_max/1000, Best.w_max));
        end
        
        if Targets.Gradient > 0
            w_test = linspace(0, 5, 50);
            plot(w_test, (Targets.Gradient * w_test) / 1000, 'k--', 'LineWidth', 1.2, ...
                'DisplayName', sprintf('Ziel-Gradient >= %d N/mm', Targets.Gradient));
        end
        
        xlabel('Durchbiegung w [mm]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Kraft F [kN]', 'FontSize', 11, 'FontWeight', 'bold');
        title(sprintf('Laminat-Optimierung (SF = %.2f): Gewichtsersparnis -%.1f %% (-%.1f g)', ...
            Targets.safety_factor, Best.weight_saving_pct, Best.weight_saving_g), 'FontSize', 13, 'FontWeight', 'bold');
        legend('Location', 'best', 'FontSize', 10);
        xlim([0, max(12.7, max(Baseline.w_max, Best.w_max) + 1)]);
        ylim([0, max(Baseline.F_max, Best.F_max) / 1000 * 1.15]);
        hold off;
    catch ME
        fprintf('Hinweis: Plot konnte nicht angezeigt werden (%s).\n', ME.message);
    end
end

%% Automatischer PDF-Export der Konsolenausgabe in Downloads
export_pdf_report(console_text, 'optimization', Targets);

