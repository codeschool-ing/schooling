---
title: Orphans, in both directions
version: 1
---

**Files and rows drift apart even in a careful app, so the planner looks for the drift instead of
hoping it never happens.** The last two sections made every write safe in order, and an app can
still end up with a file that no row names, or a row whose file is gone. The order of operations
narrows the gap; it cannot close it.

The two kinds have different causes and different cures:

| | how it happens | what the sweep does |
|---|---|---|
| **a file with no row** | the app stopped between renaming the file and inserting the row; or a row was deleted and its file was not, the order lesson 17's cache was careful about | deletes the file, which nothing can reach |
| **a row with no file** | the person deleted the file from the Files app; a restore brought back the database and not the folder; the system cleared a folder it was allowed to | removes the row, or marks it, so the next open downloads the file again |

**A part file is neither.** It is a download in progress, and the sweep leaves it for the download
to finish or for an age limit to remove.

## A sweep

Save this in `~/planner/files` as `sweep.ts`. It reads the folder and the table and compares them
in both directions:

```typescript
// sweep.ts: find files nothing points at, and rows that point at nothing.
import Database from "better-sqlite3";
import { readdirSync, existsSync, rmSync, mkdirSync } from "node:fs";

const db = new Database("files.db");
db.exec("create table if not exists attachments (name text primary key, bytes integer)");
mkdirSync("attachments", { recursive: true });
const rows = db.prepare("select name from attachments order by name").all() as { name: string }[];
const known = new Set(rows.map((r) => r.name));

for (const file of readdirSync("attachments").sort()) {
  if (file.endsWith(".part")) continue; // a download in progress, not an orphan
  if (!known.has(file)) {
    rmSync(`attachments/${file}`);
    console.log(`orphan file   attachments/${file}: deleted`);
  }
}
for (const { name } of rows) {
  if (!existsSync(`attachments/${name}`)) {
    db.prepare("delete from attachments where name = ?").run(name);
    console.log(`missing file  ${name}: row removed, the next open downloads it again`);
  }
}
console.log(`sweep done: ${(db.prepare("select count(*) as n from attachments").get() as { n: number }).n} attachments`);
```

To have something to find, the commands below make both kinds by hand: a row is deleted in the
`sqlite3` shell after its file was saved, which is the app stopping at the wrong moment, and a file
is removed with `rm`, which is the person or the system. Then the sweep runs, twice:

```
ana@dev:~/planner/files$ node save.ts guitar-tabs.pdf 1
saved guitar-tabs.pdf, 1 MB, and recorded it
ana@dev:~/planner/files$ node save.ts spanish-verbs.pdf 2
saved spanish-verbs.pdf, 2 MB, and recorded it
ana@dev:~/planner/files$ sqlite3 files.db "delete from attachments where name = 'guitar-tabs.pdf'"
ana@dev:~/planner/files$ rm attachments/notes.pdf
ana@dev:~/planner/files$ node sweep.ts
orphan file   attachments/guitar-tabs.pdf: deleted
missing file  notes.pdf: row removed, the next open downloads it again
sweep done: 1 attachments
ana@dev:~/planner/files$ node sweep.ts
sweep done: 1 attachments
```

**The second sweep found nothing**, which is what makes it safe to run at every start: it costs a
directory listing and one query. `guitar-tabs.pdf` was a megabyte nobody could reach, and is gone.
`notes.pdf` lost its row, so the next time the person opens the Statistics notes the planner
downloads them again rather than showing a document that is not there. `spanish-verbs.pdf` had a
row and a file, and was left alone.

A sweep this short leaves two choices to the app. **Deleting a row for a missing file is right for
a downloaded copy and wrong for something the person made**: a photo they attached to a session,
gone from the disk, is a loss to report, not a row to tidy away. And a sweep that deletes needs the
folder to be the app's alone, which is one more reason the sandbox of lesson 1 keeps
`files/attachments/` for the planner and nothing else.

## Before the drill

- A file goes on the disk, named by its hash; its row holds the path, the size and the hash.
- A download writes to a part file, resumes with `Range` and `If-Range`, and is renamed when whole.
- Ask for the space first; write, `fsync`, rename, then record.
- Sweep both directions at start, and leave part files alone.
