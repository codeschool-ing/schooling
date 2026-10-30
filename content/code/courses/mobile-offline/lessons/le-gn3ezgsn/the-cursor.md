---
title: The cursor: a bookmark the server hands out
version: 1
---

**A cursor is a position in the server's history of changes, given to the device with each answer,
and handed back by the device next time to say where it stopped reading.** The planner's server
numbers every write, so its cursor is the last number the device has seen. Asking `GET
/changes?after=2006` means "every row written after write 2006", and the answer carries the new
cursor to keep.

The common first attempt uses a time instead: "everything changed since my last sync at 10:00". It
looks equivalent and it is not, and the next section shows the change it loses. A sequence number
handed out by the server has one property a time does not: **it is decided in one place, in the
order the writes actually happened**, so nothing can be written with a number lower than one the
device has already read.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-cursor\" aria-label=\"The server's history of writes as a row of numbered boxes: 1 s1, 2 s2, and so on to 2006 h2000, then 2007 s7. Phone A's cursor sits after 2006, so asking for changes after 2006 returns one row, s7, and the new cursor 2007. Phone B's cursor sits after 6, so the same question from B returns 2001 rows. One history serves both, each from its own place.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the server's history: every write, numbered in the order it arrived</text><rect x=\"20\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"58.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"58.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s1</text><rect x=\"104\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"142.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><text x=\"142.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s2</text><rect x=\"188\" y=\"40\" width=\"40\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"208.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"236\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"274.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6</text><text x=\"274.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s6</text><rect x=\"320\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"358.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7</text><text x=\"358.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h1</text><rect x=\"404\" y=\"40\" width=\"40\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"452\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"490.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2006</text><text x=\"490.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2000</text><rect x=\"536\" y=\"40\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"574.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2007</text><text x=\"574.0\" y=\"68.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">s7</text><path d=\"M532 34 L532 128\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"532\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">phone A: cursor 2006</text><text x=\"532\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">after=2006 → 1 row, cursor 2007</text><path d=\"M316 34 L316 178\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"322\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">phone B: cursor 6</text><text x=\"322\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">after=6 → 2001 rows, cursor 2007</text></svg>", "caption": "The device keeps its place in one history the server writes. The cost of a pull follows how far it has to read, not how much there is."}
```

## Pulling by cursor

Remove `planner.db` so the device starts empty, then pull by cursor three times: once from nothing,
once with nothing changed, and once after another phone changes one session:

```
ana@dev:~/planner/delta$ rm planner.db
ana@dev:~/planner/delta$ node pull.ts delta
received 2006 rows, 217863 bytes; cursor 2006; 2006 sessions on the device
ana@dev:~/planner/delta$ node pull.ts delta
received 0 rows, 28 bytes; cursor 2006; 2006 sessions on the device
ana@dev:~/planner/delta$ curl -s -o /dev/null -X PUT -d '{"course":"guitar","date":"2026-10-23","minutes":25}' 'http://127.0.0.1:8011/sessions/s7?stamp=2026-10-21T10:00:00Z'
ana@dev:~/planner/delta$ node pull.ts delta
received 1 row, 132 bytes; cursor 2007; 2007 sessions on the device
```

The first pull is as large as pulling everything, because an empty device has everything to learn.
After that **the cost follows the change**. With nothing new, 28 bytes: the cursor and an empty list.
With one session written, one row, 132 bytes, and the cursor moves to 2007. The answer and the
bookmark arrive together, and `pull.ts` writes the rows and the new cursor in one transaction, for
the same reason lesson 8 wrote the outbox row with the change: a cursor saved without its rows would
skip them for ever, and rows saved without their cursor are only fetched twice.

## What the cursor is not

The cursor is opaque to the device. Here it is a number, and the device must still not do arithmetic
on it, compare it with another server's, or make one up; a server is free to change it to a string
that encodes a shard and a position, and many real ones do. **The device stores what it was given
and sends it back.**

It is also per device. Each phone has its own position in the same history, which is what lets the
server answer two phones that last synced a week apart without keeping anything per phone. What the
server does have to keep is the history itself, back to the oldest cursor anybody still holds, and
lesson 12 is what happens when it stops keeping it.
