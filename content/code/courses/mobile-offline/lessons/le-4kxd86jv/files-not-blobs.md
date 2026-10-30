---
title: Files on disk, and a row that knows where they are
version: 1
---

**A picture or a PDF belongs on the disk as a file, and the database keeps a row that says where
it is.** The tempting picture is the opposite: the database already holds the sessions, it has a
`blob` type, so the notes of a course might as well go in a column beside them. One place to back
up, one transaction, nothing to keep in step.

That works until the file is large, and then three things go wrong at once.

- **Every page of a blob goes through the database.** SQLite stores a large value across a chain of
  pages, and reading the row reads the chain. A query that selects the column by accident, as
  `select *` does, drags megabytes into memory to show a title.
- **The database file only grows.** Deleting a row frees its pages for reuse but does not give them
  back to the disk until a `VACUUM` rewrites the whole file, which needs as much free space again
  as the file takes.
- **The backup takes it all or nothing.** Lesson 1 measured what one 24 MB attachment does to
  Android's 25 MB quota. Inside the database, it cannot be excluded on its own: the rules file
  names files, not rows.

## Measured

The program below keeps the same 5 MB attachment both ways and prints the size of the database
file each time. Save it in `~/planner/files` as `attach.ts`:

```typescript
// attach.ts: keep a 5 MB attachment two ways, and compare what each does to the database.
// usage: node attach.ts blob | node attach.ts file
import Database from "better-sqlite3";
import { createHash } from "node:crypto";
import { mkdirSync, writeFileSync, statSync, rmSync } from "node:fs";

const how = process.argv[2];
rmSync(`${how}.db`, { force: true });
const db = new Database(`${how}.db`);
const pdf = Buffer.alloc(5 * 1024 * 1024, 7); // the notes of the Statistics course
const sha256 = createHash("sha256").update(pdf).digest("hex");

if (how === "blob") {
  db.exec("create table attachments (name text primary key, data blob)");
  db.prepare("insert into attachments values (?, ?)").run("statistics-notes.pdf", pdf);
} else {
  db.exec("create table attachments (name text primary key, path text, bytes integer, sha256 text)");
  mkdirSync("attachments", { recursive: true });
  writeFileSync(`attachments/${sha256}.pdf`, pdf);
  db.prepare("insert into attachments values (?, ?, ?, ?)")
    .run("statistics-notes.pdf", `attachments/${sha256}.pdf`, pdf.length, sha256);
}
db.close();
const kb = (n: number) => `${Math.round(n / 1024)} KB`;
console.log(`${how}: the database file is ${kb(statSync(`${how}.db`).size)}`);
```

```
ana@dev:~/planner/files$ node attach.ts blob
blob: the database file is 5136 KB
ana@dev:~/planner/files$ node attach.ts file
file: the database file is 12 KB
ana@dev:~/planner/files$ ls attachments
e2925fdd17c83c77e9a4f957fd170b2a72b48ac55968943dcf962f2b853c88a9.pdf
```

**Five megabytes against twelve kilobytes.** In the second run the database holds four short
values: the name, the path, the size in bytes and the SHA-256 of the contents. The file is named by
its hash, so two attachments with the same contents share one file, and a file can be checked
against its row at any time by hashing it again.

That row is the contract the rest of this lesson keeps: **a row exists only for a file that is
whole and in its place.** The next two sections write files that way when the network stops halfway
and when the disk runs out, and the last one finds what breaks the contract anyway.

## The platforms

Each platform's database has a way in, and the same advice. Room and SQLite on Android store a
`ByteArray` as a blob, and the `CursorWindow` that reads rows back holds about 2 MB by default, so
a row larger than that fails to read. SwiftData offers `@Attribute(.externalStorage)`, which keeps a
large `Data` value in a file beside the store and leaves the reference in the row, which is this
section's design done for you. In React Native, `expo-file-system` writes the file and `expo-sqlite`
keeps the row. *These are taken from each platform's documentation and were not run for this
course.*
