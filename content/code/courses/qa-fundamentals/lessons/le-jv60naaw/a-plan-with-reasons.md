---
title: A plan with its reasons, and its gaps, written down
version: 1
---

**The four answers become one table, the table becomes an order and a budget of hours, and the hours that are not
spent are written down too.** That last part is what makes prioritisation honest.

## Combining the four

Cine Aurora keeps the method simple: start from the risk score, then move an area up a place when usage or history
says it was underrated, and say why.

| area | risk | usage | history | order | hours |
|---|---|---|---|---|---|
| price rule | 9 | every order | 4 defects | 1 | 5 |
| orders | 6 | every order | 1 defect | 2 | 3 |
| refunds | 6, after Célia | 1% of orders | none yet | 3 | 2.5 |
| coupons | 6 | 6% of orders | 1 defect | 4 | 2.5 |
| seat map | 2 | 64% of orders | none yet | 5 | 2 |
| nightly report | 1 | read once a day | none yet | 6 | 1 |

Sixteen hours, spent where the damage would be greatest. The reasons are in the table, so the order can be argued with:
Rafael thought coupons belonged above refunds, because the code is newer; Joana kept refunds above because a failed
refund happens in front of a customer at the counter. Both reasons are recorded, and the order is Joana's call.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 220\" role=\"img\" data-fig=\"l20-hours\" aria-label=\"Sixteen hours of testing split across six areas, as horizontal bars: price rule 5 hours, orders 3, refunds 2.5, coupons 2.5, seat map 2, nightly report 1.\"><text x=\"130.0\" y=\"27.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">price rule</text><rect x=\"140.0\" y=\"16.0\" width=\"350.0\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"27.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"130.0\" y=\"59.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">orders</text><rect x=\"140.0\" y=\"48.0\" width=\"210.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><text x=\"130.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">refunds</text><rect x=\"140.0\" y=\"80.0\" width=\"175.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.5</text><text x=\"130.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">coupons</text><rect x=\"140.0\" y=\"112.0\" width=\"175.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.5</text><text x=\"130.0\" y=\"155.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">seat map</text><rect x=\"140.0\" y=\"144.0\" width=\"140.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"288.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"130.0\" y=\"187.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nightly report</text><rect x=\"140.0\" y=\"176.0\" width=\"70.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"218.0\" y=\"187.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"140.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hours</text></svg>", "caption": "The same sixteen hours an even split would give, spent where the damage would be greatest."}
```

## What *lightly tested* means

The nightly report gets one hour, and that is a decision, not an oversight. The hour goes on the cheapest checks with
the widest reach: does the report run, does the new column appear, does one known order show the discount it should.
Not edge cases, not every session type. **Low priority means less depth, not no testing at all**, because a crash in
something nobody looked at is still a crash.

## Saying what was not tested

At the end of the two days, Lia's summary to the team is short and has four parts:

> **Tested in depth:** the price rule, including the outline from lesson 17, the relations from lesson 19 and an hour of
> exploration; orders, including refused ones; refunds at the counter with Célia.
>
> **Tested lightly:** coupons, the agreed scenarios and the pasted spaces; the seat map on two browsers; the report's
> new column on one night's orders.
>
> **Not tested:** the seat map on phones; coupons combined with Wednesday, which still has no agreed answer.
>
> **Known open:** the 9:30 session is charged the evening price.

The third and fourth paragraphs are the important ones. They turn *we ran out of time* into a list Joana can read
before she decides to release, and they are the input to the next lesson's exit criteria. A team that hides what it did
not test is not saving face. It is moving a decision from the person who should make it to the customer who will find
out.

## When the priorities change mid-week

A plan made on Monday is wrong by Wednesday more often than not: a fix lands late, a new defect turns up in an area
scored low, a feature is pulled. The table is cheap to redo, and should be redone whenever its inputs change. The worst
version of prioritisation is the one made carefully on Monday and followed faithfully after it stopped being true.
