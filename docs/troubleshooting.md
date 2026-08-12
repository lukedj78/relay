# Quando la notte non produce niente

## Prima cosa da sapere

Nella lista dei run, **verde non vuol dire riuscito**. La documentazione e'
esplicita: lo stato verde significa che la sessione e' partita ed e' uscita
senza errori di infrastruttura. Non dice nulla sul compito.

Richieste di rete bloccate, connector mancanti e fallimenti del task compaiono
solo dentro il transcript. Aprilo.

Per questo il prompt della routine obbliga a **commentare su Linear anche in
caso di fallimento**: un run silenzioso e un run riuscito, da fuori, sono
indistinguibili.

## I sintomi

### Nessun PR, ma il run e' durato pochi secondi

La coda era vuota. Nessun issue in `Ready`. Comportamento corretto: sposta
qualcosa in `Ready` dalla UI Linear.

### L'issue e' tornato in `Ready` con label `needs-spec`

Il gate ha funzionato. Il commento dell'issue dice cosa mancava. Di solito:
criteri di accettazione assenti, oppure una decisione che spettava a te.
Riscrivi l'issue e rimettilo in coda.

### Il run non trova le skill dev-flow

`.claude/settings.json` non e' committato, o non e' sul branch di default. La
sandbox clona il **default branch**: se la config e' su un altro branch, non la
vede.

```bash
git show origin/main:.claude/settings.json
```

### `pnpm: command not found`, o il setup script fallisce a meta'

Il setup script gira **prima** che Claude inizi. Se fallisce, il run parte
comunque su un ambiente monco. Aprilo dal transcript e cerca la prima riga
rossa.

Nota: `bun` e' installato ma ha problemi noti col proxy per il fetch dei
pacchetti. Usa pnpm o npm.

### Il dev server non si avvia / la verifica nel browser non parte

I browser Playwright non sono preinstallati. La sandbox ha `chromedriver` con
Node. Due opzioni:

- usare `chromedriver`, che c'e' gia'
- installare Playwright nel setup script e aggiungere il suo CDN in
  **Allowed domains** dell'environment (la allowlist Trusted di default non lo
  contiene)

### Il run ha superato il tetto giornaliero

C'e' un cap di run per account, separato dalla quota. Lo vedi su
[claude.ai/code/routines](https://claude.ai/code/routines). Oltre il cap i run
vengono rifiutati, a meno di attivare gli usage credits — che sono euro veri.

### Al mattino sei senza quota

Il run notturno ha mangiato la finestra. Controlla:

- il modello e' **Sonnet**? Opus consuma significativamente di piu'
- gli **agent teams** sono spenti? Consumano circa 7 volte tanto
- c'e' **un solo run** schedulato, o ne hai aggiunti altri?

Attenzione a un effetto poco ovvio: la cache dei prompt dura un'ora
sull'abbonamento, ma **scende a cinque minuti appena entri negli usage credits**.
Sforare rende il resto del run improvvisamente molto piu' caro in token, non
solo in euro.

### Due run hanno preso lo stesso issue

Non dovrebbe succedere: lo stato `In Progress` e' il lock. Se e' successo,
guarda se il primo run e' morto prima di spostare l'issue — in quel caso il lock
non era ancora stato preso, ed e' il momento in cui il sistema e' scoperto.

## Dove guardare, in ordine

1. Il commento su Linear — se il prompt ha funzionato, c'e' scritto tutto li'
2. Il transcript del run su [claude.ai/code/routines](https://claude.ai/code/routines)
3. `git log origin/main` e i branch `claude/*` — a volte il lavoro c'e' ma il PR no
