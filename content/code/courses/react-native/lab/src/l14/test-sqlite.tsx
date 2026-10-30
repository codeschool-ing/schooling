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
