# Script to calculate error in EI_calc.m due to symmetric assumption vs true neutral axis / D11*
$b = 275.0 # mm
$c = 18.0  # mm core thickness

$cases = @(
    @{ Name = "Symmetric (6 plies vs 6 plies)"; t_top = 1.2; E_top = 100000; t_low = 1.2; E_low = 100000 },
    @{ Name = "Asymmetric thickness 1.25x (5 vs 4 plies)"; t_top = 1.25; E_top = 100000; t_low = 1.00; E_low = 100000 },
    @{ Name = "Asymmetric thickness 1.50x (6 vs 4 plies)"; t_top = 1.50; E_top = 100000; t_low = 1.00; E_low = 100000 },
    @{ Name = "Asymmetric thickness 2.00x (8 vs 4 plies)"; t_top = 2.00; E_top = 100000; t_low = 1.00; E_low = 100000 },
    @{ Name = "Material Asymmetry (UD top 160 GPa vs Fabric low 60 GPa, equal t=1.0mm)"; t_top = 1.00; E_top = 160000; t_low = 1.00; E_low = 60000 },
    @{ Name = "Strong Dual Asymmetry (Top 1.5mm @ 160 GPa vs Low 0.8mm @ 70 GPa)"; t_top = 1.50; E_top = 160000; t_low = 0.80; E_low = 70000 }
)

$results = foreach ($cs in $cases) {
    $tt = $cs.t_top
    $tl = $cs.t_low
    $Et = $cs.E_top
    $El = $cs.E_low
    
    # 1. Current EI_calc.m implementation (symmetric midplane assumption)
    $z_top_curr = $c / 2.0 + $tt / 2.0
    $z_low_curr = $c / 2.0 + $tl / 2.0
    $I_eigen_top = ($b * [math]::Pow($tt, 3)) / 12.0
    $I_eigen_low = ($b * [math]::Pow($tl, 3)) / 12.0
    $I_steiner_top = $b * $tt * [math]::Pow($z_top_curr, 2)
    $I_steiner_low = $b * $tl * [math]::Pow($z_low_curr, 2)
    $EI_curr = $Et * ($I_eigen_top + $I_steiner_top) + $El * ($I_eigen_low + $I_steiner_low)
    
    # 2. Rigorous Neutral Axis Calculation
    # Let z=0 at bottom of lower skin
    $zc_low = $tl / 2.0
    $zc_top = $tl + $c + $tt / 2.0
    $A_low = $b * $tl
    $A_top = $b * $tt
    
    $z_NA = ($El * $A_low * $zc_low + $Et * $A_top * $zc_top) / ($El * $A_low + $Et * $A_top)
    $d_geometric_mid = $tl + $c / 2.0 # geometric midpoint of core
    $NA_shift_mm = $z_NA - $d_geometric_mid
    
    $d_top_true = [math]::Abs($zc_top - $z_NA)
    $d_low_true = [math]::Abs($zc_low - $z_NA)
    
    $EI_true = $Et * ($I_eigen_top + $b * $tt * [math]::Pow($d_top_true, 2)) + `
               $El * ($I_eigen_low + $b * $tl * [math]::Pow($d_low_true, 2))
               
    # CLT verification: D11* = D11 - B11^2 / A11 (per unit width) * b
    $A11 = ($El * $tl + $Et * $tt)
    $B11 = $El * $tl * $zc_low + $Et * $tt * $zc_top
    $D11 = $El * ($tl * [math]::Pow($zc_low, 2) + [math]::Pow($tl, 3)/12.0) + `
           $Et * ($tt * [math]::Pow($zc_top, 2) + [math]::Pow($tt, 3)/12.0)
    $D11_star = $D11 - [math]::Pow($B11, 2) / $A11
    $EI_clt = $b * $D11_star
    
    $EI_error_pct = (($EI_curr - $EI_true) / $EI_true) * 100.0
    
    [PSCustomObject]@{
        Case = $cs.Name
        NA_Shift_mm = [math]::Round($NA_shift_mm, 2)
        EI_curr_kNm2 = [math]::Round($EI_curr / 1e9, 3)
        EI_true_kNm2 = [math]::Round($EI_true / 1e9, 3)
        EI_CLT_kNm2 = [math]::Round($EI_clt / 1e9, 3)
        Overestimate_pct = [math]::Round($EI_error_pct, 2)
    }
}

$results | Format-Table -AutoSize | Out-String -Width 160
