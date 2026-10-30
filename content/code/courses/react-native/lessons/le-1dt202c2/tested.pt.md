---
title: Testes, e os dados do ano passado
version: 1
---

A versão do diário agora é 3, então os testes que a conferem dizem 3, e um quinto teste confere o
`places`. Aqui está o `__tests__/journal.test.ts` com as duas mudanças:

```ts
// __tests__/journal.test.ts: the journal's SQL, run by Node's own SQLite in memory.
import { migrate, places, record, totals } from "../src/journal";
import { openTestDatabase } from "../test-sqlite";

const guitar = { id: "s3", course: "guitar", minutes: 20 };
const spanish = { id: "s4", course: "spanish", minutes: 30 };

test("an empty database is brought to the latest version", async () => {
  const db = openTestDatabase();
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 3 }]);
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

test("a database left at version 1 moves to the latest version and keeps its rows", async () => {
  const db = openTestDatabase();
  // how version 1 left a phone: the table, one row, and the version number
  await db.execAsync(
    "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL);" +
      "PRAGMA user_version = 1;",
  );
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 3 }]);
  expect(await db.getAllAsync("SELECT name FROM sqlite_master WHERE name = 'done_by_course'")).toHaveLength(1);
  expect(await totals(db)).toEqual([{ course: "guitar", minutes: 20 }]);
});

test("places count sessions per rounded place, and leave out sessions with none", async () => {
  const db = openTestDatabase();
  await migrate(db);
  const library = { lat: -23.56, lng: -46.66 };
  await record(db, guitar, "2026-10-21T18:00:00Z", library);
  await record(db, spanish, "2026-10-22T18:00:00Z", library);
  await record(db, { id: "s5", course: "statistics", minutes: 60 }, "2026-10-26T18:00:00Z");
  expect(await places(db)).toEqual([{ lat: -23.56, lng: -46.66, sessions: 2 }]);
  expect(await totals(db)).toHaveLength(3);
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest journal --forceExit 2>&1 | grep -E "●|has no column|Tests:"
  ● a database left at version 1 moves to the latest version and keeps its rows
    table done has no column named lat
Tests:       1 failed, 4 passed, 5 total
```

**O teste do banco antigo falhou, e o problema não era a migração.** O teste monta uma tabela da versão 1
e depois chama o `record` para pôr uma linha nela. O `record` é código de hoje: ele escreve `lat` e `lng`,
e a versão 1 não tinha essas colunas. O teste usava a versão nova para montar os dados da antiga, o que só
funcionou na aula 14 porque as duas por acaso concordavam.

**Um teste de um schema antigo escreve as linhas do jeito que a versão antiga escrevia**, em SQL puro,
nunca pelas funções de hoje. Aqui está o arquivo com esse teste corrigido:

```ts
// __tests__/journal.test.ts: the journal's SQL, run by Node's own SQLite in memory.
import { migrate, places, record, totals } from "../src/journal";
import { openTestDatabase } from "../test-sqlite";

const guitar = { id: "s3", course: "guitar", minutes: 20 };
const spanish = { id: "s4", course: "spanish", minutes: 30 };

test("an empty database is brought to the latest version", async () => {
  const db = openTestDatabase();
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 3 }]);
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

test("a database left at version 1 moves to the latest version and keeps its rows", async () => {
  const db = openTestDatabase();
  // how version 1 left a phone: the table and the version number...
  await db.execAsync(
    "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL);" +
      "PRAGMA user_version = 1;",
  );
  // and a row written as version 1 wrote it: today's record() knows columns version 1 never had
  await db.runAsync("INSERT INTO done VALUES (?, ?, ?, ?)", "s3", "guitar", 20, "2026-10-21T18:00:00Z");
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 3 }]);
  expect(await db.getAllAsync("SELECT name FROM sqlite_master WHERE name = 'done_by_course'")).toHaveLength(1);
  expect(await totals(db)).toEqual([{ course: "guitar", minutes: 20 }]);
});

test("places count sessions per rounded place, and leave out sessions with none", async () => {
  const db = openTestDatabase();
  await migrate(db);
  const library = { lat: -23.56, lng: -46.66 };
  await record(db, guitar, "2026-10-21T18:00:00Z", library);
  await record(db, spanish, "2026-10-22T18:00:00Z", library);
  await record(db, { id: "s5", course: "statistics", minutes: 60 }, "2026-10-26T18:00:00Z");
  expect(await places(db)).toEqual([{ lat: -23.56, lng: -46.66, sessions: 2 }]);
  expect(await totals(db)).toHaveLength(3);
});
```

