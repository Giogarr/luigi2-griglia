# Lancia in un colpo solo le M NxN per piu' valori di omega_base, aspetta la fine, rilancia una volta
# le fette fallite, scarica le M e prepara uno zip con i soli .mat.
# Uso (PowerShell in C:\luigi2-griglia):
#   powershell -ExecutionPolicy Bypass -File .\lancia_omega.ps1                  (default 3.5 3.8 2.8)
#   powershell -ExecutionPolicy Bypass -File .\lancia_omega.ps1 -Omega 3.5,3.8   (altri valori)
param([string[]]$Omega = @("3.5", "3.8", "2.8"), [int]$N = 200, [int]$K = 100, [switch]$Recupera)
# -Recupera: non lancia nulla, riprende i run salvati in runs_omega.json (es. dopo PC spento/sospeso)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
function Tag($w) { $w.Replace(".", "p") }   # 3.5 -> 3p5 (come num2str in merge_shards)

# 0. prerequisiti
foreach ($c in "git", "gh") { if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "manca $c" } }
gh auth status 2>$null | Out-Null; if ($LASTEXITCODE -ne 0) { throw "esegui prima: gh auth login" }

if ($Recupera) {
  $j = Get-Content runs_omega.json -Raw | ConvertFrom-Json
  $N = $j.N; $runs = [ordered]@{}; $j.runs.PSObject.Properties | ForEach-Object { $runs[$_.Name] = $_.Value }
  Write-Host "recupero run: $($runs.Values -join ', ')"
} else {
# 1. pubblica il codice (senza risultati)
git rm -r --cached -q --ignore-unmatch M_*.mat M_*.csv log*.txt esito*.json | Out-Null
git add -A; git commit -m "lancio omega $($Omega -join ',')" | Out-Null; git push

# 2. avvia un run per ogni omega (girano insieme: GitHub li mette in coda, max 20 job alla volta)
$runs = [ordered]@{}
foreach ($w in $Omega) {
  $prima = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId"
  gh workflow run luigi2.yml -f NI=$N -f NJ=$N -f K=$K -f OMEGA=$w
  do { Start-Sleep 5; $id = gh run list -w luigi2.yml -L 1 --json databaseId -q ".[0].databaseId" } while ($id -eq $prima)
  $runs[$w] = $id
  Write-Host "omega $w -> run $id  https://github.com/Giogarr/luigi2-griglia/actions/runs/$id"
}
@{ N = $N; runs = $runs } | ConvertTo-Json | Out-File -Encoding utf8 runs_omega.json
}

function Aspetta($ids) {
  do {
    $aperti = @($ids | Where-Object { (gh run view $_ --json status -q ".status") -ne "completed" })
    if ($aperti.Count) { Write-Host "$(Get-Date -Format HH:mm:ss) run ancora in corso: $($aperti -join ', ')"; Start-Sleep 120 }
  } while ($aperti.Count)
}

# 3. attesa + un solo rilancio delle fette fallite
Aspetta $runs.Values
$rifare = @($runs.Values | Where-Object { (gh run view $_ --json conclusion -q ".conclusion") -ne "success" })
if ($rifare.Count) {
  foreach ($id in $rifare) { Write-Host "run $id non riuscito: rilancio i job falliti"; gh run rerun $id --failed }
  Start-Sleep 20; Aspetta $rifare
}

# 4. log, esito e download delle M
$righe = @()
foreach ($w in $runs.Keys) {
  $id = $runs[$w]; $t = Tag $w
  gh run view $id --log | Out-File -Encoding utf8 "log_w$w.txt"
  $concl = gh run view $id --json conclusion -q ".conclusion"
  $tmp = Join-Path $env:TEMP ("luigi2_" + [guid]::NewGuid())
  gh run download $id -n "M_${N}x${N}_w$w" -D $tmp 2>$null
  Get-ChildItem $tmp -Filter "M_${N}x${N}_w*" -ErrorAction SilentlyContinue | Copy-Item -Destination . -Force
  $ok = Test-Path "M_${N}x${N}_w$t.mat"
  $righe += "omega $w | run $id | $concl | M_${N}x${N}_w$t.mat " + $(if ($ok) { "OK" } else { "MANCANTE" })
}

# 5. zip dei soli .mat
$mats = @($runs.Keys | ForEach-Object { "M_${N}x${N}_w$(Tag $_).mat" } | Where-Object { Test-Path $_ })
$zip = "M_${N}x${N}_omega_" + (($runs.Keys | ForEach-Object { Tag $_ }) -join "_") + ".zip"
if ($mats.Count) { Compress-Archive -Path $mats -DestinationPath $zip -Force; $righe += "zip: $zip ($($mats.Count) file .mat)" }

$righe | Out-File -Encoding utf8 riepilogo_omega.txt
$righe | ForEach-Object { Write-Host $_ }
Write-Host "FINE - riepilogo in riepilogo_omega.txt"
