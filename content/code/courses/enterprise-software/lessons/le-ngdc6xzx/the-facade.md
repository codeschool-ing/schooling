---
title: A facade in front, and the old system shrinking behind it
version: 1
---

The textbook strangler starts with one move: **put something you control between the old system
and everybody who calls it.** At first it passes every request straight through, and nobody
notices it is there. Then, one capability at a time, it starts sending some requests somewhere
else. The old system keeps answering everything that has not moved, and the share it answers
shrinks until it answers nothing.

That something is usually called a facade, or a routing layer. For a web application it is a
reverse proxy or an API gateway, and the routing rule is a URL path. For a system whose callers
arrive through an integration bus, it is the bus. For Coleta, most of whose inputs are files, it
is something else again, and the next section is about that case. This one is about the facade
itself, because the rules for it hold whatever form it takes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l13-stages\" aria-label=\"Three stages of a strangler side by side, each with the callers at the top and a facade below them that routes by capability. In the first stage all four capabilities go to the legacy system, a tall box, and there is no new system. In the second, two capabilities go to the legacy, now shorter, and two to the new system. In the third, all four go to the new system and the legacy is a dashed outline marked switched off.\"><defs><marker id=\"l13-stages-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-stages-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-stages-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · everything to the legacy</text><rect x=\"35.0\" y=\"43.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">callers</text><rect x=\"25.0\" y=\"97.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">facade: routes by capability</text><path d=\"M120.0 73.0 L120.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"160.0\" width=\"90.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">legacy</text><path d=\"M60.0 128.0 L47.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M70.0 128.0 L59.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M80.0 128.0 L71.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M90.0 128.0 L83.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M240.0 30.0 L240.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · some capabilities moved</text><rect x=\"275.0\" y=\"43.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">callers</text><rect x=\"265.0\" y=\"97.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">facade: routes by capability</text><path d=\"M360.0 73.0 L360.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"160.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">legacy</text><rect x=\"370.0\" y=\"160.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><text x=\"415.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">system</text><path d=\"M310.0 128.0 L299.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M320.0 128.0 L311.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M360.0 128.0 L409.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M370.0 128.0 L421.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M480.0 30.0 L480.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">3 · the legacy answers nothing</text><rect x=\"515.0\" y=\"43.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">callers</text><rect x=\"505.0\" y=\"97.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">facade: routes by capability</text><path d=\"M600.0 73.0 L600.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"160.0\" width=\"90.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"545.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">switched off</text><rect x=\"610.0\" y=\"160.0\" width=\"90.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"213.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><text x=\"655.0\" y=\"226.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">system</text><path d=\"M590.0 128.0 L637.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M600.0 128.0 L649.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M610.0 128.0 L661.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M620.0 128.0 L673.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">what moves is a capability, end to end; the callers never change</text></svg>", "caption": "The life of a strangler in three frames. The facade stays where it is; behind it, the legacy answers less at each stage until it answers nothing."}
```

## Three stages, and what moves between them

The figure shows the whole life of a strangler in three frames. In the first, every request goes
through the facade to the legacy, and the new system does not exist yet. The facade's only job is
to be there, so that later moves need no change on the callers' side.

In the second, some capabilities are served by the new system and the rest still by the legacy.
**What moved is a capability, end to end: a thing a caller asks for, answered completely by one
side.** Farm lookup, for example, is a capability. Rota asks for a farm by its code and gets the
farm's location, its tank size and the days it is collected. Either Coleta answers that or the new
service does; there is no version of it where Coleta does half.

In the third, the legacy answers nothing and can be removed. What happens to the facade then is a
choice. Sometimes it is deleted with the legacy, and the callers point straight at the new system.
Sometimes it stays, because it has become a useful stable edge with logging and versioning, and
the callers never needed to know there was a migration at all.

## Slice by capability, never by layer

The common mistake here comes from how systems are drawn. A legacy system looks like layers: a
database at the bottom, business logic in the middle, screens or files at the top. So the plan
that suggests itself is to move the layers one at a time: first the data to a new database, then
the logic into services, then the screens.

**Moving a system layer by layer is a big bang wearing a strangler's clothes.** Nothing a caller
asks for is served by the new system until the last layer has moved, because every capability
needs all three. For two years the new database is a copy nobody relies on and the new services
call the old screens' logic through a translation, and every one of those halfway states has to
work in production. The risk the strangler was meant to retire one slice at a time is retired at
the end, all at once.

A capability slice cuts through every layer. Farm lookup takes the farm's data, the rule that
decides which days a farm is collected and the interface Rota calls, and moves all three together.
It is thinner than a layer and goes all the way down, and when it is finished something real has
moved.

## The rules for the facade

The facade is the one piece of the migration that every request touches, which is why it attracts
both work and trouble. Four rules keep it useful.

**It routes and does not compute.** The temptation arrives early: the facade sees every request,
so why not have it fix up a field, merge two answers or apply a rule the legacy gets wrong? Each
of those turns the facade into a third system with business logic of its own, which is then
neither old nor new and has to be migrated too. The facade decides where a request goes and
nothing about what the answer is.

**It says which side served each request.** A log line per request, naming the capability and the
destination, is the most honest progress report the migration will have. It also tells you, on the
day something goes wrong, whether the complaint came from a request the new system answered.

**Every route can be turned back.** Routing farm lookup to the new service is a configuration
change, and so is routing it back. That is the cheap undo a big bang never has: when the new
service misbehaves on a Monday morning, the capability returns to the legacy in minutes, and the
team fixes the problem without farms or trucks noticing. A route that cannot be turned back, for
instance because the new system has started accepting writes the legacy never saw, is a one-way
door, and it should be treated as one and planned as one.

**Its availability is part of everything behind it.** A facade in front of a system that must run
365 days a year must itself run 365 days a year. Lesson 12 does the arithmetic: two components in
a chain multiply their availabilities, so a facade at 99.9% in front of a service at 99.9% gives
about 99.8%. A migration that made the system less available than it was before would be hard to
defend to the people waiting for milk trucks.

## Choosing the first slice

The order in which capabilities move is a decision, and the first one is different from the rest.
**The first slice is chosen to teach, not to pay.** It should be small, low in risk and still real:
something that goes all the way to production, so that the team builds the path from code to a
running service, the monitoring, the on-call rota and the routing switch on something where a
mistake costs little. Moving the payment calculation first would be learning all of that on the
capability where a mistake costs the most.

After the first slice the order follows two pressures. Value pulls towards the capabilities the
business most wants improved. Dependency pushes towards moving what other capabilities need
first, because a capability that reads data the legacy still owns needs a synchronisation that is
work in itself. Coexistence comes three sections on.

## Where Coleta has an edge

Coleta has almost no request-and-response interface. Its users type into green-screen terminals,
its inputs arrive as files, and its main output is a file. It has exactly two places where another
system asks it a question and waits for an answer, and both are flows on the integration bus that
Rui Andrade's team runs (lesson 8). One is farm lookup, which Rota calls every evening when it
plans the next day's routes. The other is the day's collection summary, which the quality team's
dashboard asks for every hour.

Both flows date from the bus's first years (farm lookup is lesson 8's FarmRegistry, built in 2016),
long before anybody talked about replacing Coleta, and both already
do what a facade does: Rota and the dashboard call the bus, and only the bus knows that the answer
comes from an RPG program on the IBM i. **The bus Serra Alta spent years trying to shrink is, for
these two capabilities, a facade that is already installed.** Moving farm lookup is a change to one
flow's destination, plus a translation from the new service's model into the reply Rota expects.

That covers two capabilities out of the twelve in Joana's inventory of what Coleta does. The other
ten have no edge to stand on. The trucks' handhelds, the laboratory's result files, the clerks'
screens and the nightly file to SAP need a different technique, and that is the next section.
