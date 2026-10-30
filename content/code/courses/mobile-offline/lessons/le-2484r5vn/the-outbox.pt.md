---
title: A caixa de saída, gravada junto com a mudança
version: 1
---

**Uma caixa de saída (*outbox*) é uma tabela de operações que o servidor ainda não viu, e cada uma é
gravada na mesma transação da mudança que descreve.** A aula 7 guardava um fato por linha, `pending`
ou `synced`. Isso diz *que* uma linha precisa ser enviada e nada sobre *o que* enviar: uma sessão
criada, depois alongada, depois apagada é uma linha só nesse desenho, e o servidor precisa ouvir as
três coisas, ou pelo menos a última.

A imagem errada é a de que a caixa de saída é uma lista de requisições que o app fez offline e vai
repetir depois. Ela não é uma lista de requisições. É uma lista de **mudanças no dado do planner**,
na ordem em que aconteceram, guardada ao lado do dado para que os dois nunca discordem.

## Por que a mesma transação

Grave a sessão e depois, separadamente, a linha da caixa de saída, e existe um instante entre as
duas. Se o app for encerrado nesse instante, pelo sistema recuperando memória ou pela bateria, a
sessão está no aparelho e nada jamais vai enviá-la. **Nenhum erro aparece, e a linha parece
exatamente uma que foi enviada.** Gravadas numa transação, as duas chegam juntas ou nenhuma chega.

## A caixa de saída do planner

A pasta desta aula é `~/planner/outbox`. Três tabelas: as sessões, a caixa de saída e uma terceira,
`dead`, de que a última seção da aula precisa. Cada mudança é uma função envolvida em
`db.transaction`, que o `better-sqlite3` transforma em `BEGIN` e `COMMIT` em volta dela, ou
`ROLLBACK` se ela lançar um erro. Salve isto como `store.ts`:

```typescript
// store.ts: the planner's sessions, and the outbox of operations the server has not seen yet.
import Database from "better-sqlite3";

export const db = new Database("planner.db");
db.exec(`
create table if not exists sessions (
  id text primary key, course text not null, date text not null, minutes integer not null);
create table if not exists outbox (
  seq     integer primary key autoincrement,
  op      text not null check (op in ('create', 'update', 'delete')),
  session text not null,
  body    text);
create table if not exists dead (
  seq integer primary key, op text not null, session text not null, body text, reason text not null);
`);

const enqueue = db.prepare("insert into outbox (op, session, body) values (?, ?, ?)");
const row = db.prepare("select id, course, date, minutes from sessions where id = ?");

// Each change and its outbox row are written together, or not at all.
export const addSession = db.transaction((id: string, course: string, date: string, minutes: number) => {
  db.prepare("insert into sessions values (?, ?, ?, ?)").run(id, course, date, minutes);
  enqueue.run("create", id, JSON.stringify(row.get(id)));
});
export const setMinutes = db.transaction((id: string, minutes: number) => {
  db.prepare("update sessions set minutes = ? where id = ?").run(minutes, id);
  enqueue.run("update", id, JSON.stringify(row.get(id)));
});
export const removeSession = db.transaction((id: string) => {
  db.prepare("delete from sessions where id = ?").run(id);
  enqueue.run("delete", id, null);
});
```

`seq` é a ordem. O `AUTOINCREMENT` faz o SQLite entregar um número maior que qualquer um já usado
nesta tabela, mesmo um que já foi apagado, então uma operação acrescentada depois nunca fica antes
de uma acrescentada antes. O corpo é a linha inteira como ficou depois da mudança, não a mudança em
si; a próxima seção diz por que isso é o mais fácil de enviar.

Os comandos, no lugar das telas do planner. O `revive` é para a última seção; ignore por enquanto.
Salve isto como `app.ts`:

```typescript
// app.ts: the planner's commands for this lesson: change sessions, and look at the outbox.
import { db, addSession, setMinutes, removeSession } from "./store.ts";

const [command, ...a] = process.argv.slice(2);
if (command === "add") addSession(a[0], a[1], a[2], Number(a[3]));
if (command === "minutes") setMinutes(a[0], Number(a[1]));
if (command === "remove") removeSession(a[0]);
if (command === "revive") {
  // The person fixed a session the server refused: send it again as it is now.
  db.transaction(() => {
    const dead = db.prepare("select op from dead where session = ? order by seq").get(a[0]) as { op: string };
    db.prepare("delete from dead where session = ?").run(a[0]);
    db.prepare("delete from outbox where session = ?").run(a[0]);
    const now = db.prepare("select * from sessions where id = ?").get(a[0]);
    db.prepare("insert into outbox (op, session, body) values (?, ?, ?)").run(dead.op === "create" ? "create" : "update", a[0], JSON.stringify(now));
  })();
}
if (command === "outbox") {
  for (const o of db.prepare("select seq, op, session, body from outbox order by seq").all() as any[]) {
    console.log(`#${o.seq} ${o.op.padEnd(6)} ${o.session}  ${o.body ?? ""}`.trimEnd());
  }
  for (const d of db.prepare("select seq, op, session, reason from dead order by seq").all() as any[]) {
    console.log(`dead #${d.seq} ${d.op} ${d.session}: ${d.reason}`);
  }
}
```

Adicione uma sessão, alongue-a, adicione uma segunda e veja o que está esperando:

```
ana@dev:~/planner/outbox$ node app.ts add s7 guitar 2026-10-23 25
ana@dev:~/planner/outbox$ node app.ts minutes s7 30
ana@dev:~/planner/outbox$ node app.ts add s8 statistics 2026-10-24 40
ana@dev:~/planner/outbox$ node app.ts outbox
#1 create s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}
#2 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":30}
#3 create s8  {"id":"s8","course":"statistics","date":"2026-10-24","minutes":40}
```

Três mudanças, três operações, em ordem. Nada foi enviado, porque nada nestes comandos sabe que
existe um servidor.
