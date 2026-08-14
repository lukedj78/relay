# Revisore e documentatore — piano di implementazione

> **Per chi esegue:** usa `superpowers:subagent-driven-development` (se hai i subagent) oppure `superpowers:executing-plans`. I passi hanno le caselle (`- [ ]`) per essere spuntati.

**Goal:** dare a `relay` due agenti oltre all'autore — un revisore che tenta di falsificare le affermazioni di ogni PR, e un documentatore che riconcilia i documenti quando il codice li smentisce.

**Architettura:** tre prompt, tre routine cloud, **un solo environment**. Nessun servizio nuovo, nessun codice applicativo: gli artefatti sono file Markdown (i prompt), uno script shell di collaudo, e le modifiche a `bin/relay-init` e ai documenti. Il revisore scrive review GitHub e non mergia mai; il documentatore apre PR di sole modifiche ai documenti.

**Stack:** Markdown, bash, `gh` CLI, Claude Code in modalità headless (`claude -p`) per il collaudo, routines cloud di claude.ai/code.

**Spec:** [`docs/specs/2026-08-13-revisore-e-documentatore-design.md`](../specs/2026-08-13-revisore-e-documentatore-design.md)

---

## Stato dell'esecuzione — 14 agosto 2026

| task | stato |
|---|---|
| 1 — triage nel prompt dell'autore | **fatto** (`edcbb03`) |
| 2 — corpus | **fatto** (`9450a1e`), poi corretto dai collaudi (`c76d64b`) |
| 3 — `relay-dryrun` | **fatto** (`9450a1e`) |
| 4 — prompt del revisore + casi A e B | **fatto**, con due correzioni imposte dal collaudo |
| 5 — creare la routine del revisore | **da fare a mano nella UI** |
| 6 — primo run osservato | dopo il 5 |
| 7 — prompt del documentatore + casi D ed E | **fatto**, entrambi i casi passati |
| 8 — creare la routine del documentatore | **da fare a mano nella UI** |
| 9 — `docs/cadences.md` | **fatto** (`acb93c9`) |
| 10 — `relay-init` con tre routine | **fatto** (`acb93c9`) |
| 11 — README | **fatto** (`acb93c9`) |

**Blocco trovato dai collaudi, che precede i task 5 e 6:** le anteprime Vercel
di `predictionleagues` sono protette da Deployment Protection e rispondono `302`
verso `vercel.com/sso-api`. Il revisore non può aprirle, e tre dei sei controlli
fissi tornano `non verificabile` per questo solo motivo. Accendere la routine
prima di aver tolto la protezione significa pagare un run pieno per una review
quasi vuota.

---

## Come si verifica un prompt

`relay` non ha una suite di test e non deve averne una: i suoi artefatti sono prompt, e un prompt non si compila. Ma **si può collaudare**, e la disciplina test-first si applica letteralmente:

> Prima si scrive **il verdetto atteso** su un PR di cui conosciamo già la risposta. Poi si scrive il prompt. Poi si lancia il prompt su quel PR e si confronta.

Il corpus è fatto di PR reali di `predictionleagues`, scelti perché sappiamo cosa avrebbero dovuto produrre:

