---
title: A rounded place in the journal
version: 1
---

Everything the planner does with location is in one file. Save `src/place.ts`:

```ts
// src/place.ts: where the phone is, asked only when the person has turned it on, and rounded to about a
// kilometre before anything keeps it.
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Location from "expo-location";

export type Place = { lat: number; lng: number };
const KEY = "note-place";

// Two decimal places: about 1.1 km north to south, and less east to west away from the equator.
export function rounded(lat: number, lng: number): Place {
  return { lat: Math.round(lat * 100) / 100, lng: Math.round(lng * 100) / 100 };
}

export async function notingPlace() {
  return (await AsyncStorage.getItem(KEY)) === "on";
}

// Turning it on is the moment to ask. A refusal leaves it off, and the caller is told which.
export async function setNotingPlace(on: boolean): Promise<"on" | "off" | "refused"> {
  if (on && !(await Location.requestForegroundPermissionsAsync()).granted) return "refused";
  await AsyncStorage.setItem(KEY, on ? "on" : "off");
  return on ? "on" : "off";
}

export async function currentPlace(): Promise<Place | null> {
  if (!(await notingPlace())) return null;
  const { coords } = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Low });
  return rounded(coords.latitude, coords.longitude);
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l15-round\" aria-label=\"A grid of squares about 1.1 kilometres on each side, the cells of two decimal places of latitude and longitude. The phone reports a position to six decimal places, a point inside one cell. The journal keeps only the rounded coordinates, the nearest grid point, so every position inside the shaded area around it is stored as the same place.\"><rect x=\"60\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"165.0\" y=\"65.0\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"196\" y=\"96\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"218.0\" y=\"107.5\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">about 1.1 km</text><text x=\"420\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the phone reports</text><text x=\"420\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-23.561414, -46.655881</text><text x=\"420\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the journal keeps</text><text x=\"420\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-23.56, -46.66</text><text x=\"420\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">every position in the shaded</text><text x=\"420\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">square is stored the same</text></svg>", "caption": "Rounding is done before anything is kept, so the journal never holds more than a district."}
```

- **`rounded` is the privacy rule, written once.** Two decimal places of latitude are about 1.1 km; of
  longitude, the same at the equator and less towards the poles, about 1 km in São Paulo.
- **`setNotingPlace` asks when the switch is turned on**, and only then. Turning it off asks nothing,
  and a refusal is returned rather than stored, so the switch can say what happened.
- **`currentPlace` asks for `Accuracy.Low`**, which on a phone means the network's position rather than
  the GPS: quicker, cheaper on the battery, and as precise as the rounding keeps anyway. It returns
  `null` whenever the switch is off, so the rest of the app never needs to know about the switch.

The setting itself is one string in AsyncStorage, which lesson 14 said is the store for a setting read
once.

## The journal's third version

The journal gains two columns, and a query that counts sessions per place. In `src/journal.ts`, the
third migration adds the columns, `record` takes an optional place, and `places` groups by it:

```ts
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
```

**`ALTER TABLE … ADD COLUMN` keeps every row**, and the new columns are `NULL` in each of them: sessions
logged before this version have no place, which is the truth. `places` leaves those out with `WHERE lat
IS NOT NULL`, and `totals` counts them as before. The third entry holds two statements, which is fine:
`migrate` wraps the entry in one transaction whatever it contains.
