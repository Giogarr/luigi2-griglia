# Uso: .\scarica.ps1 NI NJ   -> aspetta la fine dell'ultimo run, salva log.txt/esito.json, scarica M
param([int]$NI = 4, [int]$NJ = 4, [string]$OMEGA = "3.13")
$RUN = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId"
do {
  $st = gh run view $RUN --json status -q ".status"
  if ($st -ne "completed") { Write-Host "$(Get-Date -Format HH:mm:ss) run $RUN : $st"; Start-Sleep 60 }
} while ($st -ne "completed")
gh run view $RUN --log | Out-File -Encoding utf8 "log_w$OMEGA.txt"; Copy-Item "log_w$OMEGA.txt" log.txt
gh run view $RUN --json conclusion,jobs | Out-File -Encoding utf8 esito.json
$tmp = Join-Path $env:TEMP ("luigi2_" + [guid]::NewGuid())
gh run download $RUN -n "M_${NI}x${NJ}_w${OMEGA}" -D $tmp
Get-ChildItem $tmp -Filter "M_${NI}x${NJ}_w*" | Copy-Item -Destination . -Force
Get-ChildItem . -Filter "M_${NI}x${NJ}_w*" | Format-Table Name, Length, LastWriteTime
Write-Host "FINE run $RUN - log in log.txt"
