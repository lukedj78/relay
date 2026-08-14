# Il ciclo chiuso — design

**Data:** 2026-08-14
**Stato:** approvato in brainstorming, da tradurre in piano
**Sostituisce:** [`2026-08-13-revisore-e-documentatore-design.md`](2026-08-13-revisore-e-documentatore-design.md), che descriveva un revisore senza autorità di merge — cioè un sistema che lasciava l'attesa umana esattamente dov'era

---

## 1. L'obiettivo

Oggi `relay` produce un PR e si ferma. Il ciclo si chiude solo quando una persona
lo mergia, e finché non lo fa non parte niente altro.

L'obiettivo è togliere quel passaggio: **una issue entra, del codice verificato
esce, e il task successivo parte da solo.** Con abbastanza tracce lasciate dietro
da poter capire, a mesi di distanza, cosa è successo e perché.

Non è un obiettivo di velocità. È che il collo di bottiglia oggi non è la
capacità di scrivere codice: è il tempo che passa fra quando un PR è pronto e
quando qualcuno lo guarda.

## 2. Il ciclo

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

  in parallelo, fuori dal ciclo:
  ⑥ RETE (Action)     main rotto dopo il merge → revert, una volta sola
  ⑦ SPAZZINO (orario) raccoglie i PR fermi per un evento perso
```

Cinque agenti che ragionano, due meccanismi che non ragionano.

## 3. Il principio che tiene giù il costo

Ogni routine è un run pieno, e la quota è la stessa delle sessioni interattive.
Un ciclo chiuso con cinque agenti per PR sarebbe insostenibile se tutti e cinque
fossero routine.

> **Ciò che non richiede giudizio non deve costare quota.**

| compito | dove vive | perché |
|---|---|---|
| lint, typecheck, test | GitHub Action | deterministico |
| lock sull'issue | chiamata API nell'autore | atomico, nessun giudizio |
| revert di un merge rotto | GitHub Action | deterministico, e non c'è comunque un trigger routine per farlo |
| collegare gli screenshot | commit dell'autore | meccanico |
| decidere se un'affermazione è falsa | routine | giudizio |
| decidere come correggere | routine | giudizio |
| distinguere un fatto da una decisione | routine | giudizio |

## 4. Il lock: come si prende una issue

Il lock attuale è la label `night:wip`, ed **è rotto**. Il 13 agosto due run hanno
preso la stessa issue e prodotto i PR #47 e #48. Il motivo è strutturale: leggere
le label e poi scriverne una sono due operazioni, e fra l'una e l'altra un altro
run fa lo stesso. Nessuna quantità di prompt lo aggiusta.

Il lock nuovo è **la creazione della ref del branch**, via API:

```bash
gh api repos/:owner/:repo/git/refs -X POST \
  -f ref="refs/heads/claude/<issue>-<slug>" \
  -f sha="<sha di main>"
