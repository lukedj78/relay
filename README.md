# relay

Il livello di automazione sopra [dev-flow](https://github.com/lukedj78/dev-flow):
fa lavorare Claude Code senza di te, un task per volta.

Si chiama così per la cadenza che conta davvero: tu mergi un PR, lui prende il
testimone e corre la frazione successiva.

Monti questo repo una volta. Poi, per ogni progetto nuovo, sono due comandi e
una form da compilare.

## L'idea in una riga

**Tu decidi, lui esegue.** Le fasi di dev-flow che richiedono un giudizio —
l'idea, il PRD, il DESIGN.md, la scelta della libreria UI — le fai in una
sessione interattiva. Poi una routine cloud pesca dalle issue GitHub e apre un
PR.

## Quando gira

Tre cadenze, documentate in [`docs/cadences.md`](docs/cadences.md):

| | Trigger | Quando |
|---|---|---|
| **Metronomo** | `Schedule` | a orario fisso — **inizia da qui** |
| **Staffetta** | `GitHub` su merge | appena approvi un PR parte il successivo |
| **Pulsante** | `API` | quando lo chiami tu |

Si combinano sulla stessa routine. Non c'è niente che richieda la notte: il
vincolo vero è la quota, e «di notte» è solo un modo di dire *quando non la sto
usando io*.

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
è una sola per claude.ai, Desktop e Claude Code. Un run lungo può lasciarti a
secco quando ti serve.

Da cui le tre regole di dimensionamento, cablate nel prompt della routine:

- **un task per run**, non "svuota la coda"
- **poche partenze**, finché non hai misurato una settimana
- **Sonnet**, non Opus — Opus consuma significativamente di più, e qui serve
  esecuzione, non ragionamento architetturale

## Come si usa

### Una volta sola

```bash
echo 'export PATH="$HOME/projects/relay/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Poi crea il cloud environment su [claude.ai/code](https://claude.ai/code) →
selettore ambiente → **Add cloud environment**, incollando
[`environment/setup.sh`](environment/setup.sh) come setup script. Serve una
volta: lo stesso environment vale per tutti i progetti. Dettagli in
[`docs/environments.md`](docs/environments.md).

### Per ogni progetto nuovo

1. **Il giorno 0**, interattivo — vedi [`docs/day-0.md`](docs/day-0.md).
   Un'ora circa. Produce PRD, DESIGN.md e la lista dei task.
2. **Il controllo a vuoto**: `cd ~/projects/<slug> && relay-init --check`
   verifica i prerequisiti senza creare né committare niente.
3. **Il bootstrap**: `relay-init` — crea il repo GitHub privato e la config
4. **La coda**: `tasks-to-issues` — trasforma `tasks.md` in issue GitHub
5. **La routine**: su [claude.ai/code/routines](https://claude.ai/code/routines)
   incollando [`routine/prompt.md`](routine/prompt.md). `relay-init` stampa la
   configurazione esatta da usare.

Da lì in poi: un PR per volta, da mergiare o da chiudere.

## Perché la coda sta su GitHub e non su un tracker

Perché le sessioni cloud hanno **strumenti GitHub integrati e già
autenticati** — leggere issue, commentare, aprire PR — senza configurazione.

Il che significa che la routine gira con **zero connectors**. Non è solo
comodità: la documentazione avverte che un connector incluso in una routine può
usare tutti i suoi strumenti, scritture comprese, senza chiedere. Zero
connectors è zero superficie.

In più issue, PR e codice stanno nello stesso posto: un PR che dice
`Closes #12` chiude la issue quando lo mergi, e non c'è niente da tenere
allineato a mano.

## Cosa fa e cosa non fa

| Fa | Non fa |
|---|---|
| scaffolda l'app dal DESIGN.md | decide il DESIGN.md |
| genera pagine e moduli | sceglie la libreria UI |
| scrive test | decide cosa vale la pena testare |
| apre PR verificati | mergia su `main` |
| si ferma e chiede | inventa un workaround |

L'ultima riga è la più importante. Non c'è nessuno a cui un workaround sembri
sospetto, quindi il prompt glielo vieta: davanti a un ostacolo si ferma,
commenta sulla issue e chiude il run. **Un run che si ferma è un run riuscito.**

## Cosa devi fare tu

Di norma: **niente**, oltre a mergiare.

La routine legge la board da sola — scarta quello che è già preso, in review,
bloccato o marcato `needs-spec`, e fra il resto prende il primo per priorità e
ordine di dipendenza. Non c'è nessuna colonna "pronto per te" da alimentare a
mano: una lista da tenere aggiornata ogni mattina sarebbe solo una to-do list
con passi in più.

Ti restano due gesti, entrambi occasionali:

- **mergiare o chiudere** il PR che trovi
- **riscrivere** le issue marcate `needs-spec`, quando ti va

Nella cadenza a staffetta il primo gesto è anche il pedale dell'acceleratore.

## Dove si rompe

La qualità dei PR è esattamente la qualità delle issue GitHub. Una issue vaga
non produce niente di buono: produce codice sbagliato, che è peggio di nessun
codice. Il gate `needs-spec` la intercetta e passa alla successiva, ma non fa
miracoli — se la board è tutta vaga, non fa niente e te lo dice.

Il tempo speso a scrivere criteri di accettazione veri nel giorno 0 è l'unico
investimento che si ripaga a ogni run.

## I pezzi

| File | Cosa contiene |
|---|---|
| [`bin/relay-init`](bin/relay-init) | crea il repo GitHub, committa la config, verifica i prerequisiti |
| [`bin/tasks-to-issues`](bin/tasks-to-issues) | `tasks.md` → issue GitHub, con priorità e numerazione |
| [`environment/setup.sh`](environment/setup.sh) | il setup script del cloud environment |
| [`routine/prompt.md`](routine/prompt.md) | il prompt della routine — il vero artefatto |
| [`templates/claude-settings.json`](templates/claude-settings.json) | come la sandbox cloud carica le 43 skill dev-flow |
| [`docs/day-0.md`](docs/day-0.md) | la checklist della sessione interattiva |
| [`docs/cadences.md`](docs/cadences.md) | le tre cadenze e in che ordine adottarle |
| [`docs/environments.md`](docs/environments.md) | `DATABASE_URL` e i segreti fra progetti diversi |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | cosa guardare quando un run non produce niente |
