# Il ciclo, e cosa costa

`relay` non ha bisogno del buio. La prima versione si chiamava `night-flow` e
girava alle due di notte, ma quella era una scelta di comodo travestita da
requisito.

**Il vincolo vero non è l'ora, è la quota.** La finestra Max è una sola,
condivisa fra claude.ai, Desktop e Claude Code. Un run che parte mentre stai
lavorando compete con la tua sessione. «Di notte» è solo un modo semplice di dire
*quando non la sto usando io*.

## Il ciclo

```
      ┌─────────────────────────────────────────────────────────────┐
      │                                                             │
      ▼                                                             │
  ① AUTORE ──▶ PR aperto ──▶ ② CI (Action) ──▶ ③ REVISORE           │
      ▲                                            │                │
      │                        smentita sostanziale│                │
      │                                            ▼                │
      │                                      ④ CORRETTORE           │
      │                                            │                │
      │                                     push ──┘                │
      │                                     (torna a ③, max 2 volte)│
      │                                                             │
      │                          zero smentite + CI verde           │
      │                                            │                │
      │                                            ▼                │
      │                                        MERGE ───────────────┤
      │                                            │                │
      │                                            ├──▶ ⑤ DOCUMENTATORE
      │                                            │
      └────────────────────────────────────────────┘

  fuori dal ciclo:
  ⑥ RETE (Action)     main rotto dopo il merge → revert, una volta sola
  ⑦ SPAZZINO (orario) raccoglie i PR fermi per un evento perso
```

Nessuno di questi passaggi aspetta una persona. Quello che ti resta da fare è
in fondo a questa pagina.

## Chi parte quando

| routine | trigger | costa | cresce con |
|---|---|---|---|
| **autore** | `Schedule`, più `pull_request` closed+merged | un run pieno | i task in coda |
| **revisore** | `pull_request` opened, reopened, **synchronize** | un run pieno | i PR aperti |
| **correttore** | `pull_request` — reagisce alla review | un run pieno | le smentite |
| **documentatore** | `pull_request` closed, is merged = true | quasi zero se il PR non tocca documenti | i merge |
| **spazzino** | `Schedule` orario | quasi zero se non c'è niente di fermo | gli eventi persi |

Tutte e cinque condividono **un solo environment**, `nightly`. Si distinguono per
prompt e trigger, non per ambiente: creare un environment per routine
moltiplicherebbe i posti in cui aggiornare `DATABASE_URL`.

**Due filtri sui trigger non sono facoltativi:**

- il **revisore** e il **correttore** filtrano via i PR con la label
  `needs-human`, altrimenti un PR uscito dal ciclo ci rientra da solo
- il **documentatore** filtra via i branch che cominciano con `claude/docs-`,
  altrimenti risponde ai propri PR e il sistema entra in loop

## I due tetti, che sono diversi

**Il tetto giornaliero di run per account.** Un'issue consuma 4–6 run dal momento
in cui viene presa a quando è mergiata. Non è il costo di un task: è il costo di
un task moltiplicato per quanti giri di correzione servono.

**Il tetto orario sugli eventi webhook**, per routine e per account. Gli eventi in
eccesso **vengono scartati**, non messi in coda. Un evento scartato in un ciclo
chiuso significa un PR che resta fermo per sempre, in silenzio: il revisore non è
mai partito e non partirà.

Questa è la ragione per cui esiste **lo spazzino**, ed è anche la ragione per cui
è una routine a orario e non un trigger GitHub: le schedule non passano dai
webhook, quindi la rete non può essere zittita dallo stesso meccanismo che deve
compensare.

## Sulla parallelizzazione

Il lock che permette a più autori di girare insieme è la **creazione della ref
del branch** via API, che risponde `422` se esiste già. La label `night:wip` non
è più il lock: è un'etichetta leggibile, e basta.

Il vincolo che morde per primo non è il lock, è la quota. **Si parte da due
autori**, si misura una settimana, e si alza solo se il tetto giornaliero non è
il limite.

## In che ordine accendere

Non tutte insieme, e non a caso.

1. **L'autore da solo.** Finché non hai una settimana di run e un PR che ti
   convince.
2. **Il revisore.** È quello che restituisce di più: su dieci difetti veri di
   `predictionleagues`, sei non erano leggibili in un diff. Guarda la prima
   review prima di andare avanti.
3. **Il correttore**, non insieme al revisore. Il revisore da solo lascia i PR
   fermi dove tu li vedi — ed è il modo più sicuro di misurarlo prima di dargli
   un braccio.
4. **Il documentatore**, dopo il primo merge automatico riuscito.
5. **Lo spazzino**, per ultimo, e solo se vedi PR che si fermano.

**I due prerequisiti che precedono tutto**, e che sono interruttori umani:

- **`verify` obbligatoria su `main`** — senza, «mergia se la CI è verde» è una
  frase che nessuno fa rispettare. E **niente approvazioni obbligatorie**: le
  routine agiscono con la tua identità GitHub, e nessuno può approvare il proprio
  PR. Sarebbe un ciclo impossibile da chiudere per costruzione.
- **una chiave per le anteprime di deploy** — non disattivare la protezione: si
  genera un *Protection Bypass for Automation* su Vercel (disponibile su tutti i
  piani) e lo si mette nell'environment come `VERCEL_AUTOMATION_BYPASS_SECRET`.
  Dettagli in [`environments.md`](environments.md). Un revisore che non può
  aprire l'anteprima decide alla cieca sulla maggioranza dei difetti possibili.

## Cosa ti resta da fare

Due cose, entrambe occasionali:

- **leggere `docs/relazione.md`**, che il documentatore riempie a ogni merge
- **riscrivere le issue** finite in `needs-spec`, e guardare i PR finiti in
  `needs-human`

Il merge non è più fra queste. Se ti manca, la si toglie: è un trigger da
cambiare, non un impianto da rifare.

## Una nota sul nome dell'environment

Il cloud environment si chiama ancora `nightly`. È un nome ereditato dalla prima
versione e non ha più molto senso, ma rinominarlo significa rifarlo a mano e
ripuntarci tutte le routine — per un'etichetta. Resta `nightly`, e questa riga
esiste per non farti cercare la coerenza che non c'è.
