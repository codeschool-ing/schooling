---
title: Every path, tested
version: 1
---

**A phone can arrive at the latest version from any earlier one, so a migration is tested from
every version that ever shipped, not only from the last.** People skip updates. A phone left in a
drawer for a year opens version 4 of the app with a version 1 database, and the steps between have
never been run in that order on any developer's machine.

The test is short to write. For each version that shipped, build a database the way that version of
the app would have, put a row in it in that version's shape, run the migration, and compare the
result with a fresh install. Save this as `paths.ts` in `~/planner/migrate`:

```typescript
// paths.ts: build a phone's database at every version it can be found at, migrate it, and compare.
import Database from "better-sqlite3";
import { migrate, steps, version } from "./migrations.ts";

// The schema, as SQLite reports it, so two databases can be compared.
const shape = (db: Database.Database) =>
  JSON.stringify(db.prepare("SELECT type, name, sql FROM sqlite_schema ORDER BY name").all());
const rows = (db: Database.Database) => JSON.stringify(db.prepare("SELECT * FROM sessions ORDER BY id").all());

const fresh = new Database(":memory:");
migrate(fresh);

for (let start = 1; start < steps.length; start++) {
  const phone = new Database(":memory:");
  migrate(phone, start); // the app as it shipped at version `start`
  phone.prepare("INSERT INTO courses VALUES ('statistics', 'Statistics')").run();
  phone.prepare("INSERT INTO sessions (id, course, date, minutes, done) VALUES ('s2', 'statistics', '2026-10-20', 45, 1)").run();
  migrate(phone); // the update arrives
  const same = shape(phone) === shape(fresh) ? "same schema as a new install" : "SCHEMA DIFFERS";
  console.log(`from v${start} to v${version(phone)}: ${same}; ${rows(phone)}`);
}
```

`sqlite_schema` is SQLite's own table of tables, indexes and triggers, with the SQL that made each
one, so comparing it compares the whole shape. The rows are printed too, because a schema that
matches says nothing about whether the data survived the trip:

```
ana@dev:~/planner/migrate$ node paths.ts
from v1 to v4: same schema as a new install; [{"id":"s2","course":"statistics","date":"2026-10-20","minutes":45,"notes":"","synced":1,"done_at":"2026-10-20"}]
from v2 to v4: same schema as a new install; [{"id":"s2","course":"statistics","date":"2026-10-20","minutes":45,"notes":"","synced":1,"done_at":"2026-10-20"}]
from v3 to v4: same schema as a new install; [{"id":"s2","course":"statistics","date":"2026-10-20","minutes":45,"notes":"","synced":1,"done_at":"2026-10-20"}]
```

All three paths end with the same schema as a new install, and in each one session `s2`, saved as
`done = 1` in its old shape, arrives with `done_at` set to its date. That second check is the one
that matters to the person: a migration that produced the right tables and lost their ticks would
pass a schema comparison.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-paths\" aria-label=\"Four versions of the planner's database, v1 to v4, joined by steps 2, 3 and 4. A phone found at v1 runs steps 2, 3 and 4; one at v2 runs steps 3 and 4; one at v3 runs step 4; a new install runs every step from an empty file. An update that runs only step 4 fails from v1 and v2, because step 4 needs the synced column step 3 made.\"><defs><marker id=\"l05-paths-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-paths-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"70.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"150\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v1</text><rect x=\"290\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v2</text><rect x=\"430\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v3</text><rect x=\"570\" y=\"30\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">v4</text><path d=\"M120 48 L150 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"135.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">step 1</text><path d=\"M250 48 L290 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"270.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">step 2</text><path d=\"M390 48 L430 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"410.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">step 3</text><path d=\"M530 48 L570 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-paper-dim)\"></path><text x=\"550.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">step 4</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">new install</text><path d=\"M130 100 L620 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">phone at v1</text><path d=\"M200 130 L620 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">phone at v2</text><path d=\"M340 160 L620 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">phone at v3</text><path d=\"M480 190 L620 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-paths-ah-phosphor)\"></path><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">only step 4, from v1 or v2: no such column: synced</text></svg>", "caption": "Every version that shipped is a starting point. The test builds each one and migrates it; the shortcut that runs only the newest step fails on every phone that skipped one."}
```

## The update that only knows the last step

The shortcut this test exists to catch is an update written as "the change since last time". It
works on the developer's phone, which installs every build, and fails on any phone that skipped
one. Save this as `naive.ts`:

```typescript
// naive.ts: an update that only knows how to come from the version just before it.
import Database from "better-sqlite3";
import { migrate, steps } from "./migrations.ts";

for (let start = 1; start < steps.length; start++) {
  const phone = new Database(":memory:");
  migrate(phone, start);
  try {
    phone.exec(steps[steps.length - 1]); // "the last step is all an update needs"
    console.log(`from v${start}: worked`);
  } catch (e) {
    console.log(`from v${start}: ${(e as Error).message}`);
  }
}
```

```
ana@dev:~/planner/migrate$ node naive.ts
from v1: no such column: synced
from v2: no such column: synced
from v3: worked
```

From version 3 the last step is the only one missing, and it works. From versions 1 and 2 it fails,
because step 4 makes an index on `synced`, which step 3 created and these phones never ran. Worse,
`exec` ran the first statements of the step before the one that failed, so those databases are now
neither version 2 nor version 4. A transaction prevents that half, which is the next section.

Room has a test helper for exactly this, `MigrationTestHelper`, which creates a database at an old
version from the schema files Room exported at build time and runs the migrations on it. SwiftData
and Core Data have no equivalent, and the test is a store file kept from each shipped version.
