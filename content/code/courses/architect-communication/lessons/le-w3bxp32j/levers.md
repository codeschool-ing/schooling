---
title: Four levers, and the one that is not a lever
version: 1
---

**Every negotiation about a software deadline is a negotiation about four things: scope, time, people
and quality. Three of them can be traded. The fourth can only be hidden, and hiding it is borrowing
against the future without telling the lender.** Project managers draw the first three as the iron
triangle; most of what goes wrong in a deadline conversation is somebody quietly moving the fourth.

## The request

On Monday 5 October, Renata brings Henrique's logistics team a request from Boa Praça and from
Marola's own customers: **scheduled deliveries**, so that a customer can order on Monday for delivery
on Thursday at a chosen time. She wants it live on 1 December, for the Christmas season. The team's
estimate, after a morning of breaking it down, is about **ten weeks**. The calendar from 5 October to 1
December holds about **eight**.

## The levers

| lever | what moving it means | for scheduled deliveries |
|---|---|---|
| **scope** | doing less, or a smaller version first | deliveries up to 7 days ahead, no recurring orders, no edits after confirmation |
| **time** | moving the date | launch on 14 December instead of 1 December |
| **people** | adding people | borrowing an engineer from another team |
| **quality** | doing it less carefully | skipping tests, skipping the load test, no rollback plan |

Each of the first three has a real cost that somebody can weigh. **Scope** costs features; **time** costs
two weeks of the Christmas season; **people** costs whatever the other team was going to do, and buys
less than it seems, because adding people to a late project makes it later before it makes it sooner.
Fred Brooks observed that in *The Mythical Man-Month* in 1975, and every team has observed it since.

## Quality is not a lever

**Quality looks like a lever because nobody sees it move.** The feature ships on 1 December, the demo
works, and the cost arrives in January: a bug in how scheduled orders interact with the substitution
flow, a slow page because nobody had time to check the query, a rollback that does not exist when it
is needed. By then nobody connects it to the decision in October.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A triangle with scope, time and people at its corners and quality in the middle, marked not a lever. Beside it: the three corners can be traded, and each trade has a visible cost; quality only looks like a lever, moving it is borrowing in secret, and the bill arrives in January.\"><defs><marker id=\"levers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><polygon points=\"200,30 60,250 340,250\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></polygon><text x=\"200\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">scope</text><text x=\"40\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">time</text><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">people</text><text x=\"200\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">quality</text><text x=\"200\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(not a lever)</text><text x=\"420\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the three corners can be traded,</text><text x=\"420\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and each trade has a visible cost</text><text x=\"420\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">quality only looks like a lever:</text><text x=\"420\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">moving it is borrowing in secret,</text><text x=\"420\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">and the bill arrives in January</text></svg>", "caption": "The iron triangle, with the fourth thing people trade drawn where it belongs: inside, holding the others up."}
```

That is why lesson 4's rule applies here: **a hidden cost is a risk somebody else carries without
having agreed to.** If the team is going to accept a shortcut, say so out loud, price it, and write
it down as debt (this lesson's section on debt). If nobody would agree to the shortcut out loud,
the team should not take it quietly.

## Who moves which lever

The team does not get to choose the trade on its own, and neither does product. **Renata owns scope
and the date, because she owns the promise to customers; Henrique owns the estimate and the quality,
because his team will live with the result.** The negotiation is between those two kinds of
ownership, and the rest of this lesson is how to conduct it.
