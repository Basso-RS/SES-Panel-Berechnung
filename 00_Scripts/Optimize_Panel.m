%% OPTIMIZE_PANEL - Zielwertbasierte Laminat-Optimierung für SES Panels
% Optimiert Material, Lagenanzahl und Winkel der CFK-Deckhäute zur
% Gewichtsminimierung unter Einhaltung des FSG-Regelwerks und der Wunsch-Zielwerte.

clearvars;
close all;
clc;

this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'), fullfile(project_root, '01_Functions'), fullfile(project_root, '02_Data'));

%% ========================================================================
% 1. SICHERHEITSFAKTOR (SAFETY FACTOR)
%    Kompensiert Streuungen und Berechnungsungenauigkeiten zum Test
%    (z.B. 1.15 bedeutet: Targets werden rechnerisch mit +15% Reserve ausgelegt)
%% ========================================================================
SafetyFactor = 1.0;

%% ========================================================================
% 2. ZIELPARAMETER (TARGETS)
%    Trage hier deine Wunschwerte ein. Parameter mit 0 werden NICHT beachtet!
%
%    OFFIZIELLE FSG-RICHTWERTE FÜR SIDE IMPACT STRUCTURE (SIS nach T3.15):
%      - Absorbierte Energie:    Energy   >= 65.0 J      (Zwingende SES-Regelvorgabe!)
%      - Biegesteifigkeit:       EI       >= 5.11e9 N*mm^2 (Äquivalent zu 3 Stahlrohren)
%      - Prüfstands-Gradient:    Gradient >= 2107 N/mm   (bzw. ~5000-5500 N/mm für Chassis-Steifigkeit)
%      - Maximallast:            F_max    >= 7500 N
%% ========================================================================
Targets = struct();
Targets.safety_factor = SafetyFactor;
Targets.Gradient    = 4000;   % [N/mm]   Mindest-Gradient (z.B. 4000-5000 N/mm für Chassis, SES-Minimum = 2107 N/mm)
Targets.Energy      = 40;     % [J]      Mindest-Energieaufnahme (bei 'to_peak': 30-50 J; für SES >= 65 J 'ses_total' in Calib wählen)
Targets.EI          = 0;      % [N*mm^2] Mindest-Biegesteifigkeit (z.B. 5.11e9 für SIS)
Targets.UTS         = 0;      % [MPa]    Mindest-Deckhautfestigkeit (0 = egal)
Targets.E           = 0;      % [GPa]    Mindest-E-Modul Deckhaut (0 = egal)
Targets.F_max       = 0;      % [N]      Mindest-Bruchkraft (0 = egal)
Targets.t_skin_max  = 0;      % [mm]     Maximale Deckhautdicke (0 = egal)

%% ========================================================================
% 3. OPTIMIERUNGS-EINSTELLUNGEN
%% ========================================================================
OptSettings = struct();
OptSettings.min_plies = 4;           % Mindestanzahl Lagen pro Deckhaut (Default: 4)
OptSettings.max_plies = 8;           % Maximalanzahl Lagen pro Deckhaut (Default: 8)

% Winkelpalette:
%   'simple'   : [0°, +/-21°, 45°] (Standard Formula Student Palette, schnell)
%   'advanced' : [0°, +/-21°, +/-30°, +/-45°, +/-60°]
OptSettings.angle_mode = 'simple';

% Material-Pool (Sigapreg und IMS ausgeschlossen):
%   'all'      : T700 Fabric (t7), M40J UD (m), M40J Fabric (f), T800S UD (t8), ZZ300T (z)
%   'standard' : T700 Fabric (t7) + M40J UD (m) + T800S UD (t8)
OptSettings.material_pool = 'all';

% -------------------------------------------------------------------------
% SICHTLAGE (Kosmetische Außenlage der CFK-Deckhaut):
%   .sichtlage_active   : true (oder 'on')  = Feste Sichtlage vorgegeben
%                         false (oder 'off') = Frei optimieren (Pool)
%   .sichtlage_material : 't7' (T700 Fabric - Standard-Sichtcarbon)
%                         'f'  (M40J Fabric)
%                         'z'  (ZZ300T)
%   .sichtlage_angle    : 45 (Standard 45°-Gewebe) oder 0
% -------------------------------------------------------------------------
OptSettings.sichtlage_active   = true;   % true / false  
OptSettings.sichtlage_material = 't7';   % 't7'=T700 Fabric, 'f'=M40J Fabric, 'z'=ZZ300T
OptSettings.sichtlage_angle    = 45;     % Standard: 45°

