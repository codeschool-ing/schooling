---
title: Surviving the loss of a zone
version: 1
---

The comfortable assumption is that the provider keeps your server running, so a machine in the cloud
does not go down. **An instance lives in exactly one zone**, and when that zone has a bad day, so does
the instance, and so does everything that only exists there. The design that survives it is plain:
run everything twice, in two zones, so that either one can carry the load alone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A multi-AZ layout in sa-east-1. A load balancer at the top sends traffic to two instances, one in zone sa-east-1a and one in sa-east-1b. The database primary is in zone a and a standby is in zone b. Two flows cross the boundary between the zones and are billed per gigabyte: the instance in zone b reading from the primary in zone a, and the replication from the primary to the standby.\"><defs><marker id=\"maz-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"20\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">load balancer, in both zones</text><rect x=\"40\" y=\"90\" width=\"300\" height=\"220\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"52\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"380\" y=\"90\" width=\"300\" height=\"220\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"392\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"80\" y=\"124\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instance</text><rect x=\"420\" y=\"124\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instance</text><path d=\"M300 60 L190 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><path d=\"M420 60 L530 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><rect x=\"80\" y=\"234\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">database, primary</text><rect x=\"420\" y=\"234\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"530\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">database, standby</text><path d=\"M190 164 L190 234\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><path d=\"M460 164 L460 200 L250 200 L250 234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><text x=\"470\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crosses zones</text><path d=\"M300 262 L420 262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><text x=\"360\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">replication, crosses zones</text></svg>", "caption": "The same application, twice, in two zones. The two flows that cross a zone boundary are the ones the sheet's between-zones line applies to, on the way out and again on the way in."}
```

Three pieces make it work, and lessons 4 and 6 built two of them:

- At least two instances, in two zones, each able to serve every request.
- A load balancer in front of both, placed in both zones. It checks each instance's health and
  stops sending traffic to one that fails to answer, so a dead zone drops out of rotation without
  anybody touching anything.
- A database with a standby in the second zone. The primary takes the writes and keeps the
  standby up to date; if the primary's zone fails, the standby is promoted and the application
  reconnects to it.

Managed databases offer the third piece as one setting, usually called multi-AZ. What it does is the
same whether you click it or build it: a second copy, in a second building, kept current.

## What it costs

**The first cost is the second copy of everything.** Two `t3.medium` instances in `sa-east-1`, at
0.06720 an hour each, are 2 × 0.06720 × 720 = 96.77 dollars over a 30-day month, where one would be
48.38. The standby database is a whole second database server that serves no queries on a normal day.
Doubling is the price of the design, and it is paid every hour whether a zone fails or not.

**The second cost is the traffic between the zones**, and it is the one people miss. The sheet has a
line for it:

```
ana@laptop:~/cloud$ python3 prices.py transfer
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Data transfer, USD per GB
  out to the internet, first 10 TB         0.1500       0.0900
  out to the internet, next 40 TB          0.1380       0.0850
  out to the internet, next 100 TB         0.1260       0.0700
  out to the internet, over 150 TB         0.1140       0.0500
  between zones, each direction            0.0100       0.0100
  to the other region                      0.1380       0.0200
  in from the internet                     0.0000       0.0000
```

"Each direction" is the part to read slowly. **A gigabyte that crosses from one zone to another is
charged 0.0100 as it leaves and 0.0100 as it arrives**, so it costs 0.0200 in total. It is the same in
both regions on the sheet.

Look at the figure again. The instance in `sa-east-1b` reads from the primary database in
`sa-east-1a`, so everything it reads crosses a zone. Suppose that instance pulls 1,500 GB of query
results in a month: 1,500 × 0.0200 = 30.00 dollars. Nobody bought that on purpose; it is the bill for
putting the application in two zones and the database's primary in one of them. It is also the price
of the design working as intended, so the usual answer is to keep it and know it is there, rather than
to put everything back in one zone to save it.

::: track dba
**The standby is where a database administrator pays for multi-AZ twice.** With synchronous
replication, a commit on the primary is not confirmed until the standby has the change, so every
commit waits for a round trip between zones: short, because the zones are within 100 km, and still
longer than a commit that waited for nobody. Measure it on your own workload before you promise a
latency. And the change itself crosses zones. A database that writes 10 GB of log a day ships about
300 GB a month to its standby; replicated between two instances you run yourself, that is
300 × 0.0200 = 6.00 dollars a month on the line above. A managed database prices its own replication
on its own price page, which this sheet does not carry, so read that page before you assume either
answer.
:::

::: track *
**A managed database's standby is priced on that service's own page**, which this sheet does not
carry. The between-zones line above applies to traffic between instances you run yourself, including
a replica you set up on two of them, so read the database's price page before you assume either
answer.
:::

## A zone is not a region

**Two zones survive the loss of one zone. They do nothing for the loss of a region.** Both zones sit
under the same regional control systems, share the same regional services, and are reached through
the same region's entry points. A problem at that level reaches every zone at once, and a multi-AZ
design goes down with it, correctly configured and all.

That is not a reason to skip multi-AZ. A zone failure is the one you can design away cheaply, inside
one region, with the tools of lesson 6. A region failure is a different scale of event with a
different scale of cost, and the next section is about deciding whether to pay it.
