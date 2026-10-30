---
title: Buscar tudo, e quanto isso custa
version: 1
---

**As aulas 8 a 10 mandaram as mudanças do aparelho para o servidor. Esta aula traz as mudanças do
servidor para o aparelho: o que outro celular da mesma pessoa escreveu, ou o que o próprio servidor
mudou.** A primeira versão que todo mundo escreve pede tudo e substitui a cópia local por isso. Ela
está correta, e é a coisa certa a medir antes de substituir.

## O servidor, com uma sequência

A pasta desta aula é `~/planner/delta`. O servidor é o da aula 10, crescido numa direção: **toda
escrita que ele aceita recebe o próximo número de uma sequência única**, e uma linha lembra o número
da sua última escrita. Um delete não remove a linha; ele a marca, e a última seção da aula diz por
quê. Ele também guarda um carimbo, a hora que o celular que escreveu disse que era, que é o assunto
da terceira seção. Ele começa com as seis sessões da aula 1, e o `POST /fill` acrescenta quantas mais
você pedir, as mesmas em toda execução, para você medir um planner com alguns anos de uso. Salve isto
como `server.ts`:

```typescript
// server.ts: lesson 10's server, grown for this lesson. Every write gets the next number in one
// sequence, and a delete leaves a tombstone, so a client can ask what changed after a number.
import { createServer, type ServerResponse } from "node:http";
import { sessions as starting } from "../data.ts";

type Row = { id: string; course: string; date: string; minutes: number; seq: number; stamp: string; deleted?: true };
const rows = new Map<string, Row>();
let seq = 0;

function write(id: string, fields: Partial<Row>, stamp: string) {
  rows.set(id, { ...(rows.get(id) ?? {}), ...fields, id, seq: ++seq, stamp } as Row);
}
for (const s of starting) write(s.id, s, "2026-10-19T08:00:00Z");

function reply(res: ServerResponse, body: unknown) {
  res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(body));
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const url = new URL(req.url!, "http://x");
  const id = url.pathname.split("/")[2];
  if (req.method === "POST" && url.pathname === "/fill") {
    // A planner with a few years in it: n more sessions, the same ones on every run.
    for (let i = 1; i <= Number(url.searchParams.get("n")); i++) {
      write(`h${i}`, { course: ["spanish", "statistics", "guitar"][i % 3], date: "2025-01-01", minutes: 15 + (i % 4) * 15 }, "2026-10-19T08:00:00Z");
    }
    return reply(res, { seq });
  }
  if (req.method === "PUT") { write(id, JSON.parse(text), url.searchParams.get("stamp")!); return reply(res, rows.get(id)); }
  if (req.method === "DELETE") { write(id, { deleted: true }, url.searchParams.get("stamp")!); return reply(res, rows.get(id)); }
  const all = [...rows.values()];
  if (url.pathname === "/sessions") return reply(res, all.filter((r) => !r.deleted));
  if (url.pathname === "/changes") {
    const after = Number(url.searchParams.get("after") ?? 0);
    return reply(res, { cursor: seq, changes: all.filter((r) => r.seq > after) });
  }
  if (url.pathname === "/changed-since") {
    const t = url.searchParams.get("t")!;
    return reply(res, all.filter((r) => r.stamp > t && !r.deleted));
  }
  res.writeHead(404).end();
}).listen(8011, "127.0.0.1", () => console.log("listening on 8011"));
```

O lado do aparelho guarda uma cópia no SQLite e um marcador, `cursor`, numa tabela só dele. `all`
pede todas as sessões e substitui a cópia; `delta` pede só o que mudou depois do marcador, que a
próxima seção usa. Salve isto como `pull.ts`:

```typescript
// pull.ts: bring the device's copy up to date, all of it or only what changed.
// node pull.ts all | node pull.ts delta
import Database from "better-sqlite3";

const SERVER = "http://127.0.0.1:8011";
const db = new Database("planner.db");
db.exec(`create table if not exists sessions (id text primary key, course text, date text, minutes integer);
         create table if not exists meta (name text primary key, value text)`);
const cursor = () => Number((db.prepare("select value from meta where name = 'cursor'").get() as { value: string } | undefined)?.value ?? 0);
const save = db.prepare("insert or replace into sessions values (@id, @course, @date, @minutes)");
const drop = db.prepare("delete from sessions where id = ?");

type Change = { id: string; course: string; date: string; minutes: number; deleted?: true };
let text: string, changes: Change[], next: number;
if (process.argv[2] === "all") {
  text = await (await fetch(`${SERVER}/sessions`)).text();
  changes = JSON.parse(text);
  next = cursor();
  db.exec("delete from sessions");
} else {
  text = await (await fetch(`${SERVER}/changes?after=${cursor()}`)).text();
  ({ cursor: next, changes } = JSON.parse(text));
}
db.transaction(() => {
  for (const c of changes) c.deleted ? drop.run(c.id) : save.run(c);
  db.prepare("insert or replace into meta values ('cursor', ?)").run(String(next));
})();
const { n } = db.prepare("select count(*) as n from sessions").get() as { n: number };
console.log(`received ${changes.length} ${changes.length === 1 ? "row" : "rows"}, ${text.length} bytes; cursor ${cursor()}; ${n} sessions on the device`);
```

Suba o servidor num segundo terminal com `node server.ts`, dê a ele mais duas mil sessões e busque
tudo duas vezes:

```
ana@dev:~/planner/delta$ curl -s -X POST 'http://127.0.0.1:8011/fill?n=2000'; echo
{"seq":2006}
ana@dev:~/planner/delta$ node pull.ts all
received 2006 rows, 217837 bytes; cursor 0; 2006 sessions on the device
ana@dev:~/planner/delta$ node pull.ts all
received 2006 rows, 217837 bytes; cursor 0; 2006 sessions on the device
```

**A segunda busca moveu 217.837 bytes para descobrir que nada tinha mudado.** Esse é o formato de
buscar tudo: o custo acompanha o tamanho do dado, não o tamanho da mudança, e o tamanho do dado só
cresce. Um planner aberto dez vezes por dia na rede móvel paga isso dez vezes, em dados, em bateria
para o rádio e no tempo até a tela ficar atualizada.

Existe um custo mais silencioso também. Substituir a cópia local inteira joga fora tudo o que o
aparelho guarda e o servidor ainda não viu, então isso só pode rodar com a caixa de saída vazia, e a
aula 12 mostra um download completo que respeita isso. Para a sincronização do dia a dia, a pergunta
tem de mudar de "o que existe?" para "o que mudou desde a última vez que perguntei?", e a próxima
seção é como o aparelho pergunta isso.
