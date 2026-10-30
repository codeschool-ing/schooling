---
title: A escrita local, e a tela que lê o banco
version: 1
---

**Num app offline-first, toda mudança vai para o banco do aparelho, e toda tela é desenhada a
partir desse banco.** Nenhuma tela lê a rede diretamente, e é essa a regra que faz o app se
comportar igual com ou sem conexão. Uma tela que buscasse do servidor "só esta lista" seria a única
tela que quebra num túnel.

A versão do planner são dois arquivos numa pasta só deles, `~/planner/offline`. O primeiro guarda o
banco. Toda linha de sessão carrega uma coluna `sync`, que é o assunto da próxima seção; por ora,
repare que uma linha nova é `pending` por padrão. Salve isto como `store.ts`:

```typescript
// store.ts: the planner's sessions on the device, each one with its sync state.
import Database from "better-sqlite3";

export type Sync = "pending" | "synced" | "failed";
export type Row = { id: string; course: string; date: string; minutes: number; sync: Sync; error: string | null };

export const db = new Database("planner.db");
db.exec(`create table if not exists sessions (
  id      text primary key,
  course  text not null,
  date    text not null,
  minutes integer not null,
  done    integer not null default 0,
  sync    text not null default 'pending' check (sync in ('pending', 'synced', 'failed')),
  error   text
)`);

// The only way the app changes a session: write it here, marked as not sent yet.
export function addSession(id: string, course: string, date: string, minutes: number) {
  db.prepare("insert into sessions (id, course, date, minutes) values (?, ?, ?, ?)").run(id, course, date, minutes);
}

export function week(monday: string): Row[] {
  return db.prepare(`select id, course, date, minutes, sync, error from sessions
    where date >= ? and date < date(?, '+7 days') order by date, id`).all(monday, monday) as Row[];
}

export function pending(): Row[] {
  return db.prepare("select id, course, date, minutes, sync, error from sessions where sync = 'pending' order by id").all() as Row[];
}

export function settle(id: string, sync: Sync, error: string | null = null) {
  db.prepare("update sessions set sync = ?, error = ? where id = ?").run(sync, error, id);
}
```

O segundo são os comandos do app, no lugar das telas. `seed` carrega as seis sessões da aula 1 como
linhas que o servidor já tem; `add` é a pessoa digitando uma sessão; `week` é a tela da semana,
lida do banco. Só o `sync` falaria com um servidor, e até a aula 8 o servidor é uma função no mesmo
arquivo. Salve isto como `app.ts`:

```typescript
// app.ts: the planner's commands. Every screen reads the database; only `sync` talks to a server.
import { addSession, week, pending, settle, type Row } from "./store.ts";
import { sessions } from "../data.ts";

const label: Record<Row["sync"], string> = { pending: "waiting to send", synced: "saved", failed: "not saved:" };

// A stand-in for the server, until lesson 8 writes a real one. It refuses what a real one would.
function server(row: Row): string | null {
  if (row.minutes > 240) return "a session is at most 240 minutes";
  return null;
}

const [command, ...args] = process.argv.slice(2);
if (command === "seed") {
  // What the server already had: lesson 1's sessions, all of them saved.
  for (const s of sessions) {
    addSession(s.id, s.course, s.date, s.minutes);
    settle(s.id, "synced");
  }
  console.log(`seeded ${sessions.length} sessions`);
} else if (command === "add") {
  const [id, course, date, minutes] = args;
  addSession(id, course, date, Number(minutes));
  console.log(`added ${id}`);
} else if (command === "week") {
  for (const r of week(args[0])) {
    console.log(`${r.date}  ${r.course.padEnd(10)} ${String(r.minutes).padStart(3)} min  ${label[r.sync]} ${r.error ?? ""}`.trimEnd());
  }
} else if (command === "sync") {
  const online = args[0] === "online";
  for (const r of pending()) {
    if (!online) { console.log(`${r.id}: no network, still pending`); continue; }
    const refused = server(r);
    settle(r.id, refused ? "failed" : "synced", refused);
    console.log(`${r.id}: ${refused ? "refused, " + refused : "accepted"}`);
  }
}
```

Carregue os dados, adicione uma sessão e desenhe a semana. Não há rede em nenhum destes três
comandos:

```
ana@dev:~/planner/offline$ node app.ts seed
seeded 6 sessions
ana@dev:~/planner/offline$ node app.ts add s7 guitar 2026-10-23 25
added s7
ana@dev:~/planner/offline$ node app.ts week 2026-10-19
2026-10-19  spanish     30 min  saved
2026-10-20  statistics  45 min  saved
2026-10-21  guitar      20 min  saved
2026-10-22  spanish     30 min  saved
2026-10-23  guitar      25 min  waiting to send
```

A sessão nova aparece na tela na hora, como `waiting to send`. Nada foi enviado, nada esperou
resposta, e a tela disse a verdade sobre as duas coisas.

## A mesma regra nas três plataformas

Cada plataforma tem um jeito de uma tela **observar** o banco, de modo que uma escrita em qualquer
ponto do app redesenhe toda tela que mostra aquela linha. *Estas listagens não foram rodadas para
este curso; elas seguem a documentação do Room, do SwiftData e do `expo-sqlite`, do Expo.*

```kotlin
// Room: the DAO returns a Flow, and the screen collects it.
@Query("SELECT * FROM sessions WHERE date >= :monday AND date < :sunday ORDER BY date")
fun week(monday: String, sunday: String): Flow<List<SessionEntity>>
```

```swift
// SwiftData: the view declares the query, and SwiftUI redraws it when the store changes.
@Query(sort: \Session.date) private var sessions: [Session]
```

```typescript
// expo-sqlite: the hook re-runs the query when the table changes.
const sessions = useLiveQuery(db.select().from(sessionsTable).orderBy(sessionsTable.date));
```

A linha do Expo usa o `useLiveQuery` do Drizzle sobre o `expo-sqlite`, que é um jeito comum; o
próprio ouvinte de mudanças da biblioteca é outro. Nos três, a tela nunca pergunta "o salvamento
funcionou?". Ela desenha o que está no banco, e foi o salvamento que pôs aquilo ali.
