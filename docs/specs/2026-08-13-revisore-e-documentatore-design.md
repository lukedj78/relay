# Revisore e documentatore — design

**Data:** 2026-08-13
**Stato:** approvato in brainstorming, da tradurre in piano
**Origine:** due giorni di uso reale su `predictionleagues` — 12 PR mergiati, 16 issue chiuse, un prodotto online

---

## 1. Il problema

Oggi `relay` ha un solo agente: quello che scrive il codice e verifica se stesso. Funziona meglio di quanto ci si aspetti — i PR riportano verifiche vere, con browser reali e database veri, e la sezione «cosa NON ho verificato» è compilata sul serio. Ma ha due buchi, entrambi osservati.

**L'auto-verifica condivide i punti ciechi di chi scrive.** Il 13 agosto due run hanno preso la stessa issue e prodotto due PR con la stessa correzione. Uno ha misurato lo schermo — *«una sola schermata di successo, quindi l'annullamento funziona»*. L'altro ha misurato il database — *«due leghe create, quindi non funziona»*. Il secondo aveva ragione: il wizard non riceve nemmeno il `ctx` che contiene il segnale. Il primo non stava mentendo: aveva verificato con cura la cosa sbagliata.

**I documenti diventano falsi in silenzio.** La spec scritta il 12 agosto descriveva `packages/db` con una tabella; oggi ne ha quattro. Diceva 12 competizioni; l'API ne dà 13. Fissava il campo punteggio a 44px; nel codice è 36 disegnati e 44 toccabili. Nessuna di queste righe è sbagliata per negligenza: sono state superate dai fatti, e nessuno le ha riconciliate tranne quando è capitato di accorgersene.

## 2. Cosa dicono i dati

Ogni difetto trovato nei due giorni, e cosa l'ha trovato:

| difetto | trovato da | leggibile in un diff? |
|---|---|---|
| 17 errori di lint | CI | sì |
| bersagli tattili a 24px invece di 44 | revisione + DESIGN.md | sì |
| DESIGN.md incoerente (88 ≠ 44+8+44) | calcolo in revisione | sì |
| annullamento non collegato al `signal` | verifica che misura il server | forse |
| riga-partita che sfora di 8px | occhio umano | difficile |
| `localhost` nel bundle del client | produzione | no |
| area autenticata prerenderizzata | intestazioni HTTP in produzione | no |
| turbo che filtra le variabili d'ambiente | fallimento del deploy | no |
| `BETTER_AUTH_URL` senza schema | log del deploy | no |
| symlink `.env` caricato dal CLI | log del deploy | no |

**Sei su dieci non erano visibili in un diff.** Si sono manifestati solo facendo girare la cosa vera e misurandone l'effetto.

Conseguenza per il design: un revisore che legge il codice è il pezzo *meno* prezioso. Un revisore che **esercita l'anteprima deployata** è il più prezioso.

## 3. La decisione zero: il triage

Prima di qualunque agente, va scritta una regola che vale per tutti.

> **Se la risposta è derivabile dagli artefatti già scritti** — spec, DESIGN.md, PRD, il codice stesso — l'agente decide, implementa e **dichiara** in modo evidente.
> **Se richiede un giudizio che nessun documento contiene**, si ferma con la domanda ben posta.

### Perché serve

L'obiettivo dichiarato è prendere tutte le decisioni al momento zero, così che la routine non debba mai decidere in corsa. È l'obiettivo giusto, e riduce molto il residuo — ma non lo azzera, perché **si possono anticipare le decisioni, non le scoperte**.

Delle nove decisioni emerse in corsa il 12–13 agosto, cinque erano anticipabili: la base dei primitivi shadcn, le Instant Navigations, il deploy separato dell'agente, Node 24 nella sandbox, gli stati di schermata. Quattro no:

- il DESIGN.md che si contraddice — nessuno sapeva che fosse una domanda finché qualcuno non ha provato a implementarlo;
- se sacrificare la riga, il bersaglio o il gap — conseguenza della precedente;
- quale dei due PR gemelli tenere — giudizio su artefatti che non esistevano;
- l'annullamento non collegato — emerso misurando.

Di queste quattro, **tre avevano una risposta derivabile**: l'aritmetica dice che 96 non entra in 88; il codice dice se il segnale arriva; il confronto fra due verifiche dice quale ha misurato l'effetto. Solo una — *quale* dei tre numeri sacrificare — richiedeva un giudizio di prodotto.

Il triage cattura questa distinzione, e vale sia per l'autore sia per i due agenti nuovi.

### Il costo, dichiarato

L'agente sbaglierà a classificare. Ma sbaglierà in modo **osservabile**: ogni decisione presa va dichiarata, e le decisioni dichiarate si contano e si rivedono. È l'opposto di una scelta silenziosa, che è il fallimento vero.

---

## 4. Il revisore avversariale

### Dove vive

