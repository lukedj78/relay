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

**Atteso:** almeno **una smentita**. L'esperimento giusto conta le righe nella
tabella `leagues` dopo il doppio invio, non le schermate. Un revisore che legge
«una sola schermata di successo» e la conferma senza guardare il database ha
ripetuto esattamente l'errore che deve intercettare.

**Non è atteso** che dica che il PR è sbagliato: il fix di lint è corretto. È
attesa la smentita dell'**affermazione**, che è cosa diversa dal PR.

### B — il PR onesto

**PR:** `lukedj78/predictionleagues#45`

Aggiunge il workflow CI. Le sue affermazioni sono poche, verificabili e vere.

**Atteso:** **zero smentite.** Verdetti «confermata» o «non verificabile»,
nessun blocco.

Questo caso pesa quanto A. Un corpus di soli difetti produce un revisore che
trova sempre qualcosa, e un revisore che trova sempre qualcosa viene spento.

---

## Corpus del documentatore

### D — quattro fatti smentiti e una decisione da non toccare

**PR:** `lukedj78/predictionleagues#35` (schema di lega, partecipanti e ruleset)

Quel merge ha implementato le entità che la spec del 12 agosto descriveva al
§4.1, **discostandosene in quattro punti**, e non ha corretto una riga della
spec.

Fatti diventati falsi — il documentatore li **corregge**:

| la spec dice | il codice fa |
|---|---|
| `league.join_code` | la colonna si chiama `invite_code` |
| `scoring_ruleset.config` (jsonb, struttura `ScoringRuleSet`) | colonne piatte: `exact_score_points`, `correct_outcome_points`, … |
| `scoring_ruleset.is_preset` | non esiste |
| esiste un'entità `competition` | non c'è nessuna tabella `competition` — `league_competitions.competition_code` è un codice, non una FK |

Decisione da **non toccare, solo segnalare**:

> «Le righe sono **immutabili**: cambiare le regole significa creare una versione
> nuova, non modificarne una esistente, altrimenti i `scoring_run` storici
> perdono significato.»

Lo schema non impone nulla del genere: nessun trigger, nessuna colonna che lo
renda vero. Ma quella frase **non è un fatto sbagliato, è un requisito non ancora
implementato**. Cancellarla o ammorbidirla per «allinearla al codice»
significherebbe far sparire un vincolo di prodotto scrivendo che non è mai
esistito.

**Atteso:** quattro correzioni e una segnalazione. Gli errori che contano sono
due, in direzioni opposte:

- se **corregge anche la riga sull'immutabilità** (o la cancella), il triage
  fatti/decisioni non funziona — ed è il fallimento grave, perché distrugge
  informazione
- se **si limita a segnalare tutto** senza correggere niente, è inutile ma
  innocuo

Il primo tipo di errore vale più del secondo. Un documentatore troppo timido si
migliora; uno che riscrive le decisioni ha già perso qualcosa.

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
