# Uso (PowerShell, nella cartella C:\luigi2-griglia):  .\rilancia.ps1 4 4 1 [omega_base]
# Pubblica le modifiche, avvia il workflow, aspetta la fine, salva il log in log.txt e scarica M se c'e'.
param([int]$NI = 4, [int]$NJ = 4, [int]$K = 1, [string]$OMEGA = "3.13")
$ErrorActionPreference = "Continue"
git rm -r --cached -q --ignore-unmatch M_*.mat M_*.csv log*.txt esito.json | Out-Null
git add -A
git commit -m "aggiornamento $(Get-Date -Format s)" | Out-Null
git push
$prima = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId"
gh workflow run luigi2.yml -f NI=$NI -f NJ=$NJ -f K=$K -f OMEGA=$OMEGA
do { Start-Sleep 5; $RUN = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId" } while ($RUN -eq $prima)
Write-Host "run $RUN avviato: https://github.com/Giogarr/luigi2-griglia/actions/runs/$RUN"
& "$PSScriptRoot\scarica.ps1" $NI $NJ $OMEGA
