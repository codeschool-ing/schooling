---
title: Five criteria, two kinds
version: 1
---

Every comparison of models ends up on the same five criteria: quality, cost, latency,
context and privacy. The mistake is treating them as five scores to add up. They are two
different kinds of thing, and they are used in two different steps.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Choosing a model in two steps. First filter: every candidate goes through the thresholds, which are privacy, required features, context window and a floor on quality, and any that fails one is removed. Then rank what is left on the trade-offs, which are cost, latency and quality above the floor.\"><defs><marker id=\"l4mat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">all candidates</text><rect x=\"160\" y=\"30\" width=\"190\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1. filter</text><text x=\"255\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thresholds: pass or out</text><rect x=\"180\" y=\"82\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">privacy</text><rect x=\"180\" y=\"112\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">features</text><rect x=\"180\" y=\"142\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">context</text><rect x=\"180\" y=\"172\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quality floor</text><rect x=\"380\" y=\"95\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">short list</text><rect x=\"510\" y=\"30\" width=\"190\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2. rank</text><text x=\"605\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trade-offs: better or worse</text><rect x=\"530\" y=\"82\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cost</text><rect x=\"530\" y=\"112\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">latency</text><rect x=\"530\" y=\"142\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quality above the floor</text><rect x=\"530\" y=\"196\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the choice</text><line x1=\"130\" y1=\"120\" x2=\"160\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"350\" y1=\"120\" x2=\"380\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"480\" y1=\"120\" x2=\"510\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"605\" y1=\"180\" x2=\"605\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"255\" y1=\"210\" x2=\"255\" y2=\"236\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><text x=\"275\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">out</text></svg>", "caption": "Thresholds remove candidates; trade-offs order the ones that are left. No price makes up for a failed threshold."}
```

**Some criteria are thresholds.** The data may leave for a provider or it may not. The model
supports structured output or it does not. The window holds the longest prompt or it does not. A
model that fails one of these is not a worse candidate, it is **not a candidate**, and no price
makes up for it. Privacy is almost always a threshold; context usually is; a feature the program
depends on always is.

**Some criteria are trade-offs.** Above the line of acceptable, a better score on quality costs
something in price or speed. These are the ones to **rank** by, once the list holds only models
that could do the job.

So the method has two steps, in this order:

1. **Filter** on everything that is a threshold. What is left could all do the job.
2. **Rank** what is left: the cheapest, or the fastest, among those whose quality clears the bar.

The order matters because it stops the commonest bad decision: choosing the cheapest model in a
table and discovering later that it could not meet a requirement nobody wrote down. Section 03 is
the writing down.

## Quality is both

Quality appears in both steps, which is why it gets two names. There is a **floor**, the accuracy
below which the feature is not worth shipping, and that is a threshold. Above the floor, more
accuracy is worth some money and some time, and that is a trade-off. For ana's sorting task the
floor might be "agrees with a person on 35 of 40 cases"; whether 39 of 40 is worth twice the price
is a separate question, answered in section 08.

Neither number comes from this lesson. **Quality is measured on your own cases**, which is lesson
5. Everything here can be read off a sheet; quality cannot.
