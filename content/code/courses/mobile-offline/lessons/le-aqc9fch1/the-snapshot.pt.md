---
title: O snapshot, e a troca que não se vê pela metade
version: 1
---

**Uma ressincronização completa baixa todo o dado vivo do servidor num arquivo novo ao lado do
antigo, e depois troca o antigo pelo novo num único rename.** Até o rename, o app continua lendo a
cópia antiga, completa e consistente; depois dele, a nova. Não existe momento em que uma tela consiga
ler metade de cada uma.

A versão óbvia apaga todas as linhas e insere as do snapshot, dentro do banco em uso. Ela está certa
quando nada dá errado. Se o app for encerrado no meio, a pessoa abre um planner com metade das
sessões, e a próxima tela que ela vê é uma mentira. Uma transação salvaria as linhas, mas um download
leva segundos numa rede lenta, e segurar uma transação de escrita aberta durante a rede bloqueia toda
outra escrita que o app faz, inclusive as da pessoa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l12-swap\" aria-label=\"Três passos de uma ressincronização. Primeiro, as telas leem o planner.db, a cópia antiga, enquanto o planner.db.next é escrito ao lado com o snapshot do servidor e depois as linhas pendentes da caixa de saída, aplicadas de novo. Segundo, os dois arquivos são fechados. Terceiro, um rename faz do planner.db.next o novo planner.db, e as telas leem a cópia nova. Em nenhum momento um arquivo é lido pela metade.\"><defs><marker id=\"l12-swap-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">1 · escrito ao lado da cópia antiga</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.db</text><text x=\"120.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as telas o leem</text><rect x=\"20\" y=\"104\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.db.next</text><text x=\"120.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o snapshot do servidor</text><text x=\"120.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+ a caixa de saída, reaplicada</text><text x=\"300\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">2 · um rename</text><path d=\"M220 136 L300 136 L300 62 L496 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-swap-ah-amber)\"></path><text x=\"350\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">rename</text><text x=\"500\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">3 · a cópia nova</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.db</text><text x=\"600.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as telas o leem</text></svg>", "caption": "Até o rename o app lê a cópia antiga, inteira; depois dele, a nova. Nada nunca lê um arquivo escrito pela metade.", "same": ["planner.db", "planner.db.next"]}
```

## O aparelho, em três arquivos

As tabelas do aparelho, agora abertas de mais de um lugar, vão para um arquivo próprio. Salve isto
como `store.ts`:

```typescript
// store.ts: open a planner database file, with the three tables every device copy has.
import Database from "better-sqlite3";

export function open(file: string) {
  const db = new Database(file);
  db.exec(`
    create table if not exists sessions (id text primary key, course text, date text, minutes integer);
    create table if not exists outbox (seq integer primary key autoincrement, op text, session text, body text);
    create table if not exists meta (name text primary key, value text);`);
  return db;
}
```

A ressincronização em si. Leia ao lado das notas:

```schooling-example
{"language": "typescript", "file": "resync.ts", "parts": [{"code": "// resync.ts: replace the device's copy with the server's snapshot, keeping what is not sent yet.\nimport { renameSync, rmSync } from \"node:fs\";\nimport { open } from \"./store.ts\";\n", "note": "Todo o lado do aparelho numa ressincronização, numa função só, para o `device.ts` chamá-la no instante em que o servidor responder 410."}, {"code": "export async function resync(server: string, file: string) {\n  const text = await (await fetch(`${server}/snapshot`)).text();\n  const snapshot = JSON.parse(text) as { cursor: number; sessions: Record<string, unknown>[] };\n", "note": "Uma requisição por tudo o que o servidor tem, com o cursor que vai junto. É a única parte que precisa de rede, e acontece antes de qualquer coisa mudar no aparelho."}, {"code": "  rmSync(`${file}.next`, { force: true });\n  const next = open(`${file}.next`);\n  const old = open(file);\n  next.transaction(() => {", "note": "Um segundo arquivo ao lado do primeiro. Uma sobra de uma ressincronização que caiu é removida antes; o arquivo antigo é aberto só para ser lido."}, {"code": "    const save = next.prepare(\"insert or replace into sessions values (@id, @course, @date, @minutes)\");\n    for (const s of snapshot.sessions) save.run(s);\n    next.prepare(\"insert into meta values ('cursor', ?)\").run(String(snapshot.cursor));\n", "note": "O snapshot vai para o arquivo novo, com o cursor dele."}, {"code": "    const pending = old.prepare(\"select seq, op, session, body from outbox order by seq\").all() as\n      { seq: number; op: string; session: string; body: string | null }[];\n    for (const o of pending) {\n      next.prepare(\"insert into outbox values (?, ?, ?, ?)\").run(o.seq, o.op, o.session, o.body);\n      if (o.op === \"delete\") next.prepare(\"delete from sessions where id = ?\").run(o.session);\n      else save.run(JSON.parse(o.body!));\n    }\n    console.log(`snapshot: ${snapshot.sessions.length} sessions, ${text.length} bytes; ${pending.length} pending carried over`);\n  })();", "note": "Depois a caixa de saída é copiada, e cada operação pendente é aplicada de novo à cópia nova, para o trabalho não enviado da pessoa continuar na tela e continuar esperando envio."}, {"code": "  old.close();\n  next.close();\n", "note": "As duas conexões fechadas, para nada ficar meio escrito em nenhum dos arquivos."}, {"code": "  renameSync(`${file}.next`, file);\n}", "note": "A troca. Um rename dentro de uma pasta é atômico: quem abrir o `planner.db` depois recebe o arquivo antigo ou o novo, nunca uma mistura."}]}
```

E os comandos: `add` grava uma sessão e a linha dela na caixa de saída juntas, como faz a aula 8;
`pull` pede um delta e chama `resync` quando a resposta é 410; `show` imprime as sessões, marcando as
que ainda esperam envio. Salve isto como `device.ts`:

```typescript
// device.ts: the planner's copy on this device: add a session, pull changes, show what is there.
import { open } from "./store.ts";
import { resync } from "./resync.ts";

