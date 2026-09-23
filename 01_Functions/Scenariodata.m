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

% -------------------------------------------------------------------------
% Materialkürzel & Bezeichnungen (siehe 02_Data/materials.csv):
%   t7       : T700 Fabric      (Toray T700 Kohlefaser-Gewebe,   t = 0.31 mm, E1 =  58.2 GPa)
%   m        : M40J UD          (Toray M40J Hochmodul-UD-Gelege, t = 0.21 mm, E1 = 175.6 GPa)
%   f        : M40J Fabric      (M40J Kohlefaser-Gewebe,         t = 0.23 mm, E1 =  86.8 GPa)
%   cp       : Klebefilm        (Coupling Layer / Harzfilm zur Kernanbindung, ~20-40 gsm)
%   18core   : Wabenkern        (Plascore PAMG-XR1-5056 Aluwabe, t = 18 mm,    G = 550 MPa)
%
% Weitere im Pool verfügbare Materialien:
%   t8       : T800S UD         (Toray T800S hochfestes UD,      t = 0.15 mm, E1 = 155.7 GPa)
%   z        : ZZ300T           (Z-Twill Gewebe,                 t = 0.38 mm, E1 =  51.9 GPa)
% -------------------------------------------------------------------------
