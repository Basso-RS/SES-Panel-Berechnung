function cfk_props = calc_cfk_properties(layup_str, materials_csv_path, calc_energy, t_factor, vf_factor, failure_strain)
    % calc_cfk_properties Berechnet die KLT-Eigenschaften eines Laminats
    % 
    % Inputs:
    %   layup_str          : String des Lagenaufbaus (z.B. '45t/90t/Core/45t/90t')
    %   materials_csv_path : Pfad zur materials.csv Datenbank
    %   calc_energy        : Boolean Schalter für Festigkeitsberechnung
    %   t_factor           : (Optional) Faktor für die reale Bauteildicke (z.B. 0.95 für Verpressung)
    %   vf_factor          : (Optional) Faktor für den Fasergehalt (z.B. 1.05 für +5% Faservolumenanteil)
    %   failure_strain     : (Optional) Nenn-Bruchdehnung der Deckhaut (Default: 0.00262)
    
    if nargin < 4 || isempty(t_factor)
        t_factor = 1.0;
    end
    if nargin < 5 || isempty(vf_factor)
        vf_factor = 1.0;
    end
    if nargin < 6 || isempty(failure_strain)
        failure_strain = 0.00262;
    end
    
    persistent cached_mat_dict cached_csv_path cached_csv_date cached_E_core cached_G_core
    
    % Prüfen ob Materialdatenbank im Cache liegt oder neu geladen werden muss
    file_info = dir(materials_csv_path);
    if isempty(cached_mat_dict) || ~strcmp(cached_csv_path, materials_csv_path) || isempty(file_info) || cached_csv_date ~= file_info.datenum
        % 1. CSV einmalig laden
        opts = detectImportOptions(materials_csv_path, 'Delimiter', ';');
        opts.VariableNamingRule = 'preserve';
        for i = 1:length(opts.VariableNames)
            varName = opts.VariableNames{i};
            if ismember(varName, {'Name', 'Kurzname'})
                opts = setvartype(opts, varName, 'string');
            else
                opts = setvartype(opts, varName, 'double');
            end
        end
        mat_table = readtable(materials_csv_path, opts);
        
        % In vorberechnetes Struct-Dictionary konvertieren
        cached_mat_dict = struct();
        for r = 1:height(mat_table)
            kname = char(mat_table.Kurzname(r));
            E1 = mat_table.E1(r);
            E2 = mat_table.E2(r);
            G12 = mat_table.G12(r);
            nu12 = mat_table.N12(r);
            t_ply = mat_table.Dicke(r);
            if isnan(t_ply), t_ply = 0.2; end
            
            nu21 = 0;
            if E1 > 0, nu21 = nu12 * E2 / E1; end
            den = 1 - nu12 * nu21;
            if den == 0, den = 1; end
            
            entry = struct();
            entry.t_ply = t_ply;
            entry.Q11 = E1 / den;
            entry.Q22 = E2 / den;
            entry.Q12 = (nu12 * E2) / den;
            entry.Q66 = G12;
            entry.Q = [entry.Q11, entry.Q12, 0; entry.Q12, entry.Q22, 0; 0, 0, entry.Q66];
            
            Xt = mat_table.Xt(r); if Xt == 0, Xt = 1e6; end
            Xc = mat_table.Xc(r); if Xc == 0, Xc = 1e6; end
            Yt = mat_table.Yt(r); if Yt == 0, Yt = 1e6; end
            Yc = mat_table.Yc(r); if Yc == 0, Yc = 1e6; end
            S  = mat_table.S12(r); if S == 0,  S = 1e6;  end
            
            entry.F1 = 1/Xt - 1/Xc;
            entry.F2 = 1/Yt - 1/Yc;
            entry.F11 = 1/(Xt * Xc);
            entry.F22 = 1/(Yt * Yc);
            entry.F66 = 1/(S^2);
            entry.F12 = -0.5 * sqrt(entry.F11 * entry.F22);
            
            cached_mat_dict.(kname) = entry;
        end
        
        % Aliase für benutzerfreundliche Bezeichnungen
        if isfield(cached_mat_dict, 'ud')
            cached_mat_dict.m = cached_mat_dict.ud;
            cached_mat_dict.m40jud = cached_mat_dict.ud;
        end
        if isfield(cached_mat_dict, 'f')
            cached_mat_dict.fm40j = cached_mat_dict.f;
            cached_mat_dict.m40jf = cached_mat_dict.f;
            cached_mat_dict.m40j  = cached_mat_dict.f;
        end
        if isfield(cached_mat_dict, 't')
            cached_mat_dict.t700  = cached_mat_dict.t;
            cached_mat_dict.ft700 = cached_mat_dict.t;
            cached_mat_dict.t700f = cached_mat_dict.t;
            cached_mat_dict.t7    = cached_mat_dict.t;
            cached_mat_dict.ft    = cached_mat_dict.t;
            cached_mat_dict.tf    = cached_mat_dict.t;
        end
        if isfield(cached_mat_dict, 't8')
            cached_mat_dict.t800  = cached_mat_dict.t8;
            cached_mat_dict.t800s = cached_mat_dict.t8;
            cached_mat_dict.u8    = cached_mat_dict.t8;
        end
        if isfield(cached_mat_dict, 'a')
            cached_mat_dict.aramid = cached_mat_dict.a;
            cached_mat_dict.kevlar = cached_mat_dict.a;
        end
        
        cached_E_core = NaN; cached_G_core = NaN;
        idx_core_mat = find(strcmpi(mat_table.Kurzname, 'Core'));
        if ~isempty(idx_core_mat)
            cached_E_core = mat_table.E3(idx_core_mat);
            if cached_E_core == 0 || isnan(cached_E_core), cached_E_core = mat_table.E1(idx_core_mat); end
            cached_G_core = mat_table.G13(idx_core_mat);
            if cached_G_core == 0 || isnan(cached_G_core), cached_G_core = mat_table.G12(idx_core_mat); end
        end
        
        cached_csv_path = materials_csv_path;
        if ~isempty(file_info)
            cached_csv_date = file_info.datenum;
        end
    end
    
    mat_dict = cached_mat_dict;
    E_core = cached_E_core;
    G_core = cached_G_core;
    
    % 2. String parsen
    % Format z.B.: 45f/0M/0M/0f/cp/18core/cp/45f/-21m/21m/45f
    % Typische Schreibfehler & Formate bereinigen:
    layup_str = strrep(layup_str, '45a0a', '45a/0a');
    layup_str = regexprep(layup_str, '(\d+)/core', '$1core', 'ignorecase');
    
    parts = strsplit(layup_str, '/');
    parts = strtrim(parts);
    parts(cellfun(@isempty, parts)) = [];
    
    % Nicht-tragenden Klebefilm ('cp') entfernen
    parts(strcmpi(parts, 'cp')) = [];
    
    % Kern suchen (unterstützt 'Core', '18core', '10core', '20core' etc.)
    idx_core = find(contains(lower(parts), 'core'));
    detected_core_t = NaN;
    detected_core_dir = '';
    if isempty(idx_core)
        % Kein Kern gefunden, alles ist Top
        top_parts = parts;
        lower_parts = {};
    else
        core_token = lower(parts{idx_core(1)});
        % Kerndicke aus Bezeichner wie '18core' oder '10core' extrahieren
        core_num = sscanf(core_token, '%f');
        if ~isempty(core_num) && core_num > 0
            detected_core_t = core_num;
        end
        
        % Kern-Richtung prüfen (z.B. 'core(20w)', '18core_w', 'core_l')
        if contains(core_token, 'w')
            detected_core_dir = 'W';
        elseif contains(core_token, 'l')
            detected_core_dir = 'L';
        end
        
        top_parts = parts(1:idx_core(1)-1);
        lower_parts = parts(idx_core(1)+1:end);
        
        % Symmetrischer Aufbau (z.B. 'sym', 'sym.', 'symm', etc.)
        if isempty(lower_parts) || any(contains(lower(lower_parts), 'sym'))
            lower_parts = fliplr(top_parts);
        end
    end
    
    % Funktion um Sub-Laminat zu berechnen
    [E_top, t_top, UTS_top] = calc_sublaminate(top_parts, mat_dict, calc_energy, E_core, G_core, t_factor, vf_factor, failure_strain);
    
    if ~isempty(lower_parts)
        [E_lower, t_lower, UTS_lower] = calc_sublaminate(lower_parts, mat_dict, calc_energy, E_core, G_core, t_factor, vf_factor, failure_strain);
    else
        E_lower = E_top;
        t_lower = t_top;
        UTS_lower = UTS_top;
    end
    
    cfk_props.E_top = E_top;
    cfk_props.t_top = t_top;
    cfk_props.E_lower = E_lower;
    cfk_props.t_lower = t_lower;
    
    cfk_props.UTS_top = UTS_top;
    cfk_props.UTS_lower = UTS_lower;
    % Maßgeblich für Biegebruch ist die gedrückte obere Deckhaut (Top Skin)
    cfk_props.UTS = UTS_top;
    cfk_props.core_t = detected_core_t;
    cfk_props.core_dir = detected_core_dir;
    
