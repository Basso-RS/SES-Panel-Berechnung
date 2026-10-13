function Calib = Calibration()
% CALIBRATION Zentrale Modell- und Kalibrierungsparameter für SES Sandwich-Panels.

Calib = struct();

% Fertigung & KLT-Kompaktierung (Heißpresse ~6 bar)
Calib.thickness_factor    = 0.95;   % Bauteildicke nach Aushärtung (95% Nenndicke, erhöht E-Modul physikalisch um 1/0.95)
Calib.core_dir            = 'L';    % Wabenkern-Richtung ('W' = Quer/Transverse mit G=230 MPa, 'L' = Längs/Ribbon mit G=550 MPa)
Calib.include_core_shear  = true;   % Kernschubverzerrung nach ASTM C393 Dreipunktbiegung (Timoshenko)
Calib.fixture_stiffness   = 22218;  % [N/mm] Exakte SES Rig Compliance aus Steel-Tube-Kalibrierversuch
Calib.post_fail_factor    = 0.250;  % Restkraftplateau nach Peak (F_post = F_max * factor)

% Bruchkriterium & Versagensanalyse
Calib.failure_criterion   = 'hashin'; % 'hashin' oder 'fixed_strain'
Calib.failure_strain      = [];       % Nenn-Bruchdehnung (leer = Hashin-Interaktion)
Calib.use_lpf             = false;    % Progressives Last-Ply-Failure (false = Hashin geschlossen)

% Elastoplastizität & Energie
Calib.softening_factor    = 0.95;     % Sekanten-Softeningfaktor (aus ASTM C393 Prüfkurven: w_lin / w_max ~ 0.90..0.98)
Calib.indentation_depth   = 0.15;     % Lokale Rolleneindrückung [mm]
Calib.energy_mode         = 'to_peak';% 'to_peak' = Prüfstandsabgleich bis F_max | 'ses_total' = FS-Reglementnachweis bis 12.7 mm (inkl. Wabenstauchung)

end
