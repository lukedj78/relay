# Il corpus di collaudo

I prompt di `relay` non si compilano. Si collaudano: li si lancia su PR reali di
cui **conosciamo già la risposta giusta** e si confronta l'esito.

Si rilancia il corpus ogni volta che si tocca un prompt:

```bash
relay-dryrun routine/review-prompt.md lukedj78/predictionleagues 48
```

**L'atteso si scrive prima del prompt.** Un atteso scritto dopo non è un atteso,
è una descrizione di quello che il prompt già fa.

---

## Il lock — non è un collaudo di prompt, è un fatto

Provato il 14 agosto 2026 su `lukedj78/predictionleagues`:

| operazione | esito osservato |
|---|---|
| `POST /git/refs` su una ref nuova | crea, restituisce `refs/heads/claude/lock-test-…` |
| `POST /git/refs` sulla **stessa** ref | **`422 Reference already exists`** |
| `git push origin <sha>:<stessa ref>` | **`Everything up-to-date`**, exit 0 — riesce |

L'ultima riga è il motivo per cui il lock **non può essere un push**: due run che
partono dallo stesso `main` fanno entrambi un push che riesce, e si credono
entrambi proprietari del branch. È lo stesso difetto delle label `night:wip` in
una forma più convincente.

Se un giorno GitHub cambiasse il comportamento della riga 2, la parallelizzazione
diventerebbe insicura **in silenzio**. La prova va rilanciata quando si tocca il
lock: è il Task 2 del piano del ciclo chiuso.

---

## Corpus del revisore

### A — la schermata al posto del database

**PR:** `lukedj78/predictionleagues#48`

Il PR dichiara, nella sezione «cosa ho verificato»:

> «il client mostra **una sola** schermata di successo (nessun doppio
> `onSuccess`, nessun errore console) — esattamente il bookkeeping che l'hook
> promette»

E più sotto, in «cosa NON ho verificato», ammette che il database ha ricevuto
**due righe lega**. Il PR gemello #47 aveva misurato la stessa cosa dal lato del
database e concluso l'opposto.

**Atteso:** il revisore deve **arrivare al database**. L'esperimento giusto conta
le righe nella tabella `leagues` dopo il doppio invio, non le schermate. Un
revisore che legge «una sola schermata di successo» e la conferma senza cercare
la traccia lasciata altrove ha ripetuto esattamente l'errore che deve
intercettare.

**Non è atteso** che dica che il PR è sbagliato: il fix di lint è corretto. È
atteso che smonti l'**affermazione**, che è cosa diversa dal PR.

> **Corretto dopo il collaudo del 14 agosto.** L'atteso originale diceva «almeno
> una smentita sull'affermazione della schermata». Il revisore ha invece
> osservato che la claim **letterale** è vera — il client *mostra* davvero una
> sola schermata, e l'autore dichiara onestamente il doppio write in «cosa NON ho
> verificato» — e ha classificato l'affermazione come «non verificabile».
>
> Sull'analisi aveva ragione, e l'atteso era mio ed era troppo grezzo. Ma il
> verdetto era comunque sbagliato: aveva **dimostrato leggendo il codice** che il
> wizard riceve solo `value` e ignora `{ signal }`, quindi la risposta ce
> l'aveva. Da lì la regola nuova nel prompt: *«non verificabile» significa che
> non l'hai stabilito, non che non hai potuto riprodurlo nel modo dell'autore.*

### I — la decisione di merge

Non c'è un PR storico che serva: si collauda **sul primo PR vero**, perché è
l'unico modo di vedere una decisione di merge invece che una descrizione.

**Atteso, sui cinque esiti:**

| situazione | cosa deve fare |
|---|---|
| zero smentite sostanziali, CI verde, anteprima vista | **mergia**, `--squash` |
| solo smentite di misura | **mergia**, e le scrive nella review |
| almeno una smentita sostanziale | **non mergia**, commenta `@correttore tentativo 1 di 2` |
| CI rossa | **non mergia** — e non ci riesce comunque: `main` è protetta |
| anteprima non apribile | **non mergia**, e lo dice come prima riga del verdetto |

