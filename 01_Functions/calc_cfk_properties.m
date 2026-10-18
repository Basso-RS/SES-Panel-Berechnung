function cfk_props = calc_cfk_properties(layup_str, materials_csv_path, calc_energy, t_factor, failure_strain, use_lpf)
% CALC_CFK_PROPERTIES Berechnet KLT-Eigenschaften und Festigkeiten eines Laminats
%
% Inputs:
%   layup_str          : Lagenaufbau-String (z.B. '45f/0m/core/sym')
%   materials_csv_path : (Optional) Pfad zur materials.csv
%   calc_energy        : (Optional) Boolean für Festigkeitsberechnung (Standard: true)
%   t_factor           : (Optional) Skalierung der Lagendicke (Standard: 1.0)
%   failure_strain     : (Optional) Nenn-Bruchdehnung der Deckhaut
%   use_lpf            : (Optional) Boolean für Last-Ply-Failure (Standard: false)

if nargin < 2 || isempty(materials_csv_path)
    this_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(this_dir);
    materials_csv_path = fullfile(project_root, '02_Data', 'materials.csv');
end
if nargin < 3 || isempty(calc_energy)
    calc_energy = true;
end
if nargin < 4 || isempty(t_factor)
    t_factor = 1.0;
end
if nargin < 5
    failure_strain = [];
end
if nargin < 6 || isempty(use_lpf)
    use_lpf = false;
end

% 1. Materialdatenbank via Singleton laden
[mat_dict, E_core, G_core] = load_materials(materials_csv_path);

% 2. Lagenaufbau kanonisch parsen
[top_parts, lower_parts, detected_core_t, detected_core_dir, ~, ~, ~, detected_core_mat] = parse_layup(layup_str);

% 3. Sublaminate berechnen
[E_top, t_top, UTS_top] = calc_sublaminate(top_parts, mat_dict, calc_energy, E_core, G_core, t_factor, failure_strain, use_lpf);

% Symmetrie-Bypass: Wenn identisch oder leer, direkt zuweisen
if isempty(lower_parts) || isequal(top_parts, lower_parts)
    E_lower = E_top;
    t_lower = t_top;
    UTS_lower = UTS_top;
else
    [E_lower, t_lower, UTS_lower] = calc_sublaminate(lower_parts, mat_dict, calc_energy, E_core, G_core, t_factor, failure_strain, use_lpf);
end

cfk_props = struct();
cfk_props.E_top = E_top;
cfk_props.t_top = t_top;
cfk_props.E_lower = E_lower;
cfk_props.t_lower = t_lower;
cfk_props.UTS_top = UTS_top;
cfk_props.UTS_lower = UTS_lower;
cfk_props.UTS = UTS_top;
cfk_props.core_t = detected_core_t;
cfk_props.core_dir = detected_core_dir;
cfk_props.core_mat = detected_core_mat;

end

function [Ex, t_tot, UTS] = calc_sublaminate(parts, mat_dict, calc_energy, E_core, G_core, t_factor, failure_strain, use_lpf)
if isempty(parts)
    Ex = 0; t_tot = 0; UTS = NaN;
    return;
end
if nargin < 7
    failure_strain = [];
end
if nargin < 8 || isempty(use_lpf)
    use_lpf = false;
end

n_plies = length(parts);
Q_bar_all = zeros(3, 3, n_plies);
t_plies = zeros(n_plies, 1);

if calc_energy
    Xc_all = zeros(n_plies, 1); Xt_all = zeros(n_plies, 1);
    Yc_all = zeros(n_plies, 1); Yt_all = zeros(n_plies, 1);
    S_all  = zeros(n_plies, 1);
    E1_all = zeros(n_plies, 1); E2_all = zeros(n_plies, 1);
    G12_all= zeros(n_plies, 1); nu12_all= zeros(n_plies, 1);
    Q_all = zeros(3, 3, n_plies);
    angles_all = zeros(n_plies, 1);
end

