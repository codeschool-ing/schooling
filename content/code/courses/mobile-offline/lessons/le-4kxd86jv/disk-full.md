---
title: The disk that fills up
version: 1
---

**A full disk is an ordinary state for a phone, not a disaster, and the app that handles it well
leaves nothing behind but a message.** Phones fill up: photos, a messaging app's media, an update
waiting to install. A write that fails for lack of space returns an error like any other, called
`ENOSPC` on Android and Linux and a `NSFileWriteOutOfSpaceError` on iOS. What turns it into a bug
is what the app does next.

The bug has a precise shape. The download wrote 20 MB of a 30 MB file, the disk ran out, and the
app had already inserted the row, or renamed the part file, or both. Now the database says the notes
are there, the file is two thirds of a PDF, and the person sees an error opening it on a plane with
no way to fetch it again. **The row came before the whole file.**

## Ask first, write to a side name, record last

Three steps, in that order, and the order is the design:

1. **Ask how much room there is.** `statfs` reports the blocks free to an ordinary user. Asking for
   twice the file's size leaves room for the database's own writes and for the rest of the phone.
   A planner that refuses here can say so before it has spent the person's data on a download.
2. **Write to the part file, then force it to the disk.** `fsync` returns only when the bytes are
   on storage rather than in a buffer, so a crash a moment later still leaves a whole file.
3. **Rename, then insert the row.** Only a whole file gets its real name, and only a file with its
   real name gets a row.

Save this in `~/planner/files` as `save.ts`:

```typescript
// save.ts: write a downloaded attachment so that a full disk leaves nothing half-done.
// usage: node save.ts NAME MB [PART]   (PART defaults to attachments/NAME.part)
import Database from "better-sqlite3";
import { openSync, writeSync, fsyncSync, closeSync, renameSync, rmSync, statSync, statfsSync, mkdirSync } from "node:fs";

const [name, mb, part = `attachments/${name}.part`] = process.argv.slice(2);
const bytes = Number(mb) * 1024 * 1024;
const db = new Database("files.db");
db.exec("create table if not exists attachments (name text primary key, bytes integer)");
mkdirSync("attachments", { recursive: true });

// 1. Ask first. Twice the size leaves room for the database and everything else on the phone.
const fs = statfsSync(".");
if (fs.bavail * fs.bsize < 2 * bytes) {
  console.log(`not enough space for ${name}: asking the person to free some`);
  process.exit(1);
}

// 2. Write to the part file, and make sure it is on the disk, not in a buffer.
try {
  const fd = openSync(part, "w");
  const chunk = Buffer.alloc(64 * 1024, 1);
  for (let done = 0; done < bytes; done += chunk.length) writeSync(fd, chunk);
  fsyncSync(fd);
  closeSync(fd);
} catch (e) {
  console.log(`write failed: ${(e as NodeJS.ErrnoException).code}`);
  if (statSync(part).isFile()) rmSync(part); // a half file is removed; a device such as /dev/full is not ours
  console.log(`no row for ${name}; the screen offers to try again`);
  process.exit(1);
}

// 3. Only a whole file gets its real name, and only then a row that says it exists.
renameSync(part, `attachments/${name}`);
db.prepare("insert or replace into attachments values (?, ?)").run(name, bytes);
console.log(`saved ${name}, ${mb} MB, and recorded it`);
```

**Linux has a device that is always full.** Every write to `/dev/full` fails with `ENOSPC`, the
error a full disk returns, so passing it as the part file stands in for a disk that runs out on the
first chunk. The program's `statSync(part).isFile()` keeps it from trying to delete a device that
is not its own. On a Mac there is no `/dev/full`, and this first command will not behave the same.

```
ana@dev:~/planner/files$ node save.ts notes.pdf 5 /dev/full
write failed: ENOSPC
no row for notes.pdf; the screen offers to try again
ana@dev:~/planner/files$ node save.ts notes.pdf 5
saved notes.pdf, 5 MB, and recorded it
ana@dev:~/planner/files$ node save.ts atlas.pdf 999999
not enough space for atlas.pdf: asking the person to free some
ana@dev:~/planner/files$ sqlite3 files.db "select * from attachments"
notes.pdf|5242880
```

**Three outcomes, one rule.** The write to `/dev/full` failed, nothing was recorded, and the
person is offered a retry. The real write went through all three steps. The request for 999,999 MB
was refused before a byte was written, because the free space was asked first; the number is
absurd on purpose, so the same line comes back on any computer. The table holds one row, and it is
for the one whole file.

## The platforms

Each platform reports its free space in its own way, and each means "space this app may use",
which is not the same as "empty blocks":

- **Android**: `StorageManager.getAllocatableBytes()`, and `allocateBytes()` to reserve the space
  before writing, which may make the system clear other apps' caches to provide it.
- **iOS**: `URLResourceKey.volumeAvailableCapacityForImportantUsageKey`, which counts space the
  system would free for a download the person asked for, against `...ForOpportunisticUsageKey` for
  one they did not.
- **React Native**: `FileSystem.getFreeDiskStorageAsync()` in `expo-file-system`.

*These are quoted from each platform's documentation and were not run for this course.*
