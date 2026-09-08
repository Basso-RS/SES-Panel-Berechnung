function Calib = Calibration()
%% CALIBRATION Zentrale Verwaltung aller Kalibrierungs- und Korrekturfaktoren
% Enthält alle anpassbaren Modellparameter für Fertigung, Werkstoffkorrekturen
% und Prüfstandseffekte, getrennt von der Panel-Geometrie (Scenario).

    % 1. Faktor für Lagenaufbau-Dicke (Kompaktierung / Harzanteil)
    % 1.0  = Nennwert laut Datenblatt
    % 0.95 = 95% der Nenndicke (z.B. Autoklav-Verpressung)
    Calib.thickness_factor = 0.95;

    % 2. Faktor für Fasergehalt (Faservolumenanteil Vf der Deckhäute)
    % 1.0  = Nenn-Fasergehalt laut Materialdatenblatt (~55-60%)
    % 1.05 = +5% höherer Faseranteil im Laminat
    Calib.fiber_volume_factor = 1.0;

    % 3. Gradienten-Korrekturfaktor (Prüfstands-Biegesteifigkeit)
    % 1.00 = Reiner Nennwert laut Euler-Bernoulli Formel
    % 1.05 = +5% Kalibrierung für Prüfstandssteifigkeit
    Calib.gradient_factor = 1.05;

    % 4. Wabenkern-Schubrichtung
    % 'L' = Ribbon / Längsrichtung (G=550 MPa, Standard)
    % 'W' = Transverse / Querrichtung (G=230 MPa)
    Calib.core_dir = 'L';

    % 5. Nachbruch-Restkraftfaktor (F_postfail = F_max * post_fail_factor)
    Calib.post_fail_factor = 0.262;

    % 6. Nenn-Grenzdehnung der CFK-Deckhäute bei 3-Punkt-Biegung (Faserdruckversagen)
    % Nennwert unter Berücksichtigung der Rollen-Spannungskonzentration (~0.262%)
    Calib.failure_strain = 0.00262;

    % 7. Kurvenverweichung (Verhältnis linear-elastischer Biegeweg zu realem Bruchweg)
    % Reale Prüfstandskurven erreichen den Peak bei ca. 1.8 - 2.0x des rein linearen Wegs
    % bedingt durch elastoplastischen Kernschub und Rolleneindrückung
    Calib.softening_factor = 0.52;

    % 8. Lokale Rolleneindrückung unter dem Zylinder (in mm)
    Calib.indentation_depth = 1.0;

    % 9. Energiemodus:
    % 'to_peak'   : Energie bis Maximallast F_max (Standard Prüfstands-Auswertung / Benchmark)
    % 'ses_total' : Energie bis 12.7 mm inkl. Restkraftplateau (offizielle SES-Vorgabe)
    Calib.energy_mode = 'to_peak';

end