Una seconda routine cloud, `<progetto> — revisore`, con trigger GitHub su `pull_request` **aperto o riaperto**. Stesso environment, stesso modello, **zero connector**.

Non scatta a ogni push: i trigger GitHub hanno tetti orari durante la research preview, e ogni run consuma la stessa quota delle sessioni interattive. Un revisore che gira su ogni commit raddoppia la spesa del sistema.

**Non mergia mai.** Scrive una review GitHub e nient'altro. Il merge è una decisione separata, oggi umana.

### Cosa legge

- il corpo del PR, in particolare la sezione **«cosa ho verificato»**;
- il diff;
- `.workflow/PRD.md`, `.workflow/DESIGN.md` e le spec del progetto;
- **l'URL dell'anteprima Vercel** pubblicato dal bot sul PR — è la fonte che rende possibile il 60% dei difetti che un diff non mostra.

Se l'anteprima non è ancora pronta o il deploy è fallito, il revisore **non finge di averla vista**: attende una volta, e se manca ancora emette i verdetti che può emettere e marca gli altri **non verificabile — anteprima assente**. Una review che tace sull'anteprima mancante è peggio di nessuna review, perché sembra completa.

### Il mandato: falsificare

Per ogni affermazione nella sezione «cosa ho verificato», il revisore progetta un esperimento che la mostrerebbe **falsa**, lo esegue contro l'anteprima, e riporta quattro cose: affermazione, esperimento, risultato, verdetto.

| verdetto | significato | effetto |
|---|---|---|
| **confermata** | l'esperimento non l'ha smentita | nessuno |
| **smentita** | l'esperimento la contraddice | blocca il PR |
| **non verificabile** | non falsificabile con gli strumenti disponibili | non blocca, resta scritta |

Il terzo verdetto è quello che tiene onesto il sistema. Un revisore con mandato vago trasforma la propria cecità in un'obiezione; qui *«non ho potuto guardare»* è un esito legittimo e va detto.

**Il revisore non giudica lo stile.** Non propone rinomine, non suggerisce astrazioni, non commenta le preferenze. Il suo mandato è binario e verificabile: *dimostra che questa frase è falsa*. «Revisiona bene» non è un mandato; «falsifica questa affermazione» sì.

### La lista fissa

Oltre alle affermazioni del PR, sei controlli che valgono sempre. Ognuno nasce da un difetto reale:

| controllo | difetto d'origine |
|---|---|
| l'area autenticata reindirizza senza cookie di sessione | area servita come HTML statico, guardia mai eseguita |
| nessun `localhost` nel bundle del client | il browser del visitatore chiamava il proprio computer |
| i numeri del DESIGN.md tornano nei componenti toccati | 44+8+44 in un contenitore da 88 |
| `messages/en.json` e `it.json` hanno le stesse chiavi | `MISSING_MESSAGE` in produzione |
| le scritture si contano nel **database**, non nelle schermate | due leghe create, una sola schermata mostrata |
| il build passa da `turbo run build` | variabili filtrate da turbo, invisibile con `pnpm --filter` |

**La regola che tiene corta la lista**: si allunga **solo** quando un difetto è sfuggito e nessun controllo l'avrebbe intercettato. Mai per prudenza. Ogni riga deve poter citare il guasto che l'ha generata.

Senza questa regola, in tre mesi sono quaranta controlli, il revisore impiega venti minuti a PR, e qualcuno lo spegne — che è il modo in cui muoiono i sistemi di qualità.

### Cosa il revisore non vede

I rischi che il PR **non ha dichiarato**. Se un autore omette un'affermazione, non c'è niente da falsificare. La lista fissa copre i sei casi noti; il resto resta scoperto.

È una limitazione accettata, non risolta: il mandato stretto è ciò che rende il revisore utile, e allargarlo per coprire l'ignoto lo riporterebbe a essere un generalista rumoroso.

### Cosa succede dopo una smentita

Oggi: la review resta scritta sul PR e il merge — che è umano — non avviene. Nient'altro. Il correttore automatico è rimandato (§6), quindi **nessuno riapre il branch da solo**.

Il punto che serve dichiarare adesso, prima che il sistema esista: una smentita **non deve bloccare la coda notturna**. La routine che scrive il codice sceglie l'issue successiva e va avanti; il PR smentito resta aperto in attesa. Altrimenti un solo falso positivo ferma tutte le notti finché qualcuno non guarda — che è esattamente il fallimento da cui `blocked` protegge già oggi.

---

## 5. Il documentatore riconciliatore

### Quando scatta

Su `pull_request.closed` con merge riuscito. **Non** a fine sotto-progetto: una divergenza costa meno da correggere quando è fresca e il PR che l'ha causata è ancora sotto gli occhi.

Il primo passo è un controllo a costo quasi nullo: se nessun documento è stato smentito, esce con *«niente da riconciliare»*. La maggior parte dei merge non tocca la spec.

### Cosa fa

