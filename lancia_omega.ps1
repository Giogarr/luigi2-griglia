# Lancia in un colpo solo le M NxN per piu' valori di omega_base, aspetta la fine, rilancia una volta
# le fette fallite, scarica le M e prepara uno zip con i soli .mat.
# Uso (PowerShell in C:\luigi2-griglia):
#   powershell -ExecutionPolicy Bypass -File .\lancia_omega.ps1                  (default 3.5 3.8 2.8)
#   powershell -ExecutionPolicy Bypass -File .\lancia_omega.ps1 -Omega 2.8,3.5 -LL 1.25,0.8 -N 400 -K 256
#   powershell -ExecutionPolicy Bypass -File .\lancia_omega.ps1 -Script 3 -Omega 3.13 -N 400 -K 256
#   powershell -ExecutionPolicy Bypass -File .\lancia_omega.ps1 -Script 3 -Omega 2.8,3.5,3.13 -LL 1.25,0.8,1 -C 0.1,0.1,0.05 -N 400 -K 256
param([string[]]$Omega = @("3.5", "3.8", "2.8"), [string[]]$LL = @(), [string[]]$C = @(), [int]$N = 200, [int]$K = 100, [ValidateSet("2","3")][string]$Script = "2", [string]$Zoom = "0.5,2,0.1,0.2", [switch]$Recupera)
# -C: valori di p.c (smorzamento), uno per ogni omega (assente = 0.1); solo con -Script 3
# -Zoom "a0,as,e0,es": finestra a in (a0,a0+as], E in (e0,e0+es] con NxN punti (solo -Script 3; default = griglia originale)
# -Script 2 = Luigi2.m (matrice M) · -Script 3 = Luigi3.m (matrici MD e FMD)
# -LL: valori di p.ll, uno per ogni omega nello stesso ordine (assente = 1, come l'originale)
# -Recupera: non lancia nulla, riprende i run salvati in runs_omega.json (es. dopo PC spento/sospeso)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
Start-Transcript -Path (Join-Path $PSScriptRoot "trascrizione_omega.txt") -Append | Out-Null   # tutto l'output, errori compresi
function Riprova([scriptblock]$b, [string]$cosa) {   # fino a 3 tentativi per le chiamate a GitHub
  for ($t = 1; $t -le 3; $t++) { & $b; if ($LASTEXITCODE -eq 0) { return $true }; Write-Host "  $cosa : tentativo $t fallito, riprovo tra 30 s"; Start-Sleep 30 }
  Write-Host "  $cosa : FALLITO dopo 3 tentativi"; return $false
}
function Tag($w) { $w.Replace(".", "p") }   # 3.5 -> 3p5 (come num2str in merge_shards)
function Nome($w, $pl, $pc) { if (-not $pl) { $pl = "1" }; if (-not $pc) { $pc = "0.1" }; $n = "${P}_${N}x${N}_w$(Tag $w)"; if ([double]$pl -ne 1) { $n += "_l$(Tag $pl)" }; if ([double]$pc -ne 0.1) { $n += "_c$(Tag $pc)" }; if ($Zoom -ne "0.5,2,0.1,0.2") { $n += "_z" + (($Zoom.Split(",") | ForEach-Object { Tag $_ }) -join "_") }; $n }
function Artifact($w, $pl, $pc) { if ($Script -eq "3") { "${P}_${N}x${N}_w${w}_l${pl}_c${pc}_z$Zoom" } else { "${P}_${N}x${N}_w${w}_l$pl" } }
# con -File gli elenchi arrivano come "a,b": li separo qui
$Omega = @($Omega | ForEach-Object { $_ -split "," } | Where-Object { $_ })
$LL = @($LL | ForEach-Object { $_ -split "," } | Where-Object { $_ })
if ($LL.Count -eq 0) { $LL = @($Omega | ForEach-Object { "1" }) }
if ($LL.Count -ne $Omega.Count) { throw "-LL deve avere un valore per ogni omega" }
$C = @($C | ForEach-Object { $_ -split "," } | Where-Object { $_ })
if ($C.Count -eq 0) { $C = @($Omega | ForEach-Object { "0.1" }) }
if ($C.Count -ne $Omega.Count) { throw "-C deve avere un valore per ogni omega" }
if ($Script -eq "2" -and $Zoom -ne "0.5,2,0.1,0.2") { throw "-Zoom e disponibile solo con -Script 3" }
if ($Script -eq "2" -and @($C | Where-Object { [double]$_ -ne 0.1 }).Count) { throw "-C e disponibile solo con -Script 3" }
function Imposta { $script:WF = "luigi$Script.yml"; $script:P = $(if ($Script -eq "3") { "MDFMD" } else { "M" }) }
Imposta

