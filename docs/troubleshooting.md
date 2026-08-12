# Quando la notte non produce niente

## Prima cosa da sapere

Nella lista dei run, **verde non vuol dire riuscito**. La documentazione e'
esplicita: lo stato verde significa che la sessione e' partita ed e' uscita
senza errori di infrastruttura. Non dice nulla sul compito.

Richieste di rete bloccate, connector mancanti e fallimenti del task compaiono
solo dentro il transcript. Aprilo.

Per questo il prompt della routine obbliga a **commentare sulla issue anche in
caso di fallimento**: un run silenzioso e un run riuscito, da fuori, sono
indistinguibili.

## I sintomi

### "Niente di aggredibile stanotte"

Il run e' durato pochi secondi e non ha aperto nessun PR. La riga di spiegazione
dice quale dei tre casi e':

- **coda vuota** — non ci sono issue aperte. Lancia `tasks-to-issues`.
- **tutto bloccato** — ogni issue rimasta dipende da qualcosa di aperto. Guarda
  le righe `Blocked by #N` e la numerazione dei titoli: spesso il colpevole e'
  una issue con `night:in-review` perche' non hai ancora mergiato il suo PR.
- **tutto gia' in review** — hai PR in attesa. Mergiali o chiudili.

### Tre issue marcate `needs-spec` e nessun PR

Il gate ha funzionato tre volte di fila e il run si e' fermato, come previsto. I
commenti sulle tre issue dicono cosa mancava: di solito criteri di accettazione
assenti, o una decisione che spettava a te.

Non e' un guasto. E' la board che ti sta dicendo che non e' scritta abbastanza
bene per lavorarci da sola.

### Una issue e' rimasta con la label `night:wip`

Il run e' morto dopo aver preso il lock e prima di rilasciarlo — di solito per
un errore di infrastruttura, non per un errore suo. La notte dopo quella issue
verra' saltata, perche' `night:wip` e' fra le label escluse.

Togli la label a mano:

```bash
gh issue edit <numero> --remove-label night:wip
```

Se succede spesso, e' il segnale che i run muoiono presto: guarda il transcript.

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

### Due run hanno preso la stessa issue

Non dovrebbe succedere: la label `night:wip` e' il lock. Se e' successo, guarda
se il primo run e' morto **prima** di applicarla — fra la lettura della coda e
la scrittura della label c'e' la finestra in cui il sistema e' scoperto. E'
stretta, ma con un solo run per notte non dovrebbe mai aprirsi.

### `gh: command not found` dentro il run

Non dovrebbe capitare: la documentazione dice che le sessioni cloud hanno
strumenti GitHub integrati, autenticati tramite il proxy, senza configurazione.
Se invece succede, il ripiego e' impostare `GH_TOKEN` nelle variabili
dell'environment — ma prima verifica nel transcript che sia davvero questo il
problema, e non un `gh` che fallisce per un motivo diverso.

## Dove guardare, in ordine

1. Il commento sulla issue — se il prompt ha funzionato, c'e' scritto tutto li'
2. Il transcript del run su [claude.ai/code/routines](https://claude.ai/code/routines)
3. `git log origin/main` e i branch `claude/*` — a volte il lavoro c'e' ma il PR no
