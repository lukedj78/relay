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
