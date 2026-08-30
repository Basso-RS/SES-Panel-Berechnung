function Results = Energy_calc (Results)
%ENERGY_CALC Berechnet die absorbierte Energie (Fläche unter der Kraft-Weg-Kurve)

    % Integration der Kraft über den Weg (Ergebnis in N*mm bzw. mJ)
    E_mJ = trapz(Results.w, Results.F); 
    
    % Umrechnung in Joule (J = N*mm / 1000)
    Results.Energy = E_mJ / 1000;

end