Legge il PR mergiato e i documenti di riferimento — `PRD.md`, `DESIGN.md`, le spec — e per ogni affermazione che quel cambiamento ha reso falsa la corregge, **citando il PR che l'ha smentita**. Apre un PR con le sole modifiche ai documenti.

### Due regole strette

**Può solo correggere ciò che è diventato falso.** Non riscrive, non migliora, non riordina, non aggiunge. Un documentatore con licenza di «migliorare la documentazione» produce rifacimenti che nessuno ha chiesto e che nessuno rilegge.

**Distingue i fatti dalle decisioni**, con lo stesso triage della §3:

> riga **derivabile** — «12 competizioni» quando l'API ne dà 13, «tabella `fixture`» quando ce ne sono quattro → **corregge**
> riga che codifica una **decisione** — `score: 20px`, «il buio è il caso normale», «niente denaro nell'MVP» → **non la tocca**, apre un PR che la segnala e chiede

L'esempio d'origine: portare `score` da 20 a 16px sembrava una conseguenza aritmetica del riquadro rimpicciolito, ma era una scelta sul sistema tipografico di chi ha scritto il documento. Un agente deve fermarsi lì.

### Perché non un diario di bordo

Il materiale narrativo esiste già: i corpi dei PR, con «cosa fa / cosa ho verificato / cosa NON ho verificato», sono la miglior documentazione prodotta finora. Un agente che li riassume altrove produce un duplicato, e i duplicati divergono: dopo un mese ci sono due racconti e nessuno sa quale credere.

Gli screenshot hanno valore in un caso solo — quando mostrano una **decisione visiva**, come il confronto fra layout impilato e speculare. Un'immagine di com'era una schermata a settembre non aiuta chi la modifica a dicembre.

---

## 6. Dove vivono le cose

`relay` oggi ha un prompt solo, `routine/prompt.md`, e un environment solo. I due agenti nuovi sono due prompt e due routine, non due environment:

| artefatto | cosa contiene |
|---|---|
| `routine/prompt.md` | invariato — l'autore. Aggiunge solo il triage (§3) alle sue regole |
| `routine/review-prompt.md` | il mandato di falsificazione, i tre verdetti, la lista fissa |
| `routine/docs-prompt.md` | le due regole strette, il triage fatti/decisioni, l'uscita rapida |
| `docs/cadences.md` | va esteso: oggi descrive una cadenza sola, ne descriverà tre con costi diversi |
| `bin/relay-init` | crea oggi una routine per progetto, dovrà crearne tre |

L'environment `nightly` resta uno e condiviso — stesse credenziali, stesso setup, stessi domini consentiti. I tre agenti si distinguono per prompt e trigger, non per ambiente.

## 7. Cosa resta fuori, e perché

| rimandato | condizione per riprenderlo |
|---|---|
| **ciclo di correzione automatica** | dopo che il revisore ha dimostrato pochi falsi positivi. Un correttore che insegue smentite sbagliate è peggio di nessun correttore |
| **merge automatico** | dopo un mese di verdetti osservati. Toglie il regolatore descritto in `cadences.md`, dove la spesa cresce quanto la fiducia |
| **parallelizzazione** | dopo aver capito perché il lock `night:wip` non ha retto: il 13 agosto due run hanno preso la stessa issue. Parallelizzare prima moltiplica quel difetto |

Il lock che cede è il prerequisito nascosto della parallelizzazione, ed è già rotto oggi con due run. Va diagnosticato prima di aumentare la concorrenza.

---

## 8. Rischi

| rischio | mitigazione |
|---|---|
| il revisore produce falsi positivi e blocca PR buoni | mandato binario e falsificabile; il verdetto «non verificabile» evita di trasformare la cecità in obiezione |
| la lista fissa cresce fino a essere ingestibile | ogni riga deve citare il difetto d'origine; nessuna aggiunta preventiva |
| il documentatore riscrive documenti altrui | può solo correggere ciò che è falso; le decisioni le segnala, non le cambia |
| il costo in quota raddoppia o triplica | il revisore scatta all'apertura del PR, non a ogni push; il documentatore esce subito se non c'è nulla da riconciliare |
| i due agenti nuovi ereditano i punti ciechi dell'autore | il revisore misura **effetti** (righe nel database, intestazioni HTTP), non apparenze — è la differenza che ha distinto i due PR gemelli |

## 9. Come si misura se funziona

Dopo un mese, tre numeri:

- **difetti intercettati dal revisore** che sarebbero altrimenti arrivati su `main`;
- **falsi positivi**, cioè smentite che a un esame umano risultano sbagliate — se superano il 20%, il mandato va stretto ulteriormente;
- **righe di documento riconciliate**, e quante volte il documentatore si è fermato correttamente davanti a una decisione.

Se il primo numero è basso, il revisore non serve e va spento. Dirlo adesso, con la soglia scritta, è ciò che impedisce di tenerlo in vita per affezione.
