---
title: Application architecture: the inside of one system
version: 1
---

"Architecture" is used for three different jobs, and most arguments about what an architect does
are two people meaning different ones. **The levels are application, solution and enterprise, and
they differ in scope, in how far ahead they look, in who reads the result and in what gets
written down.** They are not ranks. An enterprise architect is not a promoted application
architect, and a decision inside one service can cost more to undo than anything on a company
roadmap.

This lesson walks the three levels at Carreto, the invented freight marketplace this course
follows. Renata Okubo has been the company's architect for a few weeks, and the first thing she
notices is that her calendar holds all three kinds of work at once, with nobody having said which
is hers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Two axes. Across, the time horizon, from weeks through months to years. Up, the scope, from one service through several teams to the whole company. Application architecture sits low and to the left: inside one service, looking months ahead. Solution architecture sits in the middle: one outcome across several teams. Enterprise architecture sits high and to the right: the whole portfolio, looking years ahead.\"><defs><marker id=\"lvl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M130 310 L700 310\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lvl-ah)\"></path><path d=\"M130 310 L130 34\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lvl-ah)\"></path><text x=\"138\" y=\"28\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">scope</text><text x=\"700\" y=\"350\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">time horizon</text><text x=\"200\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">weeks</text><text x=\"420\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">months</text><text x=\"600\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">years</text><text x=\"122\" y=\"262\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one service</text><text x=\"122\" y=\"162\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">several teams</text><text x=\"122\" y=\"76\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the company</text><rect x=\"160\" y=\"228\" width=\"190\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Application</text><text x=\"255\" y=\"276\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">inside one service</text><rect x=\"330\" y=\"130\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Solution</text><text x=\"430\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one outcome, many teams</text><rect x=\"490\" y=\"44\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Enterprise</text><text x=\"590\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the whole portfolio</text></svg>", "caption": "The three levels differ in scope and in how far ahead they look. None of them outranks the others; each answers a different question for a different reader."}
```

The figure is the lesson in one picture. This section takes the lowest box, the second section the
middle one and the third the top one, and each ends with what the level looks like in Renata's
week.

## What application architecture decides

**Application architecture is the structure inside one deployable system**: its modules and the
rules about which may call which, its layers, its data model, how it talks to the systems around
it and what it does when one of them fails. In the language of lesson 1, it is the elements,
relations and environment of a single application, seen from the inside.

Take Pricing, the service that quotes the freight for each load a shipper posts. From the outside
it is one box with one endpoint: give it an origin, a destination, a vehicle type and a weight,
and it answers with a price. Inside, the Pricing team made a handful of decisions that shape
everything they will build for the next two years:

- **The quote is computed in two stages.** A market stage estimates what the load would fetch from
  recent accepted offers on similar routes; a floor stage then applies the ANTT minimum freight
  for that vehicle and distance, and raises the price if the market stage came in below it.
- **The floor stage is the only way out.** No code path returns a price that has not passed
  through it, so a quote below the legal floor cannot leave the service by accident. That rule is
  enforced in the code's structure rather than by everybody remembering it.
- **The distance provider sits behind an adapter.** Pricing asks one internal interface for road
  distances, and the adapter behind it talks to an outside routing API. Changing provider means
  rewriting one module.
- **The ANTT table is data, not code.** When the agency publishes a new floor table, the team
  loads a file and runs the tests; nobody edits a formula.

None of these choices is visible on a company diagram, and every one of them is architecture by
the test from lesson 1: each is expensive to change once the rest of the code depends on it.
Moving the floor check from "the only way out" to "a step callers are expected to run" would be a
small diff and a large change, because the property it protects would stop being guaranteed.

## Horizon, audience and artefacts

**The horizon is months to a couple of years**: roughly the life of a major version of the
service, or the time until the team next has reason to restructure it. A decision at this level
assumes the service's purpose and its neighbours stay roughly as they are.

**The audience is the team that builds the service and the teams that call it.** The first need
the internals; the second need the contract and the failure behaviour, and nothing else. The Shipper
team, which calls Pricing for every quote it shows, needs to know that Pricing answers within its
agreed time or returns an explicit error. It has no use for the two stages.

**The artefacts are close to the code.** There is a component diagram of the service's insides,
the third of the C4 levels, which lesson 8 here introduces and `architecture-modeling` lesson 3
draws properly. There is the API contract, and there are the module boundaries written as rules a
build can check; lesson 9 shows a program that enforces one. And there are decision records in the
service's own repository. Pricing
keeps all four in its repository, and the diagram is short enough to redraw in ten minutes.

## Who does it, and where Renata fits

**At Carreto, application architecture belongs to the teams.** Each of the seven has a tech lead
and senior engineers who know their service better than anybody else, and they make these
decisions as part of the work. That is the advice process from lesson 3 doing what it is meant to:
the people who will live with a decision take it, after asking the people it affects.

Renata's part at this level is smaller than people expect. She reviews when asked, she points out
when a team's internal choice is about to leak out of the service, and she keeps an eye on the
handful of rules that every service should share. In her first month she spent about one day a
week on it, almost all in design reviews other people had asked for.

The leaking is the part that matters most. **An application decision becomes something bigger
when its consequences cross the service's boundary**, and the team making it does not always see
that happen. Kátia Lemos's Matching team, for example, wanted to cache Pricing's quotes inside
Matching for an hour, to stop calling Pricing every time a load was offered to another driver. A
reasonable internal choice, until Renata asked what happens when ANTT publishes a new floor table
at nine in the morning: for up to an hour, Matching would be offering loads at prices that no
longer met the legal minimum.

The fix was small. Pricing now returns a validity time with each quote, and Matching caches for
no longer than that. The decision that mattered was the one about where the fix belonged. A cache
inside Matching looks like Matching's business, while the rule it could break belongs to Pricing,
and the contract between the two is something neither team owns alone. **That gap between teams
is the next level up**, and the second section of this lesson is about it.

## A test for the level of a decision

When a question lands on Renata's desk, she asks three things to place it:

1. **Does the change stay inside one deployable system?** If it does, it is application
   architecture, and the team decides.
2. **Does it change what other systems can rely on**, such as a contract, an event, a guarantee or
   a time? Then it is at least solution architecture, even if only one team writes code.
3. **Does it change what the company runs or how every team works**, such as a shared platform, a
   standard or a system being retired? Then it is enterprise architecture.

The Matching cache failed the first question and passed the second, which is why a decision that
looked internal to one team ended in a change to Pricing's contract. Lesson 6 returns to this line,
between the decisions that are architectural and the ones that belong to the team, with a fuller
test.
