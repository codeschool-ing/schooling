---
title: Letting a coin decide
version: 1
---

Every trap in this lesson comes from the same source: the groups being compared differ in more than the one thing of interest. A **randomised experiment** removes that at the root.

## How randomisation works

Suppose Horta wants to know whether coupons really make no difference to delivery times. Instead of letting the marketing team choose who gets one, it lets a **random draw** decide, customer by customer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l18-randomise\" aria-label=\"The same three boxes as before, plus a coin. The coin has an arrow to coupon. The arrow from distance to coupon is crossed out. Distance still has an arrow to minutes. Any arrow left from coupon to minutes would now be the coupon's own effect.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"230.0\" y=\"23.0\" width=\"140.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">distance</text><rect x=\"45.0\" y=\"173.0\" width=\"130.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">coupon</text><rect x=\"425.0\" y=\"173.0\" width=\"130.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">minutes</text><rect x=\"20.0\" y=\"23.0\" width=\"120.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">coin toss</text><path d=\"M90.0 57.0 L105.0 171.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><path d=\"M260.0 57.0 L140.0 171.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M188.0 104.0 L212.0 124.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M212.0 104.0 L188.0 124.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M340.0 57.0 L460.0 171.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-paper)\"></path><path d=\"M178.0 190.0 L422.0 190.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#st-ah-paper)\"></path><text x=\"300.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">its own effect, if any</text></svg>", "caption": "When a coin decides who gets a coupon, distance can no longer decide it. Far and near customers get coupons equally often, so any difference left in minutes is the coupon's."}
```

Now distance cannot influence who gets a coupon. Near and far customers are equally likely to receive one, and so are big orders and small, rainy days and dry ones, and every other factor, **including the ones nobody thought of**. On average, the two groups are alike in everything except the coupon. Any difference in delivery times that is larger than chance can then be credited to the coupon.

That last clause is what makes randomisation special. Adjusting for confounders, as in the coupon example, works only for confounders that were measured. Randomisation balances the unmeasured ones too.

## Horta has already run some

The checkout page test of lesson 16 was randomised: each visitor was shown the old page or the new one at random. That is why its result, 13.1% against 11.0%, can be read as the new page **causing** more purchases, not merely going with them. The routing trial of lesson 13 was not randomised in the same way: every delivery in the trial used the new system. It relied on comparing with the earlier mean of 40 minutes, so a change in traffic over the same period would have been confounded with it.

## Good practice

- **Randomise the assignment, not just the sample.** A random sample of customers studied without a random assignment is still observational.
- **Keep a control group** that gets the old version at the same time, so that anything else that changes during the trial affects both groups equally.
- **Decide the outcome and the analysis in advance**, lesson 14's defence against p-hacking.
- **Blind where possible.** In medicine, neither patient nor doctor knows who got the real treatment, so that expectations cannot affect the outcome.

## When an experiment is impossible

Some causes cannot be assigned. Nobody can randomise people to smoke, to grow up poor, or to live in Barão Geraldo. Some experiments would be unethical, and some too slow or too expensive. For those questions, the next section's tools are what is left.
