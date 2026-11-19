# Uso: .\scarica.ps1 NI NJ   -> aspetta la fine dell'ultimo run, salva log.txt/esito.json, scarica M
param([int]$NI = 4, [int]$NJ = 4)
$RUN = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId"
do {
  $st = gh run view $RUN --json status -q ".status"
  if ($st -ne "completed") { Write-Host "$(Get-Date -Format HH:mm:ss) run $RUN : $st"; Start-Sleep 60 }
} while ($st -ne "completed")
gh run view $RUN --log | Out-File -Encoding utf8 log.txt
gh run view $RUN --json conclusion,jobs | Out-File -Encoding utf8 esito.json
gh run download $RUN -n "M_${NI}x${NJ}" -D . 2>$null
Write-Host "FINE run $RUN - log in log.txt"
