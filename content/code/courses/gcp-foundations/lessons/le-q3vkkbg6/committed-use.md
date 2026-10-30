---
title: Committed use: paying less for promising more
version: 1
---

**A committed use discount is a contract: the customer promises to pay for a level of use for one or three
years, and Google charges less for it.** The promise is paid whether the use happens or not, which is the
whole difference from sustained use. Nothing in this section ran; the percentages are the pricing page's,
read on 30 October 2026.

## Two kinds of commitment

| kind | what is promised | the discount, at most |
|---|---|---|
| **resource-based** | a number of vCPUs and gigabytes of memory, of one machine series, in one region | 37% for one year; 55% for three, 70% for memory-optimized machines |
| **flexible**, spend-based | a number of dollars an hour of Compute Engine, any series, any region | less than resource-based, in exchange for the freedom |

A **resource-based** commitment fits a steady load that will not move: the planner's production database
servers in São Paulo, which run every hour of every day and will for years. A **flexible** commitment fits a
company whose total use is steady but whose shape changes: machine types replaced, workloads moved between
regions. Both are bought per billing account and project, both appear on the bill as a fee for the
commitment and a credit against the usage it covers, and **neither can be cancelled**.

## Which discount applies

The pricing page is explicit that **discounts are mutually exclusive**, and gives the order Google applies
them in, hour by hour:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-discounts\" aria-label=\"One hour of the planner's eligible Compute Engine usage in São Paulo, drawn as a bar of 48 vCPUs, consumed from left to right in the order Google applies discounts. The first 32 vCPUs are covered by a resource-based commitment. The next part is covered by a flexible commitment, as far as its dollars an hour reach. What is left is charged at the on-demand price, and only that part may then earn a sustained use discount. No vCPU receives two discounts.\"><defs><marker id=\"l13-discounts-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one hour, 48 vCPUs of eligible usage</text><rect x=\"40.0\" y=\"50.0\" width=\"426.7\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"253.3\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1. resource-based</text><text x=\"253.3\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">32 vCPUs committed</text><rect x=\"466.7\" y=\"50.0\" width=\"106.7\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2. flexible</text><text x=\"520.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its dollars an hour</text><rect x=\"573.3\" y=\"50.0\" width=\"106.7\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><text x=\"626.7\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. on demand</text><text x=\"626.7\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">may earn sustained use</text><text x=\"40.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"466.7\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">32</text><text x=\"573.3\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"680.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">48</text><path d=\"M40.0 190.0 L680.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-discounts-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">each layer covers what the one before it left</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no vCPU is discounted twice</text></svg>", "caption": "Discounts are applied in turn, never stacked."}
```

1. resource-based commitments cover the eligible usage they match;
2. flexible commitments cover what is left of the eligible on-demand usage;
3. everything still uncovered is charged at the on-demand price, **and may then earn sustained use**.

Spot machines, which Google may stop at any moment, have prices of their own, up to 91% below on demand on
the pricing page, and earn no other discount at all.

## The decision

The arithmetic of a commitment is the question of how much of the promised use will happen. **A one-year
commitment at 37% off pays for itself if the use it covers runs more than about 63% of the time it would
have cost on demand**; below that, sustained use and on demand were cheaper. Three years at 55% is a bigger
saving and a bigger bet. The usual practice is to commit only the floor of usage that has been steady for
months, measured from the billing export of lesson 14, and to leave everything above it on demand and
sustained use.

**The commitment does not care which machines use it.** A resource-based commitment for 32 N2 vCPUs in São
Paulo covers any 32 N2 vCPUs running in that region in the projects it applies to, whichever machines they
belong to. A team that replaces N2 with a newer series has the commitment still billing and nothing for it
to cover, until it expires: the bill that arrived wrong in the first section, item 4, from the other side.
