---
title: Drenar a fila, em ordem, uma de cada vez
version: 1
---

**A caixa de saída é enviada da mais antiga para a mais nova, uma operação de cada vez, e a drenagem
para na primeira que a rede não consegue entregar.** As três regras são sobre ordem. Um update
enviado antes do create que ele atualiza chega a um servidor que nunca ouviu falar da sessão, e um
delete enviado antes de um update anterior vira um 404 seguido de uma ressurreição.

A versão tentadora envia tudo de uma vez, em paralelo, porque é mais rápido. É mais rápido até duas
operações sobre a mesma sessão chegarem na ordem inversa, o que numa rede móvel vai acontecer. Uma
de cada vez custa uma ida e volta por operação, e para as poucas dezenas de operações por dia do
planner isso não é nada.

## O servidor

O planner precisa de algo para onde enviar, e este é o menor que mantém as regras: ele guarda
sessões na memória, responde `POST`, `PUT`, `DELETE` e `GET`, e recusa uma sessão com mais de 240
minutos. Ele esquece tudo quando para, o que serve para uma aula e é o motivo de ele não ser um
servidor de verdade. Salve isto como `server.ts`:

```typescript
// server.ts: the planner's server, as small as it can be. It keeps sessions in memory, so a
// restart forgets them, and it holds the one rule a session must meet.
import { createServer } from "node:http";

type Session = { id: string; course: string; date: string; minutes: number };
const sessions = new Map<string, Session>();

function reply(res: import("node:http").ServerResponse, status: number, body: unknown) {
  res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(body) + "\n");
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const [, , id] = (req.url ?? "").split("/"); // /sessions/<id>
  const body = text ? JSON.parse(text) : null;
  console.log(req.method, req.url);

  if (req.method === "GET") return reply(res, 200, [...sessions.values()]);
  if (body && body.minutes > 240) return reply(res, 422, { error: "a session is at most 240 minutes" });
  if (req.method === "POST") {
    if (sessions.has(body.id)) return reply(res, 409, { error: `${body.id} exists` });
    sessions.set(body.id, body);
    return reply(res, 201, body);
  }
  if (!sessions.has(id)) return reply(res, 404, { error: `no session ${id}` });
  if (req.method === "PUT") { sessions.set(id, body); return reply(res, 200, body); }
  if (req.method === "DELETE") { sessions.delete(id); return reply(res, 204, null); }
  reply(res, 405, { error: "method not allowed" });
}).listen(8008, "127.0.0.1", () => console.log("listening on 8008"));
```

As aulas 9 a 12 fazem cópias próprias deste servidor, uma mudança de cada vez.

## A drenagem

O `drain.ts` lê a caixa de saída na ordem de `seq` e envia cada operação como o método HTTP que ela
representa. Um sucesso remove a linha. Uma falha de rede, ou um 5xx, para a drenagem: a operação
continua ali e a próxima execução começa por ela. Um 4xx é diferente, e a penúltima seção é sobre
ele. Salve isto como `drain.ts`:

```typescript
// drain.ts: send the outbox to the server, oldest first, one operation at a time.
import { db } from "./store.ts";

type Op = { seq: number; op: "create" | "update" | "delete"; session: string; body: string | null };
const SERVER = "http://127.0.0.1:8008/sessions";
const method = { create: "POST", update: "PUT", delete: "DELETE" };
const held = new Set<string>(); // sessions with an operation that cannot be sent

for (const o of db.prepare("select seq, op, session, body from outbox order by seq").all() as Op[]) {
  const name = `#${o.seq} ${o.op} ${o.session}`;
  if (held.has(o.session)) { console.log(`${name}: held behind a dead operation`); continue; }
  let res: Response;
  try {
    const url = o.op === "create" ? SERVER : `${SERVER}/${o.session}`;
    res = await fetch(url, { method: method[o.op], headers: { "content-type": "application/json" }, body: o.body ?? undefined });
  } catch {
    console.log(`${name}: server unreachable, stopping`);
    break;
  }
  if (res.ok) {
    db.prepare("delete from outbox where seq = ?").run(o.seq);
    console.log(`${name}: ${res.status}`);
  } else if (res.status >= 500) {
    console.log(`${name}: ${res.status}, stopping`);
    break;
  } else {
    // A 4xx is the server's answer, and it will give the same one every time.
    const reason = `${res.status} ${(await res.json()).error}`;
    db.transaction(() => {
      db.prepare("insert into dead select seq, op, session, body, ? from outbox where seq = ?").run(reason, o.seq);
      db.prepare("delete from outbox where seq = ?").run(o.seq);
    })();
    held.add(o.session);
    console.log(`${name}: ${reason}, moved to dead`);
  }
}
const { n } = db.prepare("select count(*) as n from outbox").get() as { n: number };
console.log(`${n} waiting`);
```

Primeiro sem servidor, que é o trem:

```
ana@dev:~/planner/outbox$ node drain.ts
#1 create s7: server unreachable, stopping
3 waiting
```

A primeira operação falhou e a drenagem parou ali. Ela não tentou `#2` e `#3`, porque as duas
dependem de `#1` ter chegado. Agora suba o servidor num segundo terminal, `node server.ts`, deixe-o
rodando e drene de novo a partir da primeira:

```
ana@dev:~/planner/outbox$ node drain.ts
#1 create s7: 201
#2 update s7: 200
#3 create s8: 201
0 waiting
ana@dev:~/planner/outbox$ curl -s http://127.0.0.1:8008/sessions
[{"id":"s7","course":"guitar","date":"2026-10-23","minutes":30},{"id":"s8","course":"statistics","date":"2026-10-24","minutes":40}]
```

Cada operação foi na ordem em que foi escrita, e a caixa de saída está vazia. O terminal do
servidor imprimiu uma linha por requisição:

```
ana@dev:~/planner/outbox$ node server.ts
listening on 8008
POST /sessions
PUT /sessions/s7
POST /sessions
GET /sessions
```

## Quando a drenagem roda

Aqui você a roda à mão. Num app ela roda quando uma mudança é gravada e a rede está no ar, quando a
rede volta e quando o app é aberto. **Cada um desses pode começar uma drenagem enquanto outra ainda
está rodando**, então uma caixa de saída de verdade permite uma drenagem por vez: uma flag na memória
para um processo, ou um trabalho em segundo plano que o sistema roda sozinho. A aula 16 é o que cada
plataforma deixa um app fazer em segundo plano.
