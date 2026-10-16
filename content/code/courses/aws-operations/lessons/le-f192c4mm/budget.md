---
title: The objective, and the budget it leaves
version: 1
---

An objective is a target for the indicator over a window: **99.9% of requests succeed, over a rolling
30 days**. The interesting number is the one left over. If 99.9% must succeed, 0.1% may fail, and that
0.1% is the **error budget**: the failure the team has agreed is acceptable, and can spend.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A chart of error budget remaining over 30 days, from 100% down to zero. At a burn rate of 1 the line reaches zero exactly at day 30. At 6 it reaches zero at day 5. At 14.4 it reaches zero after about 2 days.\"><defs><marker id=\"bud-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 30 L70 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 220 L630 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"62\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"62\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"70.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"256.66666666666663\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"443.3333333333333\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><text x=\"630.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"630\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">days</text><path d=\"M70 30 L630.0 220\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"378.0\" y=\"119.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">burn rate 1: lasts the month</text><path d=\"M70 30 L163.3 220\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"169.33333333333331\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--wire)\">6: gone in 5 days</text><path d=\"M70 30 L108.9 220\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"114.88888888888889\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">14.4: gone in about 2 days</text><text x=\"70\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">error budget remaining, 99.9% over 30 days</text></svg>", "caption": "The burn rate is the slope. An alert on it asks how soon the month runs out, not how bad this minute is."}
```

In requests, at the shop's thousand a minute: 43,200,000 requests in 30 days, of which 43,200 may fail.
In time, for an outage that fails everything: 0.1% of 30 days is **43.2 minutes**. The table is the
same arithmetic at other targets:

| objective | budget in 30 days, as time | failed requests at 1,000 a minute |
|---|---|---|
| 99% | 7 h 12 min | 432,000 |
| 99.5% | 3 h 36 min | 216,000 |
| 99.9% | 43.2 min | 43,200 |
| 99.95% | 21.6 min | 21,600 |
| 99.99% | 4.3 min | 4,320 |

Each nine divides the budget by ten, and the cost of earning it multiplies: at 99.99%, a single
deployment that fails for five minutes spends more than the month. **Pick the lowest objective customers
would not complain about**, not the highest the team can imagine; the objective is a promise, and the
budget is what makes it possible to keep shipping.

## What the budget is for

A budget changes arguments into arithmetic. While budget remains, the team ships features and takes
risks: canaries, migrations, experiments. When it is spent, the agreed **budget policy** applies: the next
releases are reliability work, deployments slow down, and the risky change waits. Neither side has to
win a debate about whether the service is reliable enough; the number says.

The policy only works if it is written before it is needed, signed by whoever decides priorities, and
followed the first time it bites. A budget nobody acts on is a dashboard.
