# Gli environment e le variabili

La domanda che torna sempre: *se l'environment e' uno solo e condiviso, come
gestisco `DATABASE_URL` di progetti diversi?*

La risposta breve: quasi mai devi gestirla, e quando devi, quel progetto si
prende un environment suo.

## Prima di tutto: due cose che si assomigliano e non lo sono

| | Cos'e' | Dove vive | Chi la legge |
|---|---|---|---|
| `.env.local` | la config del **progetto** | il tuo Mac, in gitignore | `pnpm dev` in locale |
| env vars dell'environment | la config della **macchina virtuale** | la scheda su claude.ai | il run notturno |

**Non c'e' nessun travaso fra le due.** Il run non "carica il `.env` del
progetto": la sandbox clona il repo, e `.env.local` non e' nel repo. Il run vede
solo quello che tu hai scritto nella scheda dell'environment.

Se le confondi, tutto il resto sembra incoerente.

## Perche' `DATABASE_URL` e' identica per tutti i progetti

Perche' il database non e' tuo: nasce e muore dentro la VM del run.

```
postgresql://postgres:postgres@localhost:5432/app
             |                  |
             utente della VM    la VM stessa
```

`localhost` e' la macchina virtuale, non il tuo Mac e non un server. Il progetto
A e il progetto B non hanno due database `app` che si pestano i piedi: hanno due
VM diverse, in due momenti diversi, e alla fine di ogni run sparisce tutto.

Non c'e' niente da variare perche' non c'e' niente di condiviso. La stringa e'
sempre la stessa esattamente come `/tmp` e' sempre `/tmp`.

Questo vale **finche' il database sta dentro la sandbox**. Un Neon vero e' un
altro discorso: vedi sotto.

## La regola per tutte le altre variabili

Una domanda sola:

> Il run notturno deve **parlare** con quel servizio, o solo **compilare**
> contro di esso?

| | Esempio tipico | Dove va la variabile |
|---|---|---|
| **Solo compilare** | Next fallisce il build se `STRIPE_SECRET_KEY` non esiste, ma nessuno chiama Stripe | placeholder in `nightly`, condiviso |
| **Deve parlare** | il run legge un Neon di staging, o testa un webhook vero | environment dedicato |

Nella pratica il primo caso copre quasi tutto, perche' **la notte scrive codice,
non esegue transazioni**. Alle variabili serve *esistere*, non essere vere.

## `nightly` — l'environment condiviso

Uno solo, per tutti i progetti. Le variabili sono l'unione di quelle di tutti i
progetti, tutte finte:

```
DATABASE_URL          postgresql://postgres:postgres@localhost:5432/app
STRIPE_SECRET_KEY     sk_test_placeholder
RESEND_API_KEY        re_placeholder
BETTER_AUTH_SECRET    placeholder-che-basta-per-il-build
BETTER_AUTH_URL       http://localhost:3000
```

**Come si fa crescere:** ogni volta che un progetto nuovo fallisce il build per
una variabile mancante, aggiungi una riga qui con un valore finto. Non serve
altro. Un progetto che non usa Resend ignora `RESEND_API_KEY` senza accorgersene.

La lista cresce e non si pulisce mai. Va bene: non c'e' niente dentro che valga
la pena proteggere.

### Le anteprime di deploy: un interruttore, non un segreto

Il revisore deve poter **aprire l'anteprima del PR**: e' la terza delle sue tre
condizioni di merge, e senza non mergia niente. Su dieci difetti veri trovati in
`predictionleagues`, sei non erano leggibili in un diff — si vedevano solo
facendo girare la cosa vera.

Vercel pero' accende **Vercel Authentication** in *Standard Protection* su ogni
progetto nuovo, e le anteprime rispondono `302` verso `vercel.com/sso-api`.

**La risposta e' spegnerla, non aggirarla:**

> Vercel → progetto → Settings → Deployment Protection →
> **Vercel Authentication** → *Disabled* → Save

Niente segreti, niente token, niente variabili, niente da tenere allineato fra
due sistemi. Per il progetto successivo e' lo stesso identico interruttore.

#### Perche' non e' un cedimento sulla sicurezza

Perche' in un progetto pubblico **la produzione e' gia' aperta**. L'anteprima
serve la stessa applicazione, con la stessa autenticazione davanti agli stessi
dati. Tenere chiusa l'anteprima mentre la produzione risponde a chiunque non
protegge i dati: protegge solo il fatto che una funzionalita' non ancora
rilasciata si veda in anticipo, su un URL che vive in un repository privato.

Vale la pena scriverlo perche' e' il tipo di ragionamento che si salta: si vede
un blocco, si cerca la chiave, e non ci si chiede **cosa stia proteggendo**. La
domanda giusta viene prima della soluzione tecnica.

#### L'eccezione: quando l'anteprima deve restare chiusa