E o `__tests__/place.test.tsx` confere o arredondamento, a chave, e uma sessão registrada com o lugar. O
substituto do `expo-location` responde o que cada teste precisa, como o da aula 13 fez com a câmera:

```tsx
// __tests__/place.test.tsx: the switch asks for location when it is turned on, stays off if refused, and
// a session marked done while it is on is logged with a rounded place.
import { NavigationContainer } from "@react-navigation/native";
import * as Location from "expo-location";
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { rounded } from "../src/place";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
jest.mock("expo-location", () => ({
  Accuracy: { Low: 2 },
  requestForegroundPermissionsAsync: jest.fn(),
  getCurrentPositionAsync: jest.fn(),
}));
const location = jest.mocked(Location);
const answer = (granted: boolean) =>
  ({ granted, canAskAgain: true, status: granted ? "granted" : "denied", expires: "never" }) as Location.LocationPermissionResponse;

beforeEach(() => jest.clearAllMocks());

test("two decimal places, and no more", () => {
  expect(rounded(-23.561414, -46.655881)).toEqual({ lat: -23.56, lng: -46.66 });
});

async function openWeek() {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
}

test("refused, the switch stays off and says what that means", async () => {
  location.requestForegroundPermissionsAsync.mockResolvedValue(answer(false));
  await openWeek();
  await fireEvent(screen.getByRole("switch", { name: "Note where I study" }), "valueChange", true);
  expect(screen.getByRole("switch", { name: "Note where I study" })).toHaveProp("value", false);
  expect(screen.getByRole("alert")).toHaveTextContent(/logged without a place/);
});

test("allowed, a session is logged with where it was done", async () => {
  location.requestForegroundPermissionsAsync.mockResolvedValue(answer(true));
  location.getCurrentPositionAsync.mockResolvedValue({
    coords: { latitude: -23.561414, longitude: -46.655881, altitude: null, accuracy: 900, altitudeAccuracy: null, heading: null, speed: null },
    timestamp: 0,
  });
  await openWeek();
  await fireEvent(screen.getByRole("switch", { name: "Note where I study" }), "valueChange", true);
  await fireEvent.press(screen.getByRole("button", { name: "Mark 20 min on 2026-10-21 done" }));
  expect(await screen.findByText("Studied at -23.56, -46.66 (1)")).toBeOnTheScreen();
  expect(location.getCurrentPositionAsync).toHaveBeenCalledWith({ accuracy: Location.Accuracy.Low });
});
```

```
ana@dev:~/planner$ npx jest journal place --verbose --forceExit 2>&1 | grep -E "✓|✕|Tests:"
  ✓ an empty database is brought to the latest version (9 ms)
  ✓ totals are per course, and a session logged twice counts once (1 ms)
  ✓ migrating twice changes nothing (1 ms)
  ✓ a database left at version 1 moves to the latest version and keeps its rows (1 ms)
  ✓ places count sessions per rounded place, and leave out sessions with none (1 ms)
  ✓ two decimal places, and no more (7 ms)
  ✓ refused, the switch stays off and says what that means (224 ms)
  ✓ allowed, a session is logged with where it was done (79 ms)
Tests:       8 passed, 8 total
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       52 passed, 52 total
Snapshots:   0 total
Time:        9.677 s, estimated 10 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```
