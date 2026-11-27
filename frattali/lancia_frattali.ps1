# Uso: cd C:\luigi2-griglia\frattali; powershell -ExecutionPolicy Bypass -File .\lancia_frattali.ps1 [-Mat file.mat]
param([string]$Mat = "MDFMD_400x400_w2p8_l1p25.mat")
Set-Location $PSScriptRoot
$m = Get-Command matlab -ErrorAction SilentlyContinue
$exe = if ($m) { $m.Source } else { (Get-ChildItem "C:\Program Files\MATLAB\*\bin\matlab.exe" | Sort-Object FullName | Select-Object -Last 1).FullName }
if (-not $exe) { throw "MATLAB non trovato" }
Write-Host "MATLAB: $exe"
& $exe -batch "frattali('$Mat')" 2>&1 | Tee-Object -FilePath log_frattali.txt
Write-Host "FINE - figure in $PSScriptRoot\out_$($Mat.Replace('.mat',''))"
