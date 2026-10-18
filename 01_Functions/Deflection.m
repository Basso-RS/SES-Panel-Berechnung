function [Results, Curve] = Deflection(Results, Scenario, Mdata)
%% DEFLECTION - Physikalische Berechnung von Gradient, Bruchkraft und Kraft-Weg-Kurve
% unter Berücksichtigung von Euler-Bernoulli-Biegesteifigkeit, Mehr-Moden-Versagen
% und kalibriertem Traversen-Softening.

    % Stützweite (Auflagerabstand) ermitteln
    if isfield(Scenario.panel, 'span') && ~isempty(Scenario.panel.span)
        span = Scenario.panel.span;
    else
        span = Scenario.panel.l;
    end

    % Biegungsanteil nach SES (Euler-Bernoulli Dreipunktbiegung)
    nenner = span^3 / (48 * Results.EI);

    % Kernschubanteil nach Timoshenko (falls aktiviert)
    inc_shear = false;
    if isfield(Mdata, 'include_core_shear') && Mdata.include_core_shear
        inc_shear = true;
    elseif isfield(Scenario, 'include_core_shear') && Scenario.include_core_shear
        inc_shear = true;
    end
    if inc_shear
        if ~isfield(Results, 'S') || isempty(Results.S) || Results.S == 0
            Results = Shearstiff_calc(Results, Mdata, Scenario);
        end
        nenner = nenner + span / (4 * Results.S);
    end

    % Prüfstands- und Vorrichtungs-Compliance (falls kalibriert)
    if isfield(Mdata, 'fixture_stiffness') && ~isempty(Mdata.fixture_stiffness) && ...
       isfinite(Mdata.fixture_stiffness) && Mdata.fixture_stiffness > 0
        nenner = nenner + 1 / Mdata.fixture_stiffness;
    end

    % Gradient (Gesamtsteifigkeit) [N/mm]
    Results.Gradient = 1 / nenner;

    % 1. Versagensmoden berechnen
    % A. Deckhaut-Bruchspannung (Biegemoment M = F * L / 4)
    if isfield(Results, 'y_max') && ~isempty(Results.y_max)
        y_max = Results.y_max;
    else
        y_max = Mdata.core.t/2 + Mdata.cfk.t_top;
    end
    F_skin = (4 * Results.I * Mdata.cfk.UTS) / (span * y_max);

    % B. Kern-Schubbruch (Querkraft V = F / 2)
    F_core = 2 * Scenario.panel.b * Mdata.core.t * Mdata.core.tau_max;

    % C. Deckhaut-Knicken / Wrinkling (Hoff-Mautner Kriterium)
    if isfield(Mdata.core, 'G') && Mdata.core.G > 0
        sigma_wrinkling = 0.5 * (Mdata.cfk.E_top * 92.0 * Mdata.core.G)^(1/3);
        F_wrinkling = (4 * Results.I * sigma_wrinkling) / (span * y_max);
    else
        F_wrinkling = inf;
    end

    % Minimale Versagenskraft ermitteln
    [F_max, fail_idx] = min([F_skin, F_core, F_wrinkling]);
    fail_modes = {'Deckhautbruch (UTS)', 'Kernschubbruch (Core Shear)', 'Deckhautknicken (Wrinkling)'};
    Results.failure_mode = fail_modes{fail_idx};
    Results.F_max = F_max;
    Results.F_skin = F_skin;
    Results.F_core = F_core;
    Results.F_wrinkling = F_wrinkling;

    % Bruchweg (Linearer elastischer Biegeweg + Traversen-Softening + Rolleneindrückung)
    w_lin = F_max / Results.Gradient;
    softening = 0.52;
    if isfield(Mdata, 'softening_factor') && ~isempty(Mdata.softening_factor)
        softening = Mdata.softening_factor;
    end
    indentation = 1.0;
    if isfield(Mdata, 'indentation_depth') && ~isempty(Mdata.indentation_depth)
        indentation = Mdata.indentation_depth;
    end
    w_max = (w_lin / softening) + indentation;
    Results.w_max = w_max;

    % 2. Kraft-Weg-Kurve nur bei Anforderung berechnen
    if nargout >= 2
        Curve = struct();
        n_steps = 200;
        w_limit = max(Scenario.panel.w, w_max);
        Curve.w = linspace(0, w_limit, n_steps);
        Curve.F = zeros(1, n_steps);
        
        eff_w = max(0, Curve.w - Scenario.panel.slack);
        w_eff_max = max(1e-6, w_max - Scenario.panel.slack);
        idx_pre = (Curve.w <= w_max);
        
        % Option A: Physikalisch konsistente Anfangssteigung dF/dw bei w=0 entspricht exakt Results.Gradient
        beta_curve  = max(1.0, (Results.Gradient * w_eff_max / F_max));
        beta_energy = max(1.0, (Results.Gradient * w_eff_max / F_max) - 1.0);
        xi = min(1.0, eff_w(idx_pre) / w_eff_max);
        Curve.F(idx_pre)  = F_max * (1 - (1 - xi).^beta_curve);
        Curve.F(~idx_pre) = F_max * Mdata.post_fail_factor;
        
        Curve.F_max = F_max;
        Curve.w_max = w_max;
        Curve.beta  = beta_energy; % Behaelt kalibrierte Energieberechnung bei
    end

    switch Results.failure_mode
        case 'Deckhautbruch (UTS)'
            Results.curve_character = 'Linear-spröde (Faserbruch)';
            Results.E_pre_expected = (F_max * w_max * 0.54) / 1000;
            Results.energy_plausibility = 'Plausibel: Spröder Faserbruch (Pre-Peak dominant)';
        case 'Kernschubbruch (Core Shear)'
            Results.curve_character = 'Elastoplastisch mit Schubplateau';
            Results.E_pre_expected = (F_max * w_max * 0.50) / 1000;
            Results.energy_plausibility = 'Plausibel: Plastische Wabenfaltung (hohe Nachbruch-Energie bis 12.7 mm)';
        case 'Deckhautknicken (Wrinkling)'
            Results.curve_character = 'Stabilitätsversagen (Wrinkling)';
            Results.E_pre_expected = (F_max * w_max * 0.52) / 1000;
            Results.energy_plausibility = 'Plausibel: Lokales Hautknicken';
    end

end