```

Se la ref esiste già, GitHub risponde **`422 Reference already exists`**. È
un'operazione sola, decisa dal server: due run non possono vincerla entrambi.
Chi perde passa alla issue successiva.

> **Attenzione a un errore facile, che ho fatto io.** `git push origin
> HEAD:refs/heads/x` **non** serve come lock: se il branch esiste e il push è
> fast-forward, riesce. Deve essere la creazione della ref via API, che è l'unica
> forma che fallisce sulla collisione.

La label `night:wip` resta, ma cambia natura: non è più il lock, è solo
un'etichetta leggibile da una persona. Non deve mai essere l'unica cosa che
impedisce una collisione.

**Questo è il prerequisito della parallelizzazione**, e adesso è risolto: N
autori in parallelo, nessun coordinamento, nessuna possibilità che due prendano
lo stesso lavoro.

## 5. L'autorità di merge

Il revisore mergia quando **entrambe** sono vere:

- la CI è verde
- non ha emesso nessuna **smentita sostanziale**

I due gradi di smentita vengono dal collaudo del 14 agosto, dove il revisore
bloccò un PR perché l'autore aveva scritto «62 test» e ne giravano 58:

| grado | significato | effetto |
|---|---|---|
| **sostanziale** | se l'affermazione cade, cade il PR | blocca, apre la correzione |
| **di misura** | la conclusione regge, un numero è sbagliato | si scrive, non blocca |

Un revisore che blocca un merge per aritmetica viene spento entro due settimane.

### I due prerequisiti, che sono interruttori umani

**1. `verify` deve diventare un check obbligatorio su `main`.** Oggi è
consultiva: il PR #45 è stato mergiato con `verify` rosso. Finché è così, «mergia
se la CI è verde» è una frase che nessuno fa rispettare.

Renderla obbligatoria ha un effetto che vale più della regola: **GitHub stesso
rifiuta il merge** con la CI rossa. Il gate smette di dipendere dalla disciplina
di un prompt e diventa una proprietà del repository.

**2. Le anteprime Vercel devono essere apribili.** Sono dietro Deployment
Protection e rispondono `302` verso `vercel.com/sso-api` (verificato sul PR #50).
Un revisore che mergia senza poter aprire l'anteprima decide alla cieca su sei
difetti veri su dieci — quelli che un diff non mostra.

Finché questi due non sono girati, il ciclo si costruisce ma non si accende.

## 6. Il ciclo di correzione

Smentita sostanziale → parte il **correttore**: una sessione nuova sullo stesso
branch, con la review in pasto e un mandato stretto — *fai cadere questa
smentita, non altro*.

Quando pusha, il revisore riparte sul trigger `synchronize`.

> Nella spec precedente avevo escluso `synchronize` perché avrebbe fatto partire
> una review a ogni push. In un ciclo chiuso **l'unico che pusha su un PR aperto
> è il correttore**: l'autore apre il PR e non lo tocca più. Quindi `synchronize`
> significa esattamente «una correzione è pronta, rivedila». Diventa il trigger
> giusto invece che uno spreco.

**Due tentativi.** Poi il PR resta aperto con la label `needs-human` e un
commento che riporta le due smentite e cosa è stato provato.

Un tentativo solo sprecherebbe il caso più frequente — il secondo correttore vede
*perché* il primo ha fallito e chiude. Tre costerebbero fino a cinque run per un
PR solo.

**La coda non si ferma.** Un PR in `needs-human` non blocca niente: gli autori
prendono le issue successive. È la stessa regola che già vale per `blocked`, e
serve perché altrimenti un solo falso positivo congela il sistema fino a quando
qualcuno guarda.

Il ciclo si interrompe anche in un altro modo: il trigger del revisore filtra via
i PR con la label `needs-human`, così un push tardivo non lo riaccende.

## 7. Le prove e la relazione

### Gli screenshot: la convenzione esisteva già

Il prompt dell'autore richiede uno screenshot nel PR dal primo giorno, e per un
po' non ha funzionato — allegarli via API dalla sandbox non riesce:

> «Screenshot full-page a 375px catturati per tutte e tre le rotte durante la
> sessione (non allegabili qui perché generati in locale nella sandbox, non
> caricabili via API)» — PR #32

**Ma la routine ha poi trovato la strada da sola**, e senza che nessuno gliela
dicesse: committare le immagini nel repository e linkarle con l'URL raw. Su
`main` c'è già `docs/pr-assets/` con le prove dei PR #17, #41 e #49, e il PR #60
la usa ancora.

> **Una correzione a me stesso.** Avevo scritto «su otto PR controllati nessuno
> contiene uno screenshot» e ci avevo costruito sopra una convenzione nuova,
> `docs/evidence/`. Era vero di quel campione — che non conteneva i PR giusti — e
> falso come generalizzazione. La convenzione da scrivere nel prompt non è una
> nuova: è **quella che il sistema aveva già trovato**, resa esplicita perché
> smetta di dipendere dal fatto che ogni run la reinventi.

La forma, quindi, è quella già in uso:

```
docs/pr-assets/<issue>/<nome>.png
```

e linkarle nel corpo del PR. Sono versionate, sopravvivono al PR, e non
dipendono da un'API di upload che la sandbox non ha.

### La relazione

A ogni merge il documentatore fa **due** cose:

1. **riconcilia** i documenti che il merge ha reso falsi — con le due regole
   strette e il triage fatti/decisioni già collaudati il 14 agosto
2. **appende una voce** a `docs/relazione.md`: numero di PR e issue, cosa è stato
   fatto, cosa è stato verificato e **come**, cosa **non** è stato verificato, le
   decisioni prese, i verdetti del revisore, i link alle prove del punto
   precedente

> **Correggo un argomento che avevo fatto e che era sbagliato.** Nella spec
> precedente ho scritto una sezione intitolata «Perché non un diario di bordo»,
> sostenendo che duplicare i corpi dei PR crea due racconti che divergono.
>
> È vero **se lo riscrive**. Qui non riscrive: **trascrive** sezioni che il PR ha
> già e ci aggiunge link permanenti. È un indice, non un doppione. E serve
> esattamente per la cosa che l'argomento originale ignorava: a dicembre, davanti
> a ottanta PR, nessuno risale a ritroso.

## 8. La parallelizzazione

Con il lock del §4 risolto, N autori girano in parallelo senza coordinarsi.

**N non è una costante da scegliere adesso.** Il vincolo che morde per primo non
è il lock ma la quota: c'è un tetto giornaliero di run per account, e ogni issue
ne consuma 4–6 nel ciclo completo. Si parte da **due** autori, si misura una
settimana, e si alza solo se il tetto non è il limite.

## 9. I vincoli della piattaforma, verificati

Letti sulla documentazione ufficiale il 14 agosto, non dedotti:

| vincolo | conseguenza sul progetto |
|---|---|
| I trigger GitHub coprono **solo** `Pull request` e `Release` | il revert non può essere una routine → è una Action |
| `pull_request.synchronize` **esiste** | il ciclo correttore → revisore funziona |
| I filtri includono `Labels`, `Is merged`, `Head branch`, `Author` | si filtra via `needs-human`, e si distingue merge da chiusura |
| I branch `claude/` sono **sempre accettati** in push | il correttore può pushare sul branch dell'autore |
| Un push su branch **protetto** viene rifiutato | proteggere `main` non rompe il ciclo: il merge non è un push |
| Gli eventi webhook hanno **tetti orari**, e quelli in eccesso **vengono scartati** | serve lo spazzino, §10 |
| C'è un **tetto giornaliero di run** per account | la parallelizzazione parte da due, non da otto |
| Tutto ciò che fa una routine appare come **te** su GitHub | i commit e i merge portano il tuo nome: la relazione è l'unico modo di sapere chi ha fatto cosa |

## 10. Le due reti

Un ciclo chiuso senza reti non è autonomo: è solo senza sorveglianza.

### La rete sul merge — una GitHub Action

Se dopo il merge la CI su `main` fallisce, o il deploy di produzione fallisce, una
Action fa `git revert` del commit di merge. È un commit nuovo: non riscrive la
storia, ed è a sua volta reversibile.

**Una volta sola.** Mai un revert di un revert. L'Action apre una issue con quello
che è successo e si ferma.

### Lo spazzino — una routine a orario

Gli eventi webhook in eccesso vengono scartati. In un ciclo chiuso questo
significa che un PR può restare fermo per sempre senza che nessuno se ne accorga:
il revisore non è mai partito, e non partirà.

Una routine oraria raccoglie i PR in limbo — aperti, senza review, senza
`needs-human`, fermi da più di un'ora — e li riapre, il che rigenera l'evento.

Le routine a orario **non** passano dai webhook, quindi questa rete non può
essere scartata dallo stesso meccanismo che deve compensare.

## 11. Cosa si salva di quello che c'è già

Non si butta niente di sostanziale:

| pezzo | stato |
|---|---|
| il mandato di falsificazione | invariato — è la parte «controlla nel dettaglio» |
| la lista fissa dei sei controlli | invariata |
| i due gradi di smentita | invariati, ed è ciò che rende sicuro il merge automatico |
| il triage derivabile/da chiedere | invariato |
| la riconciliazione dei documenti | invariata, con l'aggiunta della relazione |
| `routine/corpus.md` | si estende: nuovi casi per il correttore e per il merge |
| `bin/relay-dryrun` | invariato |

Cambia l'esito del revisore (mergia), nasce il correttore, e i documenti di
`relay` — `README.md`, `docs/cadences.md`, `bin/relay-init` — vanno riscritti,
perché descrivono un sistema con una persona in mezzo.

## 12. Rischi

| rischio | mitigazione |
|---|---|
| il revisore mergia qualcosa di rotto | CI obbligatoria (GitHub rifiuta il merge), anteprima apribile, rete di revert |
| un falso positivo blocca un PR buono | i due gradi di smentita; la coda prosegue comunque; dopo due tentativi arriva a te |
| il ciclo di correzione va in loop | massimo due tentativi, poi `needs-human`; il trigger filtra via quella label |
| un evento webhook scartato lascia un PR fermo | lo spazzino orario, che non passa dai webhook |
| la quota si esaurisce a metà giornata | si parte da due autori; ogni ciclo è misurato prima di alzare |
| il revert automatico fa danno | `git revert` non riscrive la storia; una volta sola; mai su un revert |
| tutto appare come commit tuoi | la relazione è il registro di chi ha deciso cosa |

## 13. Come si misura se funziona

Dopo due settimane:

- **quanti PR sono arrivati al merge senza di te**, e di quelli quanti hanno
  richiesto un revert
- **quante correzioni automatiche hanno chiuso** al primo o al secondo tentativo
- **quanti PR sono finiti in `needs-human`**, e quante volte avevano ragione
- **quante volte è intervenuto lo spazzino** — se è spesso, i tetti webhook sono
  il vincolo vero e la parallelizzazione va abbassata, non alzata

Se il numero di revert è maggiore di zero più di una volta, il merge automatico
va tolto e si torna a te. Scriverlo adesso, con la soglia, è ciò che impedisce di
difenderlo per affezione.
