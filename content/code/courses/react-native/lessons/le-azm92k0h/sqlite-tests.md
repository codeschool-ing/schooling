---
title: SQLite in Jest, for real
version: 1
---

**`expo-sqlite` is native code, so in Jest it has nothing to call.** The usual answer is a stand-in that
pretends, and a pretend database tests nothing about SQL: a misspelt column, a `GROUP BY` that adds the
wrong thing, a migration that fails on a table that already exists, all pass. There is a better answer
here. **Node.js has carried SQLite since version 22**, as `node:sqlite`, and Jest runs in Node.js.

The stand-in below gives the journal that SQLite, behind the three methods `Sql` asks for, and gives the
screens a `SQLiteProvider` and a `useSQLiteContext` that behave like expo-sqlite's. Save it at the top of
the project as `test-sqlite.tsx`:

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

`":memory:"` is a database that lives only as long as the object, so each provider, and each test,
starts with an empty one. `jest.setup.ts` points `expo-sqlite` at it, beside the AsyncStorage line:

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

And the screens' tests need a journal under them, as the app has. `test-utils.tsx` wraps every screen in
the provider:

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

## Two tests

`__tests__/journal.test.ts` tests the SQL directly:

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

and `__tests__/logged.test.tsx` tests the screen, through the same path a press takes: the server says
yes, the journal records, the week shows it.

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

## The types for `node:sqlite`

Check the types first:

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

**The first run fails because the project knows only the app's types and Jest's.** Lesson 3 set
`"types": ["jest"]` in `tsconfig.json`, and `node:sqlite` is described by `@types/node`. Add `"node"` to
that list, so it reads `"types": ["jest", "node"]`, and install the types for Node.js 22, the version this
course uses. The second run is clean. The cost is that the app's own files could now use Node's types
too, which on a phone describe nothing; the test helper is the only file that does.

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

**The SQL ran.** Node's SQLite printed a warning that it is experimental, which it is in Node.js 22, and
Jest passes it on; it has needed no flag since Node.js 22.13. The whole suite still passes, now
with every screen test running over an empty, real journal.
