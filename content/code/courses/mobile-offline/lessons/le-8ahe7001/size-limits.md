---
title: A size limit, and what leaves first
version: 1
---

**A cache with no size limit is a slow leak of the person's disk.** Nobody notices it in testing,
where the cache holds the covers of three courses. Somebody who browses the catalogue every day for
a year has a cache of every picture the app ever showed, and the first they hear of it is the
system telling them their phone is full, with your app near the top of the list.

So a cache gets a **budget in bytes**, not in entries: one cover picture is 40 KB and another is
4 MB, and a limit of a hundred entries says nothing about the disk. When a new item would take the
cache over the budget, something has to leave, and the usual answer is the item **least recently
used** (LRU): the one nobody has looked at for longest is the one least likely to be wanted next.

## An LRU cache in SQLite

The program below keeps cover pictures as files in `covers/` and one row per picture in a table:
its name, its size, and when it was last used. "When" is a counter that goes up by one on every
store and every hit, rather than the clock, because LRU needs an order and not a date, and a
counter cannot go backwards when the phone's clock is corrected. The budget is 10 MB. Save it in
`~/planner/cache` as `lru.ts`:

```typescript
// lru.ts: a cache of cover pictures that never grows past 10 MB, evicting the least recently used.
// usage: node lru.ts put NAME MB | node lru.ts get NAME | node lru.ts list
import Database from "better-sqlite3";
import { mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs";

const CAP = 10 * 1024 * 1024;
const MB = 1024 * 1024;
const db = new Database("covers.db");
db.exec(`create table if not exists covers (name text primary key, bytes integer, used integer);
         create table if not exists clock (tick integer); insert into clock select 0 where not exists (select 1 from clock);`);
mkdirSync("covers", { recursive: true });

// A counter rather than the time: "least recently used" needs an order, not a date.
const tick = () => db.prepare("update clock set tick = tick + 1 returning tick").get() as { tick: number };
const total = () => (db.prepare("select coalesce(sum(bytes), 0) as n from covers").get() as { n: number }).n;

function put(name: string, mb: number) {
  const bytes = mb * MB;
  if (bytes > CAP) throw new Error(`${name} is larger than the whole cache`);
  while (total() + bytes > CAP) {
    const old = db.prepare("select name, bytes from covers order by used limit 1").get() as { name: string; bytes: number };
    rmSync(`covers/${old.name}.jpg`, { force: true });
    db.prepare("delete from covers where name = ?").run(old.name);
    console.log(`evicted ${old.name} (${old.bytes / MB} MB)`);
  }
  writeFileSync(`covers/${name}.jpg`, Buffer.alloc(bytes));
  db.prepare("insert or replace into covers values (?, ?, ?)").run(name, bytes, tick().tick);
  console.log(`stored ${name} (${mb} MB)`);
}

function get(name: string) {
  const hit = db.prepare("select 1 from covers where name = ?").get(name) && existsSync(`covers/${name}.jpg`);
  if (hit) db.prepare("update covers set used = ? where name = ?").run(tick().tick, name);
  console.log(hit ? `hit ${name}` : `miss ${name}: download it again`);
}

const [cmd, name, mb] = process.argv.slice(2);
if (cmd === "put") put(name, Number(mb));
if (cmd === "get") get(name);
const rows = db.prepare("select name, bytes from covers order by used").all() as { name: string; bytes: number }[];
console.log(`cache: ${rows.map((r) => `${r.name} ${r.bytes / MB}`).join(", ") || "empty"} | ${total() / MB} of ${CAP / MB} MB`);
```

Store three covers, look at Spanish again, then store a fourth that does not fit:

```
ana@dev:~/planner/cache$ node lru.ts put spanish 4
stored spanish (4 MB)
cache: spanish 4 | 4 of 10 MB
ana@dev:~/planner/cache$ node lru.ts put statistics 3
stored statistics (3 MB)
cache: spanish 4, statistics 3 | 7 of 10 MB
ana@dev:~/planner/cache$ node lru.ts put guitar 2
stored guitar (2 MB)
cache: spanish 4, statistics 3, guitar 2 | 9 of 10 MB
ana@dev:~/planner/cache$ node lru.ts get spanish
hit spanish
cache: statistics 3, guitar 2, spanish 4 | 9 of 10 MB
ana@dev:~/planner/cache$ node lru.ts put chess 4
evicted statistics (3 MB)
stored chess (4 MB)
cache: guitar 2, spanish 4, chess 4 | 10 of 10 MB
ana@dev:~/planner/cache$ node lru.ts get statistics
miss statistics: download it again
cache: guitar 2, spanish 4, chess 4 | 10 of 10 MB
```

**Statistics left, not Spanish, although Spanish was stored first.** The `get spanish` moved it to
the back of the queue, so the least recently used item was Statistics, and evicting its 3 MB made
room for Chess's 4 MB, with the cache at exactly 10 of 10 MB. Asking for Statistics afterwards is a
miss, and the planner downloads it again: that is the whole cost of an eviction, and it is why only
the third kind of data from the first section may live under this rule.

Two details in the code are worth taking with you:

- **The file is deleted before its row.** If the program stopped between the two, the row would be
  gone and a file would be left with nothing pointing at it, which is an orphan the sweep of
  lesson 18 finds. The other order leaves a row pointing at no file, which `get` would report as a
  hit for a picture that is not there; `get` checks the file as well for exactly that reason.
- **An item larger than the whole budget is refused**, rather than evicting everything and still
  not fitting.

The image libraries named in the first section do this for you, with the budget as a setting:
`maxSizeBytes` in Coil's disk cache, `diskCapacity` in `URLCache`. What they cannot decide for you
is the number. A budget of a few tens of megabytes for pictures is a common choice; what matters is
that there is one, and that the settings screen says how much the cache holds and offers to empty
it.
