---
title: O SQLite no seu computador, e as primeiras tabelas do planner
version: 1
---

**Um banco SQLite é um arquivo comum, e nada mais.** Nenhum servidor para iniciar, nenhuma porta,
nenhuma senha. O app abre o arquivo e o lê, do jeito que um app de celular abre
`databases/planner.db` ou `Library/Application Support/planner.db`. É por isso que ele combina com
um aparelho: o banco vai para onde a caixa de areia o põe, e as regras de backup da aula 1 valem
para ele como para qualquer outro arquivo.

Duas ferramentas o alcançam neste curso. O **`better-sqlite3`**, que a aula 1 instalou, é como os
programas do planner o usam. O **shell `sqlite3`** deixa você olhar o mesmo arquivo à mão, e vem
dos pacotes do seu sistema:

```sh
sudo apt install sqlite3
```

Num Mac ele já está lá. A versão do shell e a da biblioteca podem diferir; o formato do arquivo é o
mesmo, e qualquer um dos dois abre um arquivo que o outro gravou.

## As duas tabelas

Crie a pasta da aula, `~/planner/db`, e salve isto nela como `load.ts`. Ele cria as tabelas e copia
para elas o dado da aula 1:

```typescript
// load.ts: create the planner's database and put lesson 1's data in it.
import Database from "better-sqlite3";
import { courses, sessions } from "../data.ts";

const db = new Database("planner.db");
db.exec(`
  CREATE TABLE IF NOT EXISTS courses (
    id   TEXT PRIMARY KEY,
    name TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS sessions (
    id      TEXT PRIMARY KEY,
    course  TEXT NOT NULL REFERENCES courses (id),
    date    TEXT NOT NULL,
    minutes INTEGER NOT NULL CHECK (minutes > 0),
    done    INTEGER NOT NULL DEFAULT 0
  );
`);

const addCourse = db.prepare("INSERT OR REPLACE INTO courses (id, name) VALUES (?, ?)");
const addSession = db.prepare(
  "INSERT OR REPLACE INTO sessions (id, course, date, minutes, done) VALUES (?, ?, ?, ?, ?)",
);
for (const c of courses) addCourse.run(c.id, c.name);
for (const s of sessions) addSession.run(s.id, s.course, s.date, s.minutes, s.done ? 1 : 0);

const count = db.prepare("SELECT count(*) AS n FROM sessions").get() as { n: number };
console.log(`planner.db: ${courses.length} courses, ${count.n} sessions`);
```

O esquema diz o que o planner acredita sobre o próprio dado, e o SQLite faz cumprir. Uma sessão não
pode citar um curso que não existe, por causa do `REFERENCES`; não pode durar zero minutos, por
causa do `CHECK`. O primeiro exige as chaves estrangeiras ligadas, o que o `better-sqlite3` faz em
toda conexão e o próprio SQLite não faz: o shell `sqlite3` começa com elas desligadas, até um
`PRAGMA foreign_keys = ON`. `done` é um `INTEGER`, 0 ou 1, porque o SQLite não tem tipo booleano. O
`INSERT OR REPLACE` deixa o programa seguro para rodar duas vezes.

```
ana@dev:~/planner/db$ node load.ts
planner.db: 3 courses, 6 sessions
```

Agora o mesmo arquivo, pelo shell. `.tables` lista as tabelas; `-header -column` dispõe as linhas
como tabela:

```
ana@dev:~/planner/db$ sqlite3 planner.db .tables
courses   sessions
ana@dev:~/planner/db$ sqlite3 -header -column planner.db "SELECT * FROM sessions"
id  course      date        minutes  done
--  ----------  ----------  -------  ----
s1  spanish     2026-10-19  30       1   
s2  statistics  2026-10-20  45       1   
s3  guitar      2026-10-21  20       0   
s4  spanish     2026-10-22  30       0   
s5  statistics  2026-10-26  60       0   
s6  guitar      2026-10-28  20       0   
```

## A semana, perguntada ao banco

O `show.ts` da aula 1 calculava a semana filtrando um array. Aqui o banco faz o filtro e a soma, e
devolve só a resposta. Salve isto como `week.ts`:

```typescript
// week.ts: the week screen, asked of the database instead of computed in memory.
import Database from "better-sqlite3";

const monday = process.argv[2] ?? "2026-10-19";
const db = new Database("planner.db", { readonly: true });
const week = db.prepare(`
  SELECT c.name, count(*) AS sessions, sum(s.minutes) AS planned,
         sum(CASE WHEN s.done THEN s.minutes ELSE 0 END) AS done
  FROM sessions s JOIN courses c ON c.id = s.course
  WHERE s.date >= ? AND s.date < date(?, '+7 days')
  GROUP BY c.id ORDER BY c.name
`);
for (const row of week.all(monday, monday)) console.log(row);
```

`date(?, '+7 days')` é a aritmética de datas do próprio SQLite, aplicada às mesmas datas em texto
que a aula 1 escolheu; funciona porque `YYYY-MM-DD` se ordena como texto na mesma ordem dos dias que
nomeia.

```
ana@dev:~/planner/db$ node week.ts 2026-10-19
{ name: 'Guitar', sessions: 1, planned: 20, done: 0 }
{ name: 'Spanish A2', sessions: 2, planned: 60, done: 30 }
{ name: 'Statistics', sessions: 1, planned: 45, done: 45 }
```

**Os números são os da aula 1**: 125 minutos planejados na semana de 19 de outubro, 75 deles
feitos, espalhados por três cursos. A diferença é onde foram calculados. Com seis sessões isso não
muda nada; a próxima seção as transforma em vinte mil.
