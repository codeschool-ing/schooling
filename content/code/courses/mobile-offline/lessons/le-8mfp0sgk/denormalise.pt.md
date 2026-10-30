---
title: Normalizar menos: a contagem guardada na linha do curso
version: 1
---

**Num aparelho, muitas vezes é certo guardar um número que daria para calcular, desde que algo o
mantenha verdadeiro.** A lista de cursos mostra a contagem de sessões e os minutos planejados de
cada curso. Calculado, isso é um join e um `GROUP BY` sobre toda sessão que a pessoa já planejou, a
cada abertura. Guardado na linha do curso, é a leitura de três linhas. O preço é que toda escrita em
`sessions` agora precisa atualizar também `courses`, e o perigo é a escrita que esquece.

Este programa mantém os dois números na linha do curso de dois jeitos: pelo código do próprio app,
do jeito que costuma ser escrito primeiro, e por triggers no banco. No modo app, adicionar e
redimensionar uma sessão atualizam as contagens, e removê-la não, que é o bug que vai para
produção. Salve como `denorm.ts` na `~/planner/model`:

```typescript
// denorm.ts: the course list's counts kept on the course row, by the app's code or by triggers.
import Database from "better-sqlite3";
import { courses, sessions } from "../data.ts";

const mode = process.argv[2]; // "app" or "triggers"
const db = new Database(":memory:");
db.exec(`
  CREATE TABLE courses (id TEXT PRIMARY KEY, name TEXT NOT NULL,
                        session_count INTEGER NOT NULL DEFAULT 0,
                        minutes_planned INTEGER NOT NULL DEFAULT 0);
  CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL REFERENCES courses (id),
                         date TEXT NOT NULL, minutes INTEGER NOT NULL, done INTEGER NOT NULL DEFAULT 0);
`);
if (mode === "triggers") {
  db.exec(`
    CREATE TRIGGER session_added AFTER INSERT ON sessions BEGIN
      UPDATE courses SET session_count = session_count + 1,
                         minutes_planned = minutes_planned + NEW.minutes WHERE id = NEW.course;
    END;
    CREATE TRIGGER session_removed AFTER DELETE ON sessions BEGIN
      UPDATE courses SET session_count = session_count - 1,
                         minutes_planned = minutes_planned - OLD.minutes WHERE id = OLD.course;
    END;
    CREATE TRIGGER session_changed AFTER UPDATE OF course, minutes ON sessions BEGIN
      UPDATE courses SET session_count = session_count - 1,
                         minutes_planned = minutes_planned - OLD.minutes WHERE id = OLD.course;
      UPDATE courses SET session_count = session_count + 1,
                         minutes_planned = minutes_planned + NEW.minutes WHERE id = NEW.course;
    END;
  `);
}

// The app's three writes. In "app" mode they keep the counts themselves, and one of them forgets.
const bump = db.prepare(
  "UPDATE courses SET session_count = session_count + ?, minutes_planned = minutes_planned + ? WHERE id = ?",
);
const add = db.transaction((id: string, course: string, date: string, minutes: number) => {
  db.prepare("INSERT INTO sessions (id, course, date, minutes) VALUES (?, ?, ?, ?)").run(id, course, date, minutes);
  if (mode === "app") bump.run(1, minutes, course);
});
const resize = db.transaction((id: string, minutes: number) => {
  const old = db.prepare("SELECT course, minutes FROM sessions WHERE id = ?").get(id) as { course: string; minutes: number };
  db.prepare("UPDATE sessions SET minutes = ? WHERE id = ?").run(minutes, id);
  if (mode === "app") bump.run(0, minutes - old.minutes, old.course);
});
const remove = db.transaction((id: string) => {
  db.prepare("DELETE FROM sessions WHERE id = ?").run(id); // the counts are not touched here
});

for (const c of courses) db.prepare("INSERT INTO courses (id, name) VALUES (?, ?)").run(c.id, c.name);
for (const s of sessions) add(s.id, s.course, s.date, s.minutes);
resize("s5", 50);
remove("s3");

console.log("the course list, read from the course rows alone:");
for (const r of db.prepare("SELECT name, session_count, minutes_planned FROM courses ORDER BY name").all()) {
  console.log(" ", r);
}
// The check: what the rows say against what the sessions add up to.
const drift = db.prepare(`
  SELECT c.id, c.session_count AS stored, count(s.id) AS counted
  FROM courses c LEFT JOIN sessions s ON s.course = c.id
  GROUP BY c.id HAVING stored <> counted OR c.minutes_planned <> coalesce(sum(s.minutes), 0)
`).all();
if (drift.length === 0) console.log("check: every stored count matches the sessions");
else console.log("check: drift in", drift);
```

As duas execuções carregam as seis sessões da aula 1, aumentam a `s5` para 50 minutos e removem a
`s3`, a sessão de violão do dia 21 de outubro:

```
ana@dev:~/planner/model$ node denorm.ts app
the course list, read from the course rows alone:
  { name: 'Guitar', session_count: 2, minutes_planned: 40 }
  { name: 'Spanish A2', session_count: 2, minutes_planned: 60 }
  { name: 'Statistics', session_count: 2, minutes_planned: 95 }
check: drift in [ { id: 'guitar', stored: 2, counted: 1 } ]
ana@dev:~/planner/model$ node denorm.ts triggers
the course list, read from the course rows alone:
  { name: 'Guitar', session_count: 1, minutes_planned: 20 }
  { name: 'Spanish A2', session_count: 2, minutes_planned: 60 }
  { name: 'Statistics', session_count: 2, minutes_planned: 95 }
check: every stored count matches the sessions
```

**No modo app, a lista de cursos diz que Guitar tem duas sessões e 40 minutos, e ele tem uma sessão
e 20.** Nada falhou. A tela desenha um número errado com toda a confiança, e continua desenhando até
a próxima edição tocar, por acaso, o mesmo curso. A conferência no fim, que recalcula os números a
partir das sessões e compara, é a única coisa que percebeu.

Com triggers, o banco faz a conta em toda inserção, atualização e exclusão, na mesma transação da
mudança, seja qual for o caminho de código que a fez. É por isso que a regra que este curso segue é
**manter um total guardado na mesma transação das linhas que ele soma**, e deixar o banco fazer isso
onde der. O Room aceita triggers no SQL de uma migração e uma `@DatabaseView` do lado da leitura; o
Core Data e o SwiftData mantêm valores derivados em código, então ali a conferência importa mais.

## O que isso custa

Toda escrita de sessão agora grava duas linhas em vez de uma, e o esquema tem três triggers que
quem lê `sessions` precisa saber que existem. Outros dois custos são menos óbvios.

- **A sincronização**: a aula 11 traz linhas do servidor. Se o servidor manda sessões, os triggers
  mantêm as contagens certas. Se ele também manda a linha do curso com as contagens dele, as duas
  coisas não podem ser aplicadas juntas, ou os totais são contados duas vezes.
- **Vale a pena manter a conferência.** Rode-a nos testes, e numa build de depuração na abertura. Um
  total guardado sem conferência é uma afirmação que ninguém verifica.

A tela da semana é o caso oposto. Ela também é lida com frequência, mas a resposta depende da semana
que a pessoa está olhando, então não existe um número único para guardar; o índice em `date` da
aula 3 é a resposta certa ali, não uma coluna.
