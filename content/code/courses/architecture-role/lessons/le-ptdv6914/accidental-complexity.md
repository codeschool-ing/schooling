---
title: The complexity the problem brings, and the complexity we add
version: 1
---

A system with many parts looks like a serious system, and an architect is asked what to add far
more often than what to take away. Underneath sits a belief that complexity is a sign of maturity:
the business grows, so the services, the layers and the tools multiply with it. **Some complexity
comes from the problem, and it cannot be removed without removing part of the business. The rest
was added by the people who built the system, and every piece of it could, in principle, come out
again.** Telling the two apart is where simplifying starts.

## Brooks: essence and accident

Fred Brooks drew the line in 1986, in an essay called "No Silver Bullet — Essence and Accident in
Software Engineering". He split the difficulty of building software in two. **Essential complexity
belongs to the problem**: the concepts the software has to represent and the rules it has to obey.
**Accidental complexity belongs to the way we build it**: the languages, the tools, the machines
and the structures we use to express those concepts.

The word "accidental" misleads, so it is worth getting right. Brooks did not mean complexity made
by mistake or by carelessness. He took the word in its old philosophical sense, from Aristotle: an
accident is a property a thing happens to have, as against its essence, the properties it must have
to be what it is. Accidental complexity is very often the result of a perfectly sensible decision.
It is accidental because a different decision could have solved the same problem without it.

His argument ran like this. The great gains in programming up to the 1980s, such as high-level
languages and time-sharing, had come from attacking accidental complexity, and what remained was
mostly essential, so no single new technique would bring a tenfold improvement within a decade.
Forty years on, the part of the essay an architect uses every week is the distinction itself.

## Carreto's essence

At Carreto the essential complexity is substantial, and none of it is optional.

- **The CT-e.** Every freight service needs an electronic waybill authorised by the state tax
  authority before the truck leaves (lesson 1). Its layout, its validation rules and its rejections
  belong to the tax authority, not to Carreto.
- **The minimum freight floor.** ANTT publishes the floor below which a quote may not go, so
  Pricing has to know it and apply it, whatever the market would pay.
- **Matching itself.** A load has a weight, a kind of cargo, a pickup window and a destination; a
  driver has a vehicle, a position, a schedule and a history. Offering the right load to the right
  drivers is the business.
- **Paying people.** Drivers are paid by Pix and shippers are invoiced, and the two sides have to
  reconcile to the centavo.

No architecture removes any of this. A design can only express it more or less clearly. **An
architect who promises to simplify CT-e issuance is promising to simplify the tax authority.**

## Carreto's accident

The accidental complexity is everything Carreto added on its way to handling that essence. Here is
part of the list Renata made in her first month:

- 14 deployable services for 50 engineers in 7 teams, several of them called by exactly one other
  service;
- two ways for services to talk to each other, HTTP calls and the message broker, with no rule for
  choosing, so that some pairs of services use both;
- three ways to configure a service: environment variables, a homegrown configuration service and,
  in two places, a settings file committed to the repository;
- two places that hold a load's status, the monolith's table and a copy in the load search service,
  kept in step by a nightly job that fails about once a month.

Every item had a reason on the day it was added. **None of it is required by freight, tax or
money**, and every item is something a new engineer has to learn before changing the system safely.

## Every piece costs, every month

This matters because a piece of software is not paid for once. Building it is the visible cost.
Keeping it is the larger one, and nobody sends a bill for it. Renata counted four kinds of cost that
every deployable service carries, whether anybody changes it or not.

- **On-call.** Somebody carries its pager, needs a runbook for it and gets woken by it. In the
  previous 90 days Carreto's 14 services had paged people 112 times.
- **Upgrades.** Its language version, framework, libraries and base image age whether or not anybody
  touches it, and security fixes arrive on their own schedule. Paula Reis, on Platform, measured the
  routine upgrade work at about 6 hours per service per month: 84 hours a month across the 14,
  roughly half of one engineer.
- **Documentation.** An undocumented service can be changed only by its author, and a documented one
  has documents that rot (lesson 8).
- **Knowledge.** Somebody has to remember why it exists, what calls it and what breaks when it stops.
  When that person leaves, the knowledge leaves too, unless the service left first.

The arithmetic of a single small service shows the shape. Suppose it took three engineer-weeks to
build, 120 hours, and costs 10 hours a month to keep: 6 of upgrades and 4 of on-call and questions.
By its first birthday the keeping has cost as much as the building, and over three years it costs
three times as much.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" aria-label=\"A graph of hours added up against months, from 0 to 36. A flat line at 120 hours: building the service, paid once. A line rising by 10 hours a month: keeping it. The rising line crosses the flat one at month 12, when keeping has cost as much as building, and reaches 360 hours at month 36, three times the cost of building.\"><defs><marker id=\"keepcost-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 270 L690 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#keepcost-ah)\"></path><path d=\"M80 270 L80 36\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#keepcost-ah)\"></path><text x=\"80.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"280.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"480.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">24</text><text x=\"680.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">36</text><text x=\"70\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">120</text><path d=\"M80 204.0 L680 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"70\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">240</text><path d=\"M80 138.0 L680 138.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"70\" y=\"71.99999999999997\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">360</text><path d=\"M80 71.99999999999997 L680 71.99999999999997\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"690\" y=\"304\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">months</text><text x=\"90\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hours, added up</text><path d=\"M80 204.0 L680 204.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"676\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">building: 120 hours, once</text><path d=\"M80 270 L680 71.99999999999997\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><text x=\"676\" y=\"55.99999999999997\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">keeping: 10 hours a month, 360 by month 36</text><circle cx=\"280.0\" cy=\"204.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"270.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">month 12: keeping has cost</text><text x=\"270.0\" y=\"243.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as much as building</text></svg>", "caption": "One small service, building against keeping. The flat line is the cost everybody sees; the rising one has no bill attached, and by the third year it is three times the other."}
```

**A piece of the system is a liability that sometimes earns its keep, not an asset that sometimes
costs something.** The question to ask of each one is whether what it buys is worth what it costs
every month. An independent deploy, a failure kept away from the rest, a scale the monolith cannot
reach: those are real purchases. The `architecture` course made the same argument about
microservices in its lesson 2. The next section applies it to a real inventory, one row at a time.
