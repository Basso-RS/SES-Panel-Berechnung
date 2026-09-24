$json = Get-Content -Path "c:\Users\lauri\Documents\MATLAB\SES_Panel\overview_extracted.json" -Raw | ConvertFrom-Json
$rows = $json | Where-Object { $_.Testpanel -and ($_.Testpanel -match '^2[67]_') }
$rows | Select-Object -Property row_idx, Testpanel, Aufbau, SkinThickness_Top, Bottom, 'h(mm)', 'b(mm)', Gradient, 'Energy[J]', 'E(GPa)', 'RigCompliance(N/mm)_σUTS(MPa)', GemesseneLagendicke_Top, BerechneteLagendicke_Top | Format-Table -AutoSize
