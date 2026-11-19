# Uso (PowerShell, nella cartella C:\luigi2-griglia):  .\rilancia.ps1 4 4 1
# Pubblica le modifiche, avvia il workflow, aspetta la fine, salva il log in log.txt e scarica M se c'e'.
param([int]$NI = 4, [int]$NJ = 4, [int]$K = 1)
$ErrorActionPreference = "Continue"
git add -A
git commit -m "aggiornamento $(Get-Date -Format s)" | Out-Null
git push
$prima = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId"
gh workflow run luigi2.yml -f NI=$NI -f NJ=$NJ -f K=$K
do { Start-Sleep 5; $RUN = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId" } while ($RUN -eq $prima)
Write-Host "run $RUN avviato: https://github.com/Giogarr/luigi2-griglia/actions/runs/$RUN"
gh run watch $RUN --interval 60 | Out-Null
gh run view $RUN --log | Out-File -Encoding utf8 log.txt
gh run view $RUN --json conclusion,jobs | Out-File -Encoding utf8 esito.json
gh run download $RUN -n "M_${NI}x${NJ}" -D . 2>$null
Write-Host "FINE run $RUN - log in log.txt"
Get-Content esito.json | Select-String conclusion | Select-Object -First 1
