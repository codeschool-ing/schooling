---
title: Paging, and the page that repeats a row
version: 1
---

**A list reads one screen of rows at a time, and how it asks for the next screen decides both the
cost and the correctness.** The usual first version is `LIMIT 50 OFFSET 15000`, which reads well and
does more work the further the person scrolls. The second, **keyset paging**, asks for the fifty
rows after the last one shown, and does the same small amount of work on every page.

The program below builds lesson 3's 20,000 sessions with an index on `(date, id)`, the order the
history list shows them in, and asks for page 301 both ways. To see what SQLite walked rather than
guess, it registers a function, `walked`, that counts every row the `WHERE` clause is asked about.
Save it as `paging.ts` in `~/planner/threads`:

```typescript
// paging.ts: page 301 of the session list, by OFFSET and by keyset, and what each one walks.
import Database from "better-sqlite3";

let seed = 2026; // lesson 3's generator, so the rows repeat
function random(): number {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  return seed / 2147483648;
}
const db = new Database(":memory:");
db.exec(`CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL, minutes INTEGER NOT NULL);
         CREATE INDEX sessions_date_id ON sessions (date, id);`);
const add = db.prepare("INSERT INTO sessions VALUES (?, ?, ?, ?)");
db.transaction(() => {
  for (let n = 1; n <= 20000; n++) {
    const date = new Date(Date.UTC(2023, 10, 1) + Math.floor(random() * 1096) * 86400000).toISOString().slice(0, 10);
    add.run(`s${n}`, "statistics", date, 30);
  }
})();

// walked(id) is true for every row; it counts how many rows SQLite looked at to answer.
let walked = 0;
db.function("walked", { deterministic: false }, (_id: unknown) => (walked++, 1));
const PAGE = 50;
const OFFSET = "SELECT id, date FROM sessions WHERE walked(id) ORDER BY date, id LIMIT ? OFFSET ?";
const KEYSET = "SELECT id, date FROM sessions WHERE (date, id) > (?, ?) AND walked(id) ORDER BY date, id LIMIT ?";
const byOffset = db.prepare(OFFSET);
const byKey = db.prepare(KEYSET);
for (const [name, sql] of [["offset", OFFSET], ["keyset", KEYSET]]) {
  const plan = db.prepare(`EXPLAIN QUERY PLAN ${sql}`).all(...(name === "offset" ? [PAGE, 0] : ["", "", PAGE]));
  console.log(`${name}: ${(plan as { detail: string }[]).map((p) => p.detail).join("; ")}`);
}

walked = 0;
const page301 = byOffset.all(PAGE, 300 * PAGE) as { id: string; date: string }[];
console.log(`offset: page 301 starts at ${page301[0].date} ${page301[0].id}; rows walked: ${walked}`);
const last = byOffset.all(1, 300 * PAGE - 1)[0] as { id: string; date: string }; // the end of page 300
walked = 0;
const keyed = byKey.all(last.date, last.id, PAGE) as { id: string; date: string }[];
console.log(`keyset: page 301 starts at ${keyed[0].date} ${keyed[0].id}; rows walked: ${walked}`);

// A sync adds an older session between two pages. What does each page 302 start with?
db.prepare("INSERT INTO sessions VALUES ('s20001', 'statistics', '2024-01-01', 30)").run();
const offset302 = byOffset.all(PAGE, 301 * PAGE)[0] as { id: string };
const keyed302 = byKey.all(keyed[PAGE - 1].date, keyed[PAGE - 1].id, PAGE)[0] as { id: string };
console.log(`after one older row arrives, page 302 by offset starts at ${offset302.id}, by keyset at ${keyed302.id}`);
console.log(`the last row of page 301 was ${keyed[PAGE - 1].id}`);
```

```
ana@dev:~/planner/threads$ node paging.ts
offset: SCAN sessions USING COVERING INDEX sessions_date_id
keyset: SEARCH sessions USING COVERING INDEX sessions_date_id ((date,id)>(?,?))
offset: page 301 starts at 2026-01-27 s19453; rows walked: 15050
keyset: page 301 starts at 2026-01-27 s19453; rows walked: 50
after one older row arrives, page 302 by offset starts at s10268, by keyset at s11984
the last row of page 301 was s10268
```

## Cost

Both plans use the index, so `EXPLAIN QUERY PLAN` alone looks reassuring: neither reads the table.
The difference is in the verb and in the count. **The offset query walked 15,050 index entries to
return 50**: it has to step over every row of the 300 pages before, because an offset is a count,
and the only way to count rows is to visit them. The keyset query is a `SEARCH`: it seeks straight
to the first entry after `(date, id)` of the last row shown, and walks 50. The last page, 400,
would walk all 20,000 by offset and still 50 by keyset.

## Correctness

The last two lines are the worse problem. Between page 301 and page 302 a sync delivers one older
session, dated 1 January 2024, the everyday case for an app that syncs in the background. **Every
row after it moves one position along, so page 302 by offset starts with `s10268`, the row the
person has just seen at the bottom of page 301.** Had a row been deleted instead, one would have been
skipped and never shown. The keyset page starts where the last one ended, whatever changed before
it.

Two details make keyset paging work:

- **the order must be unique.** Many sessions share a date, so `date` alone cannot say where a page
  ended; `(date, id)` can, because no two rows share both. That is why the index has both columns;
- **the comparison is a row value**, `(date, id) > (?, ?)`, which SQLite has had since 3.15 and
  answers with the index directly.

Android's Paging 3 library pages a Room query for you, and its documentation recommends keyed
loading for the same reasons. A SwiftUI `List` over a `@Query` fetches lazily, but a fetch with a
large offset has the cost measured here; a `FetchDescriptor` with `fetchLimit` and a predicate on the
last row's key is the keyset version.
