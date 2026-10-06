---
title: How much to lose, and how long to be down
version: 1
---

Two numbers turn "we have backups" into a promise somebody can check. Both are decided by the
business, like lesson 3's risk appetite, and then IT designs to meet them.

```schooling-figure
{"svg": "<svg id=\"sf-rpo-rto\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline. The last good backup is taken; later, disaster strikes; later still, the service is back. The span from the last backup to the disaster is the data lost, bounded by the recovery point objective. The span from the disaster to the service being back is the downtime, bounded by the recovery time objective.\"><defs><marker id=\"sf-rpo-rto-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 100 L700 100\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rpo-rto-ah-paper-dim)\"></path><text x=\"700\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><path d=\"M140 80 L140 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"140\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">last good backup</text><path d=\"M400 80 L400 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"400\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">disaster</text><path d=\"M620 80 L620 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"620\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">service back</text><rect x=\"142\" y=\"56\" width=\"256\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data lost: at most the RPO</text><rect x=\"402\" y=\"56\" width=\"216\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">downtime: at most the RTO</text><text x=\"270\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how often you back up</text><text x=\"510\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how fast you restore</text></svg>", "caption": "RPO looks back from the disaster; RTO looks forward from it."}
```

**Recovery point objective (RPO)**: how much data, measured in time, the business can afford to lose.
If the RPO is 24 hours, then after a disaster it is acceptable to come back with yesterday's data and
lose today's work. The RPO decides **how often** to back up: a nightly backup cannot meet an RPO of
one hour.

**Recovery time objective (RTO)**: how long the business can afford to be down. If the RTO is four
hours, then from the moment of the disaster the shop must be selling again within four hours. The
RTO decides **how fast** the restore must be, which means where the backup is, how big it is, and
whether anybody has practised.

For the shop, the owners decided:

| | target | what it requires |
|---|---|---|
| orders and customers | RPO 24 hours, RTO 8 hours | a nightly backup; a restore that has been rehearsed and takes less than a working day |
| the public website | RPO one week, RTO 2 hours | the site changes rarely; a second server or a hosting service that can take over quickly |

Notice the second row. The website's data hardly changes, so losing a week is fine, but every hour
offline loses sales, so it must come back fast. The orders are the other way round. **The two numbers
are independent**, and treating them as one leads to paying for speed where it is not needed and
missing it where it is.

### What the numbers cost

Lower targets cost more, roughly in proportion. An RPO of zero means no data may ever be lost, which
needs every change written to two places at once; an RTO of minutes needs a standby system ready to
take over. Both are possible, and both are expensive. That is why these are business decisions: the
person who owns the orders knows what a lost day costs, and lesson 3's arithmetic says whether the
cheaper target is worth it.

### Testing is the only proof

An RTO of eight hours is a claim until somebody has restored the data in less than eight hours. The
first real restore is a bad time to find out the backup is on a disk nobody can find, the encryption
key is on the server that just died, or the restore takes two days. So restores are **practised**, on
a schedule, and timed. The next section is the shop's first one.
