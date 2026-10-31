---
title: Um lugar arredondado no diário
version: 1
---

Tudo o que o planner faz com localização está num arquivo. Salve o `src/place.ts`:

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
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l15-round\" aria-label=\"Uma grade de quadrados de cerca de 1,1 quilômetro de lado, as células de duas casas decimais de latitude e longitude. O celular informa uma posição com seis casas decimais, um ponto dentro de uma célula. O diário guarda só as coordenadas arredondadas, o ponto da grade mais próximo, então toda posição dentro da área sombreada em volta dele é guardada como o mesmo lugar.\"><rect x=\"60\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"30\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"100\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"170\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"165.0\" y=\"65.0\" width=\"70\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"196\" y=\"96\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"218.0\" y=\"107.5\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cerca de 1,1 km</text><text x=\"420\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o celular informa</text><text x=\"420\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-23.561414, -46.655881</text><text x=\"420\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o diário guarda</text><text x=\"420\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-23.56, -46.66</text><text x=\"420\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">toda posição no quadrado</text><text x=\"420\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">sombreado vira o mesmo lugar</text></svg>", "caption": "O arredondamento acontece antes de qualquer coisa ser guardada, então o diário nunca tem mais que um bairro."}
```

- **O `rounded` é a regra de privacidade, escrita uma vez.** Duas casas decimais de latitude são cerca de
  1,1 km; de longitude, o mesmo no equador e menos em direção aos polos, cerca de 1 km em São Paulo.
- **O `setNotingPlace` pede quando a chave é ligada**, e só então. Desligá-la não pede nada, e uma recusa
  é devolvida em vez de guardada, para a chave poder dizer o que aconteceu.
- **O `currentPlace` pede `Accuracy.Low`**, que num celular quer dizer a posição da rede em vez do GPS:
  mais rápida, mais barata para a bateria, e tão precisa quanto o arredondamento deixa de qualquer jeito.
  Ele devolve `null` sempre que a chave está desligada, então o resto do app nunca precisa saber da chave.

A configuração em si é uma string no AsyncStorage, que a aula 14 disse ser o lugar de uma configuração
lida uma vez.

## A terceira versão do diário

O diário ganha duas colunas, e uma consulta que conta sessões por lugar. No `src/journal.ts`, a terceira
migração acrescenta as colunas, o `record` aceita um lugar opcional, e o `places` agrupa por ele:

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

**O `ALTER TABLE … ADD COLUMN` mantém todas as linhas**, e as colunas novas ficam `NULL` em cada uma: as
sessões registradas antes desta versão não têm lugar, o que é a verdade. O `places` as deixa de fora com
`WHERE lat IS NOT NULL`, e o `totals` as conta como antes. A terceira entrada tem duas instruções, e tudo
bem: o `migrate` envolve a entrada numa transação, seja o que for que ela contenha.
