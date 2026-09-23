function Results = EI_calc (Mdata,Results,Scenario)

% E-Modul und UTS zur Auswertung direkt in Results ablegen
Results.E   = (Mdata.cfk.E_top + Mdata.cfk.E_lower) / 2;
Results.UTS = Mdata.cfk.UTS;

% Geometrische Schwerpunkte der Deckhäute bezüglich Kernmitte (z = 0)
z_c_top   = +(Mdata.core.t / 2 + Mdata.cfk.t_top / 2);
z_c_lower = -(Mdata.core.t / 2 + Mdata.cfk.t_lower / 2);

% Dehnsteifigkeiten (EA) der Deckhäute
EA_top   = Mdata.cfk.E_top * Scenario.panel.b * Mdata.cfk.t_top;
EA_lower = Mdata.cfk.E_lower * Scenario.panel.b * Mdata.cfk.t_lower;

% Neutralachsen-Verschiebung z_NA gegenüber der Kernmitte
if (EA_top + EA_lower) > 0
    z_NA = (EA_top * z_c_top + EA_lower * z_c_lower) / (EA_top + EA_lower);
else
    z_NA = 0;
end

% Abstand der Deckhaut-Schwerpunkte zur tatsächlichen Neutralachse
d_top   = abs(z_c_top - z_NA);
d_lower = abs(z_c_lower - z_NA);

% Eigen-Flächenträgheitsmomente der Deckhäute (b * t^3 / 12)
I_eigen_top   = (Scenario.panel.b * Mdata.cfk.t_top^3) / 12;
I_eigen_lower = (Scenario.panel.b * Mdata.cfk.t_lower^3) / 12;

% Steiner-Anteile bezüglich der Neutralachse (b * t * d^2)
I_steiner_top   = Scenario.panel.b * Mdata.cfk.t_top * (d_top^2);
I_steiner_lower = Scenario.panel.b * Mdata.cfk.t_lower * (d_lower^2);

% Gesamte Biegesteifigkeit EI
Results.EI = Mdata.cfk.E_top * (I_eigen_top + I_steiner_top) + ...
             Mdata.cfk.E_lower * (I_eigen_lower + I_steiner_lower);

% Reines Flächenträgheitsmoment I (für SES-Auswertung)
Results.I = (I_eigen_top + I_steiner_top) + (I_eigen_lower + I_steiner_lower);

% Wichtige Neutralachsen- und Randfaser-Kennwerte für Spannungs-/Bruchberechnung
Results.z_NA = z_NA;
Results.y_top   = (Mdata.core.t / 2 + Mdata.cfk.t_top) - z_NA;
Results.y_lower = (Mdata.core.t / 2 + Mdata.cfk.t_lower) + z_NA;
Results.y_max   = max(Results.y_top, Results.y_lower);

end