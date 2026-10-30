---
title: Uma segunda versão do schema
version: 1
---

**Um celular mantém o banco em toda atualização do app**, então o schema da versão que a pessoa instalou
há um ano continua lá quando a versão de hoje abre. Mudar o schema nunca é editar o `CREATE TABLE`: um
celular que já tem a tabela nunca o rodaria de novo. É acrescentar uma migração.

Os totais do diário agrupam por curso, e conforme a tabela cresce o SQLite leria todas as linhas para
isso. Um índice no curso é a segunda versão. No `src/journal.ts`, acrescente uma linha ao fim de
`MIGRATIONS`:

```ts
// src/journal.ts: a log, kept on this phone, of every session marked done here, and what it adds up to.
// It asks for three methods and no more, so a test can hand it any SQLite that has them.
export interface Sql {
  execAsync(source: string): Promise<void>;
  runAsync(source: string, ...params: (string | number)[]): Promise<unknown>;
  getAllAsync<T>(source: string, ...params: (string | number)[]): Promise<T[]>;
}

// Each entry moves the database one version on. Entries are only ever added at the end.
const MIGRATIONS = [
  "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL)",
  "CREATE INDEX done_by_course ON done (course)",
];

export async function migrate(db: Sql) {
  const [{ user_version: from }] = await db.getAllAsync<{ user_version: number }>("PRAGMA user_version");
  for (let v = from; v < MIGRATIONS.length; v++) {
    await db.execAsync(`BEGIN; ${MIGRATIONS[v]}; PRAGMA user_version = ${v + 1}; COMMIT;`);
  }
}

export type Done = { id: string; course: string; minutes: number };

export async function record(db: Sql, s: Done, at: string) {
  await db.runAsync(
    "INSERT OR IGNORE INTO done (session, course, minutes, done_at) VALUES (?, ?, ?, ?)",
    s.id, s.course, s.minutes, at,
  );
}

export function totals(db: Sql) {
  return db.getAllAsync<{ course: string; minutes: number }>(
    "SELECT course, sum(minutes) AS minutes FROM done GROUP BY course ORDER BY course",
  );
}
```

**Entradas só são acrescentadas no fim.** A versão 1 é o que a primeira entrada fez em todo celular que a
rodou; mudá-la agora não mudaria nada nesses celulares e mudaria outra coisa nos novos, e os dois
discordariam em silêncio.

O teste que importa é o de um celular já na versão 1, com linhas dentro. No `__tests__/journal.test.ts`, o
primeiro teste agora espera a versão 2, e um quarto monta à mão um banco da versão 1, como ele era, e o
migra:

```ts
// __tests__/journal.test.ts: the journal's SQL, run by Node's own SQLite in memory.
import { migrate, record, totals } from "../src/journal";
import { openTestDatabase } from "../test-sqlite";

const guitar = { id: "s3", course: "guitar", minutes: 20 };
const spanish = { id: "s4", course: "spanish", minutes: 30 };

test("an empty database is brought to the latest version", async () => {
  const db = openTestDatabase();
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 2 }]);
  expect(await totals(db)).toEqual([]);
});

test("totals are per course, and a session logged twice counts once", async () => {
  const db = openTestDatabase();
  await migrate(db);
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await record(db, spanish, "2026-10-22T18:00:00Z");
  await record(db, guitar, "2026-10-21T18:05:00Z"); // a retry: same session
  expect(await totals(db)).toEqual([
    { course: "guitar", minutes: 20 },
    { course: "spanish", minutes: 30 },
  ]);
});

test("migrating twice changes nothing", async () => {
  const db = openTestDatabase();
  await migrate(db);
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await migrate(db);
  expect(await totals(db)).toEqual([{ course: "guitar", minutes: 20 }]);
});

test("a database left at version 1 moves to version 2 and keeps its rows", async () => {
  const db = openTestDatabase();
  // how version 1 left a phone: the table, one row, and the version number
  await db.execAsync(
    "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL);" +
      "PRAGMA user_version = 1;",
  );
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 2 }]);
  expect(await db.getAllAsync("SELECT name FROM sqlite_master WHERE name = 'done_by_course'")).toHaveLength(1);
  expect(await totals(db)).toEqual([{ course: "guitar", minutes: 20 }]);
});
```

```
ana@dev:~/planner$ npx jest journal --verbose --forceExit
(node:19) ExperimentalWarning: SQLite is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
PASS __tests__/journal.test.ts
  ✓ an empty database is brought to the latest version (5 ms)
  ✓ totals are per course, and a session logged twice counts once (1 ms)
  ✓ migrating twice changes nothing (1 ms)
  ✓ a database left at version 1 moves to version 2 and keeps its rows (2 ms)

Test Suites: 1 passed, 1 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        0.725 s, estimated 1 s
Ran all test suites matching journal.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**A linha sobreviveu à atualização, e o índice está lá.** Esse é o teste a escrever para toda migração,
porque "um celular novo funciona" é o que todo desenvolvedor confere sem querer, e "um celular do ano
passado funciona" é o que ninguém confere até uma avaliação na loja dizer que o app perdeu os dados de
alguém.
