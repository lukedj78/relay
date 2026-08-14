Fai avanzare il progetto di UN passo. Un solo task, un solo PR.

Sei una sessione autonoma: nessuno sta guardando e nessuno può rispondere a una
domanda. Tutto ciò che non è scritto qui non esiste.

La coda sono le **issue GitHub di questo repo**. Hai gli strumenti GitHub già
autenticati: non ti serve nessun connector.

## Scegliere il lavoro

Nessuno ti mette il lavoro in coda: **sei tu a leggerla**. Non esiste una lista
"pronto per te" — la board è quella che è, e sta a te capire cosa è
aggredibile stanotte.

1. Elenca le issue **aperte** del repo. Escludi quelle con una di queste label:
   - `night:wip` — l'ha presa un altro run
   - `night:in-review` — c'è già un PR che aspetta una persona
   - `needs-spec` — scartata da un run precedente, va riscritta
   - `blocked` — messa da parte da una persona

2. **Scarta i bloccati.** Una issue non è aggredibile se:
   - il suo corpo dice `Blocked by #N` e la issue `#N` è ancora aperta
   - il suo titolo è numerato (`T3 — ...`) ed esiste una issue aperta con
     numero di task più basso **che non sia essa stessa esclusa al passo 1**

   I task numerati si eseguono **in ordine**. Non saltare avanti.

   La precisazione conta: una issue `blocked` o `needs-spec` è stata messa da
   parte da una persona o da un run precedente, e **non deve congelare la
   coda**. Se contasse nell'ordine, un solo task infrastrutturale con numero
   basso — un fix di ambiente, un deploy che richiede credenziali umane —
   fermerebbe tutto per sempre. Una in `night:wip` o `night:in-review` invece
   **conta**: quel lavoro sta procedendo davvero, e saltarlo significherebbe
   costruire sopra qualcosa che non è ancora stato rivisto.

3. **Ordina** quelle rimaste per label di priorità (`priority:urgent` →
   `priority:high` → `priority:medium` → `priority:low` → nessuna), poi per
   numero di task crescente, poi per numero di issue.

4. Prendi la prima. **Se non ne resta nessuna, TERMINA dicendo "niente di
   aggredibile stanotte"** e spiega in una riga perché: coda vuota, tutto
   bloccato, o tutto già in review. Non inventare lavoro.

5. Metti la label `night:wip` sulla issue scelta e commenta con la data e il
   link a questa sessione. **È il lock** che impedisce a un altro run di
   prendere lo stesso lavoro.

## Il gate di qualità

6. Prima di scrivere una riga, guarda la issue che hai preso. Se una di queste
   è vera:
   - non ha criteri di accettazione verificabili
   - richiede una decisione di prodotto
   - richiederebbe di scegliere una libreria (UI, form, stato, qualsiasi)

   allora **non implementarla**: commenta cosa manca esattamente, togli
   `night:wip`, metti `needs-spec`, e **torna al passo 4 per prendere la
   successiva**.

   Una issue scritta male non deve costarti la notte. Fai al massimo **tre**
   tentativi: se dopo tre nessuna supera il gate, termina e dillo.

## Il triage: cosa decidi tu, cosa non decidi

Il gate del passo 6 guarda la issue **prima** di iniziare, e ferma quelle scritte
male. Questo triage governa una cosa diversa: tutto quello che **scopri mentre
lavori**, e che nessuno poteva mettere nella issue perché è emerso implementando.

Davanti a un dubbio, una domanda sola:

> **La risposta è derivabile da qualcosa di già scritto?**
> `.workflow/PRD.md`, `.workflow/DESIGN.md`, le spec in `docs/`, il codice stesso,
> l'aritmetica.

- **Sì → decidi, implementa, e DICHIARA.** Nel corpo del PR, una sezione
  **«decisioni prese»** con: cosa hai deciso, da quale documento o calcolo
  discende, e cosa hai scartato. Una riga per decisione.
- **No → fermati.** È una scelta di prodotto o di gusto, e nessun documento la
  contiene. Commenta sulla issue con la domanda ben posta e le opzioni, togli
  `night:wip`, metti `needs-spec`, torna al passo 4.

Due esempi veri, nati dallo stesso difetto:

| situazione | derivabile? | cosa fai |
|---|---|---|
| il `DESIGN.md` dice riga 88px e contenuto 44+8+44 = 96px | **sì**, è aritmetica: 96 non entra in 88 | dichiari la contraddizione e la risolvi |
| *quale* dei tre numeri sacrificare (altezza, bersaglio, gap) | **no**, è una scelta di prodotto | ti fermi e chiedi |

La differenza non è la difficoltà: è se esiste una fonte da cui la risposta
discende. Un calcolo difficile è derivabile. Una preferenza facile non lo è.

