---
title: A diagram is a view, not the architecture
version: 1
---

When somebody asks to see a company's architecture, they are usually shown a diagram, and both sides
behave as if the diagram were the thing asked for. **A diagram is a view of an architecture: a
selection, made by somebody, at some date, for some reader.** The architecture is what the running
system actually is — what calls what, what reads which table, what fails when something else does.
The two can agree. Often they do not, and the diagram is the one people believe.

## The slide in the onboarding deck

Every new engineer at Carreto is shown the same slide in their first week. It was drawn in 2021,
when the company was planning a move away from the monolith. The picture is tidy: the two apps call
an API gateway, the gateway routes to six services, every service has its own database, and all of
them exchange events through the broker.

In her first week as architect, Renata decides to check the slide against the system, which nobody
has done since it was drawn. She does not interview anybody at first. She reads what the machines
say: the deployment manifests of all 14 services, the database credentials each one is given, the
broker's list of topics and consumers, and a day of traces from the tracing system.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Two panels. Left, the 2021 slide: two apps call an API gateway, which routes to six services, each with its own database, all joined to one event bus. Right, what the system does: the gateway was never built and the apps call services directly; the monolith and its PostgreSQL database are still there, and five services connect straight to that database; only three services use the broker.\"><defs><marker id=\"slide-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"345\" height=\"320\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"182\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">the slide, drawn in 2021</text><rect x=\"365\" y=\"10\" width=\"345\" height=\"320\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"537\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">what the system does</text><rect x=\"50\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"205\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Driver app</text><rect x=\"102\" y=\"110\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">API gateway</text><path d=\"M105 80 L160 108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M260 80 L205 108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"24\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"48\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L48 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"78\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"102\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"102\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L102 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"132\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"156\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"156\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L156 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"186\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"210\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L210 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"240\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"264\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"264\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L264 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"294\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"318\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L318 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"24\" y=\"250\" width=\"318\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every service on the event bus</text><path d=\"M48 220 L48 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M102 220 L102 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M156 220 L156 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M210 220 L210 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M264 220 L264 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M318 220 L318 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"182\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">six services, six databases,</text><text x=\"182\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and no monolith in sight</text><rect x=\"405\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"560\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Driver app</text><rect x=\"477\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"537\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">gateway: never built</text><rect x=\"379\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"403\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"433\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"487\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"511\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"541\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"595\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"649\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"673\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><path d=\"M425 80 L403 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M445 80 L457 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M635 80 L619 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M655 80 L673 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"379\" y=\"236\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"439\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">monolith</text><rect x=\"515\" y=\"236\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><path d=\"M499 256 L515 256\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"621\" y=\"236\" width=\"76\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"659\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">broker</text><path d=\"M403 180 L525 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M457 180 L542 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M511 180 L559 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M565 180 L576 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M619 180 L593 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M517 180 L635 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></path><path d=\"M625 180 L667 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></path><path d=\"M679 180 L683 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></path><text x=\"537\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">solid: five services read the monolith's</text><text x=\"537\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">database; dashed: three use the broker</text></svg>", "caption": "The onboarding slide and the system it claims to show. Nothing on the left is false as a plan; as a description, it hides the connections that decide what fails together."}
```

What she finds differs from the slide in four ways:

- **there is no API gateway.** It was planned, a proof of concept was built, and the project was
  dropped when its engineer left. The apps call the services directly, each with its own address and
  its own authentication code;
- **three services use the broker**, not all of them. Tracking publishes positions, Matching
  consumes them, and Payments publishes payout results. Everything else calls over HTTP or shares
  the database;
- **five services besides the monolith connect straight to the monolith's database**, Payments among
  them, which reads the `loads` table to decide what to pay. None of these connections appears on
  the slide;
- **the monolith is still the largest component**, and on the slide it is not drawn at all — it had
  been expected to disappear within a year.

Nobody lied when the slide was drawn. It showed what the company intended to build. **What it shows
today is a plan that was partly carried out, presented as a description**, and every new engineer
since has started from it.

## Every system has an architecture, drawn or not

Lesson 1 ended on this point and here it has a consequence. Carreto's real architecture — the shared
database, the direct calls, the five hidden connections — exists whether or not anybody draws it,
and it determines what happens in an incident. When the monolith's database slows down, five
services slow down with it. An engineer who learned the system from the slide will look everywhere
except there.

Richard Taylor, Nenad Medvidović and Eric Dashofy, in *Software Architecture: Foundations, Theory,
and Practice*, give the two halves names. **The prescriptive architecture is what was intended; the
descriptive architecture is what was built.** The gap between them grows in two ways. *Drift* is the
addition of decisions the intended architecture did not include, without contradicting it: a new
service nobody planned. *Erosion* is the addition of decisions that violate it: a service reading
another's tables when the plan said each would own its own data. Carreto's slide has suffered both,
and Payments reading `loads` is erosion.

## Why the gap opens

Nobody at Carreto decided to make the slide wrong. It went wrong in the ordinary way:

1. **the diagram was drawn as an intention**, at the start of a plan, and plans change;
2. **the code changes every day and the diagram changes when somebody remembers**, which in practice
   means never;
3. **shortcuts are taken under pressure.** The `loads` connection from Payments was added during an
   incident in 2022, as a temporary fix, and it is still there;
4. **nobody owns the diagram**, so nobody is embarrassed when it is wrong.

The result is the worst kind of documentation: **a stale document that is believed.** A missing
diagram makes people ask questions. A wrong one answers them, confidently, with the wrong answer.
Lesson 8 is about keeping documentation alive — giving it an owner, a date and a place next to the
code — and about deleting it when it cannot be kept true.

## Reading the architecture from the system

What Renata did in her first week is a technique worth copying, because it does not depend on
anybody's memory. The running system leaves evidence of its structure in places that cannot drift,
because the system stops working when they are wrong:

| evidence | what it shows |
|---|---|
| deployment manifests | what runs, how many copies, with what configuration |
| credentials and connection strings | which component can reach which database or service |
| the broker's topics and consumers | who publishes what, and who listens |
| traces | which calls actually happen, and in what order |
| import statements in the code | which modules depend on which, inside one deployable |

**None of these is a diagram, and together they describe the architecture more truly than any
diagram does.** The traces come from the instrumentation you met in `scale` lessons 7 and 8; the
imports are what lesson 9 of this course turns into an automatic check.

## What a diagram is for

None of this makes diagrams useless. **A diagram is a tool for thinking and for explaining**, and
both are part of the job. The point is to draw them knowing what they are.

A diagram worth keeping answers four questions on its face: **what question it answers, who it is
for, what date it describes, and what it leaves out.** "The flow of a load from posting to payment,
for new engineers, as of March, omitting the Driver app" is a diagram somebody can trust and
somebody can correct. It also labels its lines with the kind of connector, as lesson 1 asked — an
unlabelled arrow from Payments to the database would have hidden the one fact that mattered.

Renata does not redraw the slide. She removes it from the onboarding deck, replaces it with her list
of evidence and a rough drawing dated the week she made it, and writes at the top that it will be
wrong within months. Lesson 8 shows how to choose which views a system needs, and the
`architecture-modeling` course, third in this track, teaches drawing them properly.
