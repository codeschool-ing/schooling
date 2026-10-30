---
title: Quando não dá para confiar num delta
version: 1
---

**Uma sincronização por delta é uma promessa de que a cópia do aparelho mais as mudanças desde o
cursor é igual ao dado do servidor. Quatro coisas quebram a promessa, e em cada uma a jogada correta
mais barata é jogar a cópia fora e baixar uma nova.** Esse download é uma **ressincronização
completa**. Ela custa mais que um delta, e ainda assim sai mais barata, porque a alternativa é uma
cópia errada de jeitos que ninguém consegue ver.

| o que aconteceu | por que um delta não resolve |
|---|---|
| o cursor é mais antigo que o histórico que o servidor guardou | as lápides de que ele precisa sumiram (aula 11) |
| a versão nova do app lê o dado de outro jeito | um delta traz linhas novas no formato novo, não as linhas antigas reformatadas |
| o arquivo local está danificado | deltas supõem que a cópia que remendam está sã |
| outra pessoa entra no aparelho | o cursor e as linhas pertencem a outra pessoa |

A primeira é a que um servidor precisa anunciar, porque só o servidor sabe até onde se lembra. As
outras o aparelho detecta sozinho: a segunda por uma versão de esquema que o app guarda ao lado do
cursor, a terceira pelo próprio `PRAGMA integrity_check` do SQLite falhando, a quarta pelo id da
conta mudando. A aula 5 é como uma versão de esquema é guardada no aparelho.

## O servidor avisa

A pasta desta aula é `~/planner/resync`. O servidor é o da aula 11, crescido: o `POST /forget` larga
todas as lápides, como um servidor de verdade faz periodicamente, e lembra que o histórico antes
daquele ponto se foi. Depois disso, uma requisição com um cursor mais antigo recebe **410 Gone**, o
status HTTP para "isto existiu e não vai existir de novo", e uma frase dizendo o que fazer. Ele
também entrega todo o seu dado vivo, com o cursor correspondente, em `/snapshot`. Salve isto como
`server.ts`:

```typescript
// server.ts: lesson 11's server, grown for this lesson. It can forget old tombstones, and then it
// refuses a cursor older than what it still remembers, with 410 Gone; and it hands out a snapshot.
import { createServer, type ServerResponse } from "node:http";
import { sessions as starting } from "../data.ts";

type Row = { id: string; course: string; date: string; minutes: number; seq: number; deleted?: true };
const rows = new Map<string, Row>();
let seq = 0;
let oldest = 0; // the oldest cursor the server can still answer from

const write = (id: string, fields: Partial<Row>) => rows.set(id, { ...(rows.get(id) ?? {}), ...fields, id, seq: ++seq } as Row);
for (const s of starting) write(s.id, s);

function reply(res: ServerResponse, status: number, body: unknown) {
  res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(body));
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const url = new URL(req.url!, "http://x");
  const n = Number(url.searchParams.get("n") ?? url.searchParams.get("after") ?? 0);
  const live = () => [...rows.values()].filter((r) => !r.deleted);
  if (req.method === "POST" && url.pathname === "/fill") {
    for (let i = 1; i <= n; i++) write(`h${i}`, { course: ["spanish", "statistics", "guitar"][i % 3], date: "2025-01-01", minutes: 15 + (i % 4) * 15 });
    return reply(res, 200, { seq });
  }
  if (req.method === "POST" && url.pathname === "/forget") {
    // Drop every tombstone, and with them the history before now.
    for (const [id, r] of rows) if (r.deleted) rows.delete(id);
    oldest = seq;
    return reply(res, 200, { oldest });
  }
  if (req.method === "DELETE") { write(url.pathname.split("/")[2], { deleted: true }); return reply(res, 200, { seq }); }
  if (req.method === "PUT") { write(url.pathname.split("/")[2], JSON.parse(text)); return reply(res, 200, { seq }); }
  if (url.pathname === "/changes") {
    if (n < oldest) return reply(res, 410, { error: `cursor ${n} is older than ${oldest}; resync` });
    return reply(res, 200, { cursor: seq, changes: [...rows.values()].filter((r) => r.seq > n) });
  }
  if (url.pathname === "/snapshot") return reply(res, 200, { cursor: seq, sessions: live() });
  res.writeHead(404).end();
}).listen(8012, "127.0.0.1", () => console.log("listening on 8012"));
```

Suba-o num segundo terminal com `node server.ts`. Um celular que buscou pela última vez no cursor 6
fica fora enquanto outro celular apaga `s3` e o servidor esquece as lápides; depois ele pede o delta:

```
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -X POST http://127.0.0.1:8012/forget; echo
{"oldest":7}
ana@dev:~/planner/resync$ curl -s -w ' %{http_code}\n' 'http://127.0.0.1:8012/changes?after=6'
{"error":"cursor 6 is older than 7; resync"} 410
```

O servidor poderia ter respondido com as mudanças que ainda tem, e o celular guardaria `s3` para
sempre, sem jeito de saber que ela foi apagada. **Dizer 410 é o servidor sendo honesto sobre o limite
da própria memória**, e é a deixa do aparelho para tudo o que o resto desta aula constrói.
