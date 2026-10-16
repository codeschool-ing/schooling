---
title: Overengineering, and its opposite
version: 1
---

**Overengineering is building for a problem you do not have.** It looks like diligence: more
flexibility, more capacity and more generality than the requirement asked for, all of it defensible
one piece at a time. Lesson 12 counted what every piece costs (on-call, upgrades, documentation and
the knowledge of the people who must understand it), and that cost is paid every month whether or
not the future it was built for ever arrives.

## What it looks like

Two cases at Carreto, one from a team and one from the architect.

**The capacity nobody measured.** A design from the Shipper team for a new quote service arrives
for review. It proposes a partitioned event log, three consumer groups and autoscaling across two
regions, sized for 2,000 quote requests a second. Renata asks for last year's peak. It was 6 a
second. Even allowing for ten times the growth, which is more than anyone at Carreto plans for, the
design is sized for 2,000 against a need of 60:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Three bars measuring quote requests a second. Last year&#x27;s peak was 6, a sliver. Ten times that is 60, a short bar. The design was sized for 2,000, a bar more than thirty times longer than the second.\"><text x=\"190\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">last year's peak</text><rect x=\"200\" y=\"40\" width=\"2\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"212\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"190\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ten times that</text><rect x=\"200\" y=\"90\" width=\"13.2\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"223.2\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">60</text><text x=\"190\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">designed for</text><rect x=\"200\" y=\"140\" width=\"440.0\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"650.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2,000</text><text x=\"700\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quote requests a second</text></svg>", "caption": "Even after allowing for ten times the growth, the design carries more than thirty times the capacity anyone could name a reason for."}
```

**The generality nobody asked for.** The new CT-e layout (lesson 13) means Carreto has to change
how it issues the electronic waybill. The imagined Renata of this lesson sketches a *fiscal document
engine*: a rules engine with a plugin per country and per document type, so that "when Carreto
expands to Argentina and Chile" the same engine issues their documents too. Carreto operates only
in Brazil, has no expansion approved, and issues one kind of fiscal document for freight. Her own
estimate is 16 to 22 engineer-weeks for the engine, against 5 to 7 for changing the existing CT-e
module directly: **11 to 15 engineer-weeks spent on countries Carreto does not operate in.**

The symptoms are recognisable in both:

- **Requirements that start with "when" or "if".** *When we expand*, *if we have to change cloud
  provider*, *when we have ten times the drivers*. None of these has a date, an owner or a number.
- **Abstractions with one implementation.** An interface with one class behind it, a plugin system
  with one plugin, a configuration option set to the same value everywhere.
- **Capacity designed without a measurement.** The quality attribute scenario of lesson 6 has a
  response measure, and here nobody supplied one, so the design supplied its own.
- **New technology chosen for the problem the architect finds interesting.** Lesson 12's innovation
  tokens, spent on the part of the system that needed the most boring answer.

## Why it happens

**Flexibility feels like safety.** An architect who is unsure of the future covers it with options,
and every option looks cheap on the day it is added.

**The general problem is more interesting than the specific one.** A rules engine for three
countries is a better puzzle than adding four fields to a CT-e module, and lesson 2 already named
the version of this that is about CVs rather than puzzles.

**The architect's horizon is applied to the wrong decisions.** Lesson 16 placed the architect at a
horizon of years. That is right for who owns which data, and wrong for the internals of a module
that will be rewritten anyway when its requirements change. Overengineering is often a long horizon
used on a short-horizon decision.

**Nobody put "do nothing" or "the simplest thing" on the table.** Lesson 14 asked for alternatives
including the cheapest one; a design compared only against grander versions of itself always wins.

## What it costs

| cost | the fiscal document engine | the quote service |
|---|---|---|
| to build | 11 to 15 extra engineer-weeks | three components where one service would do |
| to run | another service on call, with its own upgrades | two regions, a log and its consumers to operate |
| to learn | every new engineer meets a plugin system before the CT-e | a pipeline to understand before changing a quote |
| to change | the next layout change goes through two layers instead of one | a change to the quote format touches three consumers |

And one more, which is easy to miss: **the future it was built for, if it comes, rarely matches the
guess.** An abstraction designed with only one real case behind it tends to be wrong for the second
one, so the expansion to Argentina would likely have meant reworking the engine anyway.

## The alternative

- **Design for the requirement you have, and keep the likely change cheap rather than built.** Keep
  the CT-e module behind a clear boundary, so that a second country, if one is ever approved, is a
  new module next to it. A boundary costs almost nothing today; machinery for the second case costs
  the full price now.
- **Ask for the number** (lesson 7). How many quotes a second, at what peak, by when? Design for the
  measured peak with an agreed margin, and prove it with a load test, as the `scale` course taught.
- **Count the pieces** (lesson 12). What does this design add to the on-call rota, to the upgrade
  calendar and to the onboarding of the next engineer?
- **Write down what you chose not to build, and what would make you build it.** A decision record
  (lesson 5) that says "if an expansion to a second country is approved, revisit this" keeps the
  option open without paying for it.

That is lesson 13's *good enough for purpose*, seen from the other side.

## The opposite: the absent architect

Overengineering has a mirror image, and it is just as common: **nobody designs at all, and the
architecture happens by accident.** Each team takes sensible local decisions, and the sum of them
is a structure that nobody chose. Lesson 2 warned that "no design" is not the cure for "big design
up front"; the absent architect is what "no design" looks like a few years in.

The symptoms are what Brian Foote and Joseph Yoder called a *big ball of mud* in 1997: services
that talk through each other's tables because it was quickest that week, three different ways of
publishing an event, and nobody able to say who owns a given table. Part of the 14 services that
lesson 12 counted at Carreto came from exactly this: pieces added one sensible week at a time,
without anybody weighing them against the whole.

The cost is that **each decision was cheap and the sum is expensive**, and the sum never appears on
anybody's plan. The alternative is the course itself: just enough design up front (lesson 2), a
decision-rights table that gives each cross-team decision an owner (lesson 16), and a record of the
decisions that cross team boundaries (lesson 5).

## The five, on one map

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"A map with two axes. Across, distance from the teams and their code, from close to far. Up, how much the architect decides, from nothing to everything. The gatekeeper sits close and decides everything. The ivory tower sits far and decides everything. The PowerPoint architect sits far and in the middle. The absent architect sits far and decides nothing. A dashed box, close to the teams and in the middle, holds the role this course describes: decides what crosses teams, after advice, close to the code.\"><path d=\"M120 330 L700 330\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M120 330 L120 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"130\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">close</text><text x=\"700\" y=\"346\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">far</text><text x=\"410\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">distance from the teams and their code</text><text x=\"112\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">everything</text><text x=\"112\" y=\"320\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing</text><text x=\"120\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">how much the architect decides</text><rect x=\"150\" y=\"56\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the gatekeeper</text><rect x=\"520\" y=\"56\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the ivory tower</text><rect x=\"520\" y=\"156\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the PowerPoint architect</text><rect x=\"520\" y=\"266\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the absent architect</text><rect x=\"170\" y=\"150\" width=\"210\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decides what crosses teams,</text><text x=\"275\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">after advice, close to the code</text></svg>", "caption": "Four of the five antipatterns are places to stand. The role the course describes sits close to the code and decides only what crosses teams."}
```

Overengineering is not on the map, because it is a property of a design rather than a stance: a
gatekeeper and an absent architect could both produce one. The others are four ways of standing in
the wrong place. And each of them, looked at closely, is one of this course's lessons skipped:

| antipattern | the lessons that prevent it |
|---|---|
| the PowerPoint architect | 2 (a diagram is a view), 8 (living documentation), 15 (keep coding) |
| the ivory tower | 3 (earned authority, the advice process), 7 (gathering requirements), 10 (collaborating) |
| the gatekeeper | 9 (standards checked by machines), 11 (advising, not approving), 16 (decision rights) |
| overengineering | 6 (scenarios with numbers), 12 (simplifying), 13 (good enough), 14 (alternatives) |
| the absent architect | 2 (not a phase), 5 (decision records), 16 (whose decision it is) |

The drill that follows gives you situations from Carreto. For each one, the question is the one an
architect has to ask about their own week: which of these is it, and what would the alternative have
been?
