# Il ciclo chiuso — piano di implementazione

> **Per chi esegue:** usa `superpowers:subagent-driven-development` (se hai i subagent) oppure `superpowers:executing-plans`. I passi hanno le caselle (`- [ ]`) per essere spuntati.

**Goal:** una issue entra, del codice verificato esce, il task successivo parte da solo — senza che nessuno mergi a mano — lasciando dietro prove e una relazione leggibile.

**Architettura:** cinque routine che ragionano (autore, revisore, correttore, documentatore, spazzino) e due meccanismi che non ragionano (la CI e il revert, entrambi GitHub Actions). Il lock sulle issue è la creazione atomica di una ref. Nessun servizio nuovo.

**Stack:** Markdown (i prompt), bash, `gh` CLI, GitHub Actions, routines cloud.

**Spec:** [`docs/specs/2026-08-14-ciclo-chiuso-design.md`](../specs/2026-08-14-ciclo-chiuso-design.md)

---

## Stato dell'esecuzione — 14 agosto 2026

| task | stato |
|---|---|
| 1 — i tre interruttori | **1 su 3**: `delete_branch_on_merge` girato e verificato al primo merge |
| 2 — provare il lock atomico | **fatto**, e registrato in `corpus.md` |
| 3 — il lock nel prompt dell'autore | **fatto** (`b75d42e`) |
| 4 — l'autore committa le prove | **fatto** (`b75d42e`) |
| 5 — la relazione | **fatto** (`058827f`, e `docs/relazione.md` in PR #57) |
| 6 — il revisore mergia | **fatto** (`bf3b175`) |
| 7 — il correttore | **fatto** (`4851d32`), casi H e H2 passati |
| 8 — l'Action di revert | **fatto**, mergiata in PR #57 |
| 9 — lo spazzino | **fatto** (`4851d32`) |
| 10 — `cadences.md` | **fatto** (`db9c9d4`) |
| 11 — `relay-init` e README | **fatto** (`db9c9d4`) |
| 12 — l'accensione | **bloccata** dai due interruttori mancanti |

### Il vincolo scoperto eseguendo

**La protezione dei branch non è disponibile sui repository privati con piano
GitHub free.** Né la classic branch protection né i ruleset: entrambe rispondono
`403 Upgrade to GitHub Pro or make this repository public`.

Il prerequisito 1 del Task 1 era quindi **impossibile da soddisfare** così com'era
scritto, e il piano lo dava per acquisito.

Come è stato adattato: il revisore esegue `gh pr checks` e verifica da sé che ogni
check sia verde, invece di contare su GitHub per rifiutare il merge. **Disciplina
invece di imposizione.** La rete di revert resta sotto, ed è esattamente il caso
per cui esiste.

La differenza è reale e va detta: con la protezione, un revisore che ignora le
istruzioni **non riesce** a mergiare con la CI rossa. Senza, ci riesce, e lo si
scopre dal revert. In un sistema la cui premessa è «nessuno sta guardando», è la
differenza fra un vincolo e un consiglio.

### Due errori del piano, corretti eseguendo

- **Il rilascio del lock mancava in due percorsi.** Il gate del passo 6 e il
  triage rimandano al passo 4 dopo aver creato la ref, e il piano non diceva di
  cancellarla. Quelle issue sarebbero rimaste bloccate per sempre, in modo
  invisibile: sembrano libere, e ogni run che le prende riceve `422`.
- **Il documentatore andava in loop.** Il suo PR viene mergiato, il merge lo
  risveglia, scrive una voce su quel PR e ne apre un altro. Servono **due**
  difese, non una: la guardia nel prompt (§0a) e il filtro sul trigger — perché i
  filtri si sbagliano a configurare.

### Un limite dell'harness, corretto

`relay-dryrun` puntava a un PR ma non poteva iniettarci del contesto. Del
correttore si poteva quindi collaudare solo il caso facile («non c'è niente da
fare»), perché la review a cui reagisce non esiste su un PR storico. Ora accetta
un quarto argomento, e le fixture stanno in `routine/fixtures/`.

---

## Come si verifica

Vale quanto stabilito il 14 agosto e non cambia: **l'atteso si scrive prima del
prompt**, in `routine/corpus.md`, e si lancia con `bin/relay-dryrun` su PR veri.

Cambia una cosa in meglio: **due pezzi di questo piano sono verificabili davvero,
non per collaudo di prompt.** Il lock si prova chiamando l'API due volte e
guardando se la seconda fallisce. Il revert si prova su un branch usa-e-getta. Su
quelli non si discute di prompt: o funzionano o no.

---

## Struttura dei file

### In `relay`

| file | cosa cambia |
|---|---|
| `routine/prompt.md` | lock atomico, rilascio del lock, commit delle prove |
| `routine/review-prompt.md` | **mergia**, gestisce `synchronize`, mette `needs-human` |
| `routine/fix-prompt.md` | **nuovo** — il correttore |
| `routine/sweeper-prompt.md` | **nuovo** — lo spazzino |
| `routine/docs-prompt.md` | aggiunge la voce alla relazione |
| `routine/corpus.md` | casi nuovi per lock, merge, correzione |
| `templates/revert-on-broken-main.yml` | **nuovo** — l'Action di revert |
| `bin/relay-init` | cinque routine, e i prerequisiti come blocco |
| `docs/cadences.md`, `README.md` | riscritti per il ciclo chiuso |

### In `predictionleagues`

| file | cosa |
|---|---|
| `.github/workflows/revert-on-broken-main.yml` | **nuovo** |
| `docs/relazione.md` | **nuovo**, con l'intestazione e le voci storiche |
| `docs/evidence/` | **nuova cartella** per gli screenshot |

---

## Chunk 0: I prerequisiti

Sono azioni tue, ma **sono verificabili da qui**. Il piano non prosegue oltre il
Chunk 5 finché non passano.

### Task 1: Verificare i due interruttori

**Files:** nessuno.

- [ ] **Step 1: `verify` obbligatoria su `main`**

Tu: GitHub → `predictionleagues` → Settings → Rules → New branch ruleset su
`main`:

- ✅ **Require status checks to pass** → aggiungi `verify`
- ❌ **NON** attivare «Require a pull request before merging → Required
  approvals»
- ✅ **Bypass list**: aggiungi il ruolo *Repository admin* (o la GitHub Actions
  app), altrimenti l'Action di revert del Task 8 non può pushare

**Le due righe negative valgono quanto quella positiva.**

*Perché niente approvazioni obbligatorie:* le routine agiscono con la **tua**
identità GitHub — la documentazione lo dice esplicitamente, «commits and pull
requests carry your GitHub user». L'autore e il revisore sono quindi lo stesso
utente, e **GitHub non permette di approvare un proprio PR**. Con un'approvazione
obbligatoria il ciclo diventa impossibile da chiudere: non è una difficoltà, è
una contraddizione. Il gate è il check `verify`, non un'approvazione.

*Perché il bypass:* l'Action di revert deve pushare direttamente su `main`, e un
push diretto su un branch con check obbligatori viene rifiutato. Senza bypass la
rete non può agire proprio nel momento in cui serve.

> **Da verificare al primo uso, non dato per certo.** Se il bypass non risulta
> configurabile come previsto, il ripiego è che l'Action **apra un PR di revert**
> invece di pushare — più lento, e richiede che il revisore lo mergi, ma
> funziona. Non l'ho scritto come strada principale perché fa dipendere la rete
> dal pezzo che potrebbe essere quello rotto.

Verifica:

```bash
gh api repos/lukedj78/predictionleagues/branches/main/protection --jq '.required_status_checks.contexts' 2>&1 | head -3
```
Expected: una lista che contiene `verify`. Se risponde `Branch not protected`,
non è stato fatto.

**Perché blocca tutto:** senza, «mergia se la CI è verde» è una frase che nessuno
fa rispettare — il PR #45 è stato mergiato con `verify` rosso. Con, è **GitHub**
a rifiutare il merge, e il gate smette di dipendere dalla disciplina di un prompt.

- [ ] **Step 2: Anteprime Vercel apribili**

Tu: Vercel → `predictionleagues` → Settings → Deployment Protection → disattiva
per i Preview (oppure genera un Protection Bypass for Automation e mettilo
nell'environment come variabile).

Verifica su un PR aperto:

```bash
cd ~/projects/predictionleagues && PREV=$(gh pr view 50 --json comments --jq '[.comments[].body]|join(" ")' | grep -oE 'https://predictionleagues-[a-z0-9-]+\.vercel\.app' | head -1) && curl -s -o /dev/null -w '%{http_code}\n' "$PREV"
```
Expected: `200`. Oggi risponde `302` verso `vercel.com/sso-api`.

- [ ] **Step 3: Cancellazione automatica del branch al merge**

```bash
gh api repos/lukedj78/predictionleagues -X PATCH -f delete_branch_on_merge=true --jq .delete_branch_on_merge
```
Expected: `true`.

**Non è cosmetico.** Il lock del Chunk 1 è l'esistenza della ref
`claude/<issue>-<slug>`: se il branch sopravvive al merge, quella issue resta
lockata per sempre. Questo è metà del rilascio del lock; l'altra metà è il Task 3.

---

## Chunk 1: Il lock atomico

Il pezzo che sblocca la parallelizzazione, e l'unico difetto **aperto** del
sistema attuale: il 13 agosto due run hanno preso la stessa issue.

### Task 2: Provare che il lock è davvero atomico

Prima di scriverlo in un prompt, va dimostrato che il meccanismo fallisce quando
deve. Questo non è un collaudo di prompt: è un fatto sull'API.

**Files:** nessuno (prova usa-e-getta).

- [ ] **Step 1: Scrivere l'atteso**

La prima creazione della ref riesce. La seconda, identica, risponde **422** con
`Reference already exists`. Un `git push` fast-forward sulla stessa ref invece
**riesce** — ed è il motivo per cui non va usato come lock.

- [ ] **Step 2: Provarlo**

```bash
cd ~/projects/predictionleagues && SHA=$(git rev-parse origin/main) && REF="refs/heads/claude/lock-test-$$"
echo "--- prima creazione ---"
gh api repos/lukedj78/predictionleagues/git/refs -X POST -f ref="$REF" -f sha="$SHA" --jq .ref
echo "--- seconda creazione (deve fallire) ---"
gh api repos/lukedj78/predictionleagues/git/refs -X POST -f ref="$REF" -f sha="$SHA" 2>&1 | head -3
echo "--- pulizia ---"
gh api "repos/lukedj78/predictionleagues/git/${REF}" -X DELETE && echo "ref cancellata"
```

Expected: la prima stampa il nome della ref; la seconda stampa un errore che
contiene `Reference already exists` (HTTP 422); la pulizia conferma.

**Se la seconda riesce**, tutto il capitolo sulla parallelizzazione va rifatto e
non si prosegue.

- [ ] **Step 3: Registrare l'esito nel corpus**

In `routine/corpus.md`, nuova sezione:

````markdown
## Il lock — non è un collaudo di prompt, è un fatto

Provato il 14 agosto su `lukedj78/predictionleagues`:

| operazione | esito |
|---|---|
| `POST /git/refs` su una ref nuova | crea |
| `POST /git/refs` sulla stessa ref | **422 `Reference already exists`** |
| `git push` fast-forward sulla stessa ref | **riesce** — per questo non serve come lock |

L'ultima riga è il motivo per cui il lock non può essere un push. Se un giorno
GitHub cambiasse questo comportamento, la parallelizzazione diventa insicura in
silenzio: rilanciare la prova del Task 2 del piano.
````

- [ ] **Step 4: Commit**

```bash
cd ~/projects/relay && git add routine/corpus.md && git commit -m "corpus: il lock atomico, provato invece che supposto"
```

---

### Task 3: Il lock nel prompt dell'autore

**Files:**
- Modify: `routine/prompt.md` (passo 5, e il passo 13)

- [ ] **Step 1: Sostituire il passo 5**

Il passo 5 attuale dice di mettere la label `night:wip`. Diventa:

````markdown
5. **Prendi il lock creando la ref del branch.** Non è una formalità: è l'unica
   cosa che impedisce a un altro run di lavorare sulla tua stessa issue.

   ```bash
   gh api repos/:owner/:repo/git/refs -X POST \
     -f ref="refs/heads/claude/<numero-issue>-<slug>" \
     -f sha="$(git rev-parse origin/main)"
   ```

   - **riesce** → il lavoro è tuo, prosegui
   - **`422 Reference already exists`** → l'ha preso un altro run: **torna al
     passo 4** e prendi la issue successiva. Non insistere, non forzare.

   Poi metti anche la label `night:wip` e commenta con il link alla sessione.
   **La label non è il lock**: è solo un'etichetta perché una persona capisca
   cosa sta succedendo guardando la board. Il lock è la ref, e solo quella.

   Perché non basta un `git push`: se il branch esiste già e il push è
   fast-forward, **riesce** — e due run si ritroverebbero sullo stesso branch
   convinti entrambi di averlo preso. È successo il 13 agosto con le label
   (PR #47 e #48), ed è lo stesso difetto in una forma diversa.
````

- [ ] **Step 2: Il rilascio del lock, nel passo 13**

Il passo 13 (ti sei fermato prima della fine) diventa:

````markdown
13. **Se ti sei fermato prima di aprire il PR**, rilascia il lock: cancella la
    ref che hai creato al passo 5, togli `night:wip`, e commenta sulla issue cosa
    è successo e a che passo.

    ```bash
    gh api "repos/:owner/:repo/git/refs/heads/claude/<numero-issue>-<slug>" -X DELETE
    ```

    **Un lock non rilasciato blocca quella issue per sempre**, e nessuno se ne
    accorge: la issue resta aperta, sembra disponibile, e ogni run che la prende
    riceve 422 e passa oltre. È il modo più silenzioso in cui questo sistema può
    smettere di funzionare.

    Se invece il PR è stato aperto, **non cancellare niente**: da lì in poi il
    branch serve, e lo cancella GitHub al merge.
````

- [ ] **Step 3: Verificare la coerenza interna**

```bash
cd ~/projects/relay && grep -n "night:wip" routine/prompt.md
```
Expected: le occorrenze rimaste devono essere tutte come *etichetta*, mai come
meccanismo di esclusione. Il passo 1 la usa ancora per filtrare la coda — va
bene, è un filtro leggibile, non una garanzia.

- [ ] **Step 4: Commit**

```bash
git add routine/prompt.md && git commit -m "prompt: il lock e' la ref del branch, non la label"
```

---

## Chunk 2: Le prove e la relazione

### Task 4: L'autore committa le prove

**Files:**
- Modify: `routine/prompt.md` (passi 9 e 11)

- [ ] **Step 1: Il passo 9 dice dove finisce lo screenshot**

Aggiungere in coda al terzo strato del passo 9:

````markdown
   Lo screenshot **va committato nel repository**, non allegato al PR:

   ```
   docs/evidence/PR-<numero>/<nome-parlante>.png
   ```

   Allegare immagini via API non funziona in questa sandbox e non ha mai
   funzionato: tutti i PR di questo progetto dicono «catturato ma non
   allegabile». Committate invece sono versionate, sopravvivono al PR, e
   diventano il materiale della relazione.

   Nel corpo del PR le linki con l'URL raw:
   `https://github.com/<owner>/<repo>/blob/<branch>/docs/evidence/PR-<n>/<file>.png?raw=true`

   Se non hai potuto catturare nulla — niente browser, rotta inesistente —
   **scrivilo**. «Nessuna prova visiva, perché …» è una riga legittima. Un PR
   che tace sull'assenza di prove è indistinguibile da uno che non ne aveva
   bisogno.
````

- [ ] **Step 2: Il passo 11 le richiede**

Nella lista dei contenuti del PR, sostituire `- lo screenshot` con:

```markdown
    - **le prove**: i link raw agli screenshot committati in
      `docs/evidence/PR-<n>/`, oppure la riga che spiega perché non ce ne sono
```

- [ ] **Step 3: Creare la cartella nel progetto**

```bash
cd ~/projects/predictionleagues && mkdir -p docs/evidence && printf 'Prove visive delle verifiche, una cartella per PR.\nCommittate dagli agenti, mai cancellate a mano.\n' > docs/evidence/README.md
```

- [ ] **Step 4: Commit**

```bash
cd ~/projects/relay && git add routine/prompt.md && git commit -m "prompt: le prove si committano, allegarle non ha mai funzionato"
```

---

### Task 5: La relazione

**Files:**
- Create: `predictionleagues/docs/relazione.md`
- Modify: `routine/docs-prompt.md`

- [ ] **Step 1: Creare il file con l'intestazione**

```markdown
# Relazione di sviluppo

Registro di cosa è stato costruito, da chi, come è stato verificato e cosa è
rimasto scoperto. Una voce per PR mergiato, in ordine cronologico inverso.

**Non è un riassunto.** È una trascrizione: le sezioni vengono dai corpi dei PR,
che le contengono già, più i link permanenti alle prove. Serve a rendere
leggibile fra sei mesi un lavoro fatto oggi, quando risalire a ritroso fra
ottanta PR non lo farà nessuno.

Ogni voce la scrive il documentatore al merge. **Non modificarla a mano**: se una
voce è sbagliata, è sbagliato il PR da cui viene, e va corretto lì.

---
```

- [ ] **Step 2: Aggiungere il passo al documentatore**

In `routine/docs-prompt.md`, il §1 «L'uscita rapida» oggi permette di terminare
subito. **Va spostato**: l'uscita rapida vale per la riconciliazione, non per la
relazione, che si scrive **sempre**.

Inserire prima del §1 attuale:

````markdown
## 0. La voce nella relazione — questa si scrive sempre

Prima di ogni altra cosa, appendi una voce a `docs/relazione.md`, subito sotto
l'intestazione (ordine cronologico inverso: la più recente in cima).

**Trascrivi, non riassumere.** Le sezioni esistono già nel corpo del PR: prendile
da lì. Se riscrivi con parole tue, fra un mese ci sono due racconti e nessuno sa
quale credere.

```markdown
## PR #<n> — <titolo> · <data del merge>

Issue #<n>. Branch `claude/<...>`.

**Cosa fa** — <dal PR>

**Decisioni prese** — <dal PR, o «nessuna»>

**Verificato** — <dal PR, con l'esito>

**Non verificato** — <dal PR: questa sezione è la più preziosa fra sei mesi>

**Verdetti del revisore** — <N confermate, N smentite, N non verificabili>
<se ci sono state correzioni: quante, e cosa è caduto>

**Prove** — <link raw a docs/evidence/PR-<n>/…, oppure «nessuna, perché …»>
```

Poi passa al §1.
````

E cambiare l'uscita del §1 da «TERMINA subito» a: «**passa oltre la
riconciliazione** e termina: la voce nella relazione l'hai già scritta».

- [ ] **Step 3: Aggiungere il caso al corpus**

````markdown
### F — la relazione si scrive anche quando non c'è nulla da riconciliare

**PR:** `lukedj78/predictionleagues#45`

Il caso E dice che questo PR non smentisce nessun documento. **Ma una voce nella
relazione la merita comunque**: ha aggiunto la CI, ed è una cosa che fra sei mesi
si vorrà sapere quando è entrata.

**Atteso:** una voce in `docs/relazione.md`, **e** «niente da riconciliare».
Se esce subito senza scrivere la voce, il §0 non sta funzionando — ed è
l'errore più probabile, perché il §1 invita a terminare.
````

- [ ] **Step 4: Lanciare il caso F**

```bash
cd ~/projects/predictionleagues && ~/projects/relay/bin/relay-dryrun ~/projects/relay/routine/docs-prompt.md lukedj78/predictionleagues 45
```
Expected: la voce della relazione **e** «niente da riconciliare».

- [ ] **Step 5: Commit**

```bash
cd ~/projects/relay && git add routine/docs-prompt.md routine/corpus.md && git commit -m "documentatore: la relazione si scrive a ogni merge, la riconciliazione no"
```

---

## Chunk 3: Il revisore mergia

### Task 6: Dare al revisore l'autorità di merge

**Files:**
- Modify: `routine/review-prompt.md` (§4 «Cosa NON fai», §5 «La review», regole assolute)

- [ ] **Step 1: Scrivere l'atteso, prima**

Nel corpus, il caso G:

````markdown
### G — il revisore mergia, e quando non deve non lo fa

Non c'è un PR storico che serva: questo caso si collauda **sul primo PR vero**,
perché è l'unico modo di vedere una decisione di merge.

**Atteso, sui due esiti:**

| situazione | cosa deve fare |
|---|---|
| zero smentite sostanziali, CI verde | **mergia**, con `--squash` |
| almeno una smentita sostanziale | **non mergia**, apre la correzione |
| solo smentite di misura | **mergia**, e le scrive nella review |
| CI rossa | **non mergia** — e non deve nemmeno poterlo fare: GitHub lo rifiuta |
| anteprima non apribile | **non mergia**, e lo dice in cima |

L'ultima riga è la più importante e la più facile da sbagliare: un revisore che
non ha potuto guardare l'anteprima non ha «zero smentite», ha **zero
osservazioni**. Le due cose si assomigliano e non sono la stessa.
````

- [ ] **Step 2: Riscrivere il §4**

Sostituire le due voci sul merge:

````markdown
- **Non riscrivi il codice.** Non pushi sul branch, non correggi. Se una
  affermazione cade, non è compito tuo rimediare: apre il correttore.
- **Mergi tu, ma solo alle condizioni del §5.** Non è un permesso generico: è una
  decisione con dei prerequisiti, e se anche uno solo non è soddisfatto non
  mergi.
- **Non mergi mai se non hai potuto aprire l'anteprima.** Non avere osservazioni
  non è la stessa cosa che non avere obiezioni.
````

- [ ] **Step 3: Riscrivere il §5**

````markdown
## 5. La review, e la decisione

Pubblica sempre la review. Poi decidi.

### Quando mergi

**Tutte e tre** devono essere vere:

1. nessuna **smentita sostanziale** (le smentite di misura non bloccano)
2. la CI è verde
3. **hai potuto aprire l'anteprima** — o il PR non tocca niente di osservabile
   (solo CI, solo documentazione, solo configurazione)

Allora:

```bash
gh pr review <n> --comment --body "<la review>"
gh pr merge <n> --squash
```

**`--comment`, mai `--approve`.** Non è una scelta di stile: le routine agiscono
con l'identità dell'utente, che è anche l'autore del PR, e **GitHub rifiuta
l'approvazione del proprio PR**. Un `--approve` fallirebbe a ogni giro. Il gate
non è un'approvazione, è il check `verify`, che GitHub fa rispettare da sé.

Il merge è **squash**: su questo repository `main` ha commit a un solo parent, e
la rete di revert dipende da quello.

### Quando non mergi

**Almeno una smentita sostanziale** → `REQUEST_CHANGES`, e commenta sul PR:

```
@correttore tentativo 1 di 2 — smentita da far cadere:
<l'affermazione, l'esperimento, il risultato>
```

Poi **fermati**. Il correttore parte da solo quando vede la review.

**Se sul PR ci sono già due commenti di tentativo**, non aprirne un terzo: metti
la label `needs-human`, commenta cosa è caduto in entrambi i giri, e fermati.

**Anteprima non apribile** → `COMMENT`, prima riga del verdetto, niente merge.

### Cosa non fai mai

- non mergi con la CI rossa (e non ci riusciresti: `main` è protetta)
- non togli `needs-human`
- non mergi un PR che ha `needs-human`
````

- [ ] **Step 4: Aggiornare la regola assoluta che ora si contraddice**

La regola `Mai approve, mai merge, mai push, mai chiudere issue` diventa:

```markdown
- **Mai push sul branch, mai chiudere una issue a mano.** Il merge la chiude da
  sé (`Closes #N`). Mergi **solo** alle tre condizioni del §5.
- **Mai `--approve`.** Giri con la stessa identità GitHub dell'autore, e GitHub
  rifiuta l'approvazione del proprio PR: fallirebbe sempre. La review si
  pubblica con `--comment`, e il gate è il check `verify`.
```

- [ ] **Step 5: Verificare che non sia rimasto un divieto orfano**

```bash
cd ~/projects/relay && grep -n -i "non mergi mai\|mai merge\|il merge è una decisione" routine/review-prompt.md
```
Expected: nessuna riga che vieti il **merge** in assoluto. Se ne resta una, il
prompt si contraddice — ed è il tipo di contraddizione che un agente risolve
scegliendo la regola che gli conviene.

Il divieto di `--approve` invece **deve** restare: quello non è una
contraddizione, è un vincolo di GitHub.

- [ ] **Step 6: Rilanciare i casi A e B, che potrebbero essere cambiati**

```bash
cd ~/projects/predictionleagues
~/projects/relay/bin/relay-dryrun ~/projects/relay/routine/review-prompt.md lukedj78/predictionleagues 45
```
Expected: come prima, zero smentite — **più** una decisione di merge esplicita.
Il PR #45 è già mergiato, quindi il collaudo deve dire *«avrei mergiato»*, non
provarci.

- [ ] **Step 7: Commit**

```bash
cd ~/projects/relay && git add routine/review-prompt.md routine/corpus.md && git commit -m "revisore: mergia, a tre condizioni"
```

---

## Chunk 4: Il correttore

### Task 7: Scrivere il prompt del correttore

**Files:**
- Create: `routine/fix-prompt.md`

- [ ] **Step 1: Scrivere il file**

````markdown
Sei il correttore. Un revisore ha smentito un'affermazione di questo PR. Il tuo
unico compito è **far cadere quella smentita**.

Sei una sessione autonoma: nessuno può rispondere a una domanda. Hai gli
strumenti GitHub già autenticati.

## 1. Cosa leggi

- l'ultima review del revisore: l'affermazione, l'esperimento, il risultato
- il diff del PR
- il commento `@correttore tentativo N di 2`

**Se non trovi una smentita sostanziale nell'ultima review, non fare niente.**
Commenta «nessuna smentita da correggere» e termina. Sei stato svegliato per
sbaglio, e inventare lavoro qui costa un run e sporca un PR.

## 2. Il mandato: stretto

Correggi **quella cosa**. Non il resto.

| tentazione | cosa fai |
|---|---|
| «già che ci sono sistemo anche…» | no |
| «questo codice si potrebbe migliorare» | no |
| «riscrivo l'approccio, era sbagliato in partenza» | no — quello è un `needs-human` |
| «l'affermazione era imprecisa, la riscrivo nel PR» | **solo** se il codice è giusto e la frase era sbagliata: allora correggi la frase e dillo |

Un correttore che allarga lo scope produce un secondo PR dentro il primo, e il
revisore al giro dopo ha più superficie da falsificare, non meno. È il modo in
cui questo ciclo va in loop.

## 3. Due esiti possibili

**Il codice era sbagliato** → correggilo, e verifica con lo stesso esperimento
che il revisore ha usato per smentirlo. Se non lo riproduci, non hai finito.

**L'affermazione era sbagliata, il codice no** → correggi il corpo del PR. Capita,
ed è un esito legittimo: «62 test» quando ne girano 58 si risolve scrivendo 58.

In entrambi i casi, aggiungi al corpo del PR:

```markdown
## Correzioni

- **Tentativo N** — smentita: «<affermazione>». <cosa hai cambiato, e come l'hai
  verificato con l'esperimento del revisore>
```

## 4. Quando ti fermi

- **se è il tentativo 2 e non ce l'hai fatta**: metti `needs-human`, commenta
  cosa hai provato e perché non ha funzionato, e fermati
- **se la correzione richiede una decisione di prodotto**: `needs-human` subito,
  senza consumare il secondo tentativo
- **se la smentita nasce da un difetto preesistente** che il PR non ha
  introdotto: non correggerlo qui. Apri una issue, linkala, e scrivi nel PR che
  l'affermazione va ristretta. Poi correggi l'affermazione.

## 5. Poi

Pusha sul branch. Il revisore riparte da solo: non chiamarlo, non riaprire il PR,
non fare altro.

## Regole assolute

- Mai push su `main`. Mai `--force`, `--amend`, `--no-verify`.
- Mai toccare `.env*`. Mai migrazioni distruttive.
- Mai togliere `needs-human`.
- Mai correggere più di quello per cui sei stato chiamato.
- Mai chiudere o riaprire il PR.
- Se fallisci, **commenta comunque**: un correttore silenzioso lascia il PR
  identico a com'era, e da fuori sembra che non sia mai partito.
````

- [ ] **Step 2: Aggiungere il caso al corpus**

````markdown
### H — il correttore non allarga lo scope

**PR:** `lukedj78/predictionleagues#48`, con la review del caso A come input.

Il caso A produce (dopo le correzioni del 14 agosto) una smentita sulla claim
della schermata: il `signal` non arriva alla Server Action, quindi il doppio
invio crea due righe.

**Atteso:** il correttore ha davanti una scelta, e deve prendere quella stretta.

- **giusto:** riconosce che far arrivare il `signal` alla Server Action è un
  cambiamento di comportamento fuori dallo scope di una issue di lint, apre una
  issue, e **restringe l'affermazione** nel corpo del PR
- **sbagliato:** riscrive il wizard per inoltrare il signal

Il secondo è «risolvere il problema» ed è esattamente l'errore: trasforma un PR
di lint in un PR di comportamento, che il revisore al giro dopo deve rifalsificare
da capo.
````

- [ ] **Step 3: Lanciare il caso H**

```bash
cd ~/projects/predictionleagues && ~/projects/relay/bin/relay-dryrun ~/projects/relay/routine/fix-prompt.md lukedj78/predictionleagues 48
```
Expected: restringe l'affermazione e apre una issue. Se riscrive il wizard,
rinforza la tabella del §2.

- [ ] **Step 4: Commit**

```bash
cd ~/projects/relay && git add routine/fix-prompt.md routine/corpus.md && git commit -m "prompt: il correttore, con il mandato piu' stretto dei quattro"
```

---

## Chunk 5: Le due reti

### Task 8: L'Action di revert

**Files:**
- Create: `relay/templates/revert-on-broken-main.yml`
- Create: `predictionleagues/.github/workflows/revert-on-broken-main.yml`

- [ ] **Step 1: Scrivere il workflow**

```yaml
name: revert-on-broken-main

# La rete del ciclo chiuso: se un merge automatico rompe main, lo si annulla
# senza aspettare che qualcuno guardi.
#
# È una Action e non una routine per due motivi: non serve giudizio, e i trigger
# delle routine coprono solo Pull request e Release — non esiste un evento
# "la CI è rossa su main" a cui agganciarsi.

on:
  workflow_run:
    workflows: [verify]
    types: [completed]
    branches: [main]

permissions:
  contents: write
  issues: write

jobs:
  revert:
    if: github.event.workflow_run.conclusion == 'failure'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
          fetch-depth: 10
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Decide whether to revert
        id: decide
        run: |
          SHA="${{ github.event.workflow_run.head_sha }}"
          SUBJECT=$(git log -1 --format=%s "$SHA")

          # Mai un revert di un revert: se il commit rotto è già un revert,
          # il problema non si risolve annullando ancora. Si chiama una persona.
          if printf '%s' "$SUBJECT" | grep -q '^Revert '; then
            echo "reason=already-a-revert" >> "$GITHUB_OUTPUT"
            echo "act=stop" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          # I merge di questo repo sono squash: un solo parent, quindi
          # `git revert <sha>` senza -m. Se un giorno passassero a merge
          # commit, questa riga va cambiata — e va notato, non indovinato.
          PARENTS=$(git rev-list --parents -n 1 "$SHA" | wc -w)
          if [ "$PARENTS" -ne 2 ]; then
            echo "reason=not-a-single-parent-commit" >> "$GITHUB_OUTPUT"
            echo "act=stop" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          echo "sha=$SHA" >> "$GITHUB_OUTPUT"
          echo "subject=$SUBJECT" >> "$GITHUB_OUTPUT"
          echo "act=revert" >> "$GITHUB_OUTPUT"

      - name: Revert
        if: steps.decide.outputs.act == 'revert'
        run: |
          git config user.name  "relay-safety-net"
          git config user.email "noreply@github.com"
          git revert --no-edit "${{ steps.decide.outputs.sha }}"
          git push origin main

      - name: Tell someone
        if: always() && steps.decide.outputs.act != ''
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          if [ "${{ steps.decide.outputs.act }}" = "revert" ]; then
            TITLE="main era rotto dopo un merge automatico — annullato"
            BODY="\`verify\` ha fallito su \`main\` dopo ${{ steps.decide.outputs.sha }} (${{ steps.decide.outputs.subject }}).
          Il commit è stato annullato con un revert.
          Run della CI: ${{ github.event.workflow_run.html_url }}

          Il ciclo automatico continua. Questa issue serve a capire **perché** il revisore ha mergiato qualcosa che rompe \`main\`: è un buco nella lista fissa dei controlli."
          else
            TITLE="main è rotto e non l'ho annullato"
            BODY="\`verify\` ha fallito su \`main\`, ma non ho fatto il revert: ${{ steps.decide.outputs.reason }}.
          Run della CI: ${{ github.event.workflow_run.html_url }}

          **Serve una persona.**"
          fi
          gh issue create --title "$TITLE" --body "$BODY" --label "priority:urgent" \
            --repo "${{ github.repository }}"
```

- [ ] **Step 2: Verificare la sintassi**

```bash
cd ~/projects/predictionleagues && python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/revert-on-broken-main.yml')); print('yaml valido')"
```
Expected: `yaml valido`.

- [ ] **Step 3: Provare la logica di decisione, senza aspettare un guasto**

La parte che può sbagliare non è YAML, è lo script. Provalo isolato:

```bash
cd ~/projects/predictionleagues
for SHA in $(git rev-parse main) $(git log --format=%H --grep='^Revert ' -1 main); do
  [ -z "$SHA" ] && continue
  SUBJECT=$(git log -1 --format=%s "$SHA")
  PARENTS=$(git rev-list --parents -n 1 "$SHA" | wc -w)
  printf '%.9s  parents=%s  revert=%s  → %s\n' "$SHA" "$PARENTS" \
    "$(printf '%s' "$SUBJECT" | grep -qc '^Revert ' && echo si || echo no)" \
    "$( [ "$PARENTS" -eq 2 ] && echo revert || echo stop )"
done
```
Expected: sui commit squash di `main`, `parents=2` (lo sha più il suo parent) e
`→ revert`.

- [ ] **Step 4: Copiare il template in `relay`**

```bash
cp ~/projects/predictionleagues/.github/workflows/revert-on-broken-main.yml ~/projects/relay/templates/
```

- [ ] **Step 5: Commit in entrambi i repo**

```bash
cd ~/projects/predictionleagues && git add .github/workflows/revert-on-broken-main.yml docs/evidence docs/relazione.md && git commit -m "ci: annulla il merge se main si rompe, e apre una issue"
cd ~/projects/relay && git add templates/revert-on-broken-main.yml && git commit -m "templates: l'Action di revert, per gli altri progetti"
```

---

### Task 9: Lo spazzino

**Files:**
- Create: `routine/sweeper-prompt.md`

- [ ] **Step 1: Scrivere il file**

````markdown
Sei lo spazzino. Il tuo compito è trovare i PR rimasti fermi e rimetterli in
moto. Non giudichi codice, non mergi, non correggi.

**Perché esisti:** gli eventi webhook di GitHub hanno tetti orari, e quelli in
eccesso **vengono scartati**. Quando succede, un PR resta fermo per sempre: il
revisore non è mai partito e non partirà. Tu giri a orario, e le routine a orario
non passano dai webhook — quindi sei l'unico pezzo del sistema che non può essere
zittito dallo stesso meccanismo che deve compensare.

## Cosa cerchi

I PR **aperti** del repository che sono, tutti insieme:

- senza `needs-human`
- fermi da **più di un'ora** (nessun commit, nessuna review, nessun commento)
- in uno di questi stati:
  - nessuna review del revisore, e la CI ha finito
  - ultima review con smentita sostanziale, ma nessun commit dopo di essa
    (il correttore non è mai partito)
  - ultimo commit dopo l'ultima review (il correttore ha pushato, il revisore
    non è ripartito)

## Cosa fai

Per ciascuno, **uno solo** di questi, e poi passa al successivo:

```bash
gh pr close <n> && gh pr reopen <n>
```

Chiudere e riaprire rigenera l'evento `reopened`, che fa ripartire il revisore.
È rozzo ed è deliberato: è l'unica azione che non richiede di indovinare in quale
punto del ciclo il PR si sia fermato.

Commenta sul PR:

```
Rimesso in moto dallo spazzino: fermo da <quanto> allo stato <quale>.
Probabile evento webhook scartato.
```

## I limiti

- **Massimo tre PR per run.** Se ce ne sono di più, prendi i tre più vecchi e
  dillo nel log. Rimetterne in moto venti insieme rigenera venti eventi e li fa
  scartare di nuovo — peggiorando esattamente la cosa che devi curare.
- **Massimo due volte per lo stesso PR.** Se un PR è già stato rimesso in moto
  due volte e si ferma ancora, non è un evento perso: è qualcosa di rotto. Metti
  `needs-human` e commenta.
- **Se non trovi niente, TERMINA dicendo «nessun PR fermo».** È il caso normale.

## Regole assolute

- Mai mergiare, mai pushare, mai correggere, mai togliere label.
- Mai toccare un PR con `needs-human`.
- Mai chiudere un PR senza riaprirlo subito. Se la riapertura fallisce,
  **riprova una volta**, poi commenta e fermati: un PR chiuso e non riaperto è
  un danno peggiore di uno fermo.
````

- [ ] **Step 2: Commit**

```bash
cd ~/projects/relay && git add routine/sweeper-prompt.md && git commit -m "prompt: lo spazzino, perche' gli eventi webhook si perdono"
```

---

## Chunk 6: I documenti di `relay`

### Task 10: Riscrivere `docs/cadences.md`

**Files:**
- Rewrite: `docs/cadences.md`

- [ ] **Step 1: Riscrivere**

Il file oggi spiega tre cadenze per una routine, e in coda tre routine. Con
cinque routine e due Action non regge più: va riscritto attorno al **ciclo**, non
attorno ai trigger.

Struttura nuova:

1. **Il ciclo in un diagramma** (quello della spec §2)
2. **Chi parte quando** — tabella: routine, trigger, cosa consuma
3. **Cosa costa un'issue** — 4–6 run dall'apertura al merge, e cosa succede se si
   parallelizza
4. **I due tetti**: quello giornaliero sui run, e quello orario sui webhook, con
   la spiegazione di perché il secondo richiede lo spazzino
5. **In che ordine accendere** — il Task 12
6. La nota sul nome `nightly`, che resta

- [ ] **Step 2: Commit**

```bash
git add docs/cadences.md && git commit -m "docs: le cadenze descrivono il ciclo, non piu' i trigger"
```

---

### Task 11: `relay-init` e il README

**Files:**
- Modify: `bin/relay-init`, `README.md`

- [ ] **Step 1: `relay-init` stampa i prerequisiti prima delle routine**

Il blocco finale diventa: prima **i tre interruttori** del Task 1 (`verify`
obbligatoria, anteprime apribili, `delete_branch_on_merge`), poi le cinque
routine, poi le due Action da copiare da `templates/`.

I prerequisiti vanno **prima** perché senza di essi il ciclo si accende e non
funziona — e non funziona in silenzio.

- [ ] **Step 2: Aggiungere il controllo automatico a `relay-init --check`**

```bash
# ─── Prerequisiti del ciclo chiuso ───────────────────────────────────────────
# Non bloccano relay-init, ma senza il ciclo si accende e gira a vuoto.

REQUIRED=$(gh api "repos/$GH_OWNER/$SLUG/branches/main/protection" \
  --jq '.required_status_checks.contexts | join(",")' 2>/dev/null || echo "")
[ -n "$REQUIRED" ] && ok "main protetta, check richiesti: $REQUIRED" \
                   || warn "main NON protetta — il revisore potra' mergiare con la CI rossa"

DELBR=$(gh api "repos/$GH_OWNER/$SLUG" --jq .delete_branch_on_merge 2>/dev/null || echo "?")
[ "$DELBR" = "true" ] && ok "i branch si cancellano al merge (il lock si rilascia)" \
                      || warn "delete_branch_on_merge=false — i lock resteranno appesi"
```

- [ ] **Step 3: Riscrivere la sezione «I tre agenti» del README**

Diventa cinque, più le due Action, più la frase che oggi manca: **cosa ti resta da
fare**, che nel ciclo chiuso è *leggere la relazione e riscrivere le issue in
`needs-human`*.

Correggere anche la tabella «Cosa fa e cosa non fa», dove `mergia su main` è
nella colonna «Non fa».

- [ ] **Step 4: Verificare i link e la sintassi**

```bash
cd ~/projects/relay && bash -n bin/relay-init && grep -oE '\]\([^)]+\)' README.md | sed -E 's/^\]\(//; s/\)$//' | grep -v '^http' | while read -r f; do [ -e "${f%%#*}" ] || echo "ROTTO: $f"; done && echo ok
```
Expected: `ok`, nessun link rotto.

- [ ] **Step 5: Commit**

```bash
git add bin/relay-init README.md && git commit -m "relay-init e README: cinque agenti, due reti, tre interruttori"
```

---

## Chunk 7: L'accensione

### Task 12: Accendere, in ordine, guardando

**Files:** nessuno. Cinque form e molta pazienza.

- [ ] **Step 1: Verificare i tre interruttori del Task 1**

Se anche uno solo non passa, **fermati qui**. Il ciclo acceso senza di essi
mergia alla cieca.

- [ ] **Step 2: Accendere in questo ordine**

| # | routine | trigger | quando accenderla |
|---|---|---|---|
| 1 | autore | `Schedule` giornaliero | subito, è già viva |
| 2 | revisore | `pull_request` opened + reopened + **synchronize**, filtro: label **non contiene** `needs-human` | dopo che l'autore ha aperto un PR e l'hai letto tu |
| 3 | correttore | `pull_request` — reagisce alla review, filtro: label non contiene `needs-human` | dopo aver visto **una** review del revisore che avresti condiviso |
| 4 | documentatore | `pull_request` closed, is merged = true | dopo il primo merge automatico riuscito |
| 5 | spazzino | `Schedule` orario | per ultima, e solo se vedi PR fermi |

**Non accendere il 2 e il 3 insieme.** Il correttore senza revisore non fa
niente; il revisore senza correttore lascia PR fermi che tu vedi. Il secondo è un
modo sicuro di misurare il primo.

- [ ] **Step 3: Il primo merge automatico si guarda**

Quando il revisore mergia per la prima volta senza di te, aprilo e chiediti tre
cose:

1. **avrebbe dovuto?** — cioè: lo avresti mergiato tu
2. **ha guardato l'anteprima?** — se non la nomina, il gate più importante non
   sta funzionando
3. **la relazione ha una voce leggibile?** — perché è l'unica cosa che ti resterà
   fra sei mesi

- [ ] **Step 4: Le soglie, decise adesso e non dopo**

Dalla spec §13, scritte qui perché siano operative:

- **più di un revert** in due settimane → si toglie il merge automatico
- **lo spazzino interviene più di una volta al giorno** → i tetti webhook sono il
  vincolo vero: si abbassa la parallelizzazione, non si alza
- **più del 20% dei PR finisce in `needs-human`** → il correttore non serve, e il
  revisore va reso meno aggressivo

Sono numeri, non impressioni. Scriverli prima è ciò che impedisce di difendere il
sistema per affezione quando non funziona.

---

## Cosa questo piano non fa

- **Non sceglie N autori paralleli.** Il lock lo rende possibile, ma il vincolo
  che morde è la quota, non il lock. Si parte da due, si misura una settimana.
- **Non tocca `predictionleagues` oltre i tre file** (`revert-on-broken-main.yml`,
  `docs/relazione.md`, `docs/evidence/`). Il resto è lavoro del ciclo, non del
  piano.
- **Non riempie la relazione a ritroso.** Le voci storiche dei 18 PR già mergiati
  si potrebbero generare, ma sarebbero una ricostruzione, non una trascrizione —
  e la relazione vale perché è la seconda cosa. Si parte dal primo merge nuovo.