Ci sono progetti in cui e' vero il contrario — lavoro per clienti, prodotti non
ancora annunciati, anteprime con dati veri. Li' la protezione resta accesa, e il
revisore entra con una chiave: **Protection Bypass for Automation**.

Vercel → progetto → Settings → Deployment Protection → *Protection Bypass for
Automation* → **Create**. Disponibile su tutti i piani.

Il segreto e' **per progetto**, quindi va nel nome della variabile e non nel suo
valore, altrimenti servirebbe un environment per progetto:

```
VERCEL_BYPASS_NOME_DEL_PROGETTO    <il segreto>
```

Nome = `VERCEL_BYPASS_` piu' il nome della cartella in maiuscolo, con i trattini
diventati underscore. Il revisore lo ricava da se':

```bash
VAR="VERCEL_BYPASS_$(basename "$PWD" | tr '[:lower:]-' '[:upper:]_')"
BYPASS=$(printenv "$VAR")
```

(`printenv` e non `${!VAR}`: la seconda e' sintassi bash e la sandbox non
garantisce bash.)

Poi due intestazioni su ogni richiesta: `x-vercel-protection-bypass` con il
segreto, e `x-vercel-set-bypass-cookie: true` — la seconda serve al browser,
perche' senza il cookie la prima pagina si apre e il primo click torna alla
schermata di login.

**Se il segreto viene rigenerato**, i deployment gia' fatti puntano al vecchio
valore: serve un redeploy.

**Questa e' la strada lunga.** Prendila solo se hai risposto «si» alla domanda:
*l'anteprima contiene qualcosa che la produzione non mostra gia' a chiunque?*

## `nightly-<progetto>` — quando serve un segreto vero

Duplichi `nightly`, gli dai il nome del progetto, e ci metti la credenziale
vera. Solo quel progetto lo usa.

La ragione per non metterla nel condiviso e' nella documentazione: le env vars
di un environment sono **visibili a chiunque lo usi**. Un segreto vero dentro
l'environment condiviso e' un segreto in un posto sbagliato — e ci resta per
mesi, perche' nessuno va mai a ripulire quella lista.

Quando serve davvero, in pratica:

- il run deve leggere dati reali da un database di staging
- il run deve chiamare un'API di terze parti per verificare qualcosa
- il progetto ha un servizio proprietario raggiungibile solo con un token

Se non sei in uno di questi casi, **non stai in questo caso**. Metti un
placeholder in `nightly` e vai avanti.

## Verificare che l'environment funzioni

Senza aspettare un progetto vero. Prima punta la CLI sull'environment con
`/remote-env` dentro una sessione `claude`, poi:

```bash
cd ~/projects/relay && claude --cloud "Esegui il comando check-tools. Poi verifica che PostgreSQL sia avviato con: sudo -u postgres psql -c 'SELECT version();' e che il database app esista con: sudo -u postgres psql -lqt. Riporta l'output dei tre comandi e nient'altro. Non modificare nessun file."
```

Gira contro questo stesso repo, che non ha un `package.json`. Nel log del setup
devi vedere le quattro intestazioni in ordine:

```
── dipendenze ──   nessun package.json: il progetto non e' ancora scaffoldato
── database ──     database 'app' creato
── migrazioni ──   nessuno schema Drizzle: niente da migrare
── pronto ──
```

**Cosa questo non verifica:** il ramo `pnpm install`, che qui non viene mai
preso. Quello si scopre col primo progetto vero — ed e' il motivo per cui il
primo **Run now** della routine va guardato invece che schedulato.

## La rete, gia' che ci sei

La allowlist `Trusted` di default copre npm, GitHub, Docker Hub e i registry
comuni. Se un environment dedicato deve raggiungere un servizio tuo — un Neon,
una API interna — quel dominio va aggiunto in **Allowed domains**, altrimenti la
richiesta fallisce con `403` e `x-deny-reason: host_not_allowed`.

E' l'errore piu' facile da diagnosticare male, perche' dal fuori sembra un bug
del codice.

### I domini che servono a un progetto web dev-flow

Scoperti sul campo il 2026-08-12 su predictionleagues, dove un run si e'
fermato con `403` su `ui.shadcn.com`. Aggiungili all'environment **prima** del
primo scaffold, non dopo:

| Dominio | Serve a |
|---|---|
| `ui.shadcn.com` | registry e preset della CLI shadcn (`init`, `add`) |
| `fonts.googleapis.com` | metadati dei font per `next/font/google` |
| `fonts.gstatic.com` | i file `.woff2` scaricati in fase di build |
| `ai-gateway.vercel.sh` | il catalogo dei modelli che il compilatore di eve interroga per le metadata della finestra di contesto: senza, `eve info`/`build`/`eval` falliscono con 403 |

I primi due falliscono a tempo di scaffold, il terzo a tempo di build: senza
tutti e tre si perde un run per volta, sempre per la stessa causa.
