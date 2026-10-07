---
title: Likelihood and impact
version: 1
---

**Every risk is two numbers: how likely it is to happen in a period, and what it costs when it
does.** A risk described with only one of them cannot be compared with anything. "It could take
checkout down" is an impact with no likelihood; "it happens every Friday" is a likelihood with no
impact. The decider needs both, because they multiply.

## Expected loss

The product of the two is the **expected loss**: what the risk costs on average, per period, if
nothing is done.

```localised
expected loss per year = times it happens per year × cost each time
```

A risk that happens twice a year and costs R$ 50,000 each time has an expected loss of R$ 100,000
a year. So does one that happens fifty times a year and costs R$ 2,000 each time. On paper they are
the same size. In practice they feel different, and the difference matters for the next section:
the frequent small one is usually already visible in somebody's numbers, while the rare large one
has never happened yet and is easy to wave away.

## Two kinds of risk in one problem

Marola's Friday database problem contains both kinds, and Lívia's first proposal mixed them up:

- **A chronic loss, which is happening now.** About 180 checkouts fail every Friday evening. Its
  likelihood is not a guess: it is 52 Fridays a year, and the data already exists.
- **A tail risk, which has not happened yet.** On a bad enough Friday the database runs out of
  connections entirely, and checkout stops for everybody until somebody intervenes. Its likelihood
  is a judgement, and its impact is much larger.

They need different sentences. The chronic loss is stated as a measurement, with its source. The
tail risk is stated as an estimate, with its reasoning, and the last section of this lesson says how.

## The risk matrix

Most companies draw risks on a grid of likelihood against impact, coloured from green to red. It
is useful for one thing: **putting a technical risk on the same picture as the business risks the
board already looks at**, where it can be compared rather than argued about.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A three by three grid of likelihood in a year, unlikely, possible and certain, against impact, minor, moderate and severe. Three of Marola&#x27;s risks are placed on it: 180 failed checkouts every Friday is certain and moderate; checkout stopping for everybody is possible and severe; replica lag leaving routes a few seconds stale is possible and minor.\"><defs><marker id=\"riskgrid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"20\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"330\" y=\"20\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"510\" y=\"20\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"150\" y=\"100\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"330\" y=\"100\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"510\" y=\"100\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"150\" y=\"180\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"330\" y=\"180\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"510\" y=\"180\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"237.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">unlikely</text><text x=\"417.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">possible</text><text x=\"597.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">certain</text><text x=\"138\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">severe</text><text x=\"138\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">moderate</text><text x=\"138\" y=\"217.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">minor</text><text x=\"420\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">likelihood in a year →</text><text x=\"20\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">impact ↑</text><circle cx=\"527.0\" cy=\"137.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"537.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">180 failed checkouts</text><text x=\"537.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every Friday</text><circle cx=\"347.0\" cy=\"57.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"357.0\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">checkout stops</text><text x=\"357.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">for everybody</text><circle cx=\"347.0\" cy=\"217.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"357.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">replica lag: routes</text><text x=\"357.0\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a few seconds stale</text></svg>", "caption": "The grid puts a technical risk on the same picture as the business risks the board already reads. It shows where a risk sits; the arithmetic says how big it is."}
```

It has two well-known weaknesses, and a reader of one should know them. The bands are coarse, so
two risks a hundred times apart in expected loss can share a square. And the labels ("possible",
"severe") mean different things to different people. **Use the grid to show where a risk sits, and
the numbers behind it to say how big it is.** A square on its own invites the question "why is it
red?", and the answer to that question is the arithmetic in the next section.

## Impact is more than money

Some impacts do not convert into reais cleanly, and pretending they do weakens the argument:

- **A client's trust.** Boa Praça's contract renews in September. Nobody can price "the chain's
  operations director had to explain a late Friday to her own board", but it belongs in the list.
- **People.** An engineer paged three Fridays in a row is a resignation risk.
- **Regulation and data.** An incident that exposes customers' data has a cost set by law and by
  the news, not by the size of the basket.

State these in words, beside the numbers, not converted into invented numbers. **A precise figure
for an unpriceable impact is the false precision from lesson 1**, and a director who catches one
invented number will doubt the real ones next to it.
