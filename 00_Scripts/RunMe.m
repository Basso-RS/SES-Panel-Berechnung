%% Skript zur Vorauslegung von SES Panels 

clear all
close all
clc

%% Load Data
Scenariodata;
Materialdata;


%% Results
Results = struct();

Results = EI_calc (Mdata,Results,Scenario); % 10.2e9 N/mm2 2x tubes


%%% Wird nicht benötigt, weil im SES wird die Sherung des Kerns nicht
%%% Beachtet 
%Results = Shearstiff_calc (Results,Mdata,Scenario); % Shear for max deflection  

Results = Deflection (Results,Scenario,Mdata); % max force at 12.7mm and max deflection 

Results = Energy_calc (Results); % absorbed energy calculation 

%% Plot Results
figure('Name', 'SES Panel Force-Deflection Curve', 'Color', 'w');
plot(Results.w, Results.F, 'b-', 'LineWidth', 2);
hold on;
plot([0, max(Results.w)], [0, 0], 'k-'); % x-axis
xlabel('Durchbiegung [mm]', 'FontWeight', 'bold');
ylabel('Kraft [N]', 'FontWeight', 'bold');
title(sprintf('SES Panel Biegeversuch (E = %.1f J, F_{max} = %.0f N @ %.1f mm)', Results.Energy, Results.F_max, Results.w_max));
grid on;
