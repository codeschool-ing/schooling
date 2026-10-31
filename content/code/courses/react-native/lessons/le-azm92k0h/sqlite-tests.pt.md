---
title: SQLite no Jest, de verdade
version: 1
---

**O `expo-sqlite` é código nativo, então no Jest ele não tem o que chamar.** A resposta de costume é um
substituto que finge, e um banco de faz de conta não testa nada de SQL: uma coluna com o nome errado, um
`GROUP BY` que soma a coisa errada, uma migração que falha numa tabela que já existe, tudo passa. Aqui há
uma resposta melhor. **O Node.js traz o SQLite desde a versão 22**, como `node:sqlite`, e o Jest roda no
Node.js.

O substituto abaixo dá ao diário esse SQLite, por trás dos três métodos que o `Sql` pede, e dá às telas um
`SQLiteProvider` e um `useSQLiteContext` que se comportam como os do expo-sqlite. Salve-o na raiz do
projeto como `test-sqlite.tsx`:

```tsx
// test-sqlite.tsx: expo-sqlite for Jest, on Node's own SQLite. The same SQL runs for real, in memory,
// one database per provider, so every test starts empty.
import { DatabaseSync } from "node:sqlite";
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import type { Sql } from "./src/journal";

export function openTestDatabase(): Sql {
  const db = new DatabaseSync(":memory:");
  return {
    execAsync: async (source) => void db.exec(source),
    runAsync: async (source, ...params) => db.prepare(source).run(...params),
    getAllAsync: async <T,>(source: string, ...params: (string | number)[]) => db.prepare(source).all(...params) as T[],
  };
}

const Database = createContext<Sql | null>(null);

export function SQLiteProvider({ onInit, children }: { onInit?: (db: Sql) => Promise<void>; children: ReactNode }) {
  const [db, setDb] = useState<Sql | null>(null);
  useEffect(() => {
    const opened = openTestDatabase();
    (onInit ? onInit(opened) : Promise.resolve()).then(() => setDb(opened));
  }, [onInit]);
  return db && <Database.Provider value={db}>{children}</Database.Provider>;
}

export function useSQLiteContext() {
  const db = useContext(Database);
  if (!db) throw new Error("useSQLiteContext needs a SQLiteProvider above it");
  return db;
}
```

O `":memory:"` é um banco que vive só enquanto o objeto existe, então cada provider, e cada teste, começa
com um vazio. O `jest.setup.ts` aponta o `expo-sqlite` para ele, ao lado da linha do AsyncStorage:

```ts
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
// Reanimated 4.7 cannot start inside jest-expo 58, not even as its own stand-in, so the one
// component that uses it is replaced by its children. The rule it applies is tested on its own.
jest.mock("./src/SwipeRow", () => ({ SwipeRow: ({ children }: { children: unknown }) => children }));
// AsyncStorage's own stand-in keeps everything in memory, so every test file starts with nothing stored,
// and SQLite is Node's own, for real: see test-sqlite.tsx.
jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock"),
);
jest.mock("expo-sqlite", () => require("./test-sqlite"));
```

E os testes das telas precisam de um diário embaixo, como o app tem. O `test-utils.tsx` envolve toda tela
no provider:

```tsx
// test-utils.tsx: what a screen test puts around a screen: a query client whose plan has already loaded,
// and an empty journal.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { SQLiteProvider } from "expo-sqlite";
import type { ReactElement } from "react";
import data from "./src/courses.json";
import { migrate } from "./src/journal";
import type { Plan } from "./src/planner";

export function withPlan(ui: ReactElement, plan: Plan = data) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  client.setQueryData(["plan"], plan);
  return (
    <QueryClientProvider client={client}>
      <SQLiteProvider databaseName="planner.db" onInit={migrate}>
        {ui}
      </SQLiteProvider>
    </QueryClientProvider>
  );
}
```

## Dois testes

O `__tests__/journal.test.ts` testa o SQL diretamente:

```ts
// __tests__/journal.test.ts: the journal's SQL, run by Node's own SQLite in memory.
import { migrate, record, totals } from "../src/journal";
import { openTestDatabase } from "../test-sqlite";

const guitar = { id: "s3", course: "guitar", minutes: 20 };
const spanish = { id: "s4", course: "spanish", minutes: 30 };

test("an empty database is brought to the latest version", async () => {
  const db = openTestDatabase();
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 1 }]);
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
```

e o `__tests__/logged.test.tsx` testa a tela, pelo mesmo caminho que um toque faz: o servidor diz sim, o
diário registra, a semana mostra.

```tsx
// __tests__/logged.test.tsx: a session the server agrees is done reaches the journal, and the week shows it.
import { NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");

test("the week shows what this phone has logged", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
  expect(await screen.findByText("Nothing logged on this phone yet")).toBeOnTheScreen();
  await fireEvent.press(screen.getByRole("button", { name: "Mark 20 min on 2026-10-21 done" }));
  expect(await screen.findByText("Logged on this phone: Guitar 20 min")).toBeOnTheScreen();
});
```

## Os tipos do `node:sqlite`

Confira os tipos primeiro:

```
ana@dev:~/planner$ npx tsc --noEmit
test-sqlite.tsx(3,30): error TS2591: Cannot find name 'node:sqlite'. Do you need to install type definitions for node? Try `npm i --save-dev @types/node` and then add 'node' to the types field in your tsconfig.
ana@dev:~/planner$ npm install -E -D @types/node@22.20.5

changed 2 packages, and audited 1122 packages in 3s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npx tsc --noEmit
```

**A primeira execução falha porque o projeto só conhece os tipos do app e os do Jest.** A aula 3 pôs
`"types": ["jest"]` no `tsconfig.json`, e o `node:sqlite` é descrito pelo `@types/node`. Acrescente
`"node"` a essa lista, para ela ficar `"types": ["jest", "node"]`, e instale os tipos do Node.js 22, a
versão que este curso usa. A segunda execução passa limpa. O custo é que os arquivos do próprio app agora
poderiam usar os tipos do Node também, que num celular não descrevem nada; o auxiliar de teste é o único
arquivo que os usa.

```
ana@dev:~/planner$ npx jest journal logged --verbose --forceExit
(node:54) ExperimentalWarning: SQLite is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
PASS __tests__/journal.test.ts
  ✓ an empty database is brought to the latest version (15 ms)
  ✓ totals are per course, and a session logged twice counts once (1 ms)
  ✓ migrating twice changes nothing (1 ms)

(node:55) ExperimentalWarning: SQLite is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
PASS __tests__/logged.test.tsx (12.638 s)
  ✓ the week shows what this phone has logged (1840 ms)

Test Suites: 2 passed, 2 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        12.982 s
Ran all test suites matching journal|logged.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       47 passed, 47 total
Snapshots:   0 total
Time:        9.89 s, estimated 13 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**O SQL rodou.** O SQLite do Node imprimiu um aviso de que é experimental, o que ele é no Node.js 22, e o
Jest o repassa; ele não precisa de flag desde o Node.js 22.13. A suíte inteira continua passando, agora com
todo teste de tela rodando sobre um diário vazio e de verdade.
