---
title: Expiração, e perguntar se uma cópia ainda serve
version: 1
---

**Uma cópia expirada não é uma cópia errada; é uma que precisa ser conferida antes de voltar a ser
confiável.** A imagem comum é a de que uma entrada de cache morre na expiração e é jogada fora. O
HTTP funciona de outro jeito, e melhor para um celular: o servidor diz por quanto tempo uma cópia
está fresca, por quanto tempo ela ainda pode ser mostrada enquanto é conferida, e dá a ela uma
etiqueta, para a conferência custar algumas centenas de bytes em vez do corpo inteiro.

Três cabeçalhos carregam tudo:

| cabeçalho | de quem | o que diz |
|---|---|---|
| `Cache-Control: max-age=60` | servidor | a cópia está **fresca** por 60 segundos: mostre e não pergunte a ninguém |
| `stale-while-revalidate=300` | servidor, no mesmo cabeçalho | por 300 segundos depois disso, mostre a cópia velha na hora e confira por trás |
| `ETag: "250e0d8c86f9"` | servidor | uma etiqueta para este corpo exato |
| `If-None-Match: "250e0d8c86f9"` | cliente | "tenho esta; mande só se mudou" |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-expiry\" aria-label=\"Uma linha do tempo de uma cópia em cache, baixada no segundo 0 com max-age=60 e stale-while-revalidate=300. De 0 a 60 a cópia está fresca: é mostrada e nada é perguntado. De 60 a 360 está velha: é mostrada na hora e conferida por trás com If-None-Match. Depois de 360 está velha demais para mostrar: a tela espera a rede, e um 304 não custa corpo. As execuções do cliente nos segundos 30 e 45 caem na faixa fresca, a de 90 na faixa velha.\"><defs><marker id=\"l17-expiry-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l17-expiry-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"60\" width=\"96.0\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"136.0\" y=\"60\" width=\"480.0\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"616.0\" y=\"60\" width=\"84.0\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"88.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">fresca</text><text x=\"88.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-age</text><text x=\"376.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">velha, sendo revalidada</text><text x=\"376.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mostrada na hora, conferida por trás</text><text x=\"658.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">velha demais</text><text x=\"658.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">a tela espera</text><text x=\"88.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">mostrada, nada perguntado</text><path d=\"M40.0 150 L704.0 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper-dim)\"></path><path d=\"M40.0 145 L40.0 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M136.0 145 L136.0 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"136.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60</text><path d=\"M616.0 145 L616.0 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"616.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">360</text><text x=\"360.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundos desde que a cópia foi baixada</text><text x=\"40.0\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">execuções do fetch.ts</text><path d=\"M88.0 40 L88.0 58\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper)\"></path><text x=\"82.0\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">30</text><path d=\"M112.0 40 L112.0 58\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper)\"></path><text x=\"118.0\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">45</text><path d=\"M184.0 40 L184.0 58\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-expiry-ah-paper)\"></path><text x=\"190.0\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">90</text></svg>", "caption": "Um download, três jeitos de responder à próxima leitura. Cada 200 ou 304 recomeça a linha do tempo do zero."}
```

Se o corpo não mudou, o servidor responde **304 Not Modified** sem corpo, e o cliente mantém a
cópia e recomeça os 60 segundos dele.

## Um servidor e um cliente, em `~/planner/cache`

O servidor lê o catálogo de um arquivo e o etiqueta com o começo do SHA-256 dele, então editar o
arquivo muda a etiqueta. Ele imprime cada requisição que recebe. Salve como `server.ts`:

```typescript
// server.ts: the planner's catalogue, served with an ETag, on port 8017.
import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";

createServer((req, res) => {
  const body = readFileSync("catalogue.json");
  const etag = `"${createHash("sha256").update(body).digest("hex").slice(0, 12)}"`;
  const status = req.headers["if-none-match"] === etag ? 304 : 200;
  console.log(`${req.method} ${req.url} if-none-match=${req.headers["if-none-match"] ?? "-"} -> ${status}`);
  res.writeHead(status, { ETag: etag, "Cache-Control": "max-age=60, stale-while-revalidate=300" });
  res.end(status === 200 ? body : undefined);
}).listen(8017, "127.0.0.1");
```

E ao lado dele, os três cursos como `catalogue.json`:

```json
{"courses": ["Spanish A2", "Statistics", "Guitar"]}
```

O cliente guarda uma linha por URL no SQLite. O tempo é um argumento, `NOW` em segundos, então a
execução abaixo pode pular do segundo 0 ao 1000 sem esperar. Salve como `fetch.ts`:

```typescript
// fetch.ts: read the catalogue through a cache that honours max-age, stale-while-revalidate and ETag.
// usage: node fetch.ts NOW   (NOW is seconds on a pretend clock, so every run is repeatable)
import Database from "better-sqlite3";

