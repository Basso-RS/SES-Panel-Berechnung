function Results = Deflection (Results,Scenario,Mdata)
%% Gradient & max Force at 12.7 mm

    % Das SES ignoriert für den Gradienten und die E-Modul-Rückrechnung den Kernschub.
    % Um das SES perfekt für die Vorauslegung zu spiegeln, nutzen wir nur den Biegeterm:
    nenner = Scenario.panel.l^3 / (48 * Results.EI); 
    
    % Gradient (Steifigkeit) wie im SES [N/mm]
    Results.Gradient = 1 / nenner;

%% Force over Displacement (Weggesteuert inkl. Versagen)

    % Arrays initialise
    n_steps = 200;
    % Wir geben den Weg (w) von 0 bis 12.7 mm vor
    Results.w = linspace(0, Scenario.panel.w, n_steps);
    Results.F = zeros(1, n_steps);
    
    panel_broken = false;
    F_bruch = 0; 
    
    % Maximaler Hebelarm für Deckhautspannung (von neutraler Faser bis Außenkante)
    % (Annahme symmetrisch)
    y_max = Mdata.core.t/2 + Mdata.cfk.t_top; 
    
    % calc deflection
    for idx = 1:n_steps
        current_w = Results.w(idx);
        
        % Effektiver Weg im Panel (Setzung / Slack des Testaufbaus abziehen)
        if current_w <= Scenario.panel.slack
            effective_w = 0;
        else
            effective_w = current_w - Scenario.panel.slack;
        end
        
        if ~panel_broken
            % Lineare Kraft anhand des theoretischen Gradienten
            current_F = effective_w * Results.Gradient;
            
            % 1. Deckhaut-Spannung berechnen (Biegemoment M = F * L / 4)
            M = (current_F * Scenario.panel.l) / 4;
            sigma_skin = (M * y_max) / Results.I;
            
            % 2. Kern-Schubspannung berechnen (Querkraft V = F / 2)
            tau_core = (current_F / 2) / (Scenario.panel.b * Mdata.core.t); 
            
            % Versagenskriterium prüfen
            if sigma_skin >= Mdata.cfk.UTS || tau_core >= Mdata.core.tau_max
                panel_broken = true;
                F_bruch = current_F;
                % Kraft bricht schlagartig auf Rest-Niveau ein
                Results.F(idx) = F_bruch * Mdata.post_fail_factor;
            else
                Results.F(idx) = current_F;
            end
        else
            % Panel ist bereits gebrochen, Kraft bleibt auf Restniveau
            Results.F(idx) = F_bruch * Mdata.post_fail_factor;
        end
    end

    % Die tatsächliche Maximalkraft (Bruchlast) im Versuch
    [Results.F_max, max_idx] = max(Results.F);
    
    % Der Weg, bei dem die Maximalkraft erreicht wird (Bruchweg)
    Results.w_max = Results.w(max_idx);

end 