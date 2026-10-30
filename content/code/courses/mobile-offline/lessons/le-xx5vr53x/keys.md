---
title: The key, made on the device when the person acts
version: 1
---

**The key is made once, when the person acts, before the first request leaves, and the same key goes
with every retry of that operation.** Every word of that sentence is a rule somebody broke once.

- **Made once.** A key made per request is a new key on the retry, and the server sees a new
  operation. That is exactly the bug the key exists to stop.
- **When the person acts.** A key made from the body, a hash of course and amount, says two taps on
  Buy are one, and they may not be: the person may want two seats.
- **On the device.** Only the device knows that a retry is a retry. The server sees two requests and
  nothing else.

`buy.ts` makes it with `randomUUID()` from `node:crypto`, outside the loop. A version 4 UUID has 122
random bits, so two phones choosing the same one is not a case worth designing for. Start the server
as `node server.ts drop` again and tap Buy, with a key this time:

```
ana@dev:~/planner/idempotency$ node buy.ts key
attempt 1: no answer, trying again
attempt 2: 201, replayed { id: 'p1', user: 'ana', course: 'statistics', cents: 4900 }
ana@dev:~/planner/idempotency$ curl -s http://127.0.0.1:8010/purchases
[{"id":"p1","user":"ana","course":"statistics","cents":4900}]
```

The first try charged `p1` and lost the answer, as before. The retry carried the same key, and the
server answered **with the answer it had saved**, `p1` again, and a header saying it was a replay.
One charge. The client cannot tell a replay from a first answer and does not need to; the header is
there for logs and for tests.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-key\" aria-label=\"A sequence in time between the phone and the server. The phone makes key K when the person taps Buy and sends POST /purchases with key K. The server charges the card, saves p1 as the answer for K, and its 201 is lost on the way back. The phone sees no answer and retries with the same key K. The server finds K, sends the saved p1 again marked as replayed, and charges nothing.\"><defs><marker id=\"l10-key-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-key-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"70\" y=\"14\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the phone</text><rect x=\"490\" y=\"14\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the server</text><path d=\"M140 44 L140 290\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M560 44 L560 290\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"150\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">taps Buy: key K is made</text><path d=\"M140 76 L560 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-key-ah-phosphor)\"></path><text x=\"350\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">POST /purchases, key K</text><rect x=\"568\" y=\"92\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"102.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">charges the card</text><text x=\"643.0\" y=\"115.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">saves p1 under K</text><path d=\"M560 132 L350 142\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-key-ah-amber)\"></path><text x=\"330\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">✕</text><text x=\"350\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">201 lost on the way</text><text x=\"150\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">no answer: same key K again</text><path d=\"M140 196 L560 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-key-ah-phosphor)\"></path><rect x=\"568\" y=\"210\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"220.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">finds K: sends p1 again</text><text x=\"643.0\" y=\"233.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">charges nothing</text><path d=\"M560 256 L140 276\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-key-ah-phosphor)\"></path><text x=\"350\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">201, replayed: p1</text></svg>", "caption": "The key is made before the first try and sent with every retry, so the server can tell a retry from a second purchase."}
```

## In the outbox

In an app the key lives in the outbox row, written in the same transaction as the change, beside
`seq`. Lesson 8's table, with one column added:

```sql
create table if not exists outbox (
  seq     integer primary key autoincrement,
  op      text not null check (op in ('create', 'update', 'delete')),
  session text not null,
  body    text,
  key     text not null unique  -- made with the row, sent with every try of it
);
```

*This table is lesson 8's with the `key` column added; the lesson does not run it again.*

Storing it there is what makes it survive the app being killed between two tries: the next drain,
in a new process, reads the same key back.

**And it changes lesson 8's coalescing in one place.** Folding an update into a create is safe only
if the create has never been sent. If it was sent and its answer lost, the server may have saved it under its key. A server that compares bodies then refuses a different body under the same key. One that does not answers with the old saved answer, and the update is silently dropped. So an operation that has been tried at least once is never folded
into, and a column such as `tried` on the outbox row is how the drain and the compaction agree on
it.
