%% Emoduls + Thickness
Mdata.cfk.E_top      = 61800;    %Mpa (61.8 GPa)
Mdata.cfk.t_top      = 1.45;     %mm

Mdata.cfk.E_lower    = 61800;    %Mpa
Mdata.cfk.t_lower    = 1.45;     %mm

%% Core Data 

Mdata.core.G         = 20;       %Mpa
Mdata.core.t         = 18;       %mm
Mdata.core.tau_max   = 2.1;      %Mpa (Geschätzt für L-Richtung / Ribbon-Direction bei RT)

%% Festigkeiten (Failure Limits)
Mdata.cfk.UTS        = 360;      %Mpa (Zug-/Druckfestigkeit der Deckhäute, aus Screenshot)
% Restkraft nach Bruch in Prozent (z.B. 20% der Bruchlast)
Mdata.post_fail_factor = 0.262; 



