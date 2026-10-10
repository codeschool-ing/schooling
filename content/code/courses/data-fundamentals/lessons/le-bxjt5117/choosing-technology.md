---
title: Choosing technology, problem first
version: 1
---

**A technology is chosen against a problem and a team, never against a ranking.** The usual way it
goes wrong is to start from the tool: what the biggest companies use, what was on stage at the last
conference, what is "the best". The best tool for a company storing petabytes is a poor tool for
Roda Livre, whose dock sensors produce a few gigabytes in a year, because it brings the costs of
petabytes with it.

Seven criteria cover most choices, and their order matters: the first two can rule an option out
before the others are worth discussing.

## The problem

What has to be true when this works? The questions from the skills section give the answer: Marta
needs station counts before two van runs a day, from data an hour or two old. That rules out nothing
yet, and it already makes a stream processor answer a question nobody asked.

## The team

**A tool is only as available as the people who can fix it.** Roda Livre's team is two. A system only
Davi understands is a system with one person on call, every night, for as long as it runs. What the
team already knows counts as a real asset, because learning costs months and the first months on a
new tool are when it fails in ways nobody recognises.

## The total cost

The bill is one line of it. The rest is the hours people spend keeping it running, and what it would
cost to leave. A section at the end of this lesson works the arithmetic.

## Managed or self-hosted

**Managed** means a provider runs the software and you pay for what you use: no servers to patch,
less control, and a bill that grows with use. **Self-hosted** means you run it on machines you
control: a smaller bill and more hours. Neither is cheaper in general. For a team of two the hours
are usually the scarcer thing, and for a team of twenty with a large bill the balance can tip the
other way.

## Lock-in

Lock-in is the cost of leaving, and every choice has some. It grows with each thing that only works
in one place: a dialect of SQL with functions nobody else has, data stored in a format only one
product reads, jobs written against one provider's interface. **Open formats lower it**: raw data
kept as Parquet files, which lesson 6 introduces, can be read by dozens of engines, so the engine can
change and the data stays. Lock-in is not a reason to refuse every managed service. It is a price to
know before signing.

## Maturity

How long has it been in production use, how many people use it, and when it fails, does a search for
the error message find somebody who has seen it before? A version numbered 0.x is telling you that
its authors still expect to change it in ways that break your code. Maturity is not age alone; it is
the size of the population that has already hit the problems you are about to hit.

## Reversibility: one-way and two-way doors

Jeff Bezos's letter to Amazon's shareholders for 2015 sorted decisions into two kinds. A **two-way
door** can be walked back through: if it was wrong, you undo it at modest cost, so it should be made
quickly by whoever is closest to it. A **one-way door** cannot, or only at great cost, and deserves
slow, careful thought. The mistake in both directions is common: agonising over a two-way door for a
month, and walking through a one-way door in an afternoon.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A horizontal axis runs from two-way doors, cheap to undo and decided fast, to one-way doors, impossible to undo and decided slowly. Along it: the dashboard tool, a week to redo the charts; the format of the raw files, every kept file rewritten; the analytical database, months to move every query and load; deleting raw files after thirty days, which cannot be undone.\" data-fig=\"doors\"><defs><marker id=\"doors-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"40\" y1=\"120\" x2=\"684\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#doors-ah)\"></line><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">two-way door: decide fast</text><text x=\"684\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">one-way door: decide slowly</text><circle cx=\"110\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><rect x=\"28\" y=\"22\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"40.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the dashboard tool</text><text x=\"110.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a week to redo charts</text><line x1=\"110\" y1=\"74\" x2=\"110\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><circle cx=\"280\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><rect x=\"198\" y=\"166\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"184.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the raw file format</text><text x=\"280.0\" y=\"199.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rewrite every kept file</text><line x1=\"280\" y1=\"127\" x2=\"280\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><circle cx=\"450\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><rect x=\"368\" y=\"22\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"40.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the analytical database</text><text x=\"450.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">months: every query moves</text><line x1=\"450\" y1=\"74\" x2=\"450\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><circle cx=\"612\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><rect x=\"530\" y=\"166\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"612.0\" y=\"184.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">delete raw after 30 days</text><text x=\"612.0\" y=\"199.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cannot be undone</text><line x1=\"612\" y1=\"127\" x2=\"612\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line></svg>", "caption": "Four decisions from this lesson, placed by what it costs to undo them. Only the last one cannot be undone at all, and it is the cheapest to make."}
```

**Most technology decisions are more reversible than they feel, and a few are less.** Changing the
dashboard tool costs a week of rebuilding charts. Deleting raw files after thirty days to save on
storage costs nothing to decide and cannot be undone at all: a question asked next year about last
year has nothing left to answer it. The second decision is the one that needs the meeting.
