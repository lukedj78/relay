Fai avanzare il progetto di UN passo. Un solo task, un solo PR.

Sei una sessione autonoma: nessuno sta guardando e nessuno puo' rispondere a una
domanda. Tutto cio' che non e' scritto qui non esiste.

## Il lavoro

1. Leggi `.workflow/meta.json` e prendi il campo `phase`.

2. Chiedi a Linear il primo issue in stato "Ready" della milestone corrente,
   ordinato per priorita'. **Se la coda e' vuota, TERMINA dicendo "coda vuota".**
   Non cercare altro lavoro, non inventare task, non "gia' che ci sono".

3. Sposta l'issue in "In Progress" e commenta con la data e il link a questa
   sessione. E' il lock che impedisce a un altro run di prendere lo stesso
   lavoro.

4. Invoca la skill `dev-flow`: legge `meta.json` e dice quale specialista e'
   competente per questa `phase`. Segui quello che dice.
   - progetto non ancora scaffoldato → `design-md-to-app`, oppure
     `monorepo-bootstrap` / `rn-bootstrap` secondo `meta.json#stack.framework`
   - app gia' presente → `screenshot-to-page`, `module-add`, `forms`,
     `data-fetching` o `write-tests`, secondo l'issue
   **Non scaffoldare due volte.** Se l'app esiste gia', il bootstrap e' finito.

5. **Il gate.** Se una di queste e' vera:
   - l'issue non ha criteri di accettazione verificabili
   - richiede una decisione di prodotto
   - richiederebbe di scegliere una libreria (UI, form, stato, qualsiasi)

   allora **NON implementare**. Commenta su Linear cosa manca esattamente,
   rimetti l'issue in "Ready" con label `needs-spec`, e termina.
   Fermarsi qui e' un esito corretto, non un fallimento.

6. Implementa. Regole del codice, non negoziabili:
   - identificatori, nomi di file e rotte in **inglese**
   - commenti, messaggi di commit e testi dell'interfaccia in **italiano**
   - i18n dal primo giorno (next-intl, locali `en` + `it`): nessuna stringa
     utente hardcoded

7. Verifica in tre strati, in quest'ordine. Se uno fallisce, non passare al
   successivo: sistema, o vai al passo 9.
   - `pnpm tsc --noEmit`
   - la suite di test
   - avvia i servizi (`service postgresql start`, migrazioni, dev server), apri
     la rotta che hai toccato e fai uno **screenshot**

   Un build verde non e' una verifica. Se non hai aperto la pagina, non l'hai
   verificata.

8. Apri un PR sul branch `claude/<issue-id>-<slug>`. Nel corpo:
   - cosa fa, in due righe
   - cosa hai verificato, con l'esito
   - lo screenshot
   - una sezione **"cosa NON ho verificato"** — obbligatoria, mai vuota

9. Sposta l'issue in "In Review" e incolla il link al PR.

## Regole assolute

- Mai push su `main`. Mai `--no-verify`, `--amend`, `--force`.
- Mai toccare `.env*`.
- Mai migrazioni distruttive: niente `DROP`, niente colonne rimosse.
- Mai scegliere una libreria. Se serve, e' un `needs-spec` (passo 5).
- **Se sei bloccato, FERMATI e scrivilo su Linear.** Un workaround e' il segnale
  di fermarsi, non di proseguire. Non c'e' nessuno sveglio a cui il workaround
  sembri sospetto.
- Se la documentazione di una libreria ti serve, leggi quella ufficiale online.
  Non fidarti delle copie in `node_modules`.
- **Se fallisci a qualsiasi passo, commenta comunque su Linear** cosa e'
  successo e a che passo ti sei fermato. Un run silenzioso e' peggio di un run
  fallito: da fuori sembrano uguali.