for i = 1:n_plies
    ply_str = parts{i};
    [angle_deg, mat_id] = parse_ply_token(ply_str);
    
    if strcmp(mat_id, 'cp')
        continue;
    end
    
    if ~isfield(mat_dict, mat_id)
        error('Material %s nicht in materials.csv gefunden.', mat_id);
    end
    mat = mat_dict.(mat_id);
    
    Q11 = mat.Q11;
    Q22 = mat.Q22;
    Q12 = mat.Q12;
    Q66 = mat.Q66;
    
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
    
    if calc_energy
        angles_all(i) = theta;
        Q_all(:,:,i) = mat.Q;
        Xc_all(i) = mat.Xc;
        Xt_all(i) = mat.Xt;
        Yc_all(i) = mat.Yc;
        Yt_all(i) = mat.Yt;
        S_all(i)  = mat.S;
        E1_all(i) = mat.E1;
        E2_all(i) = mat.E2;
        G12_all(i)= mat.G12;
        nu12_all(i)= mat.nu12;
    end
end

t_tot = sum(t_plies) * t_factor;

% A-Matrix berechnen
A = zeros(3, 3);
for i = 1:n_plies
    A = A + Q_bar_all(:,:,i) * t_plies(i);
end

% Kofaktor-Inversion für 3x3 symmetrisches A
det_A = det(A);
C11 = A(2,2)*A(3,3) - A(2,3)^2;
C12 = A(1,3)*A(2,3) - A(1,2)*A(3,3);
C13 = A(1,2)*A(2,3) - A(1,3)*A(2,2);
C22 = A(1,1)*A(3,3) - A(1,3)^2;
C23 = A(1,2)*A(1,3) - A(1,1)*A(2,3);
C33 = A(1,1)*A(2,2) - A(1,2)^2;

a = [C11, C12, C13;
     C12, C22, C23;
     C13, C23, C33] / det_A;

a11 = (A(2,2)*A(3,3) - A(2,3)^2) / det_A;
Ex = 1 / (a11 * t_tot);

UTS = NaN;
if calc_energy
    if ~isempty(failure_strain) && failure_strain > 0
        UTS_fiber = Ex * failure_strain;
    elseif use_lpf
        UTS_fiber = eval_lpf_progressive(n_plies, angles_all, t_plies, E1_all, E2_all, G12_all, nu12_all, Xc_all, Xt_all, Yc_all, Yt_all, S_all, t_tot);
    else
        UTS_fiber = eval_hashin_closed_form(n_plies, angles_all, Q_all, Xc_all, Xt_all, S_all, a, t_tot);
    end
    
    if ~isnan(E_core) && ~isnan(G_core) && E_core > 0 && G_core > 0
        UTS_wrinkling = 0.5 * (Ex * E_core * G_core)^(1/3);
        UTS = min(UTS_fiber, UTS_wrinkling);
    else
        UTS = UTS_fiber;
    end
end
end

function UTS_fiber = eval_hashin_closed_form(n_plies, angles_all, Q_all, Xc_all, Xt_all, S_all, a, t_tot)
N = [-1; 0; 0];
eps0 = a * N;

is_carrier = abs(angles_all) <= (25 * pi / 180);
if ~any(is_carrier)
    is_carrier = true(n_plies, 1);
end

min_lambda_comp = inf;
for i = 1:n_plies
    if ~is_carrier(i)
        continue;
    end
    m = cos(angles_all(i)); n = sin(angles_all(i));
    T_eps = [m^2, n^2, m*n; 
             n^2, m^2, -m*n; 
             -2*m*n, 2*m*n, m^2-n^2];
    eps_loc = T_eps * eps0;
    sig_loc = Q_all(:,:,i) * eps_loc;
    sig1 = sig_loc(1);
    tau12 = sig_loc(3);
    
    if sig1 < 0
        f_FF = abs(sig1) / Xc_all(i);
    else
        f_FF = sqrt((sig1 / Xt_all(i))^2 + (tau12 / S_all(i))^2);
    end
    
    if f_FF > 0
        lambda = 1 / f_FF;
        if lambda < min_lambda_comp
            min_lambda_comp = lambda;
        end
    end
end

if isinf(min_lambda_comp)
    UTS_fiber = 300;
else
    UTS_fiber = min_lambda_comp / t_tot;
end
end

function UTS_fiber = eval_lpf_progressive(n_plies, angles_all, t_plies, E1_all, E2_all, G12_all, nu12_all, Xc_all, Xt_all, Yc_all, Yt_all, S_all, t_tot)
f_deg_matrix = 0.05;
f_deg_fiber  = 0.005;

E1_curr = E1_all;
E2_curr = E2_all;
G12_curr = G12_all;
nu12_curr = nu12_all;

iff_done = false(n_plies, 1);
ff_done  = false(n_plies, 1);
is_carrier = abs(angles_all) <= (25 * pi / 180);
if ~any(is_carrier), is_carrier = true(n_plies, 1); end