OptSettings.core_interface_fabric = true; % Lage direkt am Kern als Gewebe (Best Practice)
OptSettings.plot_curve = true;       % Kraft-Weg-Vergleichskurve plotten
OptSettings.verbose    = true;       % Detaillierte Fortschrittsanzeige im Command Window

%% ========================================================================
%% 4. BASIS-SZENARIO & KALIBRIERUNG LADEN
%% ========================================================================
Scenariodata;
Calib = Calibration();

%% ========================================================================
%% 5. OPTIMIERUNG AUSFÜHREN
%% ========================================================================
[Best, TopList, Baseline] = optimize_laminate(Scenario, Calib, Targets, OptSettings);

%% ========================================================================
%% 6. VERGLEICHS-PLOT (BASELINE VS. OPTIMUM)
%% ========================================================================
if OptSettings.plot_curve && ~isempty(Best) && isfield(Best, 'Curve')
    try
        figure('Name', 'SES Panel Optimierung: Baseline vs. Optimum', 'Color', 'w', 'Position', [150, 150, 920, 520]);
        hold on; grid on; box on;
        
        % Baseline-Kurve
        BaseCurve = Baseline.Curve;
        if isempty(BaseCurve) || ~isfield(BaseCurve, 'w')
            % Bei Bedarf Baseline-Kurve erzeugen
            BaseMdata = Materialdata(Scenario, Calib);
            [~, BaseCurve] = Deflection(Baseline, Scenario, BaseMdata);
        end
        
        plot(BaseCurve.w, BaseCurve.F / 1000, 'LineWidth', 2.0, 'Color', [0.75, 0.2, 0.2], ...
            'DisplayName', sprintf('Baseline: %s (%.1f g, %.0f g/m^2, %.0f N/mm, %.1f J)', ...
            Scenario.name, Baseline.mass_panel, Baseline.gsm_total, Baseline.Gradient, Baseline.Energy));
            
        % Optimum-Kurve
        plot(Best.Curve.w, Best.Curve.F / 1000, 'LineWidth', 2.5, 'Color', [0.1, 0.65, 0.25], ...
            'DisplayName', sprintf('Optimum: #1 %s (%.1f g, %.0f g/m^2, %.0f N/mm, %.1f J)', ...
            Best.top_skin, Best.mass_panel, Best.gsm_total, Best.Gradient, Best.Energy));
            
        % Maximallasten markieren
        if isfield(Baseline, 'w_max') && isfield(Baseline, 'F_max')
            plot(Baseline.w_max, Baseline.F_max / 1000, 'ro', 'MarkerFaceColor', [0.75, 0.2, 0.2], 'MarkerSize', 8, ...
                'DisplayName', sprintf('F_{max,Base} = %.1f kN @ %.1f mm', Baseline.F_max/1000, Baseline.w_max));
        end
        if isfield(Best, 'w_max') && isfield(Best, 'F_max')
            plot(Best.w_max, Best.F_max / 1000, 'gs', 'MarkerFaceColor', [0.1, 0.65, 0.25], 'MarkerSize', 8, ...
                'DisplayName', sprintf('F_{max,Opt}  = %.1f kN @ %.1f mm', Best.F_max/1000, Best.w_max));
        end
        
        % Zielwert-Linie (falls Gradient gefordert)
        if Targets.Gradient > 0
            w_test = linspace(0, 5, 50);
            plot(w_test, (Targets.Gradient * w_test) / 1000, 'k--', 'LineWidth', 1.2, ...
                'DisplayName', sprintf('Ziel-Gradient >= %d N/mm (inkl. SF: %d N/mm)', ...
                Targets.Gradient, round(Targets.Gradient * SafetyFactor)));
        end
        
        xlabel('Durchbiegung w [mm]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Kraft F [kN]', 'FontSize', 11, 'FontWeight', 'bold');
        title(sprintf('Laminat-Optimierung (SF = %.2f): Gewichtsersparnis -%.1f %% (-%.1f g)', ...
            SafetyFactor, Best.weight_saving_pct, Best.weight_saving_g), 'FontSize', 13, 'FontWeight', 'bold');
        legend('Location', 'best', 'FontSize', 10);
        xlim([0, max(12.7, max(Baseline.w_max, Best.w_max) + 1)]);
        ylim([0, max(Baseline.F_max, Best.F_max) / 1000 * 1.15]);
        hold off;
    catch ME
        fprintf('Hinweis: Plot konnte nicht angezeigt werden (%s).\n', ME.message);
    end
end
