---
title: The answer first, then the reasons
version: 1
---

**Put the conclusion at the top, then the reasons for it, then the evidence for each reason.** It is
the opposite of how the work happened, which is exactly why it has to be done on purpose.

The default is the story of the investigation. "On Monday we noticed timeouts. We looked at the
application logs, which showed nothing unusual. Then we checked the database…" Four paragraphs
later the reader learns what is wrong and what is being asked of them. The writer is reliving the
work; the reader is waiting for the point, and a busy one stops before reaching it.

## Bottom line up front

The military name for the habit is **BLUF**, *bottom line up front*: the first lines of a message
say what the reader must know or do, and everything below is support. A good test is whether the
message still works if the reader stops after two sentences. Here is a message Lívia nearly sent
to Renata, the head of product:

> I spent yesterday looking at the Friday checkout problem with Bruna. We went through the logs for
> the last six Fridays and compared them with the database metrics, and there is a clear pattern
> between 18:00 and 21:00. It seems the route planner competes with checkout for connections. There
> are a few ways to fix it, and they have different costs. I think we should probably discuss it.

And the version she sent:

> Friday checkout failures come from the route planner and checkout sharing one database; I want
> to propose separating them, which needs six engineer-weeks from the platform team in April. Can
> we take thirty minutes on Thursday to agree whether April is possible? Evidence below.

The second message is shorter, and the length is not the important difference. **The ask is in the
first sentence and the cost is in the second**, so Renata can answer it from her phone. The
evidence is still there for when she wants it.

## The pyramid

Barbara Minto, who taught writing to McKinsey consultants, turned the habit into a structure that
works for longer documents: the pyramid principle. **One governing idea at the top, a few
arguments directly under it, and the evidence under each argument.** Each level answers the
question the level above raises in the reader's head, which is usually "why?" or "how?".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A pyramid of boxes. At the top, the governing idea: separate the route planner from checkout&#x27;s database. Under it, three arguments: it loses sales every Friday; it can stop checkout for everybody; the fix is small and reversible. Under each argument, its evidence: 180 failed checkouts a week between 18:00 and 21:00; connections reach the limit at peak; six engineer-weeks, and the replica can be removed.\"><defs><marker id=\"pyramid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"16\" width=\"340\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Separate the route planner</text><text x=\"360\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">from checkout's database</text><rect x=\"30\" y=\"120\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">It loses sales</text><text x=\"135\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every Friday</text><rect x=\"30\" y=\"222\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"135\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">180 failed checkouts</text><text x=\"135\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a week, 18:00 to 21:00</text><path d=\"M360 66 L135 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><path d=\"M135 170 L135 220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><rect x=\"255\" y=\"120\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">It can stop checkout</text><text x=\"360\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">for everybody</text><rect x=\"255\" y=\"222\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">connections reach the</text><text x=\"360\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">limit at peak</text><path d=\"M360 66 L360 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><path d=\"M360 170 L360 220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><rect x=\"480\" y=\"120\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The fix is small</text><text x=\"585\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and reversible</text><rect x=\"480\" y=\"222\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"585\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 engineer-weeks; the</text><text x=\"585\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">replica can be removed</text><path d=\"M360 66 L585 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><path d=\"M585 170 L585 220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><text x=\"372\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">why?</text><text x=\"147\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">how do we know?</text></svg>", "caption": "Each level answers the question the level above raises: the arguments answer \"why?\", the evidence answers \"how do we know?\". A reader can stop at any level and still have the conclusion."}
```

Two rules make the pyramid work, and both are easy to break:

- **The arguments under one idea must each support it on their own.** If removing one leaves the
  conclusion standing just as firmly, it was decoration.
- **Arguments at one level are the same kind of thing.** Three reasons, or three steps, or three
  options, but not two reasons and a step. A mixed list makes the reader do the grouping you
  skipped.

Three arguments is a common number, not a rule. Two strong ones beat three where the third is
filler, and seven is a sign that some of them belong under others.

## Subject lines and titles are the first sentence

A subject line, a ticket title or a document title is read by far more people than the body. "Friday
checkout" says what the message is about. "**Decision needed by 19 March: separate the route
planner's database load (6 engineer-weeks)**" says what it is for, by when, and at what cost. The
second is longer and much faster to act on, because the reader never has to open it to know whether
it is theirs.

## When the answer cannot come first

Sometimes the reader will reject a conclusion they meet before the reasons: bad news to somebody
invested in the opposite, or a recommendation that overturns a decision they made. Even then, **the
first lines say what the document is for**: "This note explains why the migration date has to
move, and proposes two new dates." The reader still knows where they are going; you have only
chosen to walk them through the reasons before the destination. Lesson 5 returns to this when the
document becomes a presentation.
