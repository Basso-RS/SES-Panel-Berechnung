function Calib = Calibration(varargin)
%% CALIBRATION Zentrale Verwaltung aller Modell- und Fertigungsparameter
% Einheitliche Fertigungsmethode: Heißpresse bei ca. 6 bar

    % 1. Faktor für Lagenaufbau-Dicke (reale Bauteildicke nach Aushärtung)
    % 0.95 = 95% der Nenndicke (Kompaktierung in der Heißpresse bei ca. 6 bar)
    Calib.thickness_factor = 0.95;

    % 2. Faktor für Fasergehalt (Faservolumenanteil Vf der Deckhäute)
    Calib.fiber_volume_factor = 1.0;

    % 3. Gradienten-Korrekturfaktor (1.05 = Prüfstands-Biegesteifigkeit inkl. Vorrichtung)
    Calib.gradient_factor = 1.05;

    % 4. Wabenkern-Schubrichtung
    % 'L' = Ribbon / Längsrichtung (G=550 MPa, Standard)
    % 'W' = Transverse / Querrichtung (G=230 MPa)
    Calib.core_dir = 'L';

    % 5. Nachbruch-Restkraftfaktor (F_postfail = F_max * post_fail_factor)
    Calib.post_fail_factor = 0.262;

    % 6. Nenn-Grenzdehnung der CFK-Deckhäute bei 3-Punkt-Biegung
    Calib.failure_strain = 0.00262;

    % 7. Plastizitätsfaktor / Kurvenverweichung (0.52 = elastoplastischer Kernschub & Rolleneindrückung)
    Calib.softening_factor = 0.52;

    % 8. Lokale Rolleneindrückung unter dem Zylinder (in mm)
    Calib.indentation_depth = 1.0;

    % 9. Energiemodus:
    % 'to_peak'   : Energie bis Maximallast F_max (Standard Prüfstands-Auswertung)
    % 'ses_total' : Energie bis 12.7 mm inkl. Restkraftplateau (offizielle SES-Vorgabe)
    Calib.energy_mode = 'to_peak';

end
