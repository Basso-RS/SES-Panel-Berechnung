function Scenario = Scenariodata()
% SCENARIODATA Definiert Panel-Geometrie und Baseline-Lagenaufbau für SES-Berechnung.

Scenario = struct();

% Panel-Geometrie (SES Prüfvorgabe)
Scenario.panel.b      = 275;   % mm Panel-Breite
Scenario.panel.span   = 400;   % mm Stützweite (Auflagerabstand im 3-Punkt-Biegeversuch)
Scenario.panel.l_real = 500;   % mm Reale Mindestlänge des Prüfpanels (SES-Reglement)
Scenario.panel.l      = 400;   % mm Stützweite (Abwärtskompatibilität)
Scenario.panel.w      = 12.7;  % mm Max. Durchbiegung
Scenario.panel.slack  = 0.0;   % mm Vorrichtungsspiel

% Baseline-Panel (26_20)
Scenario.name   = '26_16';
Scenario.core_t = 18;
Scenario.layup  = '45t7/0m/0m/0m/21m/45t7/cp/core/sym';

if nargout == 0
    assignin('caller', 'Scenario', Scenario);
end

end
