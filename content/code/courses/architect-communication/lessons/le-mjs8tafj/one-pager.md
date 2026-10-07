---
title: The one-pager
version: 1
---

**A one-pager asks one named person or group for one decision, and fits on a screen.** It is the
document Lívia writes most often, because most decisions an architect needs are of that size: a
budget line, a few engineer-weeks, a change to how two teams work together.

## The shape

Six blocks, in this order. Each one answers the question the reader has after the one above.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"A page with six blocks from top to bottom, each answering a question of the reader. The title is the decision: what is this for? The ask, who, what and by when: what do you want from me? The problem with its size: why should I care? The proposal: what would change? Cost and risk: what does it take? If we do nothing: what is the alternative?\"><defs><marker id=\"onepager-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"300\" height=\"304\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"56\" y=\"26\" width=\"268\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the title is the decision</text><path d=\"M420 37.0 L344 37.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#onepager-ah)\"></path><text x=\"430\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what is this for?</text><rect x=\"56\" y=\"56\" width=\"268\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the ask: who, what, by when</text><path d=\"M420 71.0 L344 71.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#onepager-ah)\"></path><text x=\"430\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what do you want from me?</text><rect x=\"56\" y=\"94\" width=\"268\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the problem, with its size</text><path d=\"M420 119.0 L344 119.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#onepager-ah)\"></path><text x=\"430\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">why should I care?</text><rect x=\"56\" y=\"152\" width=\"268\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the proposal</text><path d=\"M420 177.0 L344 177.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#onepager-ah)\"></path><text x=\"430\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what would change?</text><rect x=\"56\" y=\"210\" width=\"268\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cost and risk</text><path d=\"M420 235.0 L344 235.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#onepager-ah)\"></path><text x=\"430\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what does it take?</text><rect x=\"56\" y=\"268\" width=\"268\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"293.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">if we do nothing</text><path d=\"M420 293.0 L344 293.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#onepager-ah)\"></path><text x=\"430\" y=\"293.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what is the alternative?</text><text x=\"430\" y=\"336\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the reader's question each block answers</text></svg>", "caption": "Each block answers the question the one above it leaves in the reader's head, and the last block is the one most often missing."}
```

1. **The title is the decision.** "Separate the route planner's reads from checkout's database",
   not "Database proposal".
2. **The ask**, in one sentence, with the decider and the date: "I am asking Renata and Caio to
   approve six engineer-weeks from the platform team in April, by 19 March."
3. **The problem, with its size.** Two or three sentences and one number the reader can check.
4. **The proposal.** What changes, in words the decider uses. Not the design; the design is
   somebody else's document.
5. **Cost and risk.** What it takes, what could go wrong, and what would be done if it did.
6. **What happens if we do nothing.** This is the block most often missing, and it is the one that
   makes the ask a decision rather than a request for approval.

## Lívia's one-pager

> **Separate the route planner's reads from checkout's database**
>
> **Ask.** Renata and Caio: approve six engineer-weeks of platform team time in April, and R$ 4,000
> a month in database costs, by 19 March.
>
> **Problem.** On Friday evenings, between 18:00 and 21:00, about 180 checkouts fail each week.
> The route planner and checkout share one database, and at peak they compete for its connections.
> The failures have grown from about 60 a week in October to 180 now, in step with order volume.
>
> **Proposal.** Give the route planner a read-only copy of the database (a replica), so that its
> heavy reads stop competing with checkout. Checkout keeps the main database to itself.
>
> **Cost and risk.** Six engineer-weeks once, and R$ 4,000 a month for the replica. The replica
> can lag behind the main database by a few seconds; the route planner tolerates that, and we will
> measure it before switching. If it goes wrong, the route planner is pointed back at the main
> database, which takes one configuration change.
>
> **If we do nothing.** The failures keep growing with volume. The worse case is not 180 failures
> but a Friday when the database runs out of connections entirely and checkout stops for everybody
> until somebody intervenes.

It is about two hundred words. Everything technical that is not needed for the decision (which replication
mode, how the connection limits are set, how the switch is tested) is in a design document Bruna's
team will review, linked at the bottom.

## What a one-pager is not

- **Not a summary of a longer document.** It is its own document with its own reader. A summary
  keeps the longer document's order; a one-pager is ordered for the decider.
- **Not a place for options.** If the decider must choose between three designs, that is a
  proposal. A one-pager can mention that alternatives were rejected and link to why.
- **Not neutral.** It recommends. A decider who receives a page with no recommendation has been
  handed the writer's work.
