# relay

Il livello di automazione sopra [dev-flow](https://github.com/lukedj78/dev-flow):
fa lavorare Claude Code senza di te, un task per volta.

Si chiama così per la cadenza che conta: un PR viene mergiato, e il testimone
passa alla frazione successiva senza fermarsi. All'inizio quel merge lo facevi
tu — da qui il nome. Ora lo fa il revisore, e il nome è rimasto.

Monti questo repo una volta. Poi, per ogni progetto nuovo, sono due comandi e
cinque form da compilare.

## I cinque agenti

| | Cosa fa | Non fa |
|---|---|---|
| **Autore** | prende una issue, implementa, apre un PR verificato con le prove | sceglie librerie, inventa workaround |
| **Revisore** | tenta di **falsificare** ogni affermazione, e **mergia** se non ci riesce | giudica lo stile, corregge il codice, approva |
| **Correttore** | fa cadere **quella** smentita, al massimo due volte | allarga lo scope, risolve altri problemi |
| **Documentatore** | scrive la relazione, e corregge i documenti resi **falsi** | riscrive, migliora, tocca le decisioni |
| **Spazzino** | rimette in moto i PR fermi per un evento perso | giudica, mergia, corregge |

Più due meccanismi che non ragionano, e per questo non costano quota: la **CI**,
e la **rete** che annulla un merge se `main` si rompe.

**Perché cinque e non uno.** L'autore verifica sé stesso, e ha un limite
osservato: due run sullo stesso difetto, uno ha misurato lo schermo e l'altro il
database, e solo il secondo aveva ragione. Un prompt unico con cinque mandati
avrebbe regole assolute condizionali — «non pushare, a meno che…» — e una regola
assoluta con un'eccezione non è più assoluta.

Il perché per esteso sta in
[`docs/specs/2026-08-14-ciclo-chiuso-design.md`](docs/specs/2026-08-14-ciclo-chiuso-design.md).

## L'idea in una riga

**Tu decidi, lui esegue.** Le fasi di dev-flow che richiedono un giudizio —
l'idea, il PRD, il DESIGN.md, la scelta della libreria UI — le fai in una
sessione interattiva. Poi una routine cloud pesca dalle issue GitHub e apre un
PR.

## Quando gira

Il ciclo si innesca da solo: un merge fa partire il task successivo. Il punto di
partenza è una `Schedule`, che serve a metterlo in moto la prima volta e a farlo
ripartire se la coda si svuota.

Chi parte su quale evento, e cosa costa, sta in
[`docs/cadences.md`](docs/cadences.md). Non c'è niente che richieda la notte: il
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
- **un'issue costa 4–6 run** nel ciclo completo, non uno: revisione e correzioni
  si sommano al lavoro
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
5. **Le routine**: su [claude.ai/code/routines](https://claude.ai/code/routines),
   incollando i prompt di `routine/`. `relay-init` stampa la configurazione
   esatta di tutte e cinque, e i prerequisiti da girare prima.
6. **Le due Action**: copia `templates/revert-on-broken-main.yml` nel progetto.

Da lì in poi: un PR per volta, che si mergia da sé se regge alla revisione.
**Non accenderle tutte insieme** — l'ordine è in
[`docs/cadences.md`](docs/cadences.md), e non è estetico.

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

La tabella qui sotto riguarda il sistema nel suo insieme. Chi fa cosa, agente per
agente, sta in «I cinque agenti» in cima.

| Fa | Non fa |
|---|---|
| scaffolda l'app dal DESIGN.md | decide il DESIGN.md |
| genera pagine e moduli | sceglie la libreria UI |
| scrive test | decide cosa vale la pena testare |
| apre PR verificati, con le prove | decide il prodotto |
| **mergia da solo** se il revisore non trova niente | mergia se non ha potuto guardare l'anteprima |
| annulla il merge se `main` si rompe | insiste: annulla una volta sola |
| si ferma e chiede | inventa un workaround |

L'ultima riga è la più importante. Non c'è nessuno a cui un workaround sembri
sospetto, quindi il prompt glielo vieta: davanti a un ostacolo si ferma,
commenta sulla issue e chiude il run. **Un run che si ferma è un run riuscito.**

## Cosa devi fare tu

Di norma: **niente**. Nemmeno mergiare.

La routine legge la board da sola — scarta quello che è già preso, in review,
bloccato o marcato `needs-spec`, e fra il resto prende il primo per priorità e
ordine di dipendenza. Non c'è nessuna colonna "pronto per te" da alimentare a
mano: una lista da tenere aggiornata ogni mattina sarebbe solo una to-do list
con passi in più.

Ti restano due gesti, entrambi occasionali:

- **leggere `docs/relazione.md`**, che il documentatore riempie a ogni merge: è
  lì che si capisce cosa è stato costruito e cosa è rimasto scoperto
- **riscrivere** le issue marcate `needs-spec`, e guardare i PR finiti in
  `needs-human` dopo due correzioni fallite

Il merge non è più fra questi. Se ti manca, la si toglie: è un trigger da
cambiare, non un impianto da rifare.

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
| [`routine/prompt.md`](routine/prompt.md) | il prompt dell'autore — il vero artefatto |
| [`routine/review-prompt.md`](routine/review-prompt.md) | il revisore, che mergia |
| [`routine/fix-prompt.md`](routine/fix-prompt.md) | il correttore |
| [`routine/docs-prompt.md`](routine/docs-prompt.md) | il documentatore |
| [`routine/sweeper-prompt.md`](routine/sweeper-prompt.md) | lo spazzino |
| [`routine/corpus.md`](routine/corpus.md) | i casi di collaudo dei prompt, con l'atteso |
| [`routine/fixtures/`](routine/fixtures/) | il contesto che alcuni collaudi devono iniettare |
| [`templates/revert-on-broken-main.yml`](templates/revert-on-broken-main.yml) | la rete: annulla un merge che rompe `main` |
| [`bin/relay-dryrun`](bin/relay-dryrun) | lancia un prompt su un PR vero, senza creare la routine |
| [`docs/specs/`](docs/specs/) | le decisioni di design, con il perché |
| [`templates/claude-settings.json`](templates/claude-settings.json) | come la sandbox cloud carica le 43 skill dev-flow |
| [`docs/day-0.md`](docs/day-0.md) | la checklist della sessione interattiva |
| [`docs/cadences.md`](docs/cadences.md) | le tre cadenze e in che ordine adottarle |
| [`docs/environments.md`](docs/environments.md) | `DATABASE_URL` e i segreti fra progetti diversi |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | cosa guardare quando un run non produce niente |
