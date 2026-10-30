---
title: Timestamps, and the clock that is wrong
version: 1
---

**A phone's clock is a setting the person can change, and a network can correct late or never. A
change stamped with it and fetched by comparing stamps is lost whenever the clock that wrote it was
behind the clock that asks.** That is the whole argument against syncing by time, and it is worth
watching once.

A phone's clock is wrong more often than people expect. It is set by hand to cheat a game's timer,
it drifts on a device that has been off for a week, it jumps when a network corrects it, and it
carries the wrong zone on a tablet that never left its box. None of that is the server's business
until the server uses the time to decide what to send.

## Two phones, ten minutes apart

The server keeps the stamp each phone sends with a write, and answers `/changed-since?t=` with the
rows stamped after a time: syncing by timestamp, as many apps do. This program plays both phones.
Phone A, whose clock is right, pulls at 10:00 and keeps two bookmarks, the time and the cursor.
Phone B, whose clock is ten minutes slow, adds a session at 10:05, and stamps it 09:55. Then phone A
asks what changed, both ways. Save it as `clocks.ts`:

```typescript
// clocks.ts: phone A asks what changed, once by timestamp and once by cursor, after phone B,
// whose clock is ten minutes slow, adds a session. The times are written out, not read.
const SERVER = "http://127.0.0.1:8011";
const get = async (path: string) => (await fetch(SERVER + path)).json();

// 10:00 by phone A's clock, which is right: A pulls, and keeps both kinds of bookmark.
const lastPull = "2026-10-21T10:00:00Z";
const { cursor } = await get("/changes?after=0");

// 10:05 in fact: phone B adds a session. B's clock says 09:55, and B stamps the row with it.
await fetch(`${SERVER}/sessions/s7?stamp=2026-10-21T09:55:00Z`, {
  method: "PUT", body: JSON.stringify({ course: "guitar", date: "2026-10-23", minutes: 25 }),
});

// 10:10 by A's clock: what changed since the last pull?
const byTime = (await get(`/changed-since?t=${lastPull}`)) as { id: string }[];
const byCursor = (await get(`/changes?after=${cursor}`)).changes as { id: string }[];
console.log(`by timestamp, after ${lastPull}: ${byTime.map((r) => r.id).join(", ") || "nothing"}`);
console.log(`by cursor, after ${cursor}: ${byCursor.map((r) => r.id).join(", ") || "nothing"}`);
```

Restart the server, so it starts from lesson 1's six sessions again, and run it:

```
ana@dev:~/planner/delta$ node clocks.ts
by timestamp, after 2026-10-21T10:00:00Z: nothing
by cursor, after 6: s7
```

**By timestamp, the session does not exist.** It was written after phone A's last pull and stamped
before it, so every future question "what changed after 10:00?" leaves it out, and phone A never
sees it. Nothing fails. By cursor, the same question returns it, because the server numbered the
write when it arrived, in the order things happened on the server.

## If a time is all you have

Some back ends only offer an "updated at" field. Three repairs, in order of preference:

- **Stamp on the server, not on the phone.** The server's clock is one clock, and an
  `updated_at` it writes on arrival is only as wrong as that one machine's.
- **Overlap the window.** Ask for changes since a few minutes before the last pull, and ignore the
  rows already held. It survives small skew and costs some duplicates.
- **Never let the phone's clock decide what is sent.** It may still be shown to the person, who
  recognises "Tuesday evening", and it may still be stored as what the person saw.

Lesson 13 meets the same clock again, deciding which of two edits wins, where it does more damage.