const URL = "http://127.0.0.1:8017/catalogue";
const now = Number(process.argv[2]);
const db = new Database("cache.db");
db.exec(`create table if not exists http_cache (
  url text primary key, etag text, body text, fetched_at integer, max_age integer, swr integer)`);
type Row = { etag: string; body: string; fetched_at: number; max_age: number; swr: number };
const row = db.prepare("select * from http_cache where url = ?").get(URL) as Row | undefined;

async function revalidate(): Promise<string> {
  const res = await fetch(URL, { headers: row ? { "If-None-Match": row.etag } : {} });
  const cc = res.headers.get("cache-control") ?? "";
  const maxAge = Number(/max-age=(\d+)/.exec(cc)?.[1] ?? 0);
  const swr = Number(/stale-while-revalidate=(\d+)/.exec(cc)?.[1] ?? 0);
  const body = res.status === 304 && row ? row.body : await res.text();
  db.prepare(`insert or replace into http_cache values (?, ?, ?, ?, ?, ?)`)
    .run(URL, res.headers.get("etag"), body, now, maxAge, swr);
  console.log(`  network: ${res.status} ${res.status === 304 ? "not modified, kept the copy" : "downloaded"}`);
  return body;
}

const show = (body: string) => console.log(`  on screen: ${JSON.parse(body).courses.join(", ")}`);
const age = row ? now - row.fetched_at : Infinity;
if (row && age < row.max_age) {
  console.log(`t=${now}: fresh (age ${age}s), from the cache, no request`);
  show(row.body);
} else if (row && age < row.max_age + row.swr) {
  console.log(`t=${now}: stale (age ${age}s), shown from the cache, then revalidated`);
  show(row.body);
  await revalidate();
} else {
  console.log(`t=${now}: ${row ? `too old (age ${age}s)` : "nothing cached"}, the screen waits for the network`);
  show(await revalidate());
}
```

Inicie o servidor num terminal só dele com `node server.ts`, e em outro rode o cliente em seis
momentos. Entre os segundos 30 e 45 o catálogo muda no servidor: um quarto curso, Chess, entra no
`catalogue.json`, escrito aqui com `echo` para você ver acontecer.

```
ana@dev:~/planner/cache$ node fetch.ts 0
t=0: nothing cached, the screen waits for the network
  network: 200 downloaded
  on screen: Spanish A2, Statistics, Guitar
ana@dev:~/planner/cache$ node fetch.ts 30
t=30: fresh (age 30s), from the cache, no request
  on screen: Spanish A2, Statistics, Guitar
ana@dev:~/planner/cache$ echo '{"courses": ["Spanish A2", "Statistics", "Guitar", "Chess"]}' > catalogue.json
ana@dev:~/planner/cache$ node fetch.ts 45
t=45: fresh (age 45s), from the cache, no request
  on screen: Spanish A2, Statistics, Guitar
ana@dev:~/planner/cache$ node fetch.ts 90
t=90: stale (age 90s), shown from the cache, then revalidated
  on screen: Spanish A2, Statistics, Guitar
  network: 200 downloaded
ana@dev:~/planner/cache$ node fetch.ts 100
t=100: fresh (age 10s), from the cache, no request
  on screen: Spanish A2, Statistics, Guitar, Chess
ana@dev:~/planner/cache$ node fetch.ts 1000
t=1000: too old (age 910s), the screen waits for the network
  network: 304 not modified, kept the copy
  on screen: Spanish A2, Statistics, Guitar, Chess
```

E o que o servidor viu, no terminal dele:

```
ana@dev:~/planner/cache$ node server.ts
GET /catalogue if-none-match=- -> 200
GET /catalogue if-none-match="250e0d8c86f9" -> 200
GET /catalogue if-none-match="eb1ee6129b5c" -> 304
```

**Seis execuções do cliente, três requisições.** Nos segundos 30 e 45 nada foi perguntado, e no 45
isso significou a tela mostrar três cursos enquanto o servidor tinha quatro. Esse é o preço do
`max-age`, e ele é pago de olhos abertos: por 60 segundos o planner confia numa cópia em vez da
rede. No segundo 90 a cópia estava velha mas dentro da janela de revalidação, então a lista antiga
apareceu na hora e a nova chegou por trás, um 200 porque a etiqueta não batia mais. No segundo 1000
a cópia estava velha demais para mostrar, então a tela esperou, e a conferência custou um 304 sem
corpo.

**Quanto deve durar o `max-age` é uma pergunta sobre o dado, não sobre o HTTP.** Um catálogo que
muda uma vez por semestre pode ficar fresco por um dia. A lista das sessões da própria pessoa não
deve ser guardada em cache desse jeito: ela é o primeiro tipo de dado da seção anterior, e a
aula 11 a traz com um cursor.