# 0. prerequisiti
foreach ($cmd in "git", "gh") { if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "manca $cmd" } }
gh auth status 2>$null | Out-Null; if ($LASTEXITCODE -ne 0) { throw "esegui prima: gh auth login" }

if ($Recupera) {
  $j = Get-Content runs_omega.json -Raw | ConvertFrom-Json
  $N = $j.N; if ($j.Script) { $Script = $j.Script }; if ($j.Zoom) { $Zoom = $j.Zoom }; $runs = [ordered]@{}; $j.runs.PSObject.Properties | ForEach-Object { $runs[$_.Name] = $_.Value }
  Imposta
  Write-Host "recupero run (Luigi$Script): $($runs.Values -join ', ')"
} else {
# 1. pubblica il codice (senza risultati)
git rm -r --cached -q --ignore-unmatch M_*.mat M_*.csv MDFMD_* log*.txt esito*.json | Out-Null
git add -A; git commit -m "lancio Luigi$Script omega $($Omega -join ',')" | Out-Null; git push

# 2. avvia un run per ogni omega (girano insieme: GitHub li mette in coda, max 20 job alla volta)
$runs = [ordered]@{}
for ($q = 0; $q -lt $Omega.Count; $q++) {
  $w = $Omega[$q]; $pl = $LL[$q]; $pc = $C[$q]; $key = "$w|$pl|$pc"
  $prima = gh run list -w $WF -L 1 --json databaseId -q ".[0].databaseId"
  $ga = @("workflow", "run", $WF, "-f", "NI=$N", "-f", "NJ=$N", "-f", "K=$K", "-f", "OMEGA=$w", "-f", "LL=$pl")
  if ($Script -eq "3") { $ga += @("-f", "C=$pc", "-f", "ZOOM=$Zoom") }
  gh @ga
  do { Start-Sleep 5; $id = gh run list -w $WF -L 1 --json databaseId -q ".[0].databaseId" } while ($id -eq $prima)
  $runs[$key] = $id
  Write-Host "omega $w, ll $pl, c $pc -> run $id  https://github.com/Giogarr/luigi2-griglia/actions/runs/$id"
}
@{ N = $N; Script = $Script; Zoom = $Zoom; runs = $runs } | ConvertTo-Json | Out-File -Encoding utf8 runs_omega.json
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
foreach ($key in $runs.Keys) {
  $id = $runs[$key]; $w, $pl, $pc = $key.Split("|"); if (-not $pl) { $pl = "1" }; if (-not $pc) { $pc = "0.1" }; $nm = Nome $w $pl $pc
  $null = Riprova { gh run view $id --log | Out-File -Encoding utf8 "log_$nm.txt" } "log $nm"
  $concl = gh run view $id --json conclusion -q ".conclusion"
  $tmp = Join-Path $env:TEMP ("luigi2_" + [guid]::NewGuid())
  $an = Artifact $w $pl $pc
  $null = Riprova { if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }; gh run download $id -n $an -D $tmp } "download $an"
  Get-ChildItem $tmp -Filter "${P}_${N}x${N}_w*" -ErrorAction SilentlyContinue | Copy-Item -Destination . -Force
  $ok = Test-Path "$nm.mat"
  $righe += "omega $w | ll $pl | c $pc | run $id | $concl | $nm.mat " + $(if ($ok) { "OK" } else { "MANCANTE" })
}

# 5. zip dei soli .mat
$mats = @($runs.Keys | ForEach-Object { $w, $pl, $pc = $_.Split("|"); "$(Nome $w $pl $pc).mat" } | Where-Object { Test-Path $_ })
$zip = "${P}_${N}x${N}_" + (($runs.Keys | ForEach-Object { $w, $pl, $pc = $_.Split("|"); if (-not $pl) { $pl = "1" }; $t = "w$(Tag $w)_l$(Tag $pl)"; if ($pc -and [double]$pc -ne 0.1) { $t += "_c$(Tag $pc)" }; $t }) -join "__") + $(if ($Zoom -ne "0.5,2,0.1,0.2") { "_z" + (($Zoom.Split(",") | ForEach-Object { Tag $_ }) -join "_") } else { "" }) + ".zip"
if ($mats.Count) { Compress-Archive -Path $mats -DestinationPath $zip -Force; $righe += "zip: $zip ($($mats.Count) file .mat)" }

$righe | Out-File -Encoding utf8 riepilogo_omega.txt
$righe | ForEach-Object { Write-Host $_ }
Write-Host "FINE - riepilogo in riepilogo_omega.txt"
Stop-Transcript | Out-Null
