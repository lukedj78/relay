# Il giorno 0

Un'ora circa, interattiva. Produce un PRD, un DESIGN.md e la lista dei task
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
| 4 | `/image-to-design-md` o `/figma-to-design-md` | `docs/DESIGN.md` | la direzione visiva e' un giudizio |

La coda vera — le issue GitHub — si crea **dopo**, con `tasks-to-issues`, perche'
serve prima il repo remoto che crea `relay-init`.

## Le due cose da non sbagliare

### La libreria UI

Nel passo 4 ti verra' chiesto: shadcn, Base UI, MUI o Coss/UI. **Rispondi tu.**

Il prompt della routine vieta esplicitamente alla notte di scegliere una
libreria: se serve, marca la issue `needs-spec` e passa oltre. E' voluto. Una
scelta di libreria presa male non si vede subito — si vede sei fette dopo,
quando disfarla costa un rifacimento.

### I criteri di accettazione

Nel passo 3, ogni task deve dire **come si verifica che sia fatto**. Non
"implementa la pagina prenotazioni", ma "la pagina elenca le prenotazioni del
mese corrente, filtrabili per struttura, con stato vuoto quando non ce ne sono".

La qualita' dei PR notturni sara' esattamente la qualita' di quello che scrivi
qui. Una issue vaga non produce nessun codice: produce **codice sbagliato**, che
e' peggio.

## Poi

```bash
relay-init          # repo GitHub + configurazione della sandbox
tasks-to-issues       # tasks.md → issue GitHub, con priorita' e numerazione
```

e segui le istruzioni che `relay-init` stampa per la routine.

`tasks-to-issues` va lanciato **dopo** `relay-init`, perche' ha bisogno del
repo remoto. E' idempotente: se aggiungi task al `tasks.md` puoi rilanciarlo, e
crea solo quelli mancanti. Provalo prima con `--dry-run`.

## Come la notte sceglie da sola

**Non devi spostare niente ogni mattina.** La routine legge la board intera e
decide da se': scarta quello che e' gia' preso, in review, bloccato o marcato
`needs-spec`, e fra quello che resta prende il primo per priorita' e ordine.

| Stato | Significato per la notte |
|---|---|
| aperta, senza label di flusso | **la coda**: tutto quello che non e' escluso |
| `night:wip` | presa da un run — e' anche il lock |
| `night:in-review` | c'e' un PR che ti aspetta |
| chiusa | il merge del PR l'ha chiusa (`Closes #N`) |

Perche' funzioni servono due cose, **una volta sola**, non ogni giorno:

**La priorita'.** `tasks-to-issues` la deduce dall'epic del `tasks.md`: `P0` →
`priority:urgent`, `P1` → `priority:high`, `P2` → `priority:medium`, `P3` →
`priority:low`. E' il primo criterio di ordinamento. Se vuoi cambiarla, cambi la
label sulla issue.

**L'ordine di dipendenza.** Se il Task 3 non ha senso prima del Task 2, dillo in
uno di questi modi, che la routine sa leggere:

- una riga **`Blocked by #N`** nel corpo della issue
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
