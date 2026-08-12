# night-flow

Il livello di automazione sopra [dev-flow](https://github.com/lukedj78/dev-flow):
fa lavorare Claude Code di notte, da solo, su un progetto per volta.

Monti questo repo una volta. Poi, per ogni progetto nuovo, sono due comandi e
una form da compilare.

## L'idea in una riga

**Il giorno decidi, la notte esegue.** Le fasi di dev-flow che richiedono un
giudizio — l'idea, il PRD, il DESIGN.md, la scelta della libreria UI — le fai tu
in una sessione interattiva. Poi una routine cloud pesca dalla board Linear e
apre un PR a notte.

## Perché una routine cloud e non un cron sul Mac

Le [routines](https://code.claude.com/docs/en/routines) girano su infrastruttura
Anthropic e, dice la documentazione, **non hanno permission-mode né prompt di
approvazione durante un run**. Il problema delle autorizzazioni non si configura:
non esiste. In cambio accetti tre vincoli — il repo dev'essere su GitHub,
l'ambiente è una sandbox, e c'è un tetto giornaliero di run per account.

Il Mac può stare spento.

## Cosa costa

Zero euro di compute: *"there is no separate compute charge for the cloud VM"*.
Ma un run consuma la **stessa quota** delle sessioni interattive, e la quota Max
è una sola per claude.ai, Desktop e Claude Code. Un run notturno lungo può
lasciarti a secco alle nove del mattino.

Da cui le tre regole di dimensionamento, che sono cablate nel prompt della
routine e non vanno allentate a cuor leggero:

- **un run per notte**, non tre a catena
- **un task per run**, non "svuota la coda"
- **Sonnet**, non Opus — Opus consuma significativamente di più, e di notte
  serve esecuzione, non ragionamento architetturale

## Come si usa

### Una volta sola

```bash
ln -s ~/projects/night-flow/bin/nightly-init ~/bin/nightly-init
```

Poi crea il cloud environment `nightly` su
[claude.ai/code](https://claude.ai/code) → Environments → New, incollando
[`environment/setup.sh`](environment/setup.sh) come setup script. Serve una
volta: lo stesso environment vale per tutti i progetti.

### Per ogni progetto nuovo

1. **Il giorno 0**, interattivo — vedi [`docs/day-0.md`](docs/day-0.md).
   Un'ora circa. Produce PRD, DESIGN.md e una board Linear piena.
2. **Il bootstrap**: `cd ~/projects/<slug> && nightly-init`
3. **Verifica prima**: `nightly-init --check` controlla i prerequisiti senza toccare niente.
4. **La routine**: crea una routine su
   [claude.ai/code/routines](https://claude.ai/code/routines) incollando
   [`routine/prompt.md`](routine/prompt.md). `nightly-init` stampa la
   configurazione esatta da usare.

Da lì in poi: ogni mattina trovi un PR da mergiare o da chiudere.

## Cosa fa e cosa non fa la notte

| Fa | Non fa |
|---|---|
| scaffolda l'app dal DESIGN.md | decide il DESIGN.md |
| genera pagine e moduli | sceglie la libreria UI |
| scrive test | decide cosa vale la pena testare |
| apre PR verificati | mergia su `main` |
| si ferma e chiede | inventa un workaround |

L'ultima riga è la più importante. Di notte non c'è nessuno a cui un workaround
sembri sospetto, quindi il prompt della routine gli vieta di produrne: davanti a
un ostacolo si ferma, commenta su Linear e chiude il run. **Un run che si ferma
è un run riuscito.**

## Dove si rompe

La qualità dei PR notturni è esattamente la qualità della colonna `Ready` in
Linear. Un issue vago non produce niente di buono: produce codice sbagliato, che
è peggio di nessun codice. Il passo 5 del prompt (il gate `needs-spec`) esiste
per intercettarlo, ma non fa miracoli.

Il tempo speso a scrivere criteri di accettazione veri nel giorno 0 è l'unico
investimento che si ripaga ogni notte.

## I pezzi

| File | Cosa contiene |
|---|---|
| [`bin/nightly-init`](bin/nightly-init) | crea il repo GitHub, committa la config, verifica i prerequisiti |
| [`environment/setup.sh`](environment/setup.sh) | il setup script del cloud environment |
| [`routine/prompt.md`](routine/prompt.md) | il prompt della routine — il vero artefatto |
| [`templates/claude-settings.json`](templates/claude-settings.json) | come la sandbox cloud carica le 43 skill dev-flow |
| [`docs/day-0.md`](docs/day-0.md) | la checklist della sessione interattiva |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | cosa guardare quando un run non produce niente |
