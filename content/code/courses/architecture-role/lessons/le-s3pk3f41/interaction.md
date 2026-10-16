---
title: The lines matter as much as the boxes
version: 1
---

The commonest way to describe a system is to list its parts: Carreto has a Shipper app, a Pricing
service, a Matching service, and so on. **A list of parts is not an architecture.** The same parts,
joined in different ways, are different systems: they fail differently, they change differently, and
different teams have to talk to each other to keep them running. The way the parts are joined has a
name in the literature, the *connector*, and it deserves as much attention as the parts themselves.

## Three systems with the same three boxes

Take one flow at Carreto. A shipper posts a load in the Shipper app; Pricing quotes the freight;
Matching starts offering the load to drivers. Three components, and at least three ways to join
them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three panels with the same three components: the Shipper app, Pricing and Matching. In the first the Shipper app calls the other two over HTTP; if Pricing is down, no load can be posted. In the second the Shipper app publishes to a broker that both consume; if Pricing is down, messages wait. In the third all three read and write the loads table in one PostgreSQL database; a slow query from one slows the others.\"><defs><marker id=\"wire-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"220\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">synchronous calls</text><rect x=\"72\" y=\"60\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper app</text><rect x=\"18\" y=\"170\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pricing</text><rect x=\"126\" y=\"170\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Matching</text><path d=\"M100 94 L70 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><path d=\"M140 94 L170 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><text x=\"62\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">HTTP</text><text x=\"178\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">HTTP</text><text x=\"120\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Pricing down:</text><text x=\"120\" y=\"277.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no shipper can post a load</text><rect x=\"250\" y=\"10\" width=\"220\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">through a queue</text><rect x=\"312\" y=\"50\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper app</text><rect x=\"300\" y=\"118\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">broker</text><rect x=\"258\" y=\"180\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pricing</text><rect x=\"366\" y=\"180\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"414\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Matching</text><path d=\"M360 84 L360 116\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><path d=\"M340 148 L310 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><path d=\"M380 148 L410 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><text x=\"360\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Pricing down: shippers post;</text><text x=\"360\" y=\"277.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the quote waits in the queue</text><rect x=\"490\" y=\"10\" width=\"220\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">shared database</text><rect x=\"496\" y=\"60\" width=\"66\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"529\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper</text><text x=\"529\" y=\"87.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">app</text><rect x=\"567\" y=\"60\" width=\"66\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pricing</text><rect x=\"638\" y=\"60\" width=\"66\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"671\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Matching</text><rect x=\"530\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"600\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">loads</text><path d=\"M529 102 L570 168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M600 102 L600 168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M671 102 L630 168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"600\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no arrow between the boxes;</text><text x=\"600\" y=\"277.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a slow query slows all three</text></svg>", "caption": "The same three components, three architectures. What differs is the connector, and with it what happens when one part fails and who has to agree before the data changes."}
```

**Joined by synchronous calls.** The Shipper app calls Pricing over HTTP, waits for the quote, then
calls Matching and waits again. It is the easiest version to read and to debug: one request, one
trace, one answer. Its weakness is that every part has to be up at once. If each service is
available 99.9% of the time, the three together are available about 99.7% of the time — the
probabilities multiply. Over a 30-day month, 99.9% allows about 43 minutes of downtime; 99.7% allows
about 130. And while Pricing is down, **no shipper can post a load at all**, although nothing is
wrong with posting.

**Joined through a queue.** The Shipper app saves the load and publishes a "load posted" message to
the broker. Pricing and Matching each consume it in their own time. Now Pricing can be down without
stopping shippers: the messages wait. If Pricing is down for 20 minutes while shippers post 30 loads
a minute, 600 messages are waiting when it comes back. The price of that is paid elsewhere. The
shipper no longer sees a quote in the same screen. A message can arrive twice, so every consumer has
to cope with duplicates. And somebody has to watch the depth of the queue, because a queue that
grows quietly is an outage that has not been noticed yet.

**Joined through a shared database.** All three read and write the same tables in the monolith's
PostgreSQL. This is the fastest version to build, and it is how much of Carreto works today. Nothing
on a diagram shows the dependency: there are no arrows between the boxes, only a line from each of
them to the database. But a slow query from Matching holds locks the Shipper app is waiting on, and
**a change to a column is a change to three teams' code**, which is why a migration of the `loads`
table needs three tech leads in one meeting.

## What a connector decides

The three versions differ along a handful of properties, and those properties are what an architect
reads off a connector:

| | synchronous calls | queue | shared database |
|---|---|---|---|
| a shipper posts a load while Pricing is down | fails | succeeds; the quote comes later | succeeds, unless Pricing's queries are what is slow |
| when the shipper sees the price | in the same screen | some seconds later, by a notification | in the same screen |
| who knows about whom | the caller knows every callee | publishers and consumers know only the message | everybody knows every table |
| what a change to the data costs | a change to one API, with versions | a change to one message format, with versions | a migration that every reader must survive |
| what the person on call sees | an error in one trace | a queue growing | a slow database and no obvious culprit |

None of the three is the right answer. **Each one is a decision about which failure Carreto would
rather have.** A synchronous chain is simple and fragile together. A queue keeps shippers posting
when Pricing fails, and costs duplicates and a delayed quote. A shared database is quick and hides
its coupling until the day somebody changes a column. The mechanics of each — timeouts and retries,
delivery guarantees, idempotent consumers — were the subject of `architecture` lessons 5, 6 and 7,
and this course does not repeat them. What changes here is that you look at the choice as an
architectural one: it is expensive to reverse, and it decides how three teams work together.

## Carreto uses all three at once

Real systems mix the connectors, and Carreto is no exception. When a shipper posts a load today, the
Shipper app sends it to the monolith, which saves it in the `loads` table. The monolith calls
Pricing over HTTP and waits for the quote, so a slow Pricing makes posting slow. Matching does not
hear about the load from anybody: it reads new rows from the same `loads` table every few seconds.
Tracking, the one team that left the monolith cleanly, publishes truck positions to the broker, and
Matching consumes them to know which drivers are near a load.

So one ordinary flow crosses a synchronous call, a shared table and a queue, and **each part of it
fails in its own way.** When Pricing is slow, shippers wait at the screen. When the database is
slow, posting and matching slow down together and nobody's dashboard says why. When the broker is
down, Matching keeps offering loads to drivers using positions that are getting older by the minute.
An architect who wants to say how Carreto behaves under failure has to know which connector sits on
each step, and nobody had written that down.

## The arrow on the diagram

This is also why a box-and-arrow drawing so often says less than it seems to. **An arrow with no
label could be any of the three connectors above**, and the reader fills in whichever one they
imagine. One person reads "calls"; another reads "sends an event to"; a third reads "shares data
with". All three will agree the drawing is correct.

When Renata draws Carreto for the first time, she writes the kind of every line next to it: *HTTP,
waits for reply*; *event via broker*; *reads table `loads`*. The drawing becomes harder to make look
neat and much more useful. It also shows something the old onboarding slide did not, which lesson 2
starts from: **five services besides the monolith itself connect straight to the monolith's
database**, and on the slide none of them did.

## Elements, relations and properties

Go back to the textbook definition in the previous section: elements, the relations among them, and
**the properties of both**. A connector has properties of its own — synchronous or not, what it
guarantees about delivery, what it does when the other end is missing — and they are as much part of
the architecture as the properties of a service. A team can rewrite the inside of Pricing in a
quarter and nobody outside notices. Changing Pricing from a synchronous call to a consumer of events
changes the Shipper app, the screens shippers use, the monitoring and the on-call runbook. **That
difference in cost of change is the reason connectors are architecture.**
