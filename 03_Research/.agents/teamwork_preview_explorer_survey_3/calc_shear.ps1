# Script to compute exact shear compliance vs bending compliance for various panels
$L = 400.0 # mm
$b = 275.0 # mm

$panels = @(
    @{ Name = "26_12 (10mm Core, L-dir)"; c = 10.0; t_skin = 1.17; E_skin = 120000; G_core = 550.0 },
    @{ Name = "26_12 (10mm Core, W-dir)"; c = 10.0; t_skin = 1.17; E_skin = 120000; G_core = 230.0 },
    @{ Name = "26_20 (18mm Core, L-dir)"; c = 18.0; t_skin = 1.40; E_skin = 105000; G_core = 550.0 },
    @{ Name = "26_20 (18mm Core, W-dir)"; c = 18.0; t_skin = 1.40; E_skin = 105000; G_core = 230.0 },
    @{ Name = "27_04 (20mm Core, L-dir, thin)"; c = 20.0; t_skin = 0.60; E_skin = 213000; G_core = 550.0 },
    @{ Name = "27_04 (20mm Core, W-dir, thin)"; c = 20.0; t_skin = 0.60; E_skin = 213000; G_core = 230.0 }
)

$results = foreach ($p in $panels) {
    $c = $p.c
    $t = $p.t_skin
    $E = $p.E_skin
    $G = $p.G_core
    
    $d = $c + $t
    $I_eigen = 2.0 * ($b * [math]::Pow($t, 3) / 12.0)
    $I_steiner = 2.0 * ($b * $t * [math]::Pow($d / 2.0, 2))
    $I_tot = $I_eigen + $I_steiner
    $EI = $E * $I_tot
    
    $S = ($G * $b * [math]::Pow($d, 2)) / $c
    
    # Bending compliance C_b = L^3 / (48 EI) [mm/N]
    $C_b = [math]::Pow($L, 3) / (48.0 * $EI)
    # Shear compliance C_s = L / (4 S) [mm/N]
    $C_s = $L / (4.0 * $S)
    $C_tot = $C_b + $C_s
    
    $K_euler = 1.0 / $C_b
    $K_true = 1.0 / $C_tot
    $K_current = $K_euler * 1.05 # Deflection.m current
    
    $shear_fraction_pct = ($C_s / $C_tot) * 100.0
    $stiffness_error_pct = (($K_current - $K_true) / $K_true) * 100.0
    $deflection_underestimate_pct = (($C_tot - $C_b) / $C_tot) * 100.0
    
    [PSCustomObject]@{
        Panel = $p.Name
        EI_kNm2 = [math]::Round($EI / 1e9, 2)
        S_kN = [math]::Round($S / 1e3, 1)
        K_Euler_Nmm = [math]::Round($K_euler, 0)
        K_True_Nmm = [math]::Round($K_true, 0)
        K_Deflection_m = [math]::Round($K_current, 0)
        Shear_Defl_Share = [math]::Round($shear_fraction_pct, 1)
        Stiffness_Overpred_pct = [math]::Round($stiffness_error_pct, 1)
    }
}

$results | Format-Table -AutoSize | Out-String -Width 160
