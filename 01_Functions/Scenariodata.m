function Scenario = Scenariodata()
% SCENARIODATA Definiert Panel-Geometrie und Baseline-Lagenaufbau für SES-Berechnung.

Scenario = struct();

% Panel-Geometrie (SES Prüfvorgabe)
Scenario.panel.b     = 275;   % mm Panel-Breite
Scenario.panel.l     = 400;   % mm Stützweite
Scenario.panel.w     = 12.7;  % mm Max. Durchbiegung
Scenario.panel.slack = 0.0;   % mm Vorrichtungsspiel

% Baseline-Panel (26_20)
Scenario.name   = '26_20';
Scenario.core_t = 18;
Scenario.layup  = '45fM40J/0m/0m/0m/21m/45T700/cp/18core/cp/45fT700/-21m/0m/0m/0m/45fM40J';

if nargout == 0
    assignin('caller', 'Scenario', Scenario);
end

end
