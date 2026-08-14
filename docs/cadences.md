# Le cadenze e le routine

Da leggere sapendo che ci sono **due assi**, e che «tre» ricorre su entrambi per
coincidenza:

- **quante routine** — tre: l'autore, il revisore, il documentatore
- **con che cadenza parte ciascuna** — le tre sezioni 1–3

Le sezioni 1–3 parlano del secondo asse. La sezione «Le tre routine» mette
insieme i due.

`relay` non ha bisogno del buio. La prima versione si chiamava `night-flow` e
girava alle due di notte, ma quella era una scelta di comodo travestita da
requisito.

**Il vincolo vero non è l'ora, è la quota.** La finestra Max è una sola,
condivisa fra claude.ai, Desktop e Claude Code. Un run che parte mentre stai
lavorando compete con la tua sessione interattiva. «Di notte» è solo un modo
semplice di dire *quando non la sto usando io* — se la domenica pomeriggio non
programmi, la domenica pomeriggio vale quanto le tre di notte.

Il secondo vincolo — nessuno sveglio a rispondere alle domande — vale a
qualsiasi ora, ed è gestito dal prompt: gate `needs-spec`, e la regola di
fermarsi invece di inventare un workaround.

## 1. A orario — il metronomo

Un trigger `Schedule`, intervallo minimo un'ora.

Prevedibile, spesa costante, un PR che ti aspetta. **È la cadenza con cui
iniziare**, perché è l'unica che ti permette di misurare: una settimana di run
identici ti dice quanto costano davvero in quota e quanti PR sopravvivono alla
tua review.

## 2. Sul merge — la staffetta

Un trigger `GitHub` su `pull_request.closed`, filtrato con **is merged = true**.

Appena approvi un PR, parte il task successivo. È il cambio che pesa di più:
si passa da *un task a notte* a *un task ogni volta che ne approvi uno*.

La proprietà interessante è che **si auto-regola**. Il sistema avanza solo
quando tu dai l'ok, quindi la spesa cresce esattamente quanto la tua fiducia. Se
una mattina i PR non ti convincono e non mergi niente, la catena si ferma da
sola — senza che tu debba disattivare nulla.

Il rovescio: raggiungi il **tetto giornaliero di run** molto prima. E durante la
research preview i trigger GitHub hanno cap orari per routine e per account,
oltre i quali gli eventi vengono scartati.

## 3. Su richiesta — il pulsante

Un trigger `API`: un endpoint dedicato con un bearer token, da chiamare con una
POST. Da uno script, da una scorciatoia sul telefono, dalla tua pipeline.

Complemento, non cadenza principale. Utile quando vuoi far ripartire la coda
dopo aver riscritto tre issue `needs-spec`, senza aspettare il prossimo giro.

Il token si genera dalla UI web e **si vede una volta sola**: copialo subito.

## Si combinano

Una routine accetta più trigger insieme. La combinazione sensata a regime:

| Trigger | Cosa copre |
|---|---|
| `Schedule` notturno | il fondo: un task al giorno comunque |
| `GitHub` sul merge | la resa: accelera quando tu acceleri |

Così la notte lavora anche se non hai mergiato niente, e di giorno ogni tuo
merge innesca la frazione successiva.

## Come arrivarci

Non partire dalla catena. L'ordine che consiglio:

1. **Settimana 1** — solo `Schedule`. Misuri: quanti PR arrivano, quanti ne
   mergi davvero, quanta quota resta al mattino.
2. **Quando tre o quattro PR di fila sono arrivati in buono stato**, aggiungi il
   trigger sul merge. Sono due click sulla routine esistente.
3. **L'API** quando ti accorgi di volerlo lanciare a mano — non prima.

Aggiungere o togliere un trigger a una routine esistente non è una scelta
definitiva: si fa dalla sua pagina di modifica in qualsiasi momento.

## Le tre routine

| routine | trigger | costa | cresce con |
|---|---|---|---|
| **autore** | `Schedule` + `GitHub` sul merge | un run pieno | i task che restano in coda |
| **revisore** | `GitHub` su PR aperto o riaperto | un run pieno | **i PR che apri** |
| **documentatore** | `GitHub` su merge riuscito | quasi zero, di norma | i merge che toccano i documenti |

Condividono **un solo environment**, `nightly`: stesse credenziali, stesso setup,
stessi domini consentiti. Si distinguono per prompt e per trigger, non per
ambiente. Non creare un environment per routine — si moltiplicherebbero i posti
in cui aggiornare `DATABASE_URL`.

### Cosa succede alla spesa

L'autore era una cadenza sola e prevedibile. Con tre routine il conto cambia
forma, e vale la pena vederlo scritto prima di accendere tutto:

- il **revisore** parte a ogni PR aperto. Se l'autore apre un PR al giorno, è un
  run in più al giorno. Se acceleri l'autore, acceleri anche questo: non è una
  spesa che si aggiunge una volta, è una che si aggancia alla prima.
- il **documentatore** parte a ogni merge, ma la maggior parte delle volte esce
  in pochi secondi con «niente da riconciliare». È il più economico dei tre —
  **se** l'uscita rapida funziona. Se non funziona è il più caro, perché parte
  sempre. È la prima cosa da guardare nei suoi primi run.

Il revisore **non** parte su `synchronize`, cioè a ogni push sul branch di un PR
aperto. Sarebbe la scelta più completa e anche il modo più rapido di esaurire i
tetti orari dei trigger GitHub.

### In che ordine accenderle

1. **L'autore da solo**, come oggi. Finché non hai una settimana di run.
2. **Il revisore.** È quello che restituisce di più: su dieci difetti veri di
   `predictionleagues`, sei non erano leggibili in un diff.
3. **Il documentatore**, per ultimo. È il più economico, ma serve solo quando i
   documenti hanno già cominciato a divergere — cioè non il primo mese.

## Una nota sul nome dell'environment

Il cloud environment si chiama ancora `nightly`. È un nome ereditato dalla
prima versione e non ha più molto senso, ma rinominarlo significa rifarlo a mano
e ripuntarci tutte le routine — per un'etichetta. Resta `nightly`, e questa riga
esiste per non farti cercare la coerenza che non c'è.
