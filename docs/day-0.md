# Il giorno 0

Un'ora circa, interattiva. Produce un PRD, un DESIGN.md e una board Linear
piena — cioe' tutto quello che serve alle notti per lavorare senza di te.

Questa e' la parte che **non si automatizza**, e non per limiti tecnici: sono
decisioni di prodotto. Una routine che decide da sola cosa costruire non
costruisce quello che volevi.

```bash
mkdir ~/projects/<slug> && cd ~/projects/<slug>
git init
claude
```

## I cinque passi

| # | Comando | Produce | Perche' non puo' farlo la notte |
|---|---|---|---|
| 1 | `/superpowers:brainstorming` | le decisioni | serve che qualcuno risponda alle domande |
| 2 | `/prd-from-idea` | `.workflow/PROJECT.md`, `PRD.md` | il PRD e' un'intenzione, non una derivazione |
| 3 | `/prd-to-tasks` | `.workflow/tasks.md` | dove sta il confine di un task lo decidi tu |
| 4 | `/linear-scrum` Setup | gli issue su Linear | la coda notturna e' questa |
| 5 | `/image-to-design-md` o `/figma-to-design-md` | `docs/DESIGN.md` | la direzione visiva e' un giudizio |

## Le due cose da non sbagliare

### La libreria UI

Nel passo 5 ti verra' chiesto: shadcn, Base UI, MUI o Coss/UI. **Rispondi tu.**

Il prompt della routine vieta esplicitamente alla notte di scegliere una
libreria: se serve, marca l'issue `needs-spec` e si ferma. E' voluto. Una scelta
di libreria presa male non si vede subito — si vede sei fette dopo, quando
disfarla costa un rifacimento.

### I criteri di accettazione

Nel passo 3, ogni task deve dire **come si verifica che sia fatto**. Non
"implementa la pagina prenotazioni", ma "la pagina elenca le prenotazioni del
mese corrente, filtrabili per struttura, con stato vuoto quando non ce ne sono".

La qualita' dei PR notturni sara' esattamente la qualita' di questa colonna. Un
issue vago non produce nessun codice: produce **codice sbagliato**, che e'
peggio.

## Poi

```bash
nightly-init
```

e segui le istruzioni che stampa.

## Come la notte sceglie da sola

**Non devi spostare niente ogni mattina.** La routine legge la board intera e
decide da se': scarta quello che e' gia' preso, in review, bloccato o marcato
`needs-spec`, e fra quello che resta prende il primo per priorita' e ordine.

| Stato | Significato per la notte |
|---|---|
| `Backlog` / `Todo` | **la coda**: tutto quello che non e' escluso |
| `In Progress` | preso da un run (e' anche il lock) |
| `In Review` | c'e' un PR che ti aspetta |
| `Done` | mergiato da te |

Perche' funzioni, al passo 3 devi darle due cose — **una volta sola**, non ogni
giorno:

**La priorita'.** Imposta il campo priorita' di Linear su ogni issue. E' il
primo criterio di ordinamento.

**L'ordine di dipendenza.** Se il Task 3 non ha senso prima del Task 2, dillo in
uno di questi modi, che la routine sa leggere:

- una relazione Linear **"blocked by"** verso l'issue prerequisito
- una **numerazione nel titolo** (`T1 — ...`, `T2 — ...`): i task numerati si
  eseguono in ordine crescente e la notte non salta avanti
- una riga nella descrizione che nomina il task prerequisito

`prd-to-tasks` numera gia' i task nel titolo, quindi nella maggior parte dei
casi non devi fare niente.

## Le due label che ti restano

| Label | Chi la mette | Effetto |
|---|---|---|
| `needs-spec` | la notte, quando un issue non ha criteri verificabili | escluso finche' non lo riscrivi |
| `blocked` | tu, quando vuoi togliere qualcosa dalla coda | escluso |

`blocked` e' il tuo freno a mano: se non vuoi che tocchi una certa area, la
marchi e basta. Non e' un obbligo quotidiano — e' un'eccezione.