end

function [Ex, t_tot, UTS] = calc_sublaminate(parts, mat_dict, calc_energy, E_core, G_core, t_factor, vf_factor, failure_strain)
    if isempty(parts)
        Ex = 0; t_tot = 0; UTS = NaN;
        return;
    end
    if nargin < 7 || isempty(vf_factor)
        vf_factor = 1.0;
    end
    if nargin < 8 || isempty(failure_strain)
        failure_strain = 0.00262;
    end
    
    n_plies = length(parts);
    Q_bar_all = zeros(3, 3, n_plies);
    t_plies = zeros(n_plies, 1);
    
    % Listen für Tsai-Wu
    F1_all = zeros(n_plies,1); F2_all = zeros(n_plies,1);
    F11_all = zeros(n_plies,1); F22_all = zeros(n_plies,1);
    F66_all = zeros(n_plies,1); F12_all = zeros(n_plies,1);
    Q_all = zeros(3,3,n_plies);
    angles_all = zeros(n_plies,1);
    
    for i = 1:n_plies
        ply_str = parts{i};
        
        % Schnelles Parsen von Winkel und Materialkürzel (ohne regexp)
        c = ply_str;
        idx = 1;
        if c(1) == '-' || c(1) == '+', idx = 2; end
        while idx <= length(c) && c(idx) >= '0' && c(idx) <= '9'
            idx = idx + 1;
        end
        angle_deg = sscanf(c(1:idx-1), '%f');
        mat_id = lower(c(idx:end));
        
        if strcmp(mat_id, 'cp')
            continue;
        end
        
        if ~isfield(mat_dict, mat_id)
            error('Material %s nicht in materials.csv gefunden.', mat_id);
        end
        mat = mat_dict.(mat_id);
        
        % Steifigkeitsmatrix Q skaliert mit dem Fasergehaltsfaktor (Vf)
        Q11 = mat.Q11 * vf_factor;
        Q22 = mat.Q22 * vf_factor;
        Q12 = mat.Q12 * vf_factor;
        Q66 = mat.Q66 * vf_factor;
        Q_all(:,:,i) = mat.Q * vf_factor;
        
        % Transformation in KLT
        theta = angle_deg * (pi / 180);
        m = cos(theta); n = sin(theta);
        m2 = m^2; n2 = n^2; m4 = m^4; n4 = n^4;
        
        Qbar11 = Q11*m4 + 2*(Q12 + 2*Q66)*m2*n2 + Q22*n4;
        Qbar22 = Q11*n4 + 2*(Q12 + 2*Q66)*m2*n2 + Q22*m4;
        Qbar12 = (Q11 + Q22 - 4*Q66)*m2*n2 + Q12*(m4 + n4);
        Qbar66 = (Q11 + Q22 - 2*Q12 - 2*Q66)*m2*n2 + Q66*(m4 + n4);
        Qbar16 = (Q11 - Q12 - 2*Q66)*m^3*n + (Q12 - Q22 + 2*Q66)*m*n^3;
        Qbar26 = (Q11 - Q12 - 2*Q66)*m*n^3 + (Q12 - Q22 + 2*Q66)*m^3*n;
        
        Q_bar_all(:,:,i) = [Qbar11, Qbar12, Qbar16;
                            Qbar12, Qbar22, Qbar26;
                            Qbar16, Qbar26, Qbar66];
                 
        t_plies(i) = mat.t_ply;
        angles_all(i) = theta;
        
        if calc_energy
            F1_all(i) = mat.F1;
            F2_all(i) = mat.F2;
            F11_all(i) = mat.F11;
            F22_all(i) = mat.F22;
            F66_all(i) = mat.F66;
            F12_all(i) = mat.F12;
        end
    end
    
    % Reale Dicke (inkl. Aufschlag für Harz/Toleranzen)
    t_tot = sum(t_plies) * t_factor;
    
    % A-Matrix berechnen (Einheit: N/mm)
    % Achtung: Die Steifigkeit (Fasern) ändert sich nicht durch den Harz-Aufschlag, 
    % daher nehmen wir hier weiterhin die echten Lagen-Dicken (t_plies)!
    A = zeros(3,3);
    for i = 1:n_plies
        A = A + Q_bar_all(:,:,i) * t_plies(i);
    end
    
    a = inv(A);
    % Ex des Laminats (verteilt die Steifigkeit auf die reale, größere Dicke)
    Ex = 1 / (a(1,1) * t_tot);
    
    UTS = NaN;
    if calc_energy
        % Deckhaut-Bruchspannung bei 3-Punkt-Biegung (Faserdruckversagen)
        if ~isempty(failure_strain) && failure_strain > 0
            UTS_fiber = Ex * failure_strain;
        else
            % Fallback auf Tsai-Wu FPF
            min_lambda_tens = get_fpf_lambda(1, a, n_plies, angles_all, Q_all, F1_all, F2_all, F11_all, F22_all, F66_all, F12_all);
            min_lambda_comp = get_fpf_lambda(-1, a, n_plies, angles_all, Q_all, F1_all, F2_all, F11_all, F22_all, F66_all, F12_all);
            UTS_fiber = min(min_lambda_tens, min_lambda_comp) / t_tot;
        end
        
        % Deckhautknittern (Skin Wrinkling) bei Druck
        % Formel: sigma_wrinkling = 0.5 * (E_skin * E_core * G_core)^(1/3)
        if ~isnan(E_core) && ~isnan(G_core) && E_core > 0 && G_core > 0
            UTS_wrinkling = 0.5 * (Ex * E_core * G_core)^(1/3);
            % UTS ist das Minimum aus Faserversagen und Knittern (Wrinkling)
            UTS = min(UTS_fiber, UTS_wrinkling);
        else
            UTS = UTS_fiber;
        end
    end
