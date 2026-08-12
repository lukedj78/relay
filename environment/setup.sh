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
if [ -f drizzle.config.ts ]; then
  pnpm drizzle-kit migrate || echo "migrazioni fallite — il run le rivedra'"
else
  echo "nessuno schema Drizzle: niente da migrare"
fi

echo "── pronto ──────────────────────────────────────────────"