const SERVER = "http://127.0.0.1:8012";
const FILE = "planner.db";
const [command, ...a] = process.argv.slice(2);
const db = open(FILE);
const cursor = () => Number((db.prepare("select value from meta where name = 'cursor'").get() as { value: string } | undefined)?.value ?? 0);

if (command === "add") {
  const body = { id: a[0], course: a[1], date: a[2], minutes: Number(a[3]) };
  db.transaction(() => {
    db.prepare("insert into sessions values (@id, @course, @date, @minutes)").run(body);
    db.prepare("insert into outbox (op, session, body) values ('create', ?, ?)").run(a[0], JSON.stringify(body));
  })();
}
if (command === "pull") {
  const res = await fetch(`${SERVER}/changes?after=${cursor()}`);
  if (res.status === 410) {
    console.log(`410: ${(await res.json()).error}`);
    db.close();
    await resync(SERVER, FILE);
  } else {
    const { cursor: next, changes } = await res.json();
    db.transaction(() => {
      for (const c of changes) c.deleted ? db.prepare("delete from sessions where id = ?").run(c.id)
        : db.prepare("insert or replace into sessions values (@id, @course, @date, @minutes)").run(c);
      db.prepare("insert or replace into meta values ('cursor', ?)").run(String(next));
    })();
    console.log(`delta: ${changes.length} changes, cursor ${next}`);
  }
}
if (command === "show") {
  const now = open(FILE);
  const waiting = new Set((now.prepare("select session from outbox").all() as { session: string }[]).map((o) => o.session));
  for (const s of now.prepare("select * from sessions order by date, id").all() as { id: string; course: string; date: string; minutes: number }[]) {
    console.log(`${s.id.padEnd(4)} ${s.date}  ${s.course.padEnd(10)} ${String(s.minutes).padStart(3)} min${waiting.has(s.id) ? "  waiting to send" : ""}`);
  }
  console.log(`cursor ${(now.prepare("select value from meta where name = 'cursor'").get() as { value: string }).value}`);
}
```

Reinicie o servidor, busque, e repita a história da seção anterior: o delete em outro celular, o
servidor esquecendo e a busca que volta com um 410. Desta vez o aparelho responde:

```
ana@dev:~/planner/resync$ node device.ts pull
delta: 6 changes, cursor 6
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -o /dev/null -X POST http://127.0.0.1:8012/forget
ana@dev:~/planner/resync$ node device.ts pull
410: cursor 6 is older than 7; resync
snapshot: 5 sessions, 453 bytes; 0 pending carried over
ana@dev:~/planner/resync$ node device.ts show
s1   2026-10-19  spanish     30 min
s2   2026-10-20  statistics  45 min
s4   2026-10-22  spanish     30 min
s5   2026-10-26  statistics  60 min
s6   2026-10-28  guitar      20 min
cursor 7
ana@dev:~/planner/resync$ ls
device.ts
planner.db
resync.ts
server.ts
store.ts
```

Cinco sessões, `s3` fora, cursor 7: o aparelho agora bate exatamente com o servidor, a partir de uma
busca que começou com uma recusa. O `ls` mostra um arquivo de banco só. O arquivo `.next` existiu
durante a ressincronização e virou `planner.db` no rename; o nome do arquivo antigo simplesmente
passou para ele.

## Um detalhe sobre o SQLite

O rename é seguro aqui porque o `better-sqlite3`, como o SQLite por padrão, guarda um banco num
arquivo só, e as duas conexões são fechadas antes da troca. Um banco em modo WAL guarda as escritas
recentes num segundo arquivo, `planner.db-wal`, e renomear só o arquivo principal deixaria essas
escritas para trás ou, pior, as aplicaria ao arquivo errado. Um app em modo WAL faz o checkpoint e
fecha o banco antes de trocar, e Room, Core Data e SwiftData documentam cada um como fechar o próprio
armazenamento para o arquivo poder ser substituído.
