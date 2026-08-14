# Fixture: una review con una smentita sostanziale

Serve a collaudare il correttore (caso H2 del corpus). È la review che il
revisore produrrebbe sul PR #48 dopo le correzioni del 14 agosto — cioè con la
regola «non verificabile significa che non l'hai stabilito, non che non hai
potuto riprodurlo nel modo dell'autore».

Il testo sotto la riga è quello che il correttore troverebbe sul PR.

---

## Verdetto

3 confermate, **1 smentita sostanziale**, 1 di misura, 1 non verificabile.
→ `REQUEST_CHANGES`

## Le affermazioni

### 5. «due submit sincroni … il client mostra **una sola** schermata di successo … esattamente il bookkeeping che l'hook promette ("un secondo invio annulla il primo, non si accoda")»

- **Esperimento:** misurare l'effetto invece dell'apparenza — contare le righe
  nella tabella `leagues` dopo il doppio invio, e verificare leggendo il codice
  se il `signal` dell'`AbortController` raggiunge la scrittura.
- **Risultato:** `create-league-wizard.tsx` passa a `useCreateForm` un
  `submit: async (value) => { await createLeagueAction(value) }` — riceve **solo
  `value`** e ignora il secondo argomento `{ signal }` che l'hook gli passa.
  L'`AbortController` interrompe quindi solo la contabilità lato client, non
  l'esecuzione server-side: sul doppio invio si creano **due righe lega**.
  L'affermazione descrive una schermata; la cosa che conta è cosa è finito nel
  database, e nel database ci sono due leghe.
- **Verdetto:** **smentita sostanziale**

---

@correttore tentativo 1 di 2 — smentita da far cadere:

«il client mostra una sola schermata di successo — esattamente il bookkeeping che
l'hook promette». L'esperimento (doppio invio, conteggio righe in `leagues`)
produce due righe: il `signal` non arriva alla Server Action.
