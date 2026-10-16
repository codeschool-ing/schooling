---
title: Where it starts to hurt
version: 1
---

A monolith stops being the cheap option in a handful of identifiable ways. Each one is a force, and
a split is worth its premium only when one of them is strong enough to pay it. **Naming the force
is the whole skill**: "we will move to microservices" with no force named is a fashion, and the
bill arrives anyway.

**Every change deploys everything.** Changing one line of `payments_charge` rebuilds the image and
replaces the only container, so the catalogue, which did not change, goes down and comes back with
it. With one team that is a few seconds of risk. With five teams it becomes a release train: changes
wait for a shared date, a defect in one team's code holds back the other four, and deploying gets
rarer and therefore riskier.

**Scaling copies everything.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three copies of the monolith side by side behind a load balancer. Each copy holds all four modules. In every copy only the catalogue module is drawn as busy; stock, payments and orders are idle but copied anyway.\"><defs><marker id=\"l1-scale-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"260\" y=\"24\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">load balancer</text><rect x=\"40\" y=\"90\" width=\"190\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">copy 1</text><rect x=\"52\" y=\"120\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">catalogue: busy</text><rect x=\"52\" y=\"148\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stock: idle</text><rect x=\"52\" y=\"173\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">payments: idle</text><rect x=\"52\" y=\"198\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders: idle</text><path d=\"M360 60 L135 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-scale-ah-wire)\"></path><rect x=\"265\" y=\"90\" width=\"190\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">copy 2</text><rect x=\"277\" y=\"120\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">catalogue: busy</text><rect x=\"277\" y=\"148\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stock: idle</text><rect x=\"277\" y=\"173\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">payments: idle</text><rect x=\"277\" y=\"198\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders: idle</text><path d=\"M360 60 L360 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-scale-ah-wire)\"></path><rect x=\"490\" y=\"90\" width=\"190\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">copy 3</text><rect x=\"502\" y=\"120\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">catalogue: busy</text><rect x=\"502\" y=\"148\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stock: idle</text><rect x=\"502\" y=\"173\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">payments: idle</text><rect x=\"502\" y=\"198\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders: idle</text><path d=\"M360 60 L585 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-scale-ah-wire)\"></path></svg>", "caption": "Scaling a monolith means copying all of it. When only the catalogue is busy, the other three modules are copied for nothing, with their memory and their connections."}
```

If the catalogue gets a thousand times the traffic of the rest, the only way to give it more
processes is to run more copies of the whole program, each with the memory, the start-up time and
the database connections of every module. It works, and for many shops it is cheaper than anything
else. It stops working when one module needs something the others do not, a machine with a GPU or
twenty times the memory, and every copy has to pay for it.

**A fault anywhere is a fault everywhere.** A memory leak in a report, a loop that never ends, an
unhandled exception that kills the process: in one process, each of them takes down the checkout
along with the code that caused it. Lesson 12 shows how to fence a fault in, and some of those
fences work inside one process.

**The build and the tests grow with the whole.** When the test suite takes forty minutes, a team
runs it less, and a change that took an hour starts taking a day.

**One technology for everything.** The whole program is in one language, on one runtime, with one
version of each library. A module that would be far better in another language, or that needs a
library version the rest cannot take, has to wait for everybody.

## Reading the forces

| force | what it asks for | the cheaper first step |
| --- | --- | --- |
| teams blocking each other's deploys | independent deployment | a modular monolith, with module ownership and a faster pipeline |
| one module with very different load | scaling it apart | more copies of the whole, with a cache in front of the hot part |
| one module with different hardware or runtime needs | running it apart | moving that one module out, and only that one |
| a fault in one part taking down the rest | isolation | timeouts and bulkheads inside the process, lesson 12 |

**The right-hand column is there on purpose.** Most of these forces have an answer that keeps the
monolith, and it is the answer to try first. When it is not enough, the split it points at is
small: one module, moved for one reason. Lesson 2 is about doing that properly, and about what the
split will cost from its first day.

Before leaving the lesson, stop the shop and remove its volume:

```sh
docker compose down -v
```
