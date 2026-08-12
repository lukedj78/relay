#!/usr/bin/env bash
#
# Setup script del cloud environment "nightly".
# Da incollare su claude.ai/code → Environments → New → Setup script.
#
# Un solo environment serve tutti i progetti, quindi ogni passo e' difensivo:
# la prima notte il repo e' quasi vuoto, le notti dopo no.
#
# Il risultato viene messo in cache tra le sessioni: la cache conserva i file,
# non i processi. Le dipendenze restano installate, i servizi vanno riavviati
# a ogni run — se ne occupa il prompt della routine.
#
# Le variabili d'ambiente NON vengono da qui: si settano nella scheda
# dell'environment. Perche' DATABASE_URL e' uguale per tutti i progetti e
# quando invece serve un environment dedicato, vedi docs/environments.md.

set -uo pipefail

echo "── capacita' dell'ambiente ─────────────────────────────"
# I blocchi che costano di piu' non sono i bug: sono le capacita' mancanti,
# scoperte a meta' run. Qui l'ambiente dichiara cosa sa fare, in dieci secondi.
# Nessuna riga di questo blocco fa fallire il setup: serve a diagnosticare.

probe() {  # probe <etichetta> <url>
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$2" 2>/dev/null || echo "000")
  case "$code" in
    2*|3*) printf '  rete   %-26s OK (%s)\n' "$1" "$code" ;;
    403)   printf '  rete   %-26s NEGATO dalla policy — aggiungilo in Allowed domains\n' "$1" ;;
    000)   printf '  rete   %-26s irraggiungibile\n' "$1" ;;
    *)     printf '  rete   %-26s http %s\n' "$1" "$code" ;;
  esac
}

probe "ui.shadcn.com"        "https://ui.shadcn.com/r/styles/new-york/button.json"
probe "fonts.googleapis.com" "https://fonts.googleapis.com/css2?family=Inter"
probe "fonts.gstatic.com"    "https://fonts.gstatic.com/"
probe "api.resend.com"       "https://api.resend.com/"
probe "eve.dev"              "https://eve.dev/docs"

for v in AI_GATEWAY_API_KEY VERCEL_OIDC_TOKEN ANTHROPIC_API_KEY; do
  [ -n "${!v:-}" ] && printf '  cred   %-26s presente\n' "$v" \
                   || printf '  cred   %-26s assente\n' "$v"
done

if command -v google-chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1; then
  printf '  tool   %-26s presente\n' "browser"
elif [ -d "$HOME/.cache/ms-playwright" ]; then
  printf '  tool   %-26s presente (playwright)\n' "browser"
else
  printf '  tool   %-26s ASSENTE — niente screenshot al passo 9\n' "browser"
fi

printf '  tool   %-26s %s\n' "node" "$(node -v 2>/dev/null || echo assente)"
printf '  tool   %-26s %s\n' "pnpm" "$(pnpm -v 2>/dev/null || echo assente)"

echo "── skill dev-flow ──────────────────────────────────────"
# Il .claude/settings.json che relay-init scrive nel repo DICHIARA il
# marketplace e il plugin, ma non li installa: in una sessione cloud
# /root/.claude/plugins/installed_plugins.json resta {"plugins": {}} e il
# passo 7 del prompt (invoca dev-flow) non ha niente da invocare.
# Verificato il 2026-08-12 su predictionleagues: due run consecutivi si sono
# fermati proprio qui, correttamente, invece di improvvisare.
if claude plugin list 2>/dev/null | grep -q 'dev-flow'; then
  echo "plugin dev-flow gia' installato"
else
  claude plugin marketplace add lukedj78/dev-flow \
    && claude plugin install dev-flow@dev-flow \
    && echo "plugin dev-flow installato" \
    || echo "installazione del plugin fallita — i run si fermeranno al passo 7"
fi

echo "── dipendenze ──────────────────────────────────────────"
if [ -f pnpm-lock.yaml ]; then
  pnpm install --frozen-lockfile
elif [ -f package-lock.json ]; then
  npm ci
elif [ -f package.json ]; then
  pnpm install
else
  echo "nessun package.json: il progetto non e' ancora scaffoldato"
fi

echo "── database ────────────────────────────────────────────"
# PostgreSQL 16 e' preinstallato nella sandbox ma non avviato.
service postgresql start
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';" >/dev/null 2>&1
sudo -u postgres createdb app 2>/dev/null && echo "database 'app' creato" \
                                          || echo "database 'app' gia' presente"

echo "── migrazioni ──────────────────────────────────────────"
# In un monorepo drizzle.config.ts non sta nella radice ma nel pacchetto che
# possiede lo schema (packages/db). Cercarlo solo alla radice significa non
# migrare mai, dicendo pero' "niente da migrare": il peggiore dei due esiti.
DRIZZLE_DIR=""
[ -f drizzle.config.ts ] && DRIZZLE_DIR="."
for d in packages/*/ apps/*/; do
  [ -f "${d}drizzle.config.ts" ] && DRIZZLE_DIR="${d%/}" && break
done

if [ -n "$DRIZZLE_DIR" ]; then
  echo "schema Drizzle in ${DRIZZLE_DIR}"
  (cd "$DRIZZLE_DIR" && pnpm drizzle-kit migrate) \
    || echo "migrazioni fallite — il run le rivedra'"
else
  echo "nessuno schema Drizzle: niente da migrare"
fi

echo "── pronto ──────────────────────────────────────────────"
