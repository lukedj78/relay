# Le tre cadenze

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

## Una nota sul nome dell'environment

Il cloud environment si chiama ancora `nightly`. È un nome ereditato dalla
prima versione e non ha più molto senso, ma rinominarlo significa rifarlo a mano
e ripuntarci tutte le routine — per un'etichetta. Resta `nightly`, e questa riga
esiste per non farti cercare la coerenza che non c'è.
