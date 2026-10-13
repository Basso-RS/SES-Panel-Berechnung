function [Metrics, ProcessedCurve] = evaluate_test_curve(varargin)
% EVALUATE_TEST_CURVE Berechnet physikalisch exakte Kennwerte einer Prüfstandskurve
%
% Syntax:
%   Metrics = evaluate_test_curve(w_raw, F_raw)
%   Metrics = evaluate_test_curve(w_raw, F_raw, options)
%   Metrics = evaluate_test_curve(excel_path, sheet_name)
%   Metrics = evaluate_test_curve(excel_path, sheet_name, options)
%   [Metrics, ProcessedCurve] = evaluate_test_curve(...)
%
% Beschreibung:
%   Wertet Kraft-Weg-Messdaten eines 3-Punkt-Biegeversuchs (SES Sandwich-Panel) aus:
%   1. Automatische Kontaktpunkterkennung (Filterung von Vorlast & Setzspiel).
%   2. Lineare Regression im elastischen Bereich (15% bis 45% F_max) für den Gradienten K [N/mm].
%   3. Peak-Kraft F_max [N] und Bruchweg w_max [mm].
%   4. Energie bis Maximalkraft (E_peak [J]).
%   5. Exakte Trapez-Integration bis 12.70 mm (E_12_7 [J]) mit linear interpoliertem Endpunkt.
%
% Ausgabe:
%   Metrics: Struct mit Kennwerten (Gradient, F_max, w_max, Energy_12_7, Energy_peak, R2, etc.)
%   ProcessedCurve: Struct mit bereinigter Kraft-Weg-Kurve und Fit-Linien für Plots.

%% 1. Eingabeargumente parsen
options = struct();

if nargin >= 2 && (ischar(varargin{1}) || isstring(varargin{1}))
    % Aufruf via Dateipfad und Sheet-Name
    excel_path = char(varargin{1});
    sheet_name = char(varargin{2});
    if nargin >= 3 && isstruct(varargin{3})
        options = varargin{3};
    end
    
    % Sheet einlesen
    T = readtable(excel_path, 'Sheet', sheet_name);
    w_raw = T.Traversenweg_mm;
    F_raw = T.Kraft_N;
    if ismember('Zeit_s', T.Properties.VariableNames)
        t_raw = T.Zeit_s;
    else
        t_raw = [];
    end
elseif nargin >= 2 && isnumeric(varargin{1}) && isnumeric(varargin{2})
    % Aufruf via Vektoren w_raw und F_raw
    w_raw = varargin{1}(:);
    F_raw = varargin{2}(:);
    t_raw = [];
    if nargin >= 3 && isstruct(varargin{3})
        options = varargin{3};
    end
else
    error('Ungültige Eingabeargumente für evaluate_test_curve.');
end

% Optionen mit Standardwerten belegen
f_contact_thresh = 10.0;    % Mindestkraft für Kontaktpunkt in N
fit_lower_pct    = 0.15;    % Untere Grenze für linearen Fit (15% F_max)
fit_upper_pct    = 0.45;    % Obere Grenze für linearen Fit (45% F_max)
target_w_ses     = 12.70;   % SES Referenz-Durchbiegung in mm (0.5 Zoll)

if isfield(options, 'f_contact_thresh'), f_contact_thresh = options.f_contact_thresh; end
if isfield(options, 'fit_lower_pct'),    fit_lower_pct    = options.fit_lower_pct;    end
if isfield(options, 'fit_upper_pct'),    fit_upper_pct    = options.fit_upper_pct;    end
if isfield(options, 'target_w_ses'),     target_w_ses     = options.target_w_ses;     end

%% 2. Datenbereinigung und Absolutwerte
valid_idx = ~isnan(w_raw) & ~isnan(F_raw);
w_clean = abs(double(w_raw(valid_idx)));
F_clean = abs(double(F_raw(valid_idx)));

if isempty(w_clean) || length(w_clean) < 10
    error('Zu wenige valide Datenpunkte in der Messreihe.');
end

% Roh-Peak vor Kontaktkorrektur
F_max_raw = max(F_clean);
dynamic_thresh = max(f_contact_thresh, 0.005 * F_max_raw);

%% 3. Kontaktpunkt-Detektion und Weg-Nullung
idx_contact = find(F_clean >= dynamic_thresh, 1, 'first');
if isempty(idx_contact)
    idx_contact = 1;
