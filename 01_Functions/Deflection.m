function [Results, Curve] = Deflection (Results,Scenario,Mdata)
%% Gradient & max Force at 12.7 mm

    % Gradient nach offizieller SES Euler-Bernoulli Biegeformel [N/mm]
    grad_scale = 1.0;
    if isfield(Mdata, 'gradient_factor') && ~isempty(Mdata.gradient_factor)
        grad_scale = Mdata.gradient_factor;
    end
    Results.Gradient = ((48 * Results.EI) / (Scenario.panel.l^3)) * grad_scale;

%% Analytische Bestimmung der Bruchlast (F_max) und des Bruchwegs (w_max)
    y_max = Mdata.core.t/2 + Mdata.cfk.t_top; 
    
    % 1. Maximale Kraft begrenzt durch Deckhautbruch (UTS / Wrinkling)
    if isfield(Mdata.cfk, 'UTS') && ~isnan(Mdata.cfk.UTS) && Mdata.cfk.UTS > 0
        F_skin_fail = (Mdata.cfk.UTS * 4 * Results.I) / (Scenario.panel.l * y_max);
    else
        F_skin_fail = inf;
    end
    
    % Reale Bruchlast (Deckhautversagen)
    F_max = F_skin_fail;
    
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
    end

    % Zwischengrößen EI und S aus Results entfernen
    if isfield(Results, 'EI'), Results = rmfield(Results, 'EI'); end
    if isfield(Results, 'S'),  Results = rmfield(Results, 'S');  end

end 