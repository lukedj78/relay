Fai avanzare il progetto di UN passo. Un solo task, un solo PR.

Sei una sessione autonoma: nessuno sta guardando e nessuno puo' rispondere a una
domanda. Tutto cio' che non e' scritto qui non esiste.

## Scegliere il lavoro

Nessuno ti mette il lavoro in coda: **sei tu a leggerla**. Non esiste una
colonna "pronto per te" da cui pescare — la board e' quella che e', e sta a te
capire cosa e' aggredibile stanotte.

1. Chiedi a Linear tutti gli issue del progetto, **esclusi**:
   - quelli gia' completati o cancellati
   - quelli in "In Progress" o "In Review" (li ha presi un altro run, o
     aspettano una review umana)
   - quelli con label `needs-spec` o `blocked` (gia' scartati, da un run
     precedente o da una persona)

2. **Scarta i bloccati.** Un issue non e' aggredibile se:
   - ha una relazione Linear "blocked by" verso un issue non ancora completato
   - e' un sotto-issue il cui padre dichiara un prerequisito aperto
   - la sua descrizione nomina un task precedente che non e' ancora `Done`
   - il suo titolo e' numerato (`T3 — ...`, `Task 3: ...`) ed esiste un task
     con numero piu' basso ancora aperto

   I task numerati si eseguono **in ordine**. Non saltare avanti.

3. **Ordina** quelli rimasti per: priorita' Linear (Urgent → High → Medium →
   Low → None), poi per numero di task crescente, poi per data di creazione.

4. Prendi il primo. **Se non ne resta nessuno, TERMINA dicendo "niente di
   aggredibile stanotte"** e spiega in una riga perche' — coda vuota, tutto
   bloccato, tutto gia' in review. Non inventare lavoro, non "gia' che ci sono".

5. Sposta l'issue scelto in "In Progress" e commenta con la data e il link a
   questa sessione. **E' il lock** che impedisce a un altro run di prendere lo
   stesso lavoro.

## Il gate di qualita'

6. Prima di scrivere una riga, guarda l'issue che hai preso. Se una di queste
   e' vera:
   - non ha criteri di accettazione verificabili
   - richiede una decisione di prodotto
   - richiederebbe di scegliere una libreria (UI, form, stato, qualsiasi)

   allora **non implementarlo**: commenta su Linear cosa manca esattamente,
   rimettilo nello stato in cui l'hai trovato con label `needs-spec`, e
   **torna al passo 4 per prendere il successivo**.

   Un issue scritto male non deve costarti la notte. Fai al massimo **tre**
   tentativi: se dopo tre nessun issue supera il gate, termina e dillo.

## Il lavoro

7. Leggi `.workflow/meta.json`, prendi il campo `phase`, e invoca la skill
   `dev-flow`: dice quale specialista e' competente. Segui quello che dice.
   - progetto non ancora scaffoldato → `design-md-to-app`, oppure
     `monorepo-bootstrap` / `rn-bootstrap` secondo `meta.json#stack.framework`
   - app gia' presente → `screenshot-to-page`, `module-add`, `forms`,
     `data-fetching` o `write-tests`, secondo l'issue

   **Non scaffoldare due volte.** Se l'app esiste gia', il bootstrap e' finito.

8. Implementa. Regole del codice, non negoziabili:
   - identificatori, nomi di file e rotte in **inglese**
   - commenti, messaggi di commit e testi dell'interfaccia in **italiano**
   - i18n dal primo giorno (next-intl, locali `en` + `it`): nessuna stringa
     utente hardcoded

9. Verifica in tre strati, in quest'ordine. Se uno fallisce, non passare al
   successivo: sistema, o vai al passo 12.
   - `pnpm tsc --noEmit`
   - la suite di test
   - avvia i servizi (`service postgresql start`, migrazioni, dev server), apri
     la rotta che hai toccato e fai uno **screenshot**

   Un build verde non e' una verifica. Se non hai aperto la pagina, non l'hai
   verificata.

10. Apri un PR sul branch `claude/<issue-id>-<slug>`. Nel corpo:
    - cosa fa, in due righe
    - cosa hai verificato, con l'esito
    - lo screenshot
    - una sezione **"cosa NON ho verificato"** — obbligatoria, mai vuota

11. Sposta l'issue in "In Review" e incolla il link al PR.

12. **Se ti sei fermato prima della fine**, riporta l'issue nello stato in cui
    l'hai trovato e commenta su Linear cosa e' successo e a che passo. Non
    lasciarlo in "In Progress": bloccherebbe la notte dopo.

## Regole assolute

- Mai push su `main`. Mai `--no-verify`, `--amend`, `--force`.
- Mai toccare `.env*`.
- Mai migrazioni distruttive: niente `DROP`, niente colonne rimosse.
- Mai scegliere una libreria. Se serve, e' un `needs-spec` (passo 6).
- **Se sei bloccato, FERMATI e scrivilo su Linear.** Un workaround e' il segnale
  di fermarsi, non di proseguire. Non c'e' nessuno sveglio a cui il workaround
  sembri sospetto.
- Se la documentazione di una libreria ti serve, leggi quella ufficiale online.
  Non fidarti delle copie in `node_modules`.
- **Se fallisci a qualsiasi passo, commenta comunque su Linear** cosa e'
  successo e dove ti sei fermato. Un run silenzioso e' peggio di un run
  fallito: da fuori sembrano uguali.
