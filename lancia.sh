#!/usr/bin/env bash
# Crea il repo GitHub pubblico, avvia il calcolo e scarica M quando ha finito.
# Prerequisiti: git, gh (https://cli.github.com) autenticato con `gh auth login`.
# Uso: ./lancia.sh [NI] [NJ] [K]     (default 200 200 200)
set -euo pipefail
NI=${1:-200}; NJ=${2:-200}; K=${3:-200}
REPO=${REPO:-luigi2-griglia}

for c in git gh; do command -v $c >/dev/null || { echo "manca $c"; exit 1; }; done
gh auth status >/dev/null || { echo "esegui: gh auth login"; exit 1; }

if [ ! -d .git ]; then
  git init -q && git add . && git commit -qm "Luigi2: griglia parallela"
  gh repo create "$REPO" --public --source . --push
else
  git add . && git commit -qm "aggiornamento" || true
  git push -q
fi

gh workflow run luigi2.yml -f NI="$NI" -f NJ="$NJ" -f K="$K"
sleep 10
RUN=$(gh run list --workflow luigi2.yml --limit 1 --json databaseId -q '.[0].databaseId')
echo "run $RUN · segui: gh run view $RUN --web"
gh run watch "$RUN" --interval 300 || true

# fette fallite (es. timeout) → rilancio automatico una volta, poi unione
if gh run view "$RUN" --json jobs -q '.jobs[]|select(.conclusion=="failure")|.name' | grep -q calcola; then
  gh run rerun "$RUN" --failed && sleep 10 && gh run watch "$RUN" --interval 300 || true
fi
gh run download "$RUN" -n "M_${NI}x${NJ}" -D .
ls -l "M_${NI}x${NJ}".*