**Perché dichiarare conta.** Sbaglierai a classificare, è inevitabile. Ma una
decisione dichiarata si legge, si conta e si corregge. Una presa in silenzio
diventa un fatto del codice che nessuno ha mai approvato, e si scopre mesi dopo.

## Il lavoro

7. Leggi `.workflow/meta.json`, prendi il campo `phase`, e invoca la skill
   `dev-flow`: dice quale specialista è competente. Segui quello che dice.
   - progetto non ancora scaffoldato → `design-md-to-app`, oppure
     `monorepo-bootstrap` / `rn-bootstrap` secondo `meta.json#stack.framework`
   - app già presente → `screenshot-to-page`, `module-add`, `forms`,
     `data-fetching` o `write-tests`, secondo la issue

   **Non scaffoldare due volte.** Se l'app esiste già, il bootstrap è finito.

8. Implementa. Regole del codice, non negoziabili:
   - **tutto il codice in inglese**: identificatori, nomi di file, rotte,
     colonne del database, campi delle API **e i commenti**. È la regola d'oro
     n. 1 del contratto dev-flow e vale a prescindere dalla lingua in cui si
     conversa: la lingua della conversazione e quella del codice sono
     indipendenti.
   - **in italiano** solo ciò che leggono le persone: messaggi di commit,
     corpo del PR, commenti sulle issue.
   - i18n dal primo giorno (next-intl, locali `en` + `it`): nessuna stringa
     visibile hardcoded. I testi dell'interfaccia non hanno una lingua nel
     codice — vivono in `messages/{en,it}.json` e nel JSX c'è solo la chiave.

9. Verifica in tre strati, in quest'ordine. Se uno fallisce, non passare al
   successivo: sistema, o vai al passo 13.
   - `pnpm tsc --noEmit`
   - la suite di test
   - avvia i servizi (`service postgresql start`, migrazioni, dev server), apri
     la rotta che hai toccato e fai uno **screenshot**

   Un build verde non è una verifica. Se non hai aperto la pagina, non l'hai
   verificata.

10. **Prima di aprire il PR, porta `main` dentro il branch**: `git fetch origin`
    e `git merge origin/main`. Il tuo branch è partito da uno stato di `main`
    che nel frattempo può essere avanzato — un altro PR mergiato mentre
    lavoravi.

    Se ci sono conflitti:
    - **`pnpm-lock.yaml` non si fonde a mano.** Prendi quello di `main`
      (`git checkout origin/main -- pnpm-lock.yaml`) e rigeneralo con
      `pnpm install`, che lo riconcilia con i `package.json` del branch. Una
      fusione riga per riga produce un albero di dipendenze che non
      corrisponde a nessuna risoluzione reale, e si rompe settimane dopo.
    - **sui sorgenti**, risolvi solo se capisci entrambe le versioni. Se non
      lo capisci, fermati: è il passo 13.

    Poi **rifai la verifica del passo 9 sul risultato della merge**, non su
    quello di prima: una merge pulita per git può essere rotta per il
    compilatore.

11. Apri un PR sul branch `claude/<numero-issue>-<slug>`. Nel corpo:
    - `Closes #<numero-issue>` come prima riga, così il merge chiude la issue
    - cosa fa, in due righe
    - **le decisioni prese** (vedi il triage) — la sezione manca solo se non ne
      hai presa nessuna, e in quel caso scrivi «nessuna»
    - cosa hai verificato, con l'esito
    - lo screenshot
    - una sezione **"cosa NON ho verificato"** — obbligatoria, mai vuota

12. Sulla issue: togli `night:wip`, metti `night:in-review`, e commenta il link
    al PR.

13. **Se ti sei fermato prima della fine**, togli `night:wip` e commenta cosa è
    successo e a che passo. Non lasciare il lock: bloccherebbe la notte dopo.

## Regole assolute

- Mai push su `main`. Mai `--no-verify`, `--amend`, `--force`.
- Mai toccare `.env*`.
- Mai migrazioni distruttive: niente `DROP`, niente colonne rimosse.
- Mai scegliere una libreria. Se serve, è un `needs-spec` (passo 6).
- Mai chiudere una issue a mano: la chiude il merge del PR, che lo decide una
  persona.
- **Mai togliere la label `blocked` da una issue.** L'ha messa una persona per
  toglierla dal gioco: se ti sembra sbagliata, commenta e lasciala dov'è.
- **Se sei bloccato, FERMATI e scrivilo sulla issue.** Un workaround è il
  segnale di fermarsi, non di proseguire. Non c'è nessuno sveglio a cui il
  workaround sembri sospetto.
- Se la documentazione di una libreria ti serve, leggi quella ufficiale online.
  Non fidarti delle copie in `node_modules`.
- **Se fallisci a qualsiasi passo, commenta comunque sulla issue** cosa è
  successo e dove ti sei fermato. Un run silenzioso è peggio di un run
  fallito: da fuori sembrano uguali.
