---
title: Fora da thread principal
version: 1
---

**A correção é abrir o banco em outra thread e mandar a pergunta para ela.** A thread principal
pergunta, continua desenhando e trata a resposta quando ela chega. No Node essa outra thread é um
**worker**: uma segunda thread de JavaScript com laço de eventos próprio, que conversa com a
principal só por mensagens. Cada plataforma tem nome próprio para o mesmo arranjo, e eles estão
abaixo.

Salve isto como `query-worker.ts` na `~/planner/threads`. Ele abre a própria conexão, porque uma
conexão do `better-sqlite3` pertence à thread que a abriu, e responde cada mensagem com a primeira
linha da consulta:

```typescript
// query-worker.ts: the database, opened in a thread of its own; it answers one message per query.
import Database from "better-sqlite3";
import { parentPort } from "node:worker_threads";

const db = new Database(":memory:");
parentPort!.on("message", (sql: string) => {
  parentPort!.postMessage(db.prepare(sql).get());
});
```

E o lado da thread principal, como `off-main.ts`. Tudo é igual ao `blocking.ts`, exceto que a
consulta é enviada ao worker:

```typescript
// off-main.ts: the same slow query, sent to a worker thread while the main thread keeps drawing.
import { Worker } from "node:worker_threads";
import { slow } from "./slow.ts";

let frames = 0;
const screen = setInterval(() => frames++, 16);
const worker = new Worker(new URL("./query-worker.ts", import.meta.url));

setTimeout(() => {
  const before = frames;
  worker.postMessage(slow);
  worker.once("message", ({ rows }: { rows: number }) => {
    const drawn = frames - before;
    console.log(`worker: ${rows} rows; frames drawn while the query ran: ${drawn > 0 ? "at least one" : "none"}`);
    clearInterval(screen);
    worker.terminate();
  });
}, 100);
```

```
ana@dev:~/planner/threads$ node off-main.ts
worker: 3000000 rows; frames drawn while the query ran: at least one
```

Os mesmos três milhões de linhas, a mesma consulta, e **a tela continuou desenhando enquanto ela
rodava.** A consulta não demorou menos; a thread principal só não era a que esperava por ela. O
Node 22 roda o TypeScript do worker do mesmo jeito que roda o do arquivo principal, e é por isso que
o `new URL(…, import.meta.url)` pode citar um arquivo `.ts`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l06-frames\" aria-label=\"Duas linhas do tempo de quadros que vencem a cada 16 milissegundos. Em cima, a consulta roda na thread principal: enquanto ela roda, todo quadro que vence é descartado, e o desenho só volta quando ela retorna. Embaixo, a consulta roda numa thread worker: a thread principal desenha todos os quadros enquanto o worker responde, e a resposta chega como mensagem.\"><defs><marker id=\"l06-frames-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">a consulta na thread principal</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thread principal</text><rect x=\"140\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"164\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"188\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"212\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"236\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"260\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"284\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"308\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"332\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"356\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"380\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"404\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"428\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"452\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"476\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"500\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"524\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"548\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"572\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"596\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"620\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"644\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"668\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"692\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"260\" y=\"74\" width=\"264\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"392.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">consulta lenta</text><text x=\"392\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">quadros descartados</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a consulta num worker</text><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thread principal</text><rect x=\"140\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"164\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"188\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"212\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"236\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"260\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"284\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"308\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"332\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"356\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"380\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"404\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"428\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"452\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"476\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"500\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"524\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"548\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"572\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"596\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"620\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"644\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"668\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"692\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker</text><rect x=\"260\" y=\"216\" width=\"264\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"392.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">consulta lenta</text><path d=\"M524 216 L536 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-frames-ah-phosphor)\"></path><text x=\"540\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">a resposta, como mensagem</text><text x=\"392\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">todo quadro desenhado</text></svg>", "caption": "A consulta demora o mesmo nos dois. O que muda é qual thread espera por ela, e portanto se os quadros que vencem nesse meio-tempo são desenhados.", "same": ["worker"]}
```

## O mesmo arranjo, três vezes

*Estas listagens não foram rodadas para este curso; elas seguem a documentação do Room, do SwiftData
e do Expo SQLite.*

O **Room** roda uma função `suspend` de DAO ou um `Flow` em executores próprios, e recusa de cara
uma consulta na thread principal, então o arranjo é o padrão e não uma escolha:

```kotlin
viewModelScope.launch {
    val week = dao.week("2026-10-19", "2026-10-26") // suspends; Room runs the query elsewhere
    _state.value = WeekState(week)                  // back on the main thread
}
```

O **SwiftData** dá a uma thread de segundo plano um `ModelContext` próprio pela macro `@ModelActor`.
O ator é dono do contexto, e o ator principal aguarda os métodos dele:

```swift
@ModelActor
actor SessionImporter {
    func save(_ rows: [SessionRow]) throws {
        for row in rows {
            modelContext.insert(Session(id: row.id, course: row.course, date: row.date, minutes: row.minutes))
        }
        try modelContext.save()
    }
}

let importer = SessionImporter(modelContainer: container)
try await importer.save(rows)
```

O **`expo-sqlite`** tem uma forma assíncrona e uma síncrona de cada chamada. A assíncrona roda numa
thread nativa, deixando a thread do JavaScript livre; a síncrona, `getAllSync`, é o `blocking.ts` de
novo:

```typescript
const week = await db.getAllAsync(
  "SELECT * FROM sessions WHERE date >= ? AND date < ?",
  ["2026-10-19", "2026-10-26"],
);
```

## O que isso custa

Uma segunda thread é um segundo lugar de onde o dado pode ser lido, e dois lugares podem discordar.
Enquanto o worker grava uma sincronização, a thread principal pode ler uma visão pela metade, a não
ser que as duas passem por transações; o modo WAL da aula 3 é o que deixa uma ler enquanto a outra
grava. E a resposta chega depois da pergunta, então a tela tem um momento em que já perguntou e
ainda não ouviu. A aula 7 é sobre o que desenhar nesse momento.
