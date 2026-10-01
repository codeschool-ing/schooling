---
title: A second region, and what it is for
version: 1
---

The tempting shortcut is "we will just run in two regions", said as though it were multi-AZ with a
longer cable. **A second region is a disaster recovery plan, and how much of one you buy is set by
two numbers** that the business, not the engineers, has to state first.

**RPO, the recovery point objective, is how much data you can afford to lose**, measured in time. An
RPO of one hour means that after a disaster you may come back with the state of an hour ago, and
everything written in that hour is gone. An RPO near zero means every committed write must already be
somewhere else when the region fails.

**RTO, the recovery time objective, is how long you can afford to be down.** An RTO of a day means the
business survives a day without the system; an RTO of five minutes means somebody has to be able to
switch regions in five minutes, at three in the morning, and it has to work the first time.

Both are decisions about the business stated in the language of time, and the question to ask is
"what does an hour of this system being down cost us, and what does an hour of lost orders cost us?"
The answers pick a point on a scale.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four disaster recovery strategies in a row, from left to right: backup and restore, pilot light, warm standby and active-active. An arrow above says the monthly cost rises to the right. An arrow below says the recovery time, and the data that can be lost, shrink towards the right. In the second region, backup and restore keeps only copies of the data; pilot light keeps the data replicated and the servers off; warm standby keeps a small copy of everything running; active-active serves real traffic from both regions.\"><defs><marker id=\"drs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Backup and restore</text><text x=\"30\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the second region:</text><text x=\"30\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copies of the data</text><text x=\"30\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing running</text><text x=\"30\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rebuild from scratch</text><rect x=\"196\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Pilot light</text><text x=\"206\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the second region:</text><text x=\"206\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data replicated</text><text x=\"206\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servers defined, off</text><text x=\"206\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">switch on and scale</text><rect x=\"372\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"382\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Warm standby</text><text x=\"382\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the second region:</text><text x=\"382\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a small copy running</text><text x=\"382\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data replicated</text><text x=\"382\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scale it up</text><rect x=\"548\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"558\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Active-active</text><text x=\"558\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the second region:</text><text x=\"558\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a full copy running</text><text x=\"558\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">serving real users</text><text x=\"558\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shift the traffic</text><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheaper to keep</text><text x=\"700\" y=\"32\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">dearer to keep</text><path d=\"M20 46 L700 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#drs-ah)\"></path><path d=\"M700 222 L20 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#drs-ah)\"></path><text x=\"20\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">faster back, less lost</text><text x=\"700\" y=\"244\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">hours to recover</text><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">No point on the scale is right in general: RPO and RTO pick it.</text></svg>", "caption": "The four strategies are one scale. Moving right buys a shorter RTO and RPO with money spent every month on a region that, on most days, does nothing."}
```

## Four points on one scale

Backup and restore keeps copies of the data in the second region and nothing running there. After
a disaster you build the whole system again from the copies. It is the cheapest to keep, the RPO is
the time since the last copy, and the RTO is however long a rebuild takes, often hours.

Pilot light keeps the data replicated continuously, so the RPO shrinks to the replication delay,
and keeps the servers defined but switched off, ready to be started and scaled up. The name is the
small flame in a gas boiler that is always lit so the burner can come on.

Warm standby keeps a small but complete copy of the system running in the second region, taking
no customer traffic. Recovery is scaling it up and moving the traffic, which takes minutes rather
than hours.

Active-active serves real users from both regions at once. Losing one means the other carries
everyone, which it must be sized to do. It has the smallest RTO and the largest bill, and it brings
a problem the others avoid: two regions accepting writes at the same time have to agree on what the
data is.

## Why the RPO is rarely zero across regions

The floor worked out earlier in this lesson decides this. A synchronous commit waits until the other copy has
the write. Between two zones that is a short wait; between São Paulo and Virginia it is at least
76.6 ms on every single commit, before any real network delay. **Most cross-region replication is
therefore asynchronous**: the primary commits at once and sends the change afterwards, and whatever
was in flight when the region failed is lost. That in-flight window is the RPO, and it is why "zero
data loss across regions" is a much more expensive sentence than it sounds.

## The transfer bill, and its direction

Replication moves data between regions, and the sheet prices that on its "to the other region" line.
The two columns are the price of data leaving each region: 0.1380 per GB out of `sa-east-1`, and
0.0200 per GB out of `us-east-1`. **The direction decides the price.**

Replicate 500 GB a month from a primary in São Paulo to a standby in Virginia: 500 × 0.1380 = 69.00
dollars a month. Run the same replication the other way, primary in Virginia and standby in São
Paulo: 500 × 0.0200 = 10.00 dollars. The same bytes, the same cable, 6.9 times the price, and the
cheap direction would put the primary outside Brazil, which the checklist's first question may
already have ruled out.

To the transfer add the second region's own resources: nothing running for backup and restore, a
copy of the storage for pilot light, a small fleet for warm standby, a full one for active-active.
The figure's scale is those costs arranged in order.

**A plan nobody has tested is a hope.** Whichever point you choose, the RTO is only real if the
switch has been rehearsed: restore the backup into the second region, promote the replica, move the
traffic, and time it. The first rehearsal usually finds the step nobody wrote down.