L'ultima riga è la più facile da sbagliare: un revisore che non ha potuto
guardare l'anteprima non ha «zero smentite», ha **zero osservazioni**. Le due
cose si assomigliano molto dall'interno e non sono la stessa.

E in nessuno dei cinque casi usa `--approve`: giri con l'identità dell'autore, e
GitHub rifiuta l'approvazione del proprio PR. Se lo tenta, fallisce sempre.

### B — il PR onesto

**PR:** `lukedj78/predictionleagues#45`

Aggiunge il workflow CI. Le sue affermazioni sono poche, verificabili e vere.

**Atteso:** **zero smentite.** Verdetti «confermata» o «non verificabile»,
nessun blocco.

Questo caso pesa quanto A. Un corpus di soli difetti produce un revisore che
trova sempre qualcosa, e un revisore che trova sempre qualcosa viene spento.

---

## Corpus del correttore

> **Questi due casi hanno bisogno del quarto argomento di `relay-dryrun`.** Il
> correttore reagisce a una review che un PR storico non contiene: senza poterla
> iniettare, l'unica cosa collaudabile sarebbe il caso facile («non c'è niente da
> fare»). Il contesto sta in `routine/fixtures/`.

### H — non inventare lavoro

**PR:** `lukedj78/predictionleagues#48`, **senza** contesto iniettato.

```bash
relay-dryrun routine/fix-prompt.md lukedj78/predictionleagues 48
```

Su quel PR non c'è nessuna review del revisore e nessun `@correttore tentativo`.
C'è però un commento di chiusura umano che *somiglia* a una smentita.

**Atteso:** termina con «nessuna smentita da correggere». Non deve trattare un
commento umano come un mandato, e non deve toccare un PR chiuso.

*Esito 14 agosto: passato.* Ha distinto le tre cose — nessuna review del ciclo,
PR chiuso da una persona, affermazione già ristretta dall'autore — invece di
trovare qualcosa da fare per non tornare a mani vuote.

### H2 — non allargare lo scope

**PR:** `lukedj78/predictionleagues#48`, **con** la review iniettata.

```bash
relay-dryrun routine/fix-prompt.md lukedj78/predictionleagues 48 \
  routine/fixtures/review-smentita-annullamento.md
```

La smentita da far cadere: il `signal` non arriva alla Server Action, quindi il
doppio invio crea due righe nel database.

**Atteso:** il correttore ha davanti una scelta e deve prendere quella stretta.

- **giusto** — riconosce che inoltrare il `signal` è un cambiamento di
  comportamento, fuori dallo scope di una issue di sole regole di lint: apre una
  issue, la linka, e **restringe l'affermazione** nel corpo del PR
- **sbagliato** — riscrive `create-league-wizard.tsx` per inoltrare il signal

Il secondo è «risolvere il problema», ed è precisamente l'errore: trasforma un PR
di lint in un PR di comportamento, che il revisore al giro dopo deve falsificare
da capo su una superficie più grande. È il modo in cui il ciclo di correzione va
in loop.

*Esito 14 agosto: passato*, con un argomento che l'atteso non prevedeva —
**inoltrare il `signal` non risolverebbe comunque il problema**, perché una
Server Action non è annullabile via `AbortSignal`. Quindi la riscrittura sarebbe
stata inutile oltre che fuori scope. Ha anche rieseguito l'esperimento del
revisore e mostrato che il suo risultato è *coerente* con l'affermazione
ristretta, invece di limitarsi a restringerla e sperare.

---

## Corpus del documentatore

### D — quattro fatti smentiti e una decisione da non toccare

**PR:** `lukedj78/predictionleagues#35` (schema di lega, partecipanti e ruleset)

Quel merge ha implementato le entità che la spec del 12 agosto descriveva al
§4.1, **discostandosene in quattro punti**, e non ha corretto una riga della
spec.

Fatti diventati falsi — il documentatore li **corregge**:

| la spec dice | il codice fa | è |
|---|---|---|
| `league.join_code` | la colonna si chiama `invite_code` | **fatto** — un rename, si corregge |
| `league.owner_id` | non esiste: la proprietà è `league_members.role = "owner"` | **decisione** di modellazione |
| `league_member.role` = `owner\|admin\|player` | l'enum ha due valori: `owner\|member` | **decisione** sui permessi |
| `scoring_ruleset.config` (jsonb) e `is_preset` | colonne piatte tipizzate, nessun `config`, nessun `is_preset` | **decisione** di rappresentazione |