| caso | PR | perché è nel corpus | atteso |
|---|---|---|---|
| **A — la schermata al posto del database** | [#48](https://github.com/lukedj78/predictionleagues/pull/48) | dichiara *«il client mostra una sola schermata di successo… esattamente il bookkeeping che l'hook promette»*, e più sotto ammette due righe lega nel DB | **almeno una smentita**, sull'affermazione che misura lo schermo |
| **B — il PR onesto** | [#45](https://github.com/lukedj78/predictionleagues/pull/45) | aggiunge il workflow CI; le sue affermazioni sono verificabili e vere | **zero smentite**. Questo caso misura i falsi positivi |

**Il caso B conta quanto il caso A.** Un corpus di soli difetti addestra un revisore che trova sempre qualcosa, che è il modo più rapido per rendere il sistema ignorabile.

**Cosa il corpus non può coprire, dichiarato:** i PR #42 (area autenticata prerenderizzata) e #43 (`localhost` nel bundle) sarebbero i casi migliori per i controlli fissi 1 e 2, ma le loro anteprime Vercel non esistono più. Restano nella lista fissa perché il difetto è documentato, non perché sia riproducibile. Il primo collaudo dei due controlli su materiale vivo è il Task 8.

---

## Struttura dei file

| file | responsabilità | stato |
|---|---|---|
| `routine/prompt.md` | l'autore — invariato salvo l'aggiunta del triage | modificato |
| `routine/review-prompt.md` | il revisore: mandato di falsificazione, tre verdetti, lista fissa | **nuovo** |
| `routine/docs-prompt.md` | il documentatore: due regole strette, triage fatti/decisioni | **nuovo** |
| `routine/corpus.md` | i casi di collaudo con il verdetto atteso | **nuovo** |
| `bin/relay-dryrun` | lancia un prompt su un PR in headless, per collaudare senza creare la routine | **nuovo** |
| `bin/relay-init` | stampa la configurazione di **tre** routine invece di una | modificato |
| `docs/cadences.md` | tre routine con costi diversi, non una | modificato |
| `README.md` | la tabella dei pezzi e la sezione «cosa fa / non fa» | modificato |

Un prompt per agente, un file. Non si fondono in un prompt unico con sezioni condizionali: tre routine cloud incollano tre testi diversi, e un file che serve tre destinazioni diventa illeggibile per tutte e tre.

---

## Chunk 1: Il triage

La regola che vale per tutti e tre gli agenti. Va scritta prima, perché i due prompt nuovi la citano.

### Task 1: Aggiungere il triage al prompt dell'autore

**Files:**
- Modify: `routine/prompt.md` (nuova sezione fra «Il gate di qualità» e «Il lavoro»)

- [ ] **Step 1: Scrivere l'atteso**

Prima di toccare il file, scrivi in un commento di lavoro (non nel repo) le due frasi che il prompt modificato deve rendere possibili:

1. Un run che trova `DESIGN.md` in contraddizione con sé stesso (88px di riga, 44+8+44 di contenuto) **calcola, sceglie e dichiara**, invece di marcare `needs-spec`.
2. Un run che deve scegliere *quale* dei tre numeri sacrificare **si ferma**.

Se la sezione che scrivi non separa questi due casi, è scritta male.

- [ ] **Step 2: Inserire la sezione**

In `routine/prompt.md`, subito dopo il paragrafo che chiude il passo 6 (*«Una issue scritta male non deve costarti la notte…»*), inserire:

````markdown
## Il triage: cosa decidi tu, cosa non decidi

Il gate del passo 6 ferma le issue scritte male. Questo triage governa invece
tutto quello che **scopri mentre lavori** — e che nessuno poteva scrivere prima,
perche' e' emerso implementando.

Davanti a un dubbio, una domanda sola:

> **La risposta e' derivabile da qualcosa di gia' scritto?**
> `.workflow/PRD.md`, `.workflow/DESIGN.md`, le spec in `docs/`, il codice stesso,
> l'aritmetica.

- **Sì → decidi, implementa, e DICHIARA.** Nel corpo del PR, una sezione
  **"decisioni prese"** con: cosa hai deciso, da quale documento o calcolo
  discende, e cosa hai scartato. Una riga per decisione.
- **No → fermati.** E' una decisione di prodotto o di gusto, e nessun documento
  la contiene. Commenta sulla issue con la domanda ben posta e le opzioni,
  togli `night:wip`, metti `needs-spec`, torna al passo 4.

Due esempi veri, dallo stesso difetto:

| situazione | derivabile? | cosa fai |
|---|---|---|
| `DESIGN.md` dice riga 88px e contenuto 44+8+44 = 96px | **sì**, e' aritmetica: 96 non entra in 88 | dichiari la contraddizione e la risolvi |
| *quale* dei tre numeri sacrificare (altezza, bersaglio, gap) | **no**, e' una scelta di prodotto | ti fermi e chiedi |

La differenza non e' la difficolta': e' se esiste una fonte da cui la risposta
discende. Un calcolo difficile e' derivabile. Una preferenza facile non lo e'.

**Perche' dichiarare conta.** Sbaglierai a classificare — e' inevitabile. Ma una
decisione dichiarata si legge, si conta e si corregge. Una presa in silenzio
diventa un fatto del codice che nessuno ha mai approvato, e si scopre mesi dopo.
````

- [ ] **Step 3: Aggiornare il passo 11 perché il PR abbia la sezione**

Nel passo 11 (il corpo del PR), la lista dei contenuti diventa:

```markdown
11. Apri un PR sul branch `claude/<numero-issue>-<slug>`. Nel corpo:
    - `Closes #<numero-issue>` come prima riga, cosi' il merge chiude la issue
    - cosa fa, in due righe
    - **le decisioni prese** (vedi il triage) — la sezione manca solo se non ne
      hai presa nessuna, e in quel caso scrivi "nessuna"
    - cosa hai verificato, con l'esito
    - lo screenshot
    - una sezione **"cosa NON ho verificato"** — obbligatoria, mai vuota
```

- [ ] **Step 4: Verificare che il file non si contraddica**

Il passo 6 dice *«richiede una decisione di prodotto → `needs-spec`»*, e il
triage dice *«derivabile → decidi»*. Non è una contraddizione — il passo 6 guarda
la issue **prima** di iniziare, il triage guarda ciò che emerge **durante** — ma
il testo deve dirlo. Controlla che il primo paragrafo della nuova sezione lo
dichiari esplicitamente. Se non lo fa, riscrivilo.

Run: `grep -n "scopri mentre" routine/prompt.md`  (la frase va a capo: non cercarla intera)
Expected: una riga, dentro la nuova sezione.

- [ ] **Step 5: Commit**

```bash
git add routine/prompt.md && git commit -m "prompt: il triage fra cio' che si deriva e cio' che si chiede"
```

---

## Chunk 2: Il revisore

### Task 2: Scrivere il corpus, prima del prompt

Il corpus va scritto **per primo**: è l'atteso, e un atteso scritto dopo il prompt
non è un atteso, è una descrizione.

**Files:**
- Create: `routine/corpus.md`

- [ ] **Step 1: Scrivere il file**

````markdown
# Il corpus di collaudo

I prompt di `relay` non si compilano. Si collaudano: li si lancia su PR reali di
cui **conosciamo gia' la risposta giusta** e si confronta l'esito.

Si rilancia il corpus ogni volta che si tocca un prompt. Si lancia con:

```bash
relay-dryrun routine/review-prompt.md lukedj78/predictionleagues 48
```

## Corpus del revisore

### A — la schermata al posto del database

**PR:** `lukedj78/predictionleagues#48`

Il PR dichiara, nella sezione «cosa ho verificato»:

> «il client mostra una sola schermata di successo (nessun doppio `onSuccess`,
> nessun errore console) — esattamente il bookkeeping che l'hook promette»

E piu' sotto, in «cosa NON ho verificato», ammette che il database ha ricevuto
**due righe lega**. Il PR gemello #47 aveva misurato la stessa cosa dal lato del
database e concluso l'opposto.

**Atteso:** almeno **una smentita**. L'esperimento giusto e' contare le righe
nella tabella `leagues` dopo il doppio invio, non contare le schermate. Un
revisore che legge «una sola schermata di successo» e la conferma senza guardare
il database ha ripetuto l'errore che deve intercettare.

**Non e' atteso** che il revisore dica che il PR e' sbagliato: il fix di lint e'
corretto. E' attesa la smentita dell'**affermazione**, che e' cosa diversa.

### B — il PR onesto

**PR:** `lukedj78/predictionleagues#45`

Aggiunge il workflow CI. Le sue affermazioni sono poche, verificabili e vere.

**Atteso:** **zero smentite.** Verdetti «confermata» o «non verificabile», nessun
blocco.

Questo caso pesa quanto A. Un corpus di soli difetti produce un revisore che
trova sempre qualcosa, e un revisore che trova sempre qualcosa viene spento.

## Cosa il corpus non copre

I PR #42 (area autenticata servita come HTML statico) e #43 (`localhost` nel
bundle del client) sarebbero i casi migliori per i controlli fissi 1 e 2 della
lista, ma **le loro anteprime Vercel non esistono piu'**: erano deploy di
preview, scadono. Quei due controlli restano nella lista perche' il difetto e'
documentato, non perche' sia riproducibile qui.

Il primo collaudo dei due su materiale vivo e' il primo PR aperto dopo che il
revisore e' attivo.
````

- [ ] **Step 2: Commit**

```bash
git add routine/corpus.md && git commit -m "corpus: due casi di collaudo con l'atteso scritto prima del prompt"
```

---

### Task 3: Lo script di collaudo

Senza questo, il corpus si lancia copiando e incollando testo in una sessione, e un collaudo che si fa a mano non si fa.

**Files:**
- Create: `bin/relay-dryrun`

- [ ] **Step 1: Scrivere lo script**

```bash
#!/usr/bin/env bash
#
# relay-dryrun — lancia un prompt di relay su un PR vero, senza creare la routine.
#
# Serve a collaudare un prompt prima di metterlo in produzione, e a rilanciare il
# corpus (routine/corpus.md) ogni volta che lo si tocca.
#
#   relay-dryrun routine/review-prompt.md lukedj78/predictionleagues 48
#
# Differenze dalla routine vera, da tenere a mente leggendo l'esito:
#   - gira sul TUO Mac, non nella sandbox: ha i tuoi strumenti e la tua rete
#   - NON scrive su GitHub: l'ultima sezione del prompt e' sostituita
#   - consuma la tua quota come una sessione normale

set -euo pipefail

PROMPT_FILE="${1:?uso: relay-dryrun <prompt.md> <owner/repo> <numero-pr>}"
REPO="${2:?manca owner/repo}"
PR="${3:?manca il numero del PR}"

[ -f "$PROMPT_FILE" ] || { echo "✗ prompt non trovato: $PROMPT_FILE" >&2; exit 1; }
command -v claude >/dev/null || { echo "✗ claude non installato" >&2; exit 1; }
command -v gh     >/dev/null || { echo "✗ gh non installato" >&2; exit 1; }

OUT="dryrun-$(basename "$PROMPT_FILE" .md)-${PR}.md"

# Il prompt va passato come ARGOMENTO, non su stdin: con `-p` e stdin, il testo
# piped diventa contesto e il prompt vero e' l'argomento — che qui non ci
# sarebbe. Sono ~6KB, ben sotto ARG_MAX.
PROMPT="$(cat "$PROMPT_FILE")
────────────────────────────────────────────────────────────────
COLLAUDO — questa sezione sovrascrive le istruzioni di pubblicazione
────────────────────────────────────────────────────────────────

Sei in collaudo. Il PR da esaminare e' **${REPO}#${PR}**.

NON scrivere niente su GitHub: niente review, niente commenti, niente label,
niente push. Solo letture. Stampa la review che avresti pubblicato, nello stesso
formato, e basta.

Tutto il resto del mandato vale identico."

# --allowedTools serve perche' in headless nessuno puo' rispondere a un prompt di
# permesso: senza, la sessione si pianta in silenzio invece di fallire. Sono i
# soli strumenti che servono, e sono tutti in sola lettura salvo Bash — che pero'
# gli serve per `gh pr view` e per interrogare l'anteprima.
claude -p "$PROMPT" \
  --output-format text \
  --allowedTools "Bash,Read,Grep,Glob,WebFetch" \
  > "$OUT"

echo "✓ esito in $OUT"
echo
echo "Ora confrontalo con l'atteso in routine/corpus.md."
echo "Il confronto lo fai TU: se lo fa lo script, stai chiedendo al sistema"
echo "di giudicare sé stesso."
```

- [ ] **Step 2: Renderlo eseguibile e provarlo a vuoto**

```bash
chmod +x bin/relay-dryrun && ./bin/relay-dryrun
```
Expected: `uso: relay-dryrun <prompt.md> <owner/repo> <numero-pr>` ed exit non-zero.

```bash
bash -n bin/relay-dryrun && echo "sintassi ok"
```
Expected: `sintassi ok`.

Non lanciarlo ancora su un PR vero: il primo lancio serio è il collaudo del Task 4,
e ogni lancio consuma quota come una sessione normale.

- [ ] **Step 3: Commit**

```bash
git add bin/relay-dryrun && git commit -m "bin: relay-dryrun, collaudo di un prompt su un PR vero"
```

---

### Task 4: Scrivere il prompt del revisore

**Files:**
- Create: `routine/review-prompt.md`

- [ ] **Step 1: Scrivere il file**

````markdown
Sei il revisore. Il tuo mandato non e' «revisionare bene»: e' **provare che le
affermazioni di questo PR sono false**.

Sei una sessione autonoma: nessuno sta guardando, nessuno puo' rispondere a una
domanda. Hai gli strumenti GitHub gia' autenticati.

**Non mergi mai.** Non chiudi issue, non togli label, non pushi sul branch. Scrivi
una review e finisci.

## 1. Cosa leggere

- il **corpo del PR**, in particolare le sezioni «decisioni prese», «cosa ho
  verificato» e «cosa NON ho verificato»
- il **diff**
- `.workflow/PRD.md`, `.workflow/DESIGN.md`, e le spec in `docs/`
- **l'URL dell'anteprima Vercel**, che il bot pubblica come commento sul PR

L'anteprima e' la fonte piu' importante che hai. Su dieci difetti veri trovati in
questo progetto, **sei non erano leggibili in un diff**: si sono manifestati solo
facendo girare la cosa vera. Un revisore che legge solo il diff sta guardando il
40% del problema.

**Se l'anteprima non c'e'** — deploy in corso, o fallito — aspetta due minuti e
riguarda. Se manca ancora: emetti i verdetti che puoi emettere, e marca gli altri
`non verificabile — anteprima assente`. **Non fingere di averla vista.** Una
review che tace sull'anteprima mancante sembra completa e non lo e'.

## 2. Il mandato: falsificare

Per **ogni affermazione** nella sezione «cosa ho verificato», fai quattro cose:

1. **Affermazione** — citala testualmente
2. **Esperimento** — progetta la prova che la mostrerebbe **falsa**, non quella
   che la confermerebbe
3. **Risultato** — eseguilo davvero, e riporta cosa hai osservato
4. **Verdetto** — uno dei tre qui sotto

| verdetto | quando | effetto |
|---|---|---|
| **confermata** | hai eseguito l'esperimento e non l'ha smentita | nessuno |
| **smentita** | l'esperimento la contraddice | blocca il PR |
| **non verificabile** | non falsificabile con quello che hai | non blocca, resta scritta |

**Il terzo verdetto e' obbligatorio quando serve.** Se non hai potuto guardare,
dillo: «non ho potuto guardare» e' un esito legittimo. Trasformare la propria
cecita' in un'obiezione e' il modo in cui un revisore diventa rumore.

### La regola che decide l'esperimento

**Misura l'effetto, non l'apparenza.**

E' successo davvero, in questo progetto: due run hanno corretto lo stesso difetto.
Uno ha scritto *«il client mostra una sola schermata di successo, quindi
l'annullamento funziona»*. L'altro ha contato le righe nel database e ne ha
trovate **due**. Il secondo aveva ragione. Il primo non stava mentendo — aveva
verificato con cura la cosa sbagliata.

Quindi, quando l'affermazione parla di:

| l'affermazione dice | tu misuri |
|---|---|
| «la schermata mostra…» | cosa e' finito **nel database** |
| «il pulsante e' disabilitato» | cosa succede se la richiesta **parte comunque** |
| «la pagina reindirizza» | le **intestazioni HTTP** della risposta |
| «il build passa» | il build **come lo lancia Vercel**, non come lo lanci tu |
| «i test passano» | cosa **non** copre il test che passa |

## 3. La lista fissa

Sei controlli, oltre alle affermazioni del PR. Ognuno nasce da un difetto vero,
gia' costato a questo progetto. Eseguili sempre, anche se il PR non li nomina.

1. **L'area autenticata reindirizza senza cookie di sessione.** Chiedi una rotta
   protetta dell'anteprima senza cookie e guarda la risposta. Se torna 200 con
   HTML della pagina, la guardia non sta girando — non basta che il codice della
   guardia esista.
   *Origine: l'area `(app)` veniva servita come HTML statico e il controllo di
   sessione non veniva mai eseguito.*

2. **Nessun `localhost` nel bundle del client.** Cerca `localhost` e `127.0.0.1`
   nel JavaScript servito dall'anteprima.
   *Origine: il browser del visitatore chiamava il proprio computer.*

3. **I numeri del `DESIGN.md` tornano nei componenti toccati.** Se il diff tocca
   un componente che il `DESIGN.md` dimensiona, **fai l'aritmetica**: contenuto +
   spaziature devono stare nel contenitore.
   *Origine: una riga alta 88px con dentro 44+8+44 = 96px.*

4. **`messages/en.json` e `messages/it.json` hanno le stesse chiavi.** Confronta
   gli insiemi, in entrambe le direzioni.
   *Origine: `MISSING_MESSAGE` in produzione.*

5. **Le scritture si contano nel database, non nelle schermate.** Se il diff
   tocca qualcosa che scrive, conta le righe.
   *Origine: due leghe create, una sola schermata mostrata.*

6. **Il build passa da `turbo run build`**, dalla radice, non da
   `pnpm --filter`. Sono cose diverse: turbo filtra le variabili d'ambiente
   secondo `turbo.json`, e un build che passa filtrato puo' fallire in produzione.
   *Origine: tre deploy falliti di fila.*

**Questa lista si allunga solo dopo un difetto sfuggito** a cui nessun controllo
avrebbe potuto arrivare. Mai per prudenza. Se aggiungi una riga, deve poter citare
il guasto che l'ha generata — e non sei tu ad aggiungerla: lo fa una persona.

## 4. Cosa NON fai

- **Non giudichi lo stile.** Niente rinomine, niente astrazioni suggerite, niente
  preferenze. Se non e' falsificabile, non e' tuo.
- **Non riscrivi il codice.** Non pushi sul branch, non apri un PR di correzione.
- **Non mergi e non approvi.** Nemmeno quando tutto e' confermato: `approve` su
  GitHub puo' innescare regole di merge automatico, e il merge e' una decisione
  di una persona.
- **Non blocchi la coda.** Il tuo verdetto vale per questo PR. La routine che
  scrive il codice va avanti con la issue successiva a prescindere.

## 5. La review

Pubblicala come review GitHub sul PR:

- **almeno una smentita** → stato `REQUEST_CHANGES`
- **nessuna smentita** → stato `COMMENT`
- **mai** `APPROVE`

Formato del corpo, in italiano:

```markdown
## Verdetto

<una riga: N confermate, N smentite, N non verificabili>

## Le affermazioni

### 1. «<citazione testuale dal PR>»

- **Esperimento:** <la prova che l'avrebbe mostrata falsa>
- **Risultato:** <cosa hai osservato davvero>
- **Verdetto:** confermata | smentita | non verificabile

### 2. ...

## La lista fissa

| # | controllo | esito |
|---|---|---|
| 1 | area autenticata senza cookie | ok / SMENTITA / non verificabile |
| ... | | |

## Cosa non ho potuto guardare

<obbligatoria, mai vuota — se hai potuto guardare tutto, dillo e spiega perche'
in questo caso era possibile>
```

L'ultima sezione e' obbligatoria per lo stesso motivo per cui lo e' nel PR
dell'autore: senza, non si distingue una review completa da una superficiale.

## Regole assolute

- Mai `approve`, mai merge, mai push, mai chiudere issue.
- Mai togliere o mettere label che non siano tue.
- Mai toccare `.env*`.
- Se ti fermi a meta', **commenta comunque sul PR** cosa e' successo e dove.
  Una review mancante e una review silenziosa da fuori sono identiche.
````

- [ ] **Step 2: Lanciare il caso A del corpus**

```bash
cd ~/projects/relay && ./bin/relay-dryrun routine/review-prompt.md lukedj78/predictionleagues 48
```

Expected: un file `dryrun-review-prompt-48.md`. Aprilo e cerca **una smentita
sull'affermazione della schermata**. Il criterio esatto: il revisore deve aver
progettato un esperimento che guarda le righe nel database, non le schermate.

**Se non c'è**, il prompt è sbagliato, non il corpus. Il punto più probabile da
correggere è la tabella «l'affermazione dice / tu misuri» al §2: aggiungici la
riga mancante e rilancia. Non aggiustare l'atteso.

- [ ] **Step 3: Lanciare il caso B del corpus**

```bash
./bin/relay-dryrun routine/review-prompt.md lukedj78/predictionleagues 45
```

Expected: **zero smentite**. Verdetti confermata o non verificabile.

**Se ci sono smentite**, leggile: se una è vera, il corpus va corretto e il caso
B non era onesto come credevamo — scrivilo in `corpus.md`. Se sono false, il
prompt è troppo aggressivo: il punto da rinforzare è il §4 «Cosa NON fai».

- [ ] **Step 4: Buttare via gli esiti del collaudo**

```bash
rm -f dryrun-*.md && echo 'dryrun-*.md' >> .gitignore
```

Gli esiti non si committano: sono lunghi, non deterministici, e leggerli fra un
mese non dice niente. Quello che si committa è il corpus, che è l'atteso.

- [ ] **Step 5: Commit**

```bash
git add routine/review-prompt.md .gitignore
git commit -m "prompt: il revisore avversariale"
```

---

### Task 5: Creare la routine del revisore

Questo passo si fa **a mano**, nella UI. Non è automatizzabile e non deve esserlo:
è il punto in cui una persona guarda cosa sta accendendo.

**Files:** nessuno.

- [ ] **Step 1: Creare la routine**

Su [claude.ai/code/routines](https://claude.ai/code/routines) → New routine:

| campo | valore |
|---|---|
| Nome | `predictionleagues — revisore` |
| Repository | `lukedj78/predictionleagues` |
| Environment | `nightly` |
| Connectors | **NESSUNO** — l'API ne attacca alcuni da sola, vanno tolti tutti a mano ogni volta |
| Modello | Sonnet |
| Trigger | GitHub → `pull_request`, azioni **opened** e **reopened** |
| Prompt | il contenuto di `routine/review-prompt.md` |

**Non** `synchronize`: farebbe partire una review a ogni push del branch. I trigger
GitHub hanno tetti orari, e ogni run consuma la stessa quota delle tue sessioni.

- [ ] **Step 2: Verificare che i connector siano davvero zero**

Riapri la routine appena creata e ricontrolla la sezione Connectors. Se l'API li
ha riattaccati, toglili di nuovo e salva.

Expected: lista vuota.

- [ ] **Step 3: Non accendere ancora nient'altro**

Non aggiungere altri trigger. Il prossimo passo è guardare un run vero.

---

### Task 6: Il primo run osservato

- [ ] **Step 1: Aprire un PR vero**

Il primo PR aperto dalla routine notturna dopo questo punto fa da innesco. Se non
ne arriva uno entro il giro successivo, apri tu un PR piccolo e reale su
`predictionleagues` — non un PR finto: un revisore collaudato su materiale finto
non dice niente.

- [ ] **Step 2: Leggere la review, per intero**

Le tre domande, in ordine:

1. **Ha guardato l'anteprima?** Se non la nomina, il §1 del prompt non ha
   funzionato ed è la cosa da correggere per prima — è il 60% del suo valore.
2. **Gli esperimenti misurano l'effetto o l'apparenza?** Un esperimento che
   ricontrolla lo schermo dove il PR guardava lo schermo non è un esperimento.
3. **Le smentite sono vere?** Ognuna che non lo è va contata: è la metrica dei
   falsi positivi della spec §9.

- [ ] **Step 3: Registrare l'esito nel corpus**

Se il run ha trovato qualcosa di vero che i due casi non coprivano, o ha prodotto
un falso positivo istruttivo, aggiungilo a `routine/corpus.md` come caso C, con
l'atteso scritto **come avrebbe dovuto comportarsi**.

```bash
git add routine/corpus.md && git commit -m "corpus: caso C dal primo run osservato"
```

- [ ] **Step 4: Decidere se il revisore vive**

Se la review non ha aggiunto niente a quello che già sapevi leggendo il PR, non
correggerla: **spegnila** e dillo. Un revisore tenuto in vita per affezione costa
quota a ogni PR e non ne restituisce.

---

## Chunk 3: Il documentatore

### Task 7: Scrivere il prompt del documentatore

**Files:**
- Create: `routine/docs-prompt.md`

- [ ] **Step 1: Scrivere il file**

````markdown
Sei il documentatore. Un PR e' appena stato mergiato. Il tuo unico compito e'
trovare le frasi dei documenti che **quel merge ha reso false**, e correggerle.

Sei una sessione autonoma: nessuno puo' rispondere a una domanda. Hai gli
strumenti GitHub gia' autenticati.

## 1. L'uscita rapida

**Fai questo per primo, e nella maggior parte dei casi finisce qui.**

Guarda cosa il PR ha cambiato. Poi guarda i documenti di riferimento:

- `.workflow/PRD.md`
- `.workflow/DESIGN.md`
- `docs/specs/*.md`
- `README.md`

**Qualcuno di loro contiene un'affermazione che questo merge ha smentito?**

Se no — ed e' il caso normale — **TERMINA subito** dicendo «niente da
riconciliare» e quale PR hai guardato. Non aprire un PR vuoto, non scrivere un
riassunto, non «gia' che ci sono» sistemare altro.

Un merge su tre tocca i documenti. Gli altri due devono costarti trenta secondi.

## 2. Le due regole

### Puoi solo correggere cio' che e' diventato falso

Non riscrivi. Non migliori. Non riordini. Non aggiungi sezioni. Non «rendi piu'
chiaro» un paragrafo che e' ancora vero.

Se una frase e' brutta ma vera, **la lasci brutta**.

Un documentatore con licenza di migliorare produce rifacimenti che nessuno ha
chiesto, che nessuno rilegge, e che seppelliscono le correzioni vere in mezzo a
duecento righe di diff.

### Distingui i fatti dalle decisioni

Stesso triage dell'autore, applicato ai documenti.

| la riga dice | e' | cosa fai |
|---|---|---|
| «12 competizioni nel piano free» e l'API ne dà 13 | **fatto**, verificabile | **correggi** |
| «`packages/db` con la tabella `fixture`» e ora sono quattro tabelle | **fatto** | **correggi** |
| «`score: 20px`» | **decisione** di chi ha scritto il documento | **non toccare**, segnala |
| «il buio e' il caso normale» | **decisione** | **non toccare**, segnala |
| «niente denaro nell'MVP» | **decisione** | **non toccare**, segnala |
| «le righe sono immutabili» ma lo schema non lo impone | **requisito non ancora implementato** | **non toccare**, segnala |

L'ultima riga e' la piu' insidiosa, perche' sembra un fatto sbagliato e non lo e'.
Un requisito che il codice non soddisfa ancora **non e' un errore del documento**:
e' lavoro che manca. Se lo «allinei al codice» fai sparire un vincolo scrivendo
che non e' mai esistito — ed e' l'unico modo in cui questo agente puo' fare danno
vero.

Il caso che insegna: portare `score` da 20 a 16px **sembrava** una conseguenza
aritmetica del riquadro rimpicciolito. Non lo era: era una scelta sul sistema
tipografico. Un agente si ferma li'.

Nel dubbio, e' una decisione. Il costo di segnalare una cosa ovvia e' una riga da
leggere; il costo di riscrivere una scelta altrui e' una scelta persa.

## 3. Cosa scrivi

Apri **un PR di sole modifiche ai documenti** — nessun file di codice, mai.

Branch: `docs/riconcilia-<numero-del-PR-mergiato>`

Ogni correzione cita il PR che l'ha resa necessaria. Nel corpo:

```markdown
Riconcilia i documenti dopo #<N>.

## Corretto

- `.workflow/DESIGN.md:NN` — diceva «<vecchio>», ora «<nuovo>».
  Smentito da #<N>: <in una riga, cosa nel PR l'ha resa falsa>

## Segnalato, non toccato

- `.workflow/DESIGN.md:NN` — dice «<testo>». Dopo #<N> non torna piu', ma e' una
  **decisione**, non un fatto: <perche'>. Va decisa da una persona.
```

Se non c'e' niente in «Corretto» ma qualcosa in «Segnalato», **non aprire un PR**:
commenta sul PR mergiato. Un PR senza modifiche e' rumore.

## Regole assolute

- Mai toccare file di codice. Solo `.md`.
- Mai push su `main`. Mai `--force`, `--amend`, `--no-verify`.
- Mai cancellare una riga: se e' falsa la **correggi**, se e' una decisione la
  **segnali**. Cancellare fa sparire la storia di come si e' arrivati li'.
- Se una correzione richiede di capire una scelta di prodotto, e' una decisione:
  segnala e fermati.
- Se ti fermi a meta', commenta sul PR mergiato cosa e' successo.
````

- [ ] **Step 2: Aggiungere il caso di collaudo al corpus**

In `routine/corpus.md`, dopo la sezione del revisore:

````markdown
## Corpus del documentatore

### D — quattro fatti smentiti e una decisione da non toccare

**PR:** `lukedj78/predictionleagues#35` (schema di lega, partecipanti e ruleset)

Quel merge ha implementato le entita' che la spec del 12 agosto descriveva al
§4.1, **discostandosene in quattro punti**, e non ha corretto una riga della spec.

Fatti diventati falsi — il documentatore li **corregge**:

| la spec dice | il codice fa |
|---|---|
| `league.join_code` | la colonna si chiama `invite_code` |
| `scoring_ruleset.config` (jsonb, struttura `ScoringRuleSet`) | colonne piatte: `exact_score_points`, `correct_outcome_points`, … |
| `scoring_ruleset.is_preset` | non esiste |
| esiste un'entita' `competition` | non c'e' nessuna tabella `competition` — `league_competitions.competition_code` e' un codice, non una FK |

Decisione da **non toccare, solo segnalare**:

> «Le righe sono **immutabili**: cambiare le regole significa creare una versione
> nuova, non modificarne una esistente, altrimenti i `scoring_run` storici
> perdono significato.»

Lo schema non impone nulla del genere: nessun trigger, nessuna colonna che lo
renda vero. Ma quella frase **non e' un fatto sbagliato, e' un requisito non
ancora implementato**. Cancellarla o ammorbidirla per «allinearla al codice»
significherebbe far sparire un vincolo di prodotto scrivendo che non e' mai
esistito.

**Atteso:** quattro correzioni e una segnalazione. Gli errori che contano sono
due, in direzioni opposte:

- se **corregge anche la riga sull'immutabilita'** (o la cancella), il triage
  fatti/decisioni non funziona ed e' il fallimento grave: distrugge informazione
- se **si limita a segnalare tutto** senza correggere niente, e' inutile ma
  innocuo

Il primo tipo di errore vale piu' del secondo. Un documentatore troppo timido si
migliora; uno che riscrive le decisioni ha gia' perso qualcosa.

### E — l'uscita rapida

**PR:** `lukedj78/predictionleagues#45` (il workflow CI)

Non smentisce nessun documento.

**Atteso:** «niente da riconciliare», e poco altro. Se produce un elenco di
migliorie possibili, il §1 del prompt non sta funzionando — ed e' il fallimento
piu' probabile di questo agente, quello che lo rende caro invece che economico.
````

- [ ] **Step 3: Lanciare il caso D**

```bash
./bin/relay-dryrun routine/docs-prompt.md lukedj78/predictionleagues 35
```

Expected: quattro correzioni sul §4.1 della spec, e la riga sull'immutabilità
**segnalata, non toccata**.

Se corregge o cancella la riga sull'immutabilità, il prompt è sbagliato: il punto
da rinforzare è la tabella «fatti / decisioni» del §2, che va estesa con la riga
mancante — *un requisito non ancora implementato è una decisione, non un errore*.

- [ ] **Step 4: Lanciare il caso E**

```bash
./bin/relay-dryrun routine/docs-prompt.md lukedj78/predictionleagues 45
```

Expected: **«niente da riconciliare»**, e poco altro.

- [ ] **Step 5: Commit**

```bash
rm -f dryrun-*.md
git add routine/docs-prompt.md routine/corpus.md
git commit -m "prompt: il documentatore riconciliatore"
```

---

### Task 8: Creare la routine del documentatore

- [ ] **Step 1: Creare la routine**

| campo | valore |
|---|---|
| Nome | `predictionleagues — documentatore` |
| Repository | `lukedj78/predictionleagues` |
| Environment | `nightly` |
| Connectors | **NESSUNO** |
| Modello | Sonnet |
| Trigger | GitHub → `pull_request`, azione **closed**, filtro **is merged = true** |
| Prompt | il contenuto di `routine/docs-prompt.md` |

- [ ] **Step 2: Ricontrollare i connector**

Expected: lista vuota.

- [ ] **Step 3: Osservare i primi tre merge**

La domanda è una sola: **quanti dei tre sono usciti subito con «niente da
riconciliare»?**

Se sono zero, l'uscita rapida non funziona e stai pagando un run pieno a ogni
merge. Se sono tre, aspetta un merge che tocca davvero i documenti prima di
concludere che funziona.

---

## Chunk 4: Il sistema si racconta

Tre routine con costi diversi non si spiegano da sole. Questo chunk è quello che
rende il sistema riusabile su un progetto nuovo invece che solo su questo.

### Task 9: Estendere `docs/cadences.md`

**Files:**
- Modify: `docs/cadences.md`

- [ ] **Step 1: Riscrivere il titolo e l'apertura**

Il file oggi si chiama «Le tre cadenze» e descrive tre *trigger* di **una**
routine. Ora ci sono tre *routine*. Sono assi diversi e vanno separati, altrimenti
«tre» significa due cose nello stesso documento.

Cambia il titolo in `# Le cadenze e le routine` e aggiungi, subito dopo il
paragrafo che apre il file:

```markdown
Da leggere sapendo che ci sono **due assi**, e che «tre» ricorre su entrambi per
coincidenza:

- **quante routine** — tre: l'autore, il revisore, il documentatore
- **con che cadenza parte ciascuna** — le tre qui sotto

Le sezioni 1–3 parlano del secondo asse. La sezione finale mette insieme i due.
```

- [ ] **Step 2: Aggiungere la sezione sulle tre routine**

Prima della sezione «Una nota sul nome dell'environment»:

````markdown
## Le tre routine

| routine | trigger | costa | cresce con |
|---|---|---|---|
| **autore** | `Schedule` + `GitHub` sul merge | un run pieno | i task che restano in coda |
| **revisore** | `GitHub` su PR aperto o riaperto | un run pieno | **i PR che apri** |
| **documentatore** | `GitHub` su merge riuscito | quasi zero, di norma | i merge che toccano i documenti |

Condividono **un solo environment**, `nightly`: stesse credenziali, stesso setup,
stessi domini consentiti. Si distinguono per prompt e per trigger, non per
ambiente. Non creare un environment per routine: si moltiplicherebbero i posti in
cui aggiornare `DATABASE_URL`.

### Cosa succede alla spesa

L'autore era una cadenza sola e prevedibile. Con tre routine il conto cambia
forma, e vale la pena vederlo scritto prima di accendere tutto:

- il **revisore** parte a ogni PR aperto. Se l'autore apre un PR al giorno, e'
  un run in piu' al giorno. Se acceleri l'autore, acceleri anche questo.
- il **documentatore** parte a ogni merge, ma la maggior parte delle volte esce
  in pochi secondi con «niente da riconciliare». E' il piu' economico dei tre —
  **se** l'uscita rapida funziona. Se non funziona, e' il piu' caro, perche'
  parte sempre.

Il revisore non fa partire un run su `synchronize`, cioe' a ogni push sul branch
di un PR aperto. Sarebbe la scelta piu' completa e la piu' rapida per esaurire i
tetti orari dei trigger GitHub.

### In che ordine accenderle

1. **L'autore da solo**, come oggi. Finche' non hai una settimana di run.
2. **Il revisore.** E' quello che restituisce di piu': su dieci difetti veri di
   `predictionleagues`, sei non erano leggibili in un diff.
3. **Il documentatore**, per ultimo. E' il piu' economico, ma anche quello che
   serve solo quando i documenti hanno gia' cominciato a divergere — cioe' non
   il primo mese.
````

- [ ] **Step 3: Commit**

```bash
git add docs/cadences.md && git commit -m "docs: le tre routine, e cosa costa accenderle"
```

---

### Task 10: `relay-init` stampa tre routine

**Files:**
- Modify: `bin/relay-init:106-138` (il blocco finale «Cosa incollare nella form»)

- [ ] **Step 1: Sostituire il blocco finale**

Sostituisci l'heredoc finale con:

````bash
cat <<EOF

────────────────────────────────────────────────────────────────
  Il repo e' pronto. Mancano la coda e le routine.
────────────────────────────────────────────────────────────────

  1. La coda — trasforma i task in issue GitHub:

       $NIGHT_FLOW/bin/tasks-to-issues --dry-run
       $NIGHT_FLOW/bin/tasks-to-issues

  2. Le routine — https://claude.ai/code/routines → New routine

     Tutte e tre: Repository $GH_OWNER/$SLUG, Environment nightly,
     Modello Sonnet, e **Connectors NESSUNO** — l'API ne attacca
     alcuni da sola, vanno tolti a mano ogni volta e ricontrollati
     dopo il salvataggio.

     ┌─ $SLUG — notte ────────────────── ACCENDI QUESTA PER PRIMA
     │  Trigger   Schedule → daily, 02:00
     │  Prompt    $NIGHT_FLOW/routine/prompt.md
     └─

     ┌─ $SLUG — revisore ─────────────── quando l'autore e' rodato
     │  Trigger   GitHub → pull_request, opened + reopened
     │            (NON synchronize: un run a ogni push)
     │  Prompt    $NIGHT_FLOW/routine/review-prompt.md
     └─

     ┌─ $SLUG — documentatore ────────── per ultima
     │  Trigger   GitHub → pull_request, closed, is merged = true
     │  Prompt    $NIGHT_FLOW/routine/docs-prompt.md
     └─

     L'ordine non e' estetico: vedi $NIGHT_FLOW/docs/cadences.md.
     Ogni routine e' un run pieno di quota, e il revisore parte a
     ogni PR che l'autore apre.

  3. Premi "Run now" sulla prima e GUARDA il run. Il setup script
     sbaglia sempre qualcosa la prima volta. Accendi il cron solo
     dopo che un run e' arrivato fino al PR — e le altre due solo
     dopo che il primo PR ti e' sembrato buono.

EOF
````

- [ ] **Step 2: Provarlo su un progetto vero**

```bash
cd ~/projects/predictionleagues && relay-init --check
```
Expected: `✓ prerequisiti verificati (phase='module_added')` e nessuna modifica.

`--check` esce prima del blocco stampato, quindi per vedere l'output nuovo senza
toccare niente:

```bash
cd ~/projects/relay && bash -n bin/relay-init && sed -n '106,175p' bin/relay-init
```
Expected: sintassi valida, e i tre riquadri leggibili.

- [ ] **Step 3: Commit**

```bash
git add bin/relay-init && git commit -m "relay-init: stampa la configurazione delle tre routine"
```

---

### Task 11: Aggiornare il README

**Files:**
- Modify: `README.md` (tabella «Quando gira», tabella «I pezzi», sezione «Cosa fa e cosa non fa»)

- [ ] **Step 1: Aggiungere le tre routine sopra la tabella delle cadenze**

Dopo il paragrafo «Monti questo repo una volta…», inserisci:

```markdown
## I tre agenti

| | Cosa fa | Non fa |
|---|---|---|
| **Autore** | prende una issue, implementa, apre un PR verificato | mergia, sceglie librerie, inventa workaround |
| **Revisore** | tenta di **falsificare** ogni affermazione del PR | giudica lo stile, corregge il codice, approva |
| **Documentatore** | corregge le frasi che il merge ha reso **false** | riscrive, migliora, tocca le decisioni |

L'autore verifica sé stesso, e questo ha un limite osservato: due run sullo stesso
difetto, uno ha misurato lo schermo e l'altro il database, e solo il secondo aveva
ragione. Il revisore esiste per quello. Il documentatore esiste perché i documenti
diventano falsi in silenzio.
```

- [ ] **Step 2: Correggere la riga «mergia su `main`» della tabella esistente**

La sezione «Cosa fa e cosa non fa» descrive l'autore. Aggiungi sopra la tabella:
`La tabella qui sotto riguarda l'**autore**. Per gli altri due, vedi sopra.`

- [ ] **Step 3: Aggiungere i file nuovi alla tabella «I pezzi»**

```markdown
| [`routine/review-prompt.md`](routine/review-prompt.md) | il prompt del revisore |
| [`routine/docs-prompt.md`](routine/docs-prompt.md) | il prompt del documentatore |
| [`routine/corpus.md`](routine/corpus.md) | i casi di collaudo, con l'atteso |
| [`bin/relay-dryrun`](bin/relay-dryrun) | lancia un prompt su un PR vero, senza creare la routine |
| [`docs/specs/`](docs/specs/) | le decisioni di design, con il perché |
```

- [ ] **Step 4: Verificare che ogni link punti a un file esistente**

```bash
cd ~/projects/relay && grep -oE '\]\([^)]+\)' README.md | sed -E 's/^\]\(//; s/\)$//' | grep -v '^http' | while read -r f; do [ -e "${f%%#*}" ] || echo "ROTTO: $f"; done
```
Expected: nessun output.

- [ ] **Step 5: Commit**

```bash
git add README.md && git commit -m "README: i tre agenti e cosa distingue ciascuno"
```

---

## Cosa questo piano non fa

Rimandati nella spec §7, e non li anticipiamo:

- **il correttore automatico** — finché non sappiamo quanti falsi positivi produce
  il revisore, un correttore che insegue smentite sbagliate è peggio di nessun
  correttore
- **il merge automatico** — toglie il regolatore per cui la spesa cresce quanto la
  fiducia
- **la parallelizzazione** — il lock `night:wip` ha già ceduto con due run
  (13 agosto, due PR sulla stessa issue). Va diagnosticato prima di aumentare la
  concorrenza, non dopo

Il terzo è il più importante da non dimenticare: è un difetto **aperto**, non una
funzionalità mancante.
