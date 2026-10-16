---
title: One model, two jobs
version: 1
---

Quitanda's orders live in one table, and that table does two jobs. It **takes changes**: an order is
placed, an item is added, a payment arrives, and each change has rules (a paid order cannot gain items).
And it **answers questions**: the customer's order history, the warehouse's list for the morning, the
best sellers this week, the report the accountant wants. The same rows, the same columns, the same
indexes serve both.

For a long time that is the right design, and for most systems it stays right. It starts to pinch when
the two jobs pull in different directions:

- **The reads need shapes the writes do not.** The best sellers want totals per product, the order page
  wants items with names and prices, the search box wants text. Each is a join and an aggregate over
  the same normalised tables, computed on every request.
- **The reads and the writes grow differently.** A shop reads its catalogue hundreds of times for every
  order placed. Lesson 10's read replica is one answer; it copies the same model, so it carries the
  same expensive joins to another machine.
- **The rules get tangled with the views.** Columns added so a screen can show something end up being
  set, checked and trusted by the code that takes orders.

**CQRS**, Command Query Responsibility Segregation, a name Greg Young gave around 2010 to an idea from
Bertrand Meyer, separates the two. A **write model** takes commands and enforces the rules. One or more
**read models**, each shaped for the questions it answers, are built from the changes the write model
records. Queries never touch the write model; commands never touch a read model.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two arrangements. On the left, one model: commands and queries both go to the same orders table. On the right, CQRS: commands go to a write model, which records changes; the changes flow to read models, an order summary and units sold, and queries go to those.\"><defs><marker id=\"l13-cqrs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-cqrs-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-cqrs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">one model</text><rect x=\"70\" y=\"100\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><text x=\"130\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">commands</text><path d=\"M130 78 L130 98\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-amber)\"></path><text x=\"130\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">queries</text><path d=\"M130 176 L130 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-phosphor)\"></path><path d=\"M260 40 L260 220\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"490\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">CQRS</text><text x=\"300\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">commands</text><path d=\"M320 84 L320 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-amber)\"></path><rect x=\"290\" y=\"110\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">write model</text><path d=\"M422 135 L478 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-paper-dim)\"></path><text x=\"450\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">changes</text><path d=\"M478 135 L500 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"62\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">order_summary</text><rect x=\"500\" y=\"160\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">units_sold</text><path d=\"M478 135 L498 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-paper-dim)\"></path><text x=\"590\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">queries read these</text></svg>", "caption": "CQRS separates the model that takes changes from the models that answer questions, and joins them with a flow of changes."}
```

Three things CQRS does **not** require, because they are often bundled with it in descriptions:

| often assumed | in fact |
| --- | --- |
| separate databases | the lab keeps both models in one PostgreSQL |
| event sourcing | the write model can be ordinary tables that publish changes, with an outbox from lesson 7 |
| a message broker | a read model can be updated in the same transaction, or by polling a table |

What it does require is accepting that **a read model built from changes is a copy, and lags**: lesson
9's window, inside one application. A screen that shows a read model right after a command needs lesson
9's read-your-writes.