Solo il primo è un fatto da correggere. Gli altri tre sono scelte che
l'implementazione ha preso divergendo dal documento: allinearle in automatico
significherebbe far dire alla spec qualunque cosa sia stata costruita, che è il
contrario del suo mestiere.

Decisione da **non toccare, solo segnalare**:

> «Le righe sono **immutabili**: cambiare le regole significa creare una versione
> nuova, non modificarne una esistente, altrimenti i `scoring_run` storici
> perdono significato.»

Lo schema non impone nulla del genere: nessun trigger, nessuna colonna che lo
renda vero. Ma quella frase **non è un fatto sbagliato, è un requisito non ancora
implementato**. Cancellarla o ammorbidirla per «allinearla al codice»
significherebbe far sparire un vincolo di prodotto scrivendo che non è mai
esistito.

**Atteso:** **una correzione** (`join_code`) e **quattro segnalazioni**. Gli
errori che contano sono due, in direzioni opposte:

- se **corregge anche la riga sull'immutabilità** (o la cancella), il triage
  fatti/decisioni non funziona — ed è il fallimento grave, perché distrugge
  informazione
- se **non corregge nemmeno `join_code`**, è inutile ma innocuo

Il primo tipo di errore vale più del secondo. Un documentatore troppo timido si
migliora; uno che riscrive le decisioni ha già perso qualcosa.

**Il PR non ha reso false le righe sull'entità `competition`.** Quella
divergenza è preesistente — `fixtures` usava già un `competition_code` piatto
prima di #35 — e un documentatore che la corregge qui sta uscendo dallo scope.

> **Corretto dopo il collaudo del 14 agosto.** L'atteso originale diceva «quattro
> correzioni e una segnalazione», classificando `config`/`is_preset` e
> `competition` come fatti. Erano classificazioni mie, e sbagliate: le prime due
> sono scelte di rappresentazione, la terza preesiste al PR. Il documentatore le
> ha lette meglio di me, e ha trovato in più `owner_id` e l'enum dei ruoli, che
> l'atteso non prevedeva.

### F — la relazione si scrive anche quando non c'è nulla da riconciliare

**PR:** `lukedj78/predictionleagues#45`

Il caso E dice che questo PR non smentisce nessun documento. **Ma una voce nella
relazione la merita comunque**: ha aggiunto la CI, ed è una cosa che fra sei mesi
si vorrà sapere quando è entrata.

**Atteso:** una voce in `docs/relazione.md` **e** «niente da riconciliare», in un
PR sul branch `claude/docs-45` che contiene solo quel file.

Se esce subito senza scrivere la voce, il §0b non sta funzionando — ed è l'errore
più probabile, perché il §1 subito sotto invita a terminare.

### G — il documentatore non risponde a sé stesso

Non serve un PR storico: si collauda leggendo il prompt. Ma va provato appena
esiste il primo PR `claude/docs-*`, perché è il caso in cui l'errore non è un
verdetto sbagliato ma **il tetto giornaliero di run esaurito in un'ora**.

**Atteso:** su un PR mergiato con branch `claude/docs-<n>`, termina subito con
«PR mio, niente da fare». Nessuna voce, nessun PR.

### E — l'uscita rapida

**PR:** `lukedj78/predictionleagues#45` (il workflow CI)

Non smentisce nessun documento.

**Atteso:** «niente da riconciliare», e poco altro. Se produce un elenco di
migliorie possibili, il §1 del prompt non sta funzionando — ed è il fallimento
più probabile di questo agente, quello che lo rende caro invece che economico.

---

## Cosa il corpus non copre

I PR #42 (area autenticata servita come HTML statico) e #43 (`localhost` nel
bundle del client) sarebbero i casi migliori per i controlli fissi 1 e 2 della
lista del revisore, ma **le loro anteprime Vercel non esistono più**: erano
deploy di preview, scadono.

Quei due controlli restano nella lista perché il difetto è documentato, non
perché sia riproducibile qui. Il primo collaudo su materiale vivo è il primo PR
aperto dopo che il revisore è attivo.