n_inc = 100;
eps_range = linspace(0, 0.015, n_inc);
max_sigma = 0;

for k = 1:n_inc
    eps_x = -eps_range(k);
    if eps_x == 0, continue; end
    
    A_curr = zeros(3, 3);
    Q_curr = zeros(3, 3, n_plies);
    for i = 1:n_plies
        den = max(1e-6, 1 - nu12_curr(i)^2 * E2_curr(i) / max(1e-6, E1_curr(i)));
        Q11 = E1_curr(i) / den;
        Q22 = E2_curr(i) / den;
        Q12 = (nu12_curr(i) * E2_curr(i)) / den;
        Q66 = G12_curr(i);
        Q_loc = [Q11, Q12, 0; Q12, Q22, 0; 0, 0, Q66];
        Q_curr(:,:,i) = Q_loc;
        
        m = cos(angles_all(i)); n = sin(angles_all(i));
        m2 = m^2; n2 = n^2; m4 = m^4; n4 = n^4;
        Qb11 = Q11*m4 + 2*(Q12 + 2*Q66)*m2*n2 + Q22*n4;
        Qb22 = Q11*n4 + 2*(Q12 + 2*Q66)*m2*n2 + Q22*m4;
        Qb12 = (Q11 + Q22 - 4*Q66)*m2*n2 + Q12*(m4 + n4);
        Qb66 = (Q11 + Q22 - 2*Q12 - 2*Q66)*m2*n2 + Q66*(m4 + n4);
        Qb16 = (Q11 - Q12 - 2*Q66)*m^3*n + (Q12 - Q22 + 2*Q66)*m*n^3;
        Qb26 = (Q11 - Q12 - 2*Q66)*m*n^3 + (Q12 - Q22 + 2*Q66)*m^3*n;
        Qb = [Qb11, Qb12, Qb16; Qb12, Qb22, Qb26; Qb16, Qb26, Qb66];
        A_curr = A_curr + Qb * t_plies(i);
    end
    
    if rcond(A_curr(2:3, 2:3)) > 1e-12
        eps_sub = A_curr(2:3, 2:3) \ (-A_curr(2:3, 1) * eps_x);
        eps_y = eps_sub(1); gam_xy = eps_sub(2);
    else
        eps_y = -nu12_all(1) * eps_x; gam_xy = 0;
    end
    eps_glob = [eps_x; eps_y; gam_xy];
    Nx = A_curr(1, :) * eps_glob;
    sig_bar = abs(Nx) / t_tot;
    if sig_bar > max_sigma
        max_sigma = sig_bar;
    end
    
    for i = 1:n_plies
        m = cos(angles_all(i)); n = sin(angles_all(i));
        T_eps = [m^2, n^2, m*n; n^2, m^2, -m*n; -2*m*n, 2*m*n, m^2-n^2];
        eps_loc = T_eps * eps_glob;
        sig_loc = Q_curr(:,:,i) * eps_loc;
        sig1 = sig_loc(1); sig2 = sig_loc(2); tau12 = sig_loc(3);
        
        if sig1 < 0
            f_FF = abs(sig1) / Xc_all(i);
        else
            f_FF = (sig1 / Xt_all(i))^2 + (tau12 / S_all(i))^2;
        end
        
        if sig2 >= 0
            f_IFF = (sig2 / Yt_all(i))^2 + (tau12 / S_all(i))^2;
        else
            f_IFF = (sig2 / (2*S_all(i)))^2 + ((Yc_all(i)/(2*S_all(i)))^2 - 1)*(sig2 / Yc_all(i)) + (tau12 / S_all(i))^2;
        end
        
        if f_IFF >= 1.0 && ~iff_done(i)
            iff_done(i) = true;
            E2_curr(i) = E2_all(i) * f_deg_matrix;
            G12_curr(i) = G12_all(i) * f_deg_matrix;
            nu12_curr(i) = 0;
        end
        if f_FF >= 1.0 && ~ff_done(i)
            ff_done(i) = true;
            E1_curr(i) = E1_all(i) * f_deg_fiber;
            E2_curr(i) = E2_all(i) * f_deg_fiber;
            G12_curr(i) = G12_all(i) * f_deg_fiber;
            nu12_curr(i) = 0;
        end
    end
    
    if all(ff_done(is_carrier))
        break;
    end
end
UTS_fiber = max_sigma;
end
