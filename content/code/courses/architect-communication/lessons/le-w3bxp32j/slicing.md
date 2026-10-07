---
title: Trading scope by slicing
version: 1
---

**The cheapest lever is almost always scope, and the skill is cutting the feature so that the first
slice is useful on its own.** A slice that is "the database part" or "the back end, without the
screens" delivers nothing on the date. A slice that lets one kind of customer do one thing end to end
delivers something real, and the rest follows.

## The slices

The team and Renata spent an hour at a whiteboard with the feature broken into pieces, each marked by
whether Boa Praça needed it on 1 December:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two rows of blocks scaled to weeks. The December row: state machine, 3 weeks; order ahead up to 7 days, 3 weeks; the pickers&#x27; screen, 1 week; and one week of margin, inside the 8 weeks available. The January row, dashed: 30 days ahead, half a week; recurring orders, 2 weeks; editing after confirmation, 1 week.\"><defs><marker id=\"slices-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"236\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">state machine</text><rect x=\"260\" y=\"60\" width=\"236\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">order ahead, 7 days</text><rect x=\"500\" y=\"60\" width=\"76\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pickers'</text><text x=\"508\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">screen</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1 December: 7 of 8 weeks</text><rect x=\"580\" y=\"60\" width=\"76\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"586\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">margin</text><path d=\"M660 30 L660 52\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M660 114 L660 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"656\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">8 weeks available</text><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">January: 3.5 weeks</text><rect x=\"20\" y=\"170\" width=\"156\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"28\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">30 days</text><rect x=\"180\" y=\"170\" width=\"156\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"188\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">recurring orders</text><rect x=\"340\" y=\"170\" width=\"156\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"348\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">edit after confirming</text><text x=\"20\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one week of drawing = one week of work; quality is inside every block, not a block of its own</text></svg>", "caption": "The feature, sliced. The top row is useful on its own on 1 December; the bottom row is dated, not dropped."}
```

| piece | weeks | needed on 1 December? |
|---|---|---|
| untangle the order state machine | 3 | yes, everything else depends on it |
| order ahead, up to 7 days, at a chosen hour | 3 | yes, it is the feature |
| show scheduled orders to the store's pickers | 1 | yes, or the stores cannot prepare them |
| order ahead up to 30 days | 0.5 | no |
| recurring orders ("every Thursday") | 2 | no |
| edit an order after confirmation | 1 | no; cancel and reorder works for now |

The first three rows are **seven weeks**: inside the eight available, with one week of margin for the
load test and whatever it finds. The other three rows, three and a half weeks, go into January.

## Rules for a slice

- **It works end to end**, for some customer, on its own. Ordering ahead with no way for the store to
  see the order is not a slice; it is a bug with a launch date.
- **It is the smallest thing that serves the interest found earlier**, not the smallest thing that
  can be built.
- **What is left out is written down and dated**, so it is a plan and not an abandonment. "Recurring
  orders, January, two weeks" is a commitment; "later" is a hope.
- **Quality is not sliced.** The seven weeks include tests, the load test and a rollback plan. A
  slice is less feature, never less care.

## Why it usually works

Most features follow the pattern Lívia found here: **most of the value is in a minority of the
pieces, and most of the cost is in the rest.** Recurring orders were two weeks of work for a use
Renata thought perhaps one customer in twenty would want before Easter. Splitting the feature and
pricing each piece (lesson 8 did the same for flash deals) is what makes that visible, and visible is
all it takes for the person who owns scope to make the cut themselves.
