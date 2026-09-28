---
title: What calls a function
version: 1
---

A function does nothing until something invokes it. **The thing that invokes it is called a
trigger, or an event source, and it decides two things: the shape of the event, and whether anybody
is waiting for the answer.** Four sources cover most of what functions are used for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four things that call a function: an HTTP request through an API gateway or a function URL, a message on a queue, a file landing in a bucket, and a schedule. All four arrive as an event passed to the same handler. Only the HTTP request has somebody waiting for the answer; for the other three the result is whatever the function wrote somewhere.\"><defs><marker id=\"sl-trig-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">An HTTP request</text><text x=\"32\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">GET /hello?name=ana</text><path d=\"M230 47 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"20\" y=\"88\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">A message on a queue</text><text x=\"32\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SQS</text><path d=\"M230 115 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"20\" y=\"156\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">A file lands in a bucket</text><text x=\"32\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">s3:ObjectCreated:Put</text><path d=\"M230 183 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"20\" y=\"224\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">A schedule</text><text x=\"32\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">rate(5 minutes)</text><path d=\"M230 251 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"310\" y=\"118\" width=\"140\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">your function</text><text x=\"380\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">handler(event, context)</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">somebody is waiting</text><text x=\"512\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the return value is the response</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"512\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">nobody is waiting</text><text x=\"512\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the result is what it wrote:</text><text x=\"512\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a row, a file, a message</text><text x=\"512\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">failures are retried or</text><text x=\"512\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept aside, not shown to a user</text><path d=\"M450 135 L500 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><path d=\"M450 165 L500 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path></svg>", "caption": "One handler, four doors. The event is shaped differently for each, and only one of them has a caller waiting at the other end."}
```

- An HTTP request. The function answers a URL, either through an API gateway, which adds routing,
  authentication and rate limits in front of it, or through a function URL, an address AWS gives
  one function directly. This is the case of the previous two sections, and the only one of the
  four where a person is waiting.
- A message on a queue. Another part of the system puts work on a queue, SQS on AWS, and the
  platform takes messages off it and hands them to the function in batches. A message the function
  fails on goes back on the queue and is tried again.
- A file landing in a bucket. Object storage, lesson 5's subject, can announce each new object, and
  the announcement can call a function: a photo is uploaded, a function makes the thumbnail. The
  event names the bucket and the key, not the contents; the function reads the object itself.
- A schedule. A rule such as `rate(5 minutes)`, or a cron expression, calls the function on the
  clock: a nightly clean-up, a report every Monday. It is cron without a machine to run cron on.

There are more, such as changes in a database table or messages on a stream, and they follow one of
the two patterns below.

## Somebody waiting, or nobody

**Whether anybody is waiting is the distinction that changes how you write the handler.** An HTTP
call is synchronous: the caller waits, the return value becomes the response, and an error is
something a person sees. The other three are asynchronous as far as your code is concerned. Nobody
is waiting, the return value goes nowhere useful, and the result is whatever the function wrote: a
row, a file, another message.

A failure in an asynchronous call is invisible to any user, so the platform retries it. What
happens once the retries run out is a setting: the event is dropped, or it is kept aside in a
dead-letter queue for somebody to look at. **A function with no dead-letter queue and no alarm can
fail on every event for a week and nobody will know**, because there is no user to complain.

## The same event, twice

Retries have a consequence for the code: **the same event can arrive more than once.** AWS
documents that asynchronous invocation and SQS standard queues deliver at least once, so a duplicate
is part of the contract, not a fault. A thumbnail made twice is harmless. An e-mail sent twice, or
a card charged twice, is not.

A handler that does something which must happen once has to recognise an event it has already
handled, usually by recording an id carried in the event and checking it before acting. Such a
handler is called idempotent: running it twice on the same event leaves the world as running it
once did. It is not a serverless idea, it belongs to every system built on queues, but a function
behind a queue is where most people meet it first.
