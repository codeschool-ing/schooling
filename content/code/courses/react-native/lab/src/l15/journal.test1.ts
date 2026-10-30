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
