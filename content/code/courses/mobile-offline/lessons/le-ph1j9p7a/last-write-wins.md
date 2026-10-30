---
title: Last write wins, and what it throws away
version: 1
---

**Last write wins keeps whichever write carries the newest stamp, and drops the other one
whole.** It is the default of many sync layers and of most hand-written ones, because it is one
comparison and it always produces an answer. The trouble is in the word *whole*: the record is
replaced, not merged, so everything the losing write changed goes with it.

The program below plays the morning of the previous section. A server holds `s3`, each device
holds a copy, and four events happen in the order they happened: two offline edits, then two
syncs. Each edit stamps the copy with the device's clock, and each sync keeps the copy only if its
stamp is newer than the server's. Make the folder `~/planner/lww` and save it there as `lww.ts`:

```schooling-example
{"language": "typescript", "file": "lww.ts", "parts": [{"code": "// lww.ts: two devices edit one session offline, and the server keeps the last write.\ntype Session = { id: string; course: string; date: string; minutes: number; done: boolean };\ntype Change = Partial<Pick<Session, \"minutes\" | \"done\">>;\n\nconst [policy = \"device-clock\", ...args] = process.argv.slice(2);\nconst skew: Record<string, number> = {}; // minutes a device's clock is ahead\nfor (const a of args) {\n  const [device, by] = a.split(\"=\");\n  skew[device] = Number(by);\n}\n", "note": "A session, the fields an edit may change, and the arguments: which clock stamps a write, and how many minutes ahead a device's clock runs."}, {"code": "function at(hhmm: string, plus = 0): string {\n  const [h, m] = hhmm.split(\":\").map(Number);\n  const t = h * 60 + m + plus;\n  return `${String(Math.floor(t / 60)).padStart(2, \"0\")}:${String(t % 60).padStart(2, \"0\")}`;\n}\n", "note": "A time of day as HH:MM, moved on by some minutes. Strings of this shape sort in time order, so `>` compares them."}, {"code": "let server = { session: { id: \"s3\", course: \"guitar\", date: \"2026-10-21\", minutes: 20, done: false }, stamp: \"09:00\" };\nconst copies: Record<string, { session: Session; stamp: string }> = {\n  phone: structuredClone(server),\n  tablet: structuredClone(server),\n};\n", "note": "The server's row, stamped 09:00, and a copy of it on each device, which is what both had before the morning began."}, {"code": "// What happened, at the true time it happened. Both devices are offline until they sync.\nconst events: { time: string; device: string; change?: Change }[] = [\n  { time: \"10:05\", device: \"phone\", change: { minutes: 30 } },\n  { time: \"10:20\", device: \"tablet\", change: { done: true } },\n  { time: \"10:40\", device: \"tablet\" },\n  { time: \"11:00\", device: \"phone\" },\n];\n", "note": "The morning, in the order it happened: two edits made offline, then each device's sync when it found a network."}, {"code": "console.log(`policy: ${policy}` + (args.length ? `, ${args.join(\" \")}` : \"\"));\nfor (const e of events) {\n  const copy = copies[e.device];\n  const who = `${e.time} ${e.device.padEnd(7)}`;\n  if (e.change) {\n    const [field, value] = Object.entries(e.change)[0];\n    const before = copy.session[field as keyof Change];\n    copy.session = { ...copy.session, ...e.change };\n    copy.stamp = at(e.time, skew[e.device] ?? 0);\n    console.log(`${who} edits s3: ${field} ${before} -> ${value}, stamped ${copy.stamp}`);\n    continue;\n  }", "note": "An edit changes the local copy and stamps it with the device's clock, skew included. The change is folded into a whole session here, and from this line on nothing records which field was touched."}, {"code": "  // Last write wins: the newer stamp replaces the whole row; the older one is dropped.\n  const stamp = policy === \"server-clock\" ? e.time : copy.stamp;\n  if (stamp > server.stamp) {\n    server = { session: copy.session, stamp };\n    console.log(`${who} syncs: ${stamp} is newer than the server's row, kept`);\n  } else {\n    console.log(`${who} syncs: ${stamp} is older than the server's ${server.stamp}, dropped`);\n  }\n}", "note": "The rule itself. A sync keeps the copy if its stamp is newer than the server's, and drops it otherwise. With `server-clock`, the stamp is the time the write arrived."}, {"code": "console.log(`server s3: minutes ${server.session.minutes}, done ${server.session.done}`);", "note": "What the server holds at the end."}]}
```

Run it with the devices' clocks as the stamp, which is what an app does when it writes
`updated_at = now()` on the device:

```
ana@dev:~/planner/lww$ node lww.ts device-clock
policy: device-clock
10:05 phone   edits s3: minutes 20 -> 30, stamped 10:05
10:20 tablet  edits s3: done false -> true, stamped 10:20
10:40 tablet  syncs: 10:20 is newer than the server's row, kept
11:00 phone   syncs: 10:05 is older than the server's 10:20, dropped
server s3: minutes 20, done true
```

The server ends with 20 minutes, done. **Ana's change to 30 minutes is gone, and nothing said
so.** The phone's sync at 11:00 was answered, the phone's outbox emptied, and the next pull will
quietly put 20 minutes back on her phone. If she notices at all, she will think she forgot to save.

## Why the row went, and not the field

The losing write did not touch `done`, and the winning one did not touch `minutes`. They changed
different fields, and a rule that looked at fields would have kept both. Last write wins looks at
rows, because the stamp is on the row: `copy.session = { ...copy.session, ...e.change }` folds the
change into a complete session, and from then on the program cannot tell which fields Ana
actually touched. That is the information lesson 14 keeps, with a merge field by field against the
version both devices started from.

**Write down what last write wins costs before choosing it**, in one sentence per table: "if two
devices change a session while offline, the one stamped later replaces the other, including the
fields it did not change". A team that can read that sentence aloud and accept it has made a
decision. A team that cannot has a bug that no test of a single device will ever show.
