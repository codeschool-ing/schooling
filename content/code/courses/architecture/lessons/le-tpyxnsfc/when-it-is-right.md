---
title: When the monolith is the right call
version: 1
---

The mistaken idea is that a monolith is what a team builds before it knows better, and that a
serious system is made of services. **For most systems, most of the time, one well-divided program
is the cheaper and the safer design**, and the reasons are concrete.

**One team.** A program that one team of up to about ten people works on has nobody to coordinate
with but itself. The main thing services buy is that separate teams can deploy separately, and a
single team gets nothing for that price.

**The boundaries are not known yet.** A new product changes its idea of what an order is, or where
stock ends and the catalogue begins, every few weeks. Inside one program that is a refactoring.
Across services it is a change to two APIs and a migration. Martin Fowler's advice in 2015, under
the name *MonolithFirst*, was to start with a monolith and split only when the boundaries have
stopped moving, because a split along the wrong line is worse than no split.

**The data has to be consistent.** The previous section showed it: one database, one transaction,
four changes or none. A shop that must never sell what it does not have gets that for free here.

**Latency.** A function call takes nanoseconds and a call across a network takes at least a
fraction of a millisecond, often several. A request that touches ten parts of the system pays that
ten times when the parts are services.

**Operations.** One thing to deploy, one log to read, one process to profile, one place where an
error has a stack trace that goes all the way down. Lesson 2 counts what that list becomes with
five services.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A chart with the complexity of the system on the horizontal axis and the team&#x27;s productivity on the vertical axis. The monolith line starts high and falls steeply as complexity grows. The microservices line starts lower, because of the cost of running many services, and falls slowly. The two lines cross; to the left of the crossing the monolith is more productive.\"><defs><marker id=\"l1-premium-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M80 250 L680 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-premium-ah-wire)\"></path><path d=\"M80 250 L80 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-premium-ah-wire)\"></path><text x=\"380\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">complexity of the system</text><text x=\"90\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">productivity</text><path d=\"M90 70 C 250 80, 380 150, 640 236\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90 150 C 300 152, 450 160, 640 180\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"170\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">monolith</text><text x=\"470\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">microservices</text><circle cx=\"430\" cy=\"162\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></circle><text x=\"430\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the crossing</text><text x=\"200\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">most systems live here</text></svg>", "caption": "The shape Martin Fowler drew in 2015 for the microservice premium. There are no numbers on it on purpose: where the lines cross differs per system, and most systems never reach it."}
```

Fowler drew that picture in 2015 to name the **microservice premium**: the fixed cost of running a
system as services, paid in deployment, monitoring and the handling of failures between them, before
any of their benefits arrive. Below some level of complexity the premium is never earned back.

## Large systems that stayed one program

This is not advice for small systems only. Shopify has described in its engineering blog how it
keeps its core commerce application as one large Ruby on Rails program, and divides it into
components with enforced boundaries rather than into services. And in 2023 the team behind Amazon
Prime Video's stream monitoring wrote that moving that tool from separate distributed components
into a single process cut its infrastructure cost by more than 90%, because the components had
been passing every video frame to each other through storage.

**Neither is an argument that services are wrong.** Each is evidence that the shape of a system
follows from its forces, the team, the data, the load, and not from its size or from the year.
