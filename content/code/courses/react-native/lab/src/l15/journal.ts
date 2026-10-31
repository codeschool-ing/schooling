// src/journal.ts: a log, kept on this phone, of every session marked done here, and what it adds up to.
// It asks for three methods and no more, so a test can hand it any SQLite that has them.
export interface Sql {
  execAsync(source: string): Promise<void>;
  runAsync(source: string, ...params: (string | number | null)[]): Promise<unknown>;
  getAllAsync<T>(source: string, ...params: (string | number | null)[]): Promise<T[]>;
}

// Each entry moves the database one version on. Entries are only ever added at the end.
const MIGRATIONS = [
  "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL)",
  "CREATE INDEX done_by_course ON done (course)",
  "ALTER TABLE done ADD COLUMN lat REAL; ALTER TABLE done ADD COLUMN lng REAL",
];

export async function migrate(db: Sql) {
  const [{ user_version: from }] = await db.getAllAsync<{ user_version: number }>("PRAGMA user_version");
  for (let v = from; v < MIGRATIONS.length; v++) {
    await db.execAsync(`BEGIN; ${MIGRATIONS[v]}; PRAGMA user_version = ${v + 1}; COMMIT;`);
  }
}

export type Done = { id: string; course: string; minutes: number };
export type Where = { lat: number; lng: number };

export async function record(db: Sql, s: Done, at: string, where: Where | null = null) {
  await db.runAsync(
    "INSERT OR IGNORE INTO done (session, course, minutes, done_at, lat, lng) VALUES (?, ?, ?, ?, ?, ?)",
    s.id, s.course, s.minutes, at, where?.lat ?? null, where?.lng ?? null,
  );
}

export function places(db: Sql) {
  return db.getAllAsync<{ lat: number; lng: number; sessions: number }>(
    "SELECT lat, lng, count(*) AS sessions FROM done WHERE lat IS NOT NULL GROUP BY lat, lng ORDER BY sessions DESC",
  );
}

export function totals(db: Sql) {
  return db.getAllAsync<{ course: string; minutes: number }>(
    "SELECT course, sum(minutes) AS minutes FROM done GROUP BY course ORDER BY course",
  );
}
