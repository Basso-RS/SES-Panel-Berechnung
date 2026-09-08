%% Panel Dimensions (SES Vorgabe)

% do not change
Scenario.panel.b = 275;   % mm Panel width
Scenario.panel.l = 400;   % mm Support distance 
Scenario.panel.w = 12.7;  % mm max deflection
% do not change

%% Test Setup (Anpassung an Realität)
Scenario.panel.slack = 0.0;   % Auf 0 gesetzt, um die maximale theoretische Energie nach SES zu erhalten

%% Panel-Parameter (Reine Bauteil- und Geometriedaten)
Scenario.name = '26_20';

% Kerndicke in mm (z.B. 10, 18, 20)
Scenario.core_t = 18;

% Lagenaufbau Panel 26_20:
Scenario.layup = '45fM40J/0m/0m/0m/21m/45T700/cp/18core/cp/45fT700/-21m/0m/0m/0m/45fM40J';
