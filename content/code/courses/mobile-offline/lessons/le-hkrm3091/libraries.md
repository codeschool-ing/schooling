---
title: The libraries, and what a CRDT costs
version: 1
---

**A CRDT pays for never asking with history it has to carry.** Every merge rule of this lesson
works because something remembers more than the current value: a count per device, a tag per add,
the client id and position of every inserted item. That memory is called **metadata**, and the
deleted items it still has to know about are **tombstones**. How much of it a document carries
depends on what the app asks of the library, and it can be measured.

## Measured on one session

This program makes one document, changes `s3`'s minutes a thousand times, then adds a thousand
notes and deletes them all. It prints the document's size against the same data as JSON. Save it
as `costs.ts` in `~/planner/crdt`:

```typescript
// costs.ts: what a Yjs document weighs after many edits, against the same data as JSON.
import * as Y from "yjs";

// `keep-history` turns off Yjs's garbage collection, which an app does to offer undo or
// to show earlier versions: deleted content is then kept rather than discarded.
const doc = new Y.Doc({ gc: process.argv[2] !== "keep-history" });
doc.clientID = 1;
const s3 = new Y.Map<unknown>();
doc.getMap("sessions").set("s3", s3);
const notes = doc.getArray<string>("notes");
const size = () => Y.encodeStateAsUpdate(doc).length;
const json = () => JSON.stringify({ sessions: doc.getMap("sessions").toJSON(), notes: notes.toJSON() }).length;

s3.set("minutes", 20);
console.log(`fresh               ${String(size()).padStart(6)} bytes as Yjs, ${json()} as JSON`);
for (let m = 1; m <= 1000; m++) s3.set("minutes", m);
console.log(`1000 edits later    ${String(size()).padStart(6)} bytes as Yjs, ${json()} as JSON`);
for (let n = 0; n < 1000; n++) notes.push([`note ${n}`]);
notes.delete(0, 1000);
console.log(`1000 notes, deleted ${String(size()).padStart(6)} bytes as Yjs, ${json()} as JSON`);
```

```
ana@dev:~/planner/crdt$ node costs.ts
fresh                   35 bytes as Yjs, 45 as JSON
1000 edits later        47 bytes as Yjs, 47 as JSON
1000 notes, deleted     61 bytes as Yjs, 47 as JSON
ana@dev:~/planner/crdt$ node costs.ts keep-history
fresh                   35 bytes as Yjs, 45 as JSON
1000 edits later      2983 bytes as Yjs, 47 as JSON
1000 notes, deleted  12887 bytes as Yjs, 47 as JSON
```

With its garbage collection on, which is Yjs's default, the document barely grows: a thousand
overwrites cost 12 bytes, and a thousand deleted notes leave 14 more, because Yjs discards deleted
content and merges what is left of it. **With collection off, the same edits weigh 12,887 bytes**
against 47 bytes of JSON. That is the setting an app needs to offer undo across sessions or to show
yesterday's version, because both require the deleted content to still be there. Multiply by every
course and every week of a year, and the history, not the data, is what fills the database.

## The libraries

| library | what it is | where it runs |
|---|---|---|
| **Yjs** | shared maps, arrays and text, built for editors | JavaScript, so React Native and the web; Yrs is its port to Rust, with bindings for other languages |
| **Automerge** | a JSON-like document with full history, built for local-first apps | a Rust core with JavaScript and Swift packages, among others |
| **cr-sqlite** | CRDT merge rules added to ordinary SQLite tables | a SQLite extension, wherever SQLite can load one |

*None of the three was run here on a phone. Yjs was run in Node, above; the rest of this table comes
from each project's documentation.* Their packages for Kotlin and Swift change faster than this
course, so check the project's own page before choosing one for your platform.

## When a CRDT is the wrong tool

- **A rule that must hold across all devices.** Two offline devices can each book the last seat;
  no merge can undo that afterwards. Only a server can refuse.
- **A row where the same field rarely changes twice.** The planner's sessions are this case:
  lesson 14's version number and merge cost one integer per row and keep the conflicts they cannot
  settle for the person to see. A CRDT would settle them silently.
- **Data the server must query.** A document stored as bytes cannot be searched with SQL until it
  is decoded; a report over every student's minutes needs ordinary rows somewhere.
- **Permissions.** Every device holding the document can write any part of it, and the server
  receives merged bytes rather than requests it can approve one by one.

**So reach for a CRDT where the data is shared text or a list several people edit**, the planner's
notes, and where every addition must count, the minutes studied. Keep rows, versions and the
server's say for everything else.
