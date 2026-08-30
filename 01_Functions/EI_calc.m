function Results = EI_calc (Mdata,Results,Scenario)

% Abstand der Schwerpunkte der Deckhäute vom Gesamt-Schwerpunkt (bei symmetrischem Aufbau)
z_top = Mdata.core.t/2 + Mdata.cfk.t_top/2;
z_lower = Mdata.core.t/2 + Mdata.cfk.t_lower/2;

% Eigheitsmoment der Deckhäute (b * t^3 / 12)
I_eigen_top = (Scenario.panel.b * Mdata.cfk.t_top^3) / 12;
I_eigen_lower = (Scenario.panel.b * Mdata.cfk.t_lower^3) / 12;

% Steiner-Anteil (b * t * z^2)
I_steiner_top = Scenario.panel.b * Mdata.cfk.t_top * z_top^2;
I_steiner_lower = Scenario.panel.b * Mdata.cfk.t_lower * z_lower^2;

% Biegesteifigkeit (EI = E * I)
Results.EI = Mdata.cfk.E_top * (I_eigen_top + I_steiner_top) + Mdata.cfk.E_lower * (I_eigen_lower + I_steiner_lower);

% Zur Kontrolle: Das reine Flächenträgheitsmoment I wie im SES
Results.I = (I_eigen_top + I_steiner_top) + (I_eigen_lower + I_steiner_lower);

end