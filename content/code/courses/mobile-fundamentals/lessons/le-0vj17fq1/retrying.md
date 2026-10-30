---
title: Trying again, without making things worse
version: 1
---

**A failed request is often worth sending again, and a retry written carelessly turns one failure
into two kinds of damage.** The first kind is to the server: a thousand phones that all retry at
once, at full speed, keep a struggling server down. The second kind is to the data: a request
that changed something, sent twice, can change it twice. A safe retry answers three questions
before it sends anything again.

## How many times, and how far apart

`fetchWeek` retries only when the server answers with a status of 500 or above, which means *the
server* failed and might not next time. A 404 or a 403 will fail the same way however often it is
asked, so it is thrown at once. The number of retries is a parameter with a small default, and the
wait between attempts **doubles** each time: 500 milliseconds, then a second, then two. That is
*exponential backoff*, and it gives a server that is restarting time to come back instead of a
queue of requests waiting for it.

`/flaky` has already been asked three times, by `curl`, so its next two calls fail and the one
after them answers. Ask it with two retries, and then once more with none:

```
ana@dev:~/planner$ node fetchweek.ts /flaky --retries 2
asking http://127.0.0.1:8014/flaky
attempt 1: HTTP 503, waiting 500 ms
attempt 2: HTTP 503, waiting 1000 ms
{ monday: '2026-10-19', planned: 180, done: 120 }
after 1.6 s
ana@dev:~/planner$ node fetchweek.ts /flaky
asking http://127.0.0.1:8014/flaky
Error: HTTP 503 after 1 attempt(s)
after 0.1 s
```

With two retries, the client waited 500 ms after the first 503 and 1000 ms after the second, and
the third attempt answered: 1.6 seconds in all, 1.5 of them spent waiting. The next call was the first of a
new pair of failures, and with no retries that first 503 was the end. **The limit matters as much
as the wait**: if two retries had not been enough, the client would have thrown after its third
attempt rather than trying for ever.

**A real client adds randomness to each wait, called *jitter***, so that phones which failed at the
same moment do not all come back at the same moment too. It is left out here so that your output
matches the transcript. The `mobile-offline` course measures both in its lesson 9.

## Which requests may be repeated

**Asking for the week can be repeated as often as you like: reading it twice changes nothing.** A
request that changes something is different, and the trap is a timeout. When a request times out,
the client knows only that no answer arrived. It does not know whether the server never received
the request, or received it, did the work, and lost the answer on the way back:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-lost-answer\" aria-label=\"A sequence between the phone and the server. The phone sends: add a 30-minute session. The server adds it and answers, but the answer is lost on the way back. The phone's deadline passes, it knows only that no answer came, and it sends the same request again. The server adds a second session. The week now says 210 minutes planned instead of 180.\"><defs><marker id=\"l14-lost-answer-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the phone</text><rect x=\"530\" y=\"14\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the server</text><path d=\"M115 44 L115 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M605 44 L605 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M115 70 L605 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-lost-answer-ah-phosphor)\"></path><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">add a 30-minute session</text><rect x=\"612\" y=\"98\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"662.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">adds it: 180 → 210</text><path d=\"M605 136 L380 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"372\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--amber)\">✕</text><text x=\"470\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the answer is lost on the way</text><rect x=\"8\" y=\"168\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"58.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">deadline passes:</text><text x=\"58.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no answer came</text><path d=\"M115 214 L605 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-lost-answer-ah-phosphor)\"></path><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">add a 30-minute session, again</text><rect x=\"612\" y=\"240\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"662.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">adds another:</text><text x=\"662.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">210 → 240</text></svg>", "caption": "A timeout tells the phone that no answer arrived, not that nothing happened. A request that changes something can be done twice."}
```

For "mark session `s3` as done" that is harmless, because doing it twice leaves it done, exactly as
`markDone` does in lesson 1. For "add a 30-minute session on Thursday" it is a second session, and
the student's week now says 210 minutes planned instead of 180. Nothing failed, and the screen is
wrong.

The table is the rule this course leaves you with; the tools to follow it come later.

| request | sent twice | retry it after a timeout? |
|---|---|---|
| read the week | the same answer twice | yes |
| mark a session done | done, once | yes: it is the same either way |
| add a session | two sessions | only with a key that lets the server recognise the repeat |
| pay for a subscription | two charges | only with that key, and nothing else will do |

**The key in the last two rows is called an idempotency key**: the app makes up a unique id for the
operation once, sends it with every attempt, and the server refuses to do the same id twice. The
`mobile-offline` course builds the rest around it: lesson 8 keeps such operations in a queue on the
device, the *outbox*, so that they survive the app being killed; lesson 9 is the backoff; and
lesson 10 is the key itself, with the payment that went through twice.

## When to try again

The third question is when, and the network gives a better answer than the clock. **A request that
failed because there was no network is best retried when the system says the network is back**,
which is the callback from the first section of this lesson. A request that failed with a 503 is
retried after a backoff. And a request the user is waiting for gets a few quick attempts, then a
screen that says what happened and offers a button: the next section is that screen.
