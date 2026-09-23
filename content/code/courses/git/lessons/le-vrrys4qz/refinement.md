---
title: Refinement: getting tickets ready
version: 1
---

Ready tickets do not appear by themselves. They are made in **refinement** (also called *backlog
refinement* or, in older teams, *grooming*): a regular session, often an hour a week, in which the team reads
the tickets near the top of the backlog **before** anybody is about to start them.

## What happens in it

For each ticket, the team asks the questions Ana asked too late:

- Is the problem clear? Who has it?
- What are the acceptance criteria? Somebody writes them down, there and then.
- What do we not know? Who can find out by next week?
- Is it too big?

The product owner brings the *what* and *why*; developers and testers bring the *how* and the *what could go
wrong*. Some teams call a small version of this **the three amigos**: one person from product, one developer
and one tester look at a ticket together for ten minutes before it is ready. Each sees problems the others
miss: Diego would have asked about refunds in the first minute, because testing the unhappy path is his job.

## Splitting a big ticket

*Pay online* is too big to be one ticket even after its questions are answered. The question is **how** to
split it, and there are two ways:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two ways of splitting ticket 35, pay online. On the left, split by layer into three tickets: a payments table in the database, a payment endpoint on the server, and a pay button on the order page; nothing a customer can use until all three are done. On the right, split by slice into three tickets: pay by Pix, pay by card, refund a payment; each one cuts through page, server and database, and each one is usable on its own, in this order.\"><defs><marker id=\"sl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">split by layer</text><rect x=\"20\" y=\"50\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payments table in the database</text><rect x=\"20\" y=\"98\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payment endpoint on the server</text><rect x=\"20\" y=\"146\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pay button on the order page</text><text x=\"20\" y=\"212\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nothing a customer can use until all three are done</text><path d=\"M355 20 L355 262\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"390\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">split by slice</text><text x=\"452\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">page</text><text x=\"452\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">server</text><text x=\"452\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">database</text><rect x=\"470\" y=\"46\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"470\" y=\"94\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"470\" y=\"142\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"503\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pay by</text><text x=\"503\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Pix</text><rect x=\"548\" y=\"46\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"548\" y=\"94\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"548\" y=\"142\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pay by</text><text x=\"581\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">card</text><rect x=\"626\" y=\"46\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"626\" y=\"94\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"626\" y=\"142\" width=\"66\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"659\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">refund a</text><text x=\"659\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">payment</text><text x=\"390\" y=\"252\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">each one usable on its own, in this order</text></svg>", "caption": "A slice goes through every layer, so the first one can be released and learnt from while the second is being built."}
```

**Splitting by layer** (database, server, page) feels natural to developers, and it produces three tickets
none of which does anything a customer can see. Nothing can be released until all three are finished, so the
first real feedback comes weeks later.

**Splitting by slice** cuts through every layer for one small, complete thing. *Pay by Pix* needs a little
of the database, a little of the server and a little of the page, and at the end a customer can pay by Pix.
It can be released alone and teach the team something while *pay by card* is being built. That is the split
lesson 9's short branches depend on: a slice fits in a branch that lives a day or two.

A ticket that is a slice has a title a customer would understand. If the title only makes sense to a developer
(*add payments table*), it is probably a layer.