end

function min_lambda = get_fpf_lambda(Nx, a, n_plies, angles_all, Q_all, F1_all, F2_all, F11_all, F22_all, F66_all, F12_all)
    N = [Nx; 0; 0];
    eps0 = a * N; % Globale Dehnungen der Mittelfläche
    min_lambda = inf;
    
    for i = 1:n_plies
        m = cos(angles_all(i)); n = sin(angles_all(i));
        
        % Globale Dehnungen ins lokale System der Schicht rotieren
        T_eps = [m^2, n^2, m*n; 
                 n^2, m^2, -m*n; 
                 -2*m*n, 2*m*n, m^2-n^2];
        eps_loc = T_eps * eps0;
        
        % Spannungen im lokalen System
        sig_loc = Q_all(:,:,i) * eps_loc;
        sig1 = sig_loc(1);
        sig2 = sig_loc(2);
        tau12 = sig_loc(3);
        
        % Tsai-Wu Polynom: a*lambda^2 + b*lambda - 1 = 0
        a_tsai = F11_all(i)*sig1^2 + F22_all(i)*sig2^2 + F66_all(i)*tau12^2 + 2*F12_all(i)*sig1*sig2;
        b_tsai = F1_all(i)*sig1 + F2_all(i)*sig2;
        
        discriminant = b_tsai^2 + 4*a_tsai;
        if discriminant >= 0
            lambda1 = (-b_tsai + sqrt(discriminant)) / (2*a_tsai);
            lambda2 = (-b_tsai - sqrt(discriminant)) / (2*a_tsai);
            
            % Wir interessieren uns für den positiven Skalierungsfaktor der aufgebrachten Last
            lambda_pos = max(lambda1, lambda2);
            if lambda_pos > 0 && lambda_pos < min_lambda
                min_lambda = lambda_pos;
            end
        end
    end
end
