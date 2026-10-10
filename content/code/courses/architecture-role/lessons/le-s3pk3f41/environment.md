---
title: The system in its environment
version: 1
---

It is tempting to think of architecture as something that happens inside the code, between services
and databases. **Most of the forces that shape an architecture come from outside it.** They are the
people who use the system and pay for it, the rules it has to obey, the teams that build it, the
people who keep it running at three in the morning, and the business it exists to serve. The
standard's phrase was "a system in its environment", and the environment is where most of an
architect's questions start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Three nested regions. At the centre, Carreto&#x27;s software: the monolith and the other services. Around it, Carreto the company: seven teams whose structure the software copies, and the Platform team that runs it. Outside both: shippers, drivers and carriers, the state tax authority that authorises each CT-e, the national transport agency that publishes the freight floor, banks that carry Pix payouts, and competitors.\"><defs><marker id=\"env-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"340\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">outside Carreto</text><rect x=\"170\" y=\"60\" width=\"380\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Carreto, the company</text><rect x=\"250\" y=\"130\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the software:</text><text x=\"360\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the monolith and</text><text x=\"360\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the other services</text><text x=\"360\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">7 teams: the structure</text><text x=\"360\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the software ends up copying</text><text x=\"360\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Platform runs it all;</text><text x=\"360\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">product and finance pay for it</text><rect x=\"22\" y=\"60\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">shippers: quotes,</text><text x=\"90.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">CT-e, where is my load</text><rect x=\"22\" y=\"230\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">drivers and carriers:</text><text x=\"90.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">weak signal, paid fast</text><rect x=\"562\" y=\"60\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SEFAZ: authorises</text><text x=\"630.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">each CT-e</text><rect x=\"562\" y=\"140\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ANTT: the minimum</text><text x=\"630.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">freight floor</text><rect x=\"562\" y=\"230\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banks: Pix payouts</text><text x=\"630.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">to drivers</text><rect x=\"22\" y=\"145\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">competitors: a slow</text><text x=\"90.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">quote loses the load</text><text x=\"360\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each force from outside becomes a quality attribute the structure is judged by</text></svg>", "caption": "A system in its environment. The software sits inside a company, and the company inside a world of customers, regulators and partners; each layer pushes on the structure at the centre."}
```

## The people with a stake

A *stakeholder* is anybody who is affected by the system or can affect it. At Carreto the list is
long, and every entry cares about something different:

- shippers want a quote in seconds, a CT-e issued without errors, and to know where their load is;
- drivers want the app to work on a weak mobile signal at the side of a road, and to be paid quickly
  and correctly;
- Sílvio Matos, the finance director, wants every invoice to match every payment, and an audit trail
  when the tax authority asks;
- Helena Prado, the product director, wants new features to reach shippers without a quarter of
  waiting;
- the seven teams want to change their own part without waiting for the other six.

Those wishes pull against each other. The finance director's audit trail costs storage and code that
the product director would rather spend on features; the drivers' weak signal argues for an app that
works offline, which makes the payment flow harder to keep consistent. **An architecture is partly a
record of how those pulls were resolved**, and an architect who talks only to engineers resolves
them without knowing they existed. Lesson 7 is about getting these wishes out of the people who hold
them, and lesson 10 about working with them over time.

## The rules

Freight in Brazil is regulated, and the rules reach into the structure of the system rather than
staying at its edge.

**The electronic waybill.** Every freight service needs a CT-e — Conhecimento de Transporte
Eletrônico — authorised by the state tax authority (SEFAZ) before the truck leaves. So a step in
Carreto's most important flow depends on a service Carreto does not run and cannot fix. The
architecture has to say what happens when that authorisation is slow or unavailable, and who is
told.

**The freight floor.** The national transport agency, ANTT, publishes a minimum freight floor — the
*piso mínimo do frete*, created by law 13.703 of 2018 — and a quote may not go below it. That is a
rule Pricing must enforce, and it has a consequence that is easy to miss. The floor table changes
over time, so when a shipper disputes a quote months later, Carreto has to show which table was in
force when the quote was made. **A regulatory rule became a data-retention requirement.**

**Paying drivers.** Independent drivers carry the cost of fuel and tolls before they are paid, and
many of them want the money by Pix as soon as the delivery is proved. That makes the speed and
correctness of Payments a reason drivers choose Carreto over a competitor, rather than a back-office
detail.

None of these is a technical choice, and all three constrain technical choices. An architect does
not need to be a tax lawyer, and this course will not pretend to be one, but **an architect who does
not know the rules exist will design a system that breaks them**.

## The organisation

In 1968 Melvin Conway observed that organisations which design systems end up producing designs that
copy their own communication structures. The observation is known as **Conway's law**, and Carreto
illustrates it well. Tracking has its own team, and it has its own service and its own database. The
monolith's `loads` table is read and written by Payments, Matching and the Shipper app, three teams
that used to be one team — and the shared table is the trace that the old team left in the code.

Conway's law cuts both ways for an architect. **A structure that ignores the organisation will be
bent back into its shape**: a design with one service shared by four teams turns, within a year,
into four teams queuing to change one service. And a change of structure often needs a change of
teams to stick. Lesson 10 comes back to this, including the deliberate use of the law that has
become known as the inverse Conway manoeuvre.

## The operations

Somebody has to deploy, monitor and repair whatever the architecture contains. Carreto's Platform
team is a handful of engineers looking after the infrastructure for all seven teams, and each of the
14 deployable services needs a pipeline, dashboards, alerts and somebody who understands it when it
fails. **A design that needs more operational skill than the company has is a bad design for that
company**, however well it works somewhere with ten times the staff. Lesson 12 counts what each of
Carreto's services costs to keep and asks which ones are paying their way.

## The business

Finally, the system exists to make Carreto a living. The company earns a fee on the freight it
arranges, so its revenue grows with the number of loads that move. Some of the demand is seasonal:
grain cooperatives post far more loads at harvest than in the rest of the year. **The business
decides which qualities are worth paying for**: a quote that takes ten seconds instead of two loses
shippers to a competitor, while a monthly report that takes an hour to generate loses nobody.

## Quality attributes: what architecture is for

Put the five together and a pattern appears. Almost any functionality — posting a load, quoting it,
paying a driver — could be built on almost any structure: the monolith, fourteen services, or two
hundred. What the structure decides is **how well** the system does those things: how fast, how
reliably, how securely, how cheaply it changes, how easily it is audited. These are called *quality
attributes* (an older name is non-functional requirements), and **they are what an architecture is
for.**

Each force in this section shows up as one. The drivers' weak signal becomes a requirement on
availability and offline behaviour. The tax authority becomes a requirement on resilience to an
outside dependency. The freight floor becomes auditability. The seven teams become modifiability and
deployability. The Platform team's size becomes operability. **A quality attribute is the
environment, translated into something a structure can be judged against.** Lesson 6 shows how to
write one precisely enough to be tested, and lesson 7 how to find out which ones the business
actually needs.

That completes the definition this lesson started with: elements, the relations among them, and the
environment they answer to, judged by what each decision would cost to change. The next lesson
removes three things that are often mistaken for architecture.