end

w_contact = w_clean(idx_contact);
w = w_clean(idx_contact:end) - w_contact;
F = F_clean(idx_contact:end);

% Sicherstellen, dass Weg monoton wächst
[w, sort_idx] = sort(w);
F = F(sort_idx);

% Negative Wege nach Nullung abschneiden
non_neg = w >= 0;
w = w(non_neg);
F = F(non_neg);

%% 4. Peak-Kraft und Bruchverschiebung
[F_max, idx_max] = max(F);
w_max = w(idx_max);

%% 5. Steifigkeitsgradient K via linearer Regression (ASTM / SES Fenster)
F_fit_low = fit_lower_pct * F_max;
F_fit_high = fit_upper_pct * F_max;

idx_fit = find(F >= F_fit_low & F <= F_fit_high & (1:length(F))' <= idx_max);
if length(idx_fit) < 3
    % Fallback: Finde mindestens die ersten Punkte vor dem Peak
    idx_fit = find((1:length(F))' <= max(3, round(0.3 * idx_max)));
end

w_fit = w(idx_fit);
F_fit = F(idx_fit);

% Linearer Fit: F = K * w + d
p = polyfit(w_fit, F_fit, 1);
K_grad = p(1);
d_offset = p(2);

% Bestimmtheitsmaß R^2
F_fit_pred = polyval(p, w_fit);
SS_tot = sum((F_fit - mean(F_fit)).^2);
SS_res = sum((F_fit - F_fit_pred).^2);
if SS_tot > 0
    R2 = max(0, 1 - (SS_res / SS_tot));
else
    R2 = 1.0;
end

% Toe-Kompensation: Schnittpunkt der Tangente mit der Wegachse
w_toe = -d_offset / max(1e-6, K_grad);

%% 6. Energieberechnung (Peak & 12.7 mm SES-Vorgabe)
% A) Energie bis Peak
E_peak = trapz(w(1:idx_max), F(1:idx_max)) / 1000; % N*mm -> Joule

% B) Gesamtenergie bis 12.7 mm
w_end = w(end);
F_end = F(end);

if w_end >= target_w_ses
    % Punkt genau bei 12.70 mm linear interpolieren
    idx_pre127 = find(w < target_w_ses);
    F_127 = interp1(w, F, target_w_ses, 'linear');
    
    w_ses = [w(idx_pre127); target_w_ses];
    F_ses = [F(idx_pre127); F_127];
    
    E_12_7 = trapz(w_ses, F_ses) / 1000;
    reached_12_7 = true;
else
    % Test endete vor 12.7 mm
    E_12_7 = trapz(w, F) / 1000;
    reached_12_7 = false;
end

% C) Nachbruch-Energieanteil
E_postfail = max(0, E_12_7 - E_peak);

% D) Sekantensteifigkeit & Softening-Verhältnis
K_secant = F_max / max(1e-6, w_max);
softening_ratio = K_secant / max(1e-6, K_grad);

%% 7. Ergebnisstruktur zusammenstellen
Metrics = struct();
Metrics.Gradient         = K_grad;            % N/mm
Metrics.F_max            = F_max;             % N
Metrics.w_max            = w_max;             % mm
Metrics.Energy_12_7      = E_12_7;            % J (SES Standard)
Metrics.Energy_peak      = E_peak;            % J (bis Maximalkraft)
Metrics.Energy_postfail  = E_postfail;        % J (Plateaubereich)
Metrics.R2_gradient      = R2;                % Güte des linearen Fits
Metrics.w_toe            = w_toe;             % mm
Metrics.w_end            = w_end;             % mm
Metrics.F_end            = F_end;             % N
Metrics.reached_12_7     = reached_12_7;      % Boolean
Metrics.softening_ratio  = softening_ratio;   % K_secant / K_tangent
Metrics.K_secant         = K_secant;          % N/mm

if nargout > 1
    ProcessedCurve = struct();
    ProcessedCurve.w          = w;
    ProcessedCurve.F          = F;
    ProcessedCurve.w_fit      = w_fit;
    ProcessedCurve.F_fit_pred = F_fit_pred;
    ProcessedCurve.K_grad     = K_grad;
    ProcessedCurve.d_offset   = d_offset;
    ProcessedCurve.w_max      = w_max;
    ProcessedCurve.F_max      = F_max;
    ProcessedCurve.target_w   = target_w_ses;
end

end
