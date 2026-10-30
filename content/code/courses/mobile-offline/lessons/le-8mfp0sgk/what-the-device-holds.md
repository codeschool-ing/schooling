---
title: The device holds a window, not the archive
version: 1
---

**A phone keeps one person's data, and of that, the part the screens can reach.** The server holds
every person and every year. Copying all of it is impossible, and copying all of one person's is
usually wasteful: the planner's screens show this week, the weeks around it and the courses, and
three years of finished sessions sit unread while they take space, slow migrations and swell the
backup lesson 1 measured.

So the planner keeps a **window**: every course, every session from a number of weeks back, and
every session still to come. What falls out of the window can be deleted, with one exception that
is the whole difficulty: **a row that has not reached the server is never deleted**, however old,
because on the device it is the only copy there is.

The program below makes the three years of lesson 3, adds a `synced` column with some of October
still unsent, and marks one old session as edited offline last night, the case that is easy to
forget. Then it prunes everything older than the window that has been sent. Save it as
`window.ts` in `~/planner/model`:

```typescript
// window.ts: what a phone keeps of three years of sessions, and what it may let go.
import Database from "better-sqlite3";
import { statSync } from "node:fs";

let seed = 2026; // the same generator as lesson 3's big.ts, so the rows repeat
function random(): number {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  return seed / 2147483648;
}

const today = process.argv[2] ?? "2026-10-21";
const weeks = Number(process.argv[3] ?? 12);
const db = new Database("window.db");
db.exec(`DROP TABLE IF EXISTS sessions;
  CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL,
                         minutes INTEGER NOT NULL, done INTEGER NOT NULL, synced INTEGER NOT NULL)`);
const add = db.prepare("INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?)");
const start = Date.UTC(2023, 10, 1);
db.transaction(() => {
  for (let n = 1; n <= 20000; n++) {
    const date = new Date(start + Math.floor(random() * 1096) * 86400000).toISOString().slice(0, 10);
    const synced = date < "2026-10-01" || random() < 0.5 ? 1 : 0; // October still has unsent rows
    add.run(`s${n}`, "statistics", date, 30, 1, synced);
  }
  // One old session edited offline last night, and never sent.
  db.prepare("UPDATE sessions SET synced = 0 WHERE id = 's17'").run();
})();

const cutoff = db.prepare("SELECT date(?, ?) AS d").get(today, `-${weeks * 7} days`) as { d: string };
const count = (where: string) => (db.prepare(`SELECT count(*) AS n FROM sessions WHERE ${where}`).get(cutoff.d) as { n: number }).n;
const size = () => `${Math.round(statSync("window.db").size / 1024)} KB`;
console.log(`three years on the phone: 20000 sessions, ${size()}`);
console.log(`keeping ${weeks} weeks back from ${today}: everything from ${cutoff.d}`);
console.log(`  older than that:          ${count("date < ?")}`);
console.log(`  older, and not yet sent:  ${count("date < ? AND synced = 0")}`);
const pruned = db.prepare("DELETE FROM sessions WHERE date < ? AND synced = 1").run(cutoff.d).changes;
db.exec("VACUUM");
const left = (db.prepare("SELECT count(*) AS n FROM sessions").get() as { n: number }).n;
console.log(`pruned ${pruned}; ${left} sessions stay on the phone, ${size()}`);
```

```
ana@dev:~/planner/model$ node window.ts 2026-10-21 12
three years on the phone: 20000 sessions, 1064 KB
keeping 12 weeks back from 2026-10-21: everything from 2026-07-29
  older than that:          18229
  older, and not yet sent:  1
pruned 18228; 1772 sessions stay on the phone, 104 KB
ana@dev:~/planner/model$ node window.ts 2026-10-21 52
three years on the phone: 20000 sessions, 1064 KB
keeping 52 weeks back from 2026-10-21: everything from 2025-10-22
  older than that:          13213
  older, and not yet sent:  1
pruned 13212; 6788 sessions stay on the phone, 364 KB
```

**Twelve weeks keep 1,772 of 20,000 sessions, and the file goes from 1064 KB to 104 KB.** A year
keeps 6,788. In both runs one row older than the window survived the prune, `s17`, because it had
not been sent; once lesson 8's outbox delivers it, the next prune takes it.

`VACUUM` at the end rewrites the file without the freed pages. SQLite otherwise keeps them for
reuse and the file does not shrink, which is lesson 3's index measurement seen from the other side.
On a phone, run it rarely and in the background: it rewrites the whole database.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l04-window\" aria-label=\"A timeline of three years of sessions, from November 2023 to October 2026. The last twelve weeks before 21 October 2026, and everything after it, are the window the phone keeps: 1,772 of 20,000 sessions. Everything earlier that was sent to the server is pruned. One old session, edited offline and not yet sent, is kept outside the window.\"><defs><marker id=\"l04-window-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-window-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"605.0\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"635.0\" y=\"70\" width=\"55.0\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"332.5\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">older than the window, and sent: pruned</text><text x=\"690\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">the window: kept</text><text x=\"690\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12 weeks back, and everything ahead</text><path d=\"M684.5 150 L684.5 106\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-window-ah-paper)\"></path><text x=\"684.5\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">today</text><text x=\"30.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2023-11</text><text x=\"250.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2024-11</text><text x=\"470.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2025-11</text><rect x=\"172.7\" y=\"79\" width=\"8\" height=\"16\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M176.7 150 L176.7 107\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-window-ah-amber)\"></path><text x=\"164.7\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">edited offline, not sent: kept</text><text x=\"690\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper)\">1,772 of 20,000 sessions stay</text></svg>", "caption": "The device keeps the part of the history its screens reach, and the rows it has not sent yet, wherever they fall."}
```

## Choosing the window

The window is a product decision written as a number. Three things set it:

- **what the screens show**: if the history screen scrolls back a year, a year is the window, or the
  screen has to ask the server for the rest, which works only online;
- **what the server can resend**: anything pruned must be fetchable again, which lesson 12 relies on
  when it rebuilds a database from scratch;
- **what the person typed and has not sent**: never part of the window's arithmetic, because it is
  never pruned.

Lesson 17 applies the same thinking to the cache, where the server's copy is the truth and the
device's is a convenience.
