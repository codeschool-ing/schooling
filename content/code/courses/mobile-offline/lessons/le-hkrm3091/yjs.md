---
title: Yjs, a CRDT library, on the planner's week
version: 1
---

**For lists and text, use a library: the merge is the hard part, and it has been written.** A
counter and a set fit in thirty lines. A list where two people insert at the same position, and
every device must agree on the order of both insertions forever, does not; neither does text,
which is a list of characters. **Yjs** is one of the two libraries most used for this, written in
JavaScript, and it runs in Node exactly as it runs in a React Native app or a browser. Install it
in `~/planner`, beside `better-sqlite3`:

```
ana@dev:~/planner$ npm install -E yjs@13.6.33

added 3 packages in 806ms
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "type": "module",
  "dependencies": {
    "better-sqlite3": "13.0.3",
    "yjs": "13.6.33"
  }
}
```

A Yjs **document** holds shared types: a `Y.Map`, a `Y.Array`, a `Y.Text`. Each device has its own
copy of the document and edits it locally, with no network. Syncing is two calls: one device asks
the other what it has already seen, as a **state vector**, and the other encodes just the changes
missing from it, as an **update**. Applying an update is a merge, and it has the three properties
of the first section.

This program gives the phone and the tablet one document each, puts session `s3` in it as a nested
`Y.Map`, and lets each device edit it offline and add a note to the week. Save it as `yjs.ts` in
`~/planner/crdt`:

```typescript
// yjs.ts: the planner's week as a Yjs document, edited on two devices offline.
import * as Y from "yjs";

// Each device holds its own copy of the document. The client id names the device in the
// document's history; it is fixed here so every run prints the same bytes.
const phone = new Y.Doc();
phone.clientID = 1;
const tablet = new Y.Doc();
tablet.clientID = 2;

// The phone creates s3, and the tablet receives it: both start from the same state.
const s3 = new Y.Map<unknown>();
phone.getMap("sessions").set("s3", s3);
s3.set("course", "guitar");
s3.set("minutes", 20);
s3.set("done", false);
Y.applyUpdate(tablet, Y.encodeStateAsUpdate(phone));

// Offline: each device edits s3 and adds a note to the week. With `same-field`, both
// devices change the minutes instead of one changing the minutes and the other `done`.
const sameField = process.argv[2] === "same-field";
const session = (doc: Y.Doc) => doc.getMap("sessions").get("s3") as Y.Map<unknown>;
session(phone).set("minutes", 30);
phone.getArray("notes").push(["bring the capo"]);
if (sameField) session(tablet).set("minutes", 25);
else session(tablet).set("done", true);
tablet.getArray("notes").push(["tune before starting"]);

// Back online: each sends the other only what the other has not seen.
const toTablet = Y.encodeStateAsUpdate(phone, Y.encodeStateVector(tablet));
const toPhone = Y.encodeStateAsUpdate(tablet, Y.encodeStateVector(phone));
console.log(`update to the tablet ${toTablet.length} bytes, to the phone ${toPhone.length} bytes`);
Y.applyUpdate(tablet, toTablet);
Y.applyUpdate(phone, toPhone);

for (const [name, doc] of [["phone", phone], ["tablet", tablet]] as const) {
  console.log(name.padEnd(6), JSON.stringify(doc.getMap("sessions").toJSON()), JSON.stringify(doc.getArray("notes").toJSON()));
}
```

```
ana@dev:~/planner/crdt$ node yjs.ts
update to the tablet 40 bytes, to the phone 45 bytes
phone  {"s3":{"course":"guitar","minutes":30,"done":true}} ["bring the capo","tune before starting"]
tablet {"s3":{"course":"guitar","minutes":30,"done":true}} ["bring the capo","tune before starting"]
```

**Both devices hold the same document, and nothing was lost**: 30 minutes from the phone, done
from the tablet, and both notes. It merged field by field because `s3` is a `Y.Map` of its own,
so each field is a separate key with its own history, the same separation lesson 14 had to build by
keeping a base copy. And each device sent the other 40-odd bytes: the state vector meant neither
had to send the whole document.

## The same field, on both devices

Run it again with both devices changing the minutes, the case lesson 14 handed to a person:

```
ana@dev:~/planner/crdt$ node yjs.ts same-field
update to the tablet 40 bytes, to the phone 46 bytes
phone  {"s3":{"course":"guitar","minutes":25,"done":false}} ["bring the capo","tune before starting"]
tablet {"s3":{"course":"guitar","minutes":25,"done":false}} ["bring the capo","tune before starting"]
```

Both devices agree on 25, and the phone's 30 is gone. Yjs settled it with a fixed tie-break between
the two devices' client ids, so the answer is the same everywhere, which is all a CRDT promises.
**For a session's length, that is last write wins again**, and if the planner wants Ana to choose,
the app has to notice the case itself; nothing in the document says a conflict happened. Where Yjs
earns its place is the notes: two people typing into the same list or the same paragraph keep
everything they typed, in an order both screens agree on, and no screen has to ask anybody.

An app keeps the document as bytes: `Y.encodeStateAsUpdate(doc)` is the whole thing, and it can go
into a SQLite `BLOB` column beside the rows of lesson 3, one document per course or per week.
