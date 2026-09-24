function Calib = Calibration()
% CALIBRATION Zentrale Modell- und Kalibrierungsparameter für SES Sandwich-Panels.

Calib = struct();

% Fertigung & KLT-Kompaktierung (Heißpresse ~6 bar)
Calib.thickness_factor    = 0.95;   % Bauteildicke nach Aushärtung (95% Nenndicke)
Calib.fiber_volume_factor = 1.0;    % Faservolumenanteil-Skalierung
Calib.gradient_factor     = 1.05;   % Prüfstands-Biegesteifigkeitsfaktor
Calib.core_dir            = 'L';    % Wabenkern-Richtung ('L' = Längs/Ribbon, 'W' = Quer)
Calib.post_fail_factor    = 0.262;  % Restkraftplateau nach Peak (F_post = F_max * factor)

% Bruchkriterium & Versagensanalyse
Calib.failure_criterion   = 'hashin'; % 'hashin' oder 'fixed_strain'
Calib.failure_strain      = [];       % Nenn-Bruchdehnung (leer = Hashin-Interaktion)
Calib.use_lpf             = false;    % Progressives Last-Ply-Failure (false = Hashin geschlossen)

% Elastoplastizität & Energie
Calib.softening_factor    = 0.52;     % Plastizitäts- und Softening-Faktor
Calib.indentation_depth   = 1.0;      % Lokale Rolleneindrückung [mm]
Calib.energy_mode         = 'to_peak';% 'to_peak' (bis F_max) oder 'ses_total' (bis 12.7 mm)

end
