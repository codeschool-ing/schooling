---
title: Discovery: from symptoms to a diagnosis
version: 1
---

**Discovery is finding out what is actually happening, from three sources that each lie in a
different way: the data, the people, and the system itself.** A diagnosis built on one of them
inherits its blind spot. Built on all three, the blind spots mostly cancel out.

## Start with the data, because it does not have an opinion

Lívia's first afternoon was the deploy log and the incident notes for January to April. She
counted, before forming any view:

| | |
|---|---|
| logistics releases, January to April | 23 |
| releases followed by a route-planning incident within 24 hours | 7 |
| share of releases that caused an incident | about 30% |
| median time from merge to production | 9 days |

Then, for each of the seven incidents, she read the notes and wrote down one line on what had
actually broken:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A count of the seven route-planning incidents by cause. A shared table changed by one service and read by the other: 5. A configuration error: 1. Capacity at a Friday peak: 1. A timeout between the two services: 0.\"><defs><marker id=\"incidentca-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a shared table changed by one service, read by the other</text><rect x=\"430\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"478\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"526\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"574\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"622\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"676\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"20\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a configuration error</text><rect x=\"430\" y=\"66\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"484\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">capacity at a Friday peak</text><rect x=\"430\" y=\"110\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"484\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a timeout between the two services</text><rect x=\"430\" y=\"154\" width=\"40\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"484\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"20\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the 7 route-planning incidents after logistics releases, January to April, by what broke</text></svg>", "caption": "The row that matters is the empty one. A broker solves timeouts between services, and none of the seven incidents was one."}
```

Five of the seven had the same shape: one service changed a column in a table that both the route
planner and the zone service read, and the other service broke when it read the new format. One
was a configuration error. One was a capacity problem during a Friday peak, which is lesson 4's
story again.

**None of the seven was caused by a synchronous call between the two services timing out**, which
is the problem a message broker would solve. That did not settle the question yet. The data shows
what broke; it does not show why the team had not stopped it breaking.

## Then the people, because the data cannot say why

Four interviews of thirty minutes, with people Henrique chose, each opened by repeating the
contract's line that this was not an evaluation of anybody. Lívia asked the same open questions of
each:

- *What happens on the day of a release?*
- *When a release breaks something, how do you find out?*
- *If you could change one thing about how you release, what would it be?*

Three of the four mentioned the shared table without being asked about it. Two said, in different
words, that changing it "needs the zone service people to agree, and they're always busy", so
changes were made quietly and hoped for the best. Paulo, the most senior engineer, said the broker
idea had come up because "with a broker each service would have its own copy of the data and
nobody could break anybody else".

That sentence was the diagnosis waiting to be noticed. **The broker was not wanted for messaging;
it was wanted as a way to stop sharing a table without having to negotiate who owned it.**

## Then the system, to check what people believe

People's accounts of their own system are partly folklore. Lívia spent an hour reading the
schema's change history and the code of both services. She confirmed that the table had no owner
written down anywhere, that both services wrote to it, and that there was no test that ran the two
services together before a release; they were tested together only in staging, overnight, after
the merge.

## Hypotheses, held loosely

By the halfway check-in on 22 May, Lívia had three hypotheses, and she presented them to Henrique
as hypotheses, with what would distinguish them:

1. **The services need asynchronous messaging.** Would predict timeouts in the incidents. *Not
   seen.*
2. **The shared table has no owner and no contract**, so changes to it are unreviewed by the other
   side. Would predict incidents after schema changes. *Five of seven.*
3. **The two services are only tested together after merging**, so the break is found late. Would
   predict incidents found in staging or production, never before merge. *All seven.*

Hypotheses 2 and 3 were both true and reinforced each other. The halfway check-in is where Henrique
first heard this, a week before the written note, which is why the final note did not surprise him.
