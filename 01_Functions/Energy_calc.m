function Results = Energy_calc (Results, Curve, Scenario, Mdata)
%ENERGY_CALC Berechnet die absorbierte Energie (analytisch exakt oder via Integration)

    % Energiemodus ermitteln ('to_peak' für Prüfstand / Benchmark, 'ses_total' für 12.7 mm Reglement)
    energy_mode = 'to_peak';
    if nargin >= 4 && isfield(Mdata, 'energy_mode') && ~isempty(Mdata.energy_mode)
        energy_mode = Mdata.energy_mode;
    end

    % 1. Schneller und exakter analytischer Pfad (wenn Curve, Scenario & Mdata übergeben werden)
    if nargin >= 4 && isfield(Curve, 'F_max') && isfield(Curve, 'w_max') && ...
       isfield(Scenario, 'panel') && isfield(Mdata, 'post_fail_factor')
   
        F_max = Curve.F_max;
        w_max = Curve.w_max;
        slack = Scenario.panel.slack;
        w_end = Scenario.panel.w;
        w_eff_max = max(0, w_max - slack);
        
        % Exaktes Integral der nicht-linearen Softening-Kurve bis zum Bruch bei w_max
        if isfield(Curve, 'beta') && ~isempty(Curve.beta)
            beta = Curve.beta;
        else
            grad = Results.Gradient;
            beta = max(1.0, (grad * w_eff_max / max(1e-6, F_max)) - 1);
        end
        E_pre_fail = F_max * w_eff_max * (beta / (beta + 1));
        
        if strcmp(energy_mode, 'to_peak')
            % Energie bis Maximalkraft (entspricht der Auswertung der Prüfmaschine im Sheet)
            Results.Energy = E_pre_fail / 1000;
        else
            % Gesamtenergie bis 12.7 mm inkl. Nachbruch-Plateau (nach offiziellem SES-Reglement)
            E_postfail = (F_max * Mdata.post_fail_factor) * max(0, w_end - w_max);
            Results.Energy = (E_pre_fail + E_postfail) / 1000;
        end
        
    % 2. Numerischer Fallback via Trapezregel
    elseif nargin > 1 && isfield(Curve, 'w') && isfield(Curve, 'F')
        if strcmp(energy_mode, 'to_peak') && isfield(Curve, 'w_max')
            idx = (Curve.w <= Curve.w_max);
            Results.Energy = trapz(Curve.w(idx), Curve.F(idx)) / 1000;
        else
            Results.Energy = trapz(Curve.w, Curve.F) / 1000;
        end
    elseif isfield(Results, 'w') && isfield(Results, 'F')
        Results.Energy = trapz(Results.w, Results.F) / 1000;
    else
        error('Keine Kraft-Weg-Daten (w, F) für Energy_calc gefunden.');
    end

end
