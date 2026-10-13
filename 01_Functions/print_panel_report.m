function print_panel_report(Results, Mdata, Scenario, Weight, duration_ms)
% PRINT_PANEL_REPORT Gibt formatierte SES-Berechnungsergebnisse auf der Konsole aus.
%
% Syntax:
%   print_panel_report(Results, Mdata, Scenario, Weight, duration_ms)

if nargin < 5 || isempty(duration_ms)
    duration_ms = NaN;
end

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
fprintf('STEIFIGKEIT (STIFFNESS):\n');
fprintf('  - E-Modul Deckhaut (E):   %6.1f GPa  (%d MPa)\n', Results.E / 1000, round(Results.E));
if isfield(Results, 'EI')
    fprintf('  - Biegesteifigkeit (EI):  %6.2f kN*m^2  (%.2e N*mm^2)\n', Results.EI / 1e9, Results.EI);
end
if isfield(Results, 'I')
    fprintf('  - Flächenträgheitsmoment: %6.0f mm^4\n', Results.I);
end
fprintf('  - Prüfstandsgradient:     %6.0f N/mm   (SES 3-Punkt-Biegesteifigkeit)\n', Results.Gradient);
fprintf('----------------------------------------------------------------------\n');
fprintf('FESTIGKEIT & VERSAGEN (STRENGTH & FAILURE):\n');
fprintf('  - Bruchspannung (UTS):    %6.1f MPa\n', Results.UTS);
if isfield(Results, 'F_max')
    fprintf('  - Maximalkraft (F_max):   %6.2f kN    (%d N)\n', Results.F_max / 1000, round(Results.F_max));
end
if isfield(Results, 'failure_mode')
    fprintf('  - Versagensmodus:         %s\n', Results.failure_mode);
end
if isfield(Results, 'curve_character')
    fprintf('  - Kurvencharakter:        %s\n', Results.curve_character);
end
if isfield(Results, 'w_max')
    fprintf('  - Bruchweg bei F_max:     %6.2f mm\n', Results.w_max);
end
fprintf('----------------------------------------------------------------------\n');
fprintf('ENERGIEAUFNAHME (ENERGY ABSORPTION):\n');
energy_mode_str = 'to_peak';
if isfield(Mdata, 'energy_mode') && ~isempty(Mdata.energy_mode)
    energy_mode_str = Mdata.energy_mode;
end
fprintf('  - Absorbierte Energie:    %6.1f J     (Modus: %s)\n', Results.Energy, energy_mode_str);
if isfield(Results, 'energy_plausibility')
    fprintf('  - Plausibilität:          %s\n', Results.energy_plausibility);
end
if strcmp(energy_mode_str, 'to_peak')
    fprintf('  - Hinweis Energiemodi:    ''to_peak'' misst bis F_max (fuer Pruefstandsabgleich),\n');
    fprintf('                            ''ses_total'' bis 12.7 mm (FS-Regelwerksnachweis).\n');
else
    fprintf('  - Hinweis Energiemodi:    ''ses_total'' misst bis 12.7 mm (FS-Regelwerksnachweis),\n');
    fprintf('                            ''to_peak'' bis F_max (fuer Pruefstandsabgleich).\n');
end
fprintf('======================================================================\n');
if ~isnan(duration_ms)
    fprintf('>> Berechnung erfolgreich abgeschlossen in %.2f ms (%.4f s).\n\n', duration_ms, duration_ms / 1000);
end

end
