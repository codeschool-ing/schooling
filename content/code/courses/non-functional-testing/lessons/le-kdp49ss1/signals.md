---
title: Three signals and two methods
version: 1
---

Everything in this course so far happened before a release. The load test ran against a machine
you owned, the audit read a page you served, the scanner looked at a repository you could see.
**Production is where the defects you did not test for arrive**, with users nobody modelled,
on networks nobody chose, at an hour nobody planned. Monitoring is how a team finds out before
those users write in, and it is the operability third of the course: in lesson 1's table, *when it
misbehaves in production, does somebody find out first?*

A running system can tell you about itself in three ways, and they answer different questions.
Teams that collect one and call it monitoring usually discover which question they cannot answer
on the night they need it.

## Metrics, logs and traces

**A metric is a number sampled over time**: requests answered, requests that failed, how long they
took, how busy the processor is. It is aggregated before it is stored, so a million requests cost
the same handful of numbers as ten. That makes metrics cheap enough to keep for months and fast
enough to alert on, and it is also their limit: a metric says that 3% of bookings failed in the
last five minutes, and it cannot say which ones.

**A log is a record of one event.** One line per request, per error, per booking. It answers the
question a metric throws away, *what happened to this one*, and it costs in proportion to the
traffic: a busy system writes gigabytes a day, and searching them needs a tool built for it.

**A trace follows one request through every part that handled it.** Each part is a *span*, with a
start and a duration, and the spans nest: the request, inside it the database query, inside that
nothing, next to it the call to the payment provider. In a system of twenty services the trace is
the only record that shows a slow checkout spent its time in the fourth one. boxoffice is one
process, and it already carries a trace of one line: the `Server-Timing` header lesson 1 showed you,
`db;dur=…, pay;dur=…, total;dur=…`, is the same idea with no tool around it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-signals\" aria-label=\"One booking request, POST /bookings, in the middle, and the three records it leaves behind. As a metric, it adds one to a counter labelled with its route and status, and one to a duration bucket: cheap, and it says how many and how fast, never which one. As a log line, it is one JSON record with its own request id, status and milliseconds: it says what happened to this request. As a trace, it is a bar for the whole request with a bar inside it for each part, the database and the payment: it says where the time went.\"><defs><marker id=\"l22-signals-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"20.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">POST /bookings</text><path d=\"M360.0 62.0 L120.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-signals-nf-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"120.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">metric</text><rect x=\"20.0\" y=\"138.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"120.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">how many, how fast</text><path d=\"M360.0 62.0 L360.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-signals-nf-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">log</text><rect x=\"260.0\" y=\"138.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">what happened to this one</text><path d=\"M360.0 62.0 L600.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-signals-nf-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"600.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">trace</text><rect x=\"500.0\" y=\"138.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"600.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">where the time went</text><text x=\"120.0\" y=\"162.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">requests_total{</text><text x=\"120.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">route=&quot;/bookings&quot;,</text><text x=\"120.0\" y=\"187.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">status=&quot;201&quot;} +1</text><text x=\"120.0\" y=\"228.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">duration_bucket{</text><text x=\"120.0\" y=\"241.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">le=&quot;0.1&quot;} +1</text><text x=\"360.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;request_id&quot;:</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;ana-test-1&quot;,</text><text x=\"360.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;route&quot;: &quot;/bookings&quot;,</text><text x=\"360.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;status&quot;: 201,</text><text x=\"360.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;ms&quot;: 68.8}</text><rect x=\"512.0\" y=\"160.0\" width=\"176.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"520.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">request</text><rect x=\"512.0\" y=\"190.0\" width=\"50.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><text x=\"537.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">db</text><rect x=\"566.0\" y=\"190.0\" width=\"116.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"624.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pay</text><path d=\"M512.0 236.0 L688.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"512.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">0</text><text x=\"688.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">time</text></svg>", "caption": "One request, three records. Each answers a question the other two cannot."}
```

The three are joined by an id. A log line that carries the request id can be found from the trace
that carries the same id, and a metric can carry a sample of trace ids beside its numbers. **Without
the id each signal is an island**, and the person on call spends the first twenty minutes matching
timestamps by eye.

## RED for a service, USE for a resource

Two short checklists say which metrics to collect first, and they look at the system from opposite
sides.

| method | for | the three numbers |
|---|---|---|
| **RED** | a service, seen by whoever calls it | **R**ate of requests, **E**rrors among them, **D**uration of each |
| **USE** | a resource the service runs on | **U**tilisation, how busy it is; **S**aturation, how much work is queued for it; **E**rrors it reports |

RED is Tom Wilkie's, from the microservices world: for every endpoint, how many, how many failed,
how long. It is what a user feels, so it is what an alert should watch, and lesson 24 builds on
exactly that. USE is Brendan Gregg's, from performance work on operating systems: for every
resource — processors, memory, disks, network links — how busy, how queued, how broken. It is
where you look once RED says something is wrong.

**A resource is anything that work waits for, and not only hardware.** In boxoffice the processor
is one, and so is `booking_lock`, the lock every booking holds while it pays: its utilisation is
the share of time somebody holds it, and its saturation is how many bookings are waiting at the
door. Lesson 9 measures exactly that wait. A machine at 40% CPU with a saturated lock is a slow
box office, and a USE check that only looks at hardware calls it healthy.

The numbers RED asks for are the ones lesson 8 taught you to read. Rate is throughput, errors is
the error rate, and duration is a distribution, which means a percentile and never a mean. **A
dashboard showing the average response time is making the mistake lesson 8 is about**, at the
scale of a whole production system.

## A log line for a machine to read

A log written for a person reads like a sentence: `Booked seat 12 of show 990 for ana in 68 ms`.
It is easy to read one of and very hard to search a million of, because every question becomes a
regular expression that breaks the day somebody rewords the message.

A **structured log** writes the same event as fields, one JSON object per line:

```json
{"ts": "2026-10-10T07:25:35.959+00:00", "level": "info", "request_id": "ana-test-1", "method": "POST", "route": "/bookings", "status": 201, "ms": 68.8}
```

Now "every booking that took more than 500 ms" is a filter on `ms`, "every failure on the booking
route" is a filter on `route` and `status`, and neither breaks when the wording changes, because
there is no wording. The `request_id` is the field that pays for the rest: it is sent back to the
client in a header, so a customer's complaint, a support ticket or a failed synthetic check can
quote it, and the one line that matters is found in a second among millions.

Two things never go in a log line, whatever the format: a password or a token, and anything that
identifies a person beyond what the investigation needs. Logs are copied to more places, and kept
longer, than the database they describe.
