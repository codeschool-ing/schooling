---
title: Where there is no distributed commit
version: 1
---

Inside one database, a checkout is easy to make safe: reserve the stock, record the payment, book the
delivery, all in one transaction, and if any part fails the database rolls back the rest. Nothing
outside ever sees a half-finished checkout.

Split those three into services, each owning its own database as lesson 2 argued they should, and the
transaction is gone. **No database can roll back a change in another database.** If the delivery
cannot be booked after the card was charged, nothing undoes the charge on its own.

There is a protocol for transactions across databases, **two-phase commit**: a coordinator asks every
participant to prepare, and commits only if all of them said yes. It exists (XA in Java,
`PREPARE TRANSACTION` in PostgreSQL) and is rarely used between services, for reasons this course has already
met. Every participant holds its locks until the coordinator decides, so one slow participant slows
them all, as in lesson 12. If the coordinator disappears after "prepare", the participants wait with
their locks held, which lesson 8 would call choosing consistency over availability, for every service at
once. And most of what a checkout talks to, a payment gateway, a carrier's API, a broker, does not
speak it at all.

## The saga

Hector Garcia-Molina and Kenneth Salem described the alternative in 1987, for long-running transactions
inside one database, and the name stuck. **A saga is a sequence of local transactions, each with a
compensating transaction that semantically undoes it.** The steps run in order, each committing on its
own. If one fails, the compensations of the steps already done run in reverse order.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A saga of three steps in a row: reserve stock, charge the card, schedule the delivery. Under the first two, their compensations: release stock and refund the card. The third step fails, and arrows go back from it to the refund and then to the release, in reverse order.\"><defs><marker id=\"l14-saga-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-saga-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">reserve stock</text><path d=\"M222 65 L268 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-phosphor)\"></path><rect x=\"270\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">charge card</text><path d=\"M452 65 L498 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-phosphor)\"></path><rect x=\"500\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">schedule delivery</text><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fails</text><rect x=\"40\" y=\"150\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">release stock</text><rect x=\"270\" y=\"150\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refund card</text><path d=\"M590 116 L590 175 L452 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-amber)\"></path><path d=\"M268 175 L222 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-amber)\"></path></svg>", "caption": "Each step commits on its own. When a later step fails, the earlier ones are not rolled back; they are compensated, in reverse order."}
```

For Quitanda's checkout:

| step | service | compensation |
| --- | --- | --- |
| reserve the coffee | stock | release the reservation |
| charge the card | payments | refund the charge |
| schedule the delivery | shipping | none: it is the last step |
| confirm the reservation as sold | stock | none: the order is complete |

The rest of the lesson is about what that table leaves out. Who runs the steps. What "undo" can and
cannot mean. And what other customers see while a saga is halfway through, which a transaction hides and
a saga does not.
