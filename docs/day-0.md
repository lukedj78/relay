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

## La colonna Ready

`linear-scrum` crea gli stati. Verifica che ci siano, e che significhino questo:

| Stato | Significato per la notte |
|---|---|
| `Backlog` | invisibile — la notte non lo tocca |
| `Ready` | **la coda**: pronto, con criteri verificabili |
| `In Progress` | preso da un run (e' anche il lock) |
| `In Review` | c'e' un PR che ti aspetta |
| `Done` | mergiato da te |

Il flusso di controllo tuo e' uno solo: **cosa sposti in `Ready`**. Lo fai di
giorno, dalla UI di Linear, senza toccare ne' il prompt ne' il repo.
