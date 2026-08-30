function Results = Shearstiff_calc (Results,Mdata,Scenario)
    
    % Abstand zum Schwerpunkt
    d = Mdata.core.t + (Mdata.cfk.t_top + Mdata.cfk.t_lower)/2;
    
    Results.S = (Mdata.core.G * Scenario.panel.b * d^2) / Mdata.core.t;

end 