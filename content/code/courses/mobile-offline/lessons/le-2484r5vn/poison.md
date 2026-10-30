---
title: The operation that will never be accepted
version: 1
---

**A drain that stops at every failure has a weakness: one operation the server will always refuse
blocks every operation behind it, forever.** That operation is called **poison**, and the outbox
has to recognise it, take it out of the way, and say so.

The wrong reaction is to treat every failure the same, retry it, and stop again. A network error is
temporary and the next drain may succeed. A **422 Unprocessable Entity** is the server reading the
operation and saying no, and it will say no to the same bytes every time. Retrying it is a loop; the
person's other sessions wait behind it and none of them ever leaves the phone.

## Taking it out of the way

`drain.ts` already tells the two apart. A network error or a 5xx stops the drain. A 4xx moves the
operation into the `dead` table with the server's reason, in one transaction with removing it from
the outbox, and the drain carries on. A 300-minute session, a correction to it, and a different
session after both:

```
ana@dev:~/planner/outbox$ node app.ts add s11 statistics 2026-10-27 300
ana@dev:~/planner/outbox$ node app.ts minutes s11 200
ana@dev:~/planner/outbox$ node app.ts add s12 spanish 2026-10-28 30
ana@dev:~/planner/outbox$ node drain.ts
#9 create s11: 422 a session is at most 240 minutes, moved to dead
#10 update s11: held behind a dead operation
#11 create s12: 201
1 waiting
ana@dev:~/planner/outbox$ node app.ts outbox
#10 update s11  {"id":"s11","course":"statistics","date":"2026-10-27","minutes":200}
dead #9 create s11: 422 a session is at most 240 minutes
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-poison\" aria-label=\"The outbox holds three operations in order: number 9, create s11 at 300 minutes; number 10, update s11 to 200 minutes; number 11, create s12. The drain sends number 9 and the server answers 422, so it moves to the dead table. Number 10 is held, because it updates a session the server never created. Number 11 belongs to another session and is sent, and the server answers 201.\"><defs><marker id=\"l08-poison-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-poison-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the outbox, oldest first</text><rect x=\"20\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#9  create s11  300 min</text><text x=\"270\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">422: moved to dead</text><rect x=\"20\" y=\"102\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#10 update s11  200 min</text><text x=\"270\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">held: same session</text><rect x=\"20\" y=\"164\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#11 create s12   30 min</text><text x=\"270\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">201: sent</text><rect x=\"560\" y=\"162\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the server</text><path d=\"M240 192 L556 192\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-poison-ah-phosphor)\"></path><rect x=\"560\" y=\"38\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dead</text><path d=\"M240 68 L556 68\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-poison-ah-amber)\"></path></svg>", "caption": "A refused operation leaves the queue so the rest can pass, and the operations on the same row wait behind it."}
```

Three answers, and the second is the interesting one. `#10` is a valid update, 200 minutes, and it
was not sent. **It was held because the session it updates was never created on the server.** Sent,
it would have been a 404; sent and accepted, it would have described a row that does not exist.
`s12` belongs to another session, depends on nothing, and went.

This is the honest limit of a drain that skips poison. **Operations on different rows are
independent and can pass a dead one; operations on the same row cannot.** If the planner's
operations depended on each other across rows, a session on a course that was itself refused, the
held set would have to follow that dependency too.

## Bringing it back

A dead operation is a decision for the person, not for the app, and lesson 7's last section says how
to put it to them: which session, why, what to do. Here the person has already fixed it, changing the
length to 200. `revive` drops the dead operation and the held one, and queues a single create from
the row as it is now:

```
ana@dev:~/planner/outbox$ node app.ts revive s11
ana@dev:~/planner/outbox$ node app.ts outbox
#12 create s11  {"id":"s11","course":"statistics","date":"2026-10-27","minutes":200}
ana@dev:~/planner/outbox$ node drain.ts
#12 create s11: 201
0 waiting
ana@dev:~/planner/outbox$ curl -s http://127.0.0.1:8008/sessions
[{"id":"s7","course":"guitar","date":"2026-10-23","minutes":40},{"id":"s8","course":"statistics","date":"2026-10-24","minutes":40},{"id":"s10","course":"guitar","date":"2026-10-26","minutes":20},{"id":"s12","course":"spanish","date":"2026-10-28","minutes":30},{"id":"s11","course":"statistics","date":"2026-10-27","minutes":200}]
```

The server has `s11`, at the length the person chose, and the outbox is empty.

## A count, and a limit

`dead` is also the place to look when something is wrong with the app rather than the person. A
release that sends a malformed body fills it on every phone at once, and a count of dead operations
reported by the app is how a team finds out the same day. Lesson 9 adds the other half of this: how
long to wait before trying an operation again, and how many times.
