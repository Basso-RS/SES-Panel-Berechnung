$w = New-Object -ComObject WScript.Shell
$s = $w.CreateShortcut('c:\Users\lauri\Documents\MATLAB\SES_Panel\Literatur.lnk')
Write-Output $s.TargetPath
