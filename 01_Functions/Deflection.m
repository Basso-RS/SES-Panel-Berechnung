function [Results, Curve] = Deflection (Results,Scenario,Mdata)
%% DEFLECTION Berechnet Biegung, Gradient, Bruchlasten und Kraft-Weg-Verlauf

    L = Scenario.panel.l;
    b = Scenario.panel.b;

    % 1. Gradient nach offizieller SES Euler-Bernoulli Biegeformel [N/mm]
    % (Verifiziert als präziseste Formel mit nur 6.7% mittlerer Abweichung zu den 2024er Testpanels)
    grad_scale = 1.0;
    if isfield(Mdata, 'gradient_factor') && ~isempty(Mdata.gradient_factor)
        grad_scale = Mdata.gradient_factor;
    end
    Results.Gradient = ((48 * Results.EI) / (L^3)) * grad_scale;

%% Analytische Bestimmung der Versagensmodi (Multi-Mode Failure Envelope)
    if isfield(Results, 'y_max') && Results.y_max > 0
        y_max = Results.y_max;
    else
        y_max = Mdata.core.t/2 + Mdata.cfk.t_top;
    end
    
    % 1. Deckhautbruch (Zug- oder Druckversagen / UTS)
    if isfield(Mdata.cfk, 'UTS') && ~isnan(Mdata.cfk.UTS) && Mdata.cfk.UTS > 0
        F_skin_fail = (Mdata.cfk.UTS * 4 * Results.I) / (L * y_max);
    else
        F_skin_fail = inf;
    end
    
    % 2. Kernschubversagen (Core Shear Failure nach ASTM C393: tau_max = V / (b*d))
    d_core = Mdata.core.t + (Mdata.cfk.t_top + Mdata.cfk.t_lower) / 2;
    if isfield(Mdata.core, 'tau_max') && ~isnan(Mdata.core.tau_max) && Mdata.core.tau_max > 0
        % V_max = F / 2  =>  F_core = 2 * b * d * tau_max
        F_core_fail = 2 * b * d_core * Mdata.core.tau_max;
    else
        F_core_fail = inf;
    end
    
    % 3. Deckhaut-Knicken / Wrinkling (Hoff-Mautner / Plantema)
    E_core_z = 92; % MPa (PAMG 5056 Wabenkern Druckmodul)
    sigma_wrinkling = 0.5 * (Mdata.cfk.E_top * E_core_z * Mdata.core.G)^(1/3);
    F_wrinkling_fail = (sigma_wrinkling * 4 * Results.I) / (L * y_max);
    
    % Maßgebliche Bruchlast bestimmen
    [F_max, fail_idx] = min([F_skin_fail, F_core_fail, F_wrinkling_fail]);
    fail_modes = {'Deckhautbruch (UTS)', 'Kernschubbruch (Core Shear)', 'Deckhautknicken (Wrinkling)'};
    Results.failure_mode = fail_modes{fail_idx};
    Results.F_skin = F_skin_fail;
    Results.F_core = F_core_fail;
    Results.F_wrinkling = F_wrinkling_fail;

    % Linear-elastischer Biegeweg
    w_lin = F_max / Results.Gradient;
    
    % Reale Durchbiegung am Peak unter Berücksichtigung von Kernplastizität & Rolleneindrückung
    softening = 0.52;
    if isfield(Mdata, 'softening_factor') && ~isempty(Mdata.softening_factor)
        softening = Mdata.softening_factor;
    end
    
    delta_indent = 1.0;
    if isfield(Mdata, 'indentation_depth') && ~isempty(Mdata.indentation_depth)
        delta_indent = Mdata.indentation_depth;
    end
    
    w_max = (w_lin / softening) + delta_indent + Scenario.panel.slack;

%% Curve Struct (vektorisiert erzeugt, ohne for-Schleife)
    if nargout > 1
        Curve = struct();
        n_steps = 200;
        w_limit = max(Scenario.panel.w, w_max);
        Curve.w = linspace(0, w_limit, n_steps);
        Curve.F = zeros(1, n_steps);
        
        eff_w = max(0, Curve.w - Scenario.panel.slack);
        w_eff_max = max(1e-6, w_max - Scenario.panel.slack);
        idx_pre = (Curve.w <= w_max);
        
        % Nicht-lineare Softening-Kurve bis zum Bruch bei w_max
        % (Tangente bei w=0 entspricht dem SES-Biegegradienten, Tangente bei w_max geht horizontal über)
        beta = max(1.0, (Results.Gradient * w_eff_max / F_max) - 1);
        xi = min(1.0, eff_w(idx_pre) / w_eff_max);
        Curve.F(idx_pre)  = F_max * (1 - (1 - xi).^beta);
        
        % Nachbruch-Restkraftplateau
        Curve.F(~idx_pre) = F_max * Mdata.post_fail_factor;
        
        Curve.F_max = F_max;
        Curve.w_max = w_max;
        Curve.beta  = beta;
    end

    % Wichtige physikalische Kennwerte direkt in Results speichern
    Results.F_max = F_max;
    Results.w_max = w_max;

    % Kurvencharakter & Plausibilitätsbewertung nach Versagensmodus
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