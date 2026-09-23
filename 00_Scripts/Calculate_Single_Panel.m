%% CALCULATE_SINGLE_PANEL - Einzelsimulation eines SES Sandwich Panels
% Berechnet Steifigkeit, Bruchspannung und absorbierte Energie für das in
% Scenariodata.m definierte Panel und gibt die Ergebnisse formatiert aus.

clearvars;
close all;
clc;

this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
project_root = fileparts(this_dir);
addpath(fullfile(project_root, '00_Scripts'), fullfile(project_root, '01_Functions'), fullfile(project_root, '02_Data'));

tic;

%% Load Data
Scenariodata;
Calib = Calibration(Scenario);
Mdata = Materialdata(Scenario, Calib);

%% Results
Results = struct();
Results = EI_calc(Mdata, Results, Scenario);
Results = Shearstiff_calc(Results, Mdata, Scenario);
[Results, Curve] = Deflection(Results, Scenario, Mdata);
Results = Energy_calc(Results, Curve, Scenario, Mdata);

%% Gewicht & Flächenmasse berechnen
Weight = calc_panel_weight(Scenario);
Results.Weight = Weight;

%% Zeitausgabe & Auswertung anzeigen
t_calc = toc;

fprintf('\n======================================================================\n');
fprintf('                     SES PANEL BERECHNUNGSERGEBNIS                    \n');
fprintf('======================================================================\n');
if isfield(Scenario, 'name') && ~isempty(Scenario.name)
    fprintf('  Panel / Szenario:         %s\n', Scenario.name);
end
fprintf('  Lagenaufbau:              %s\n', Scenario.layup);
fprintf('  Prüfgeometrie:            L = %.0f mm, b = %.0f mm\n', ...
    Scenario.panel.l, Scenario.panel.b);
fprintf('----------------------------------------------------------------------\n');
fprintf('GEOMETRIE:\n');
fprintf('  - Deckhautdicke oben:     %6.2f mm\n', Mdata.cfk.t_top);
fprintf('  - Deckhautdicke unten:    %6.2f mm\n', Mdata.cfk.t_lower);
fprintf('  - Kerndicke:              %6.2f mm  (Richtung: %s)\n', Mdata.core.t, Mdata.core.dir);
fprintf('  - Gesamtdicke:            %6.2f mm\n', Mdata.cfk.t_top + Mdata.core.t + Mdata.cfk.t_lower);
fprintf('----------------------------------------------------------------------\n');
fprintf('GEWICHT & FLÄCHENMASSE (PANEL):\n');
fprintf('  - Panel-Gesamtgewicht:    %6.1f g      (SES Prüfpanel: %.0f x %.0f mm)\n', ...
    Weight.mass_panel, Weight.panel_b, Weight.panel_l);
fprintf('  - Gesamt-Flächengewicht:  %6.0f g/m^2   (Sandwich inkl. Kern & beider Deckhäute)\n', ...
    Weight.gsm_total);
if Weight.gsm_skins > 0
    fprintf('    -> CFK-Deckhäute (2x):  %6.0f g/m^2   (%5.1f g, %4.1f%%)\n', ...
        Weight.gsm_skins, Weight.mass_skins, Weight.mass_skins / Weight.mass_panel * 100);
    fprintf('       - Deckhaut oben:     %6.0f g/m^2   (%5.1f g)\n', Weight.gsm_top, Weight.mass_top);
    fprintf('       - Deckhaut unten:    %6.0f g/m^2   (%5.1f g)\n', Weight.gsm_lower, Weight.mass_lower);
end
if Weight.gsm_core > 0
    fprintf('    -> Wabenkern (%.0f mm):   %6.0f g/m^2   (%5.1f g, %4.1f%%)\n', ...
        Weight.core_t, Weight.gsm_core, Weight.mass_core, Weight.mass_core / Weight.mass_panel * 100);
end
if Weight.gsm_cp > 0
    fprintf('    -> Klebefilm (%dx cp):   %6.0f g/m^2   (%5.1f g, %4.1f%%)\n', ...
        Weight.n_cp, Weight.gsm_cp, Weight.mass_cp, Weight.mass_cp / Weight.mass_panel * 100);
end
fprintf('----------------------------------------------------------------------\n');
fprintf('MECHANISCHE EIGENSCHAFTEN:\n');
fprintf('  - E-Modul Deckhaut (E):   %6.1f GPa  (%d MPa)\n', Results.E / 1000, round(Results.E));
fprintf('  - Bruchspannung (UTS):    %6.1f MPa\n', Results.UTS);
if isfield(Results, 'EI')
    fprintf('  - Biegesteifigkeit (EI):  %6.2f kN*m^2  (%.2e N*mm^2)\n', Results.EI / 1e9, Results.EI);
end
if isfield(Results, 'I')
    fprintf('  - Flächenträgheitsmoment: %6.0f mm^4\n', Results.I);
end
fprintf('----------------------------------------------------------------------\n');
fprintf('3-PUNKT-BIEGUNG & ENERGIE:\n');
fprintf('  - Prüfstandsgradient:     %6.0f N/mm   (SES Euler-Bernoulli Biegesteifigkeit)\n', Results.Gradient);
if isfield(Results, 'F_max')
    fprintf('  - Maximalkraft (F_max):   %6.2f kN    (%d N)\n', Results.F_max / 1000, round(Results.F_max));
end
if isfield(Results, 'failure_mode')
    fprintf('  - Versagensmodus:         %s\n', Results.failure_mode);
end
if isfield(Results, 'curve_character')
    fprintf('  - Kurvencharakter:        %s\n', Results.curve_character);
end
if isfield(Results, 'energy_plausibility')
    fprintf('  - Energie-Plausibilität:  %s\n', Results.energy_plausibility);
end
if isfield(Results, 'w_max')
    fprintf('  - Bruchweg bei F_max:     %6.2f mm\n', Results.w_max);
end
energy_mode_str = 'to_peak';
if isfield(Calib, 'energy_mode')
    energy_mode_str = Calib.energy_mode;
end
fprintf('  - Absorbierte Energie:    %6.1f J     (Modus: %s)\n', Results.Energy, energy_mode_str);
fprintf('======================================================================\n');
fprintf('>> Berechnung erfolgreich abgeschlossen in %.2f ms (%.4f s).\n\n', t_calc * 1000, t_calc);

clearvars t_calc energy_mode_str this_dir project_root

