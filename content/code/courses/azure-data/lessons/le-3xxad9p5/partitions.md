---
title: Logical and physical partitions
version: 1
---

**There are two kinds of partition in Cosmos DB, and confusing them is how a design goes wrong.** A
logical partition is every item that shares one value of the partition key: all of customer `c-17`'s
orders. A physical partition is a piece of Azure's machinery, storage and compute that holds many
logical partitions. You choose the key, and so the logical partitions; Azure decides the physical
ones, and adds more as the container grows, splitting the logical partitions between them by a hash of
the key's value.

**This section is taught from Microsoft's documentation, and nothing in it was run.** The emulator has
one physical partition, as the next section shows, so none of what follows can be seen in it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Items with partition key values c-17, c-18, c-19, c-40 and c-41 go through the hash of the key's value, and each logical partition, all the items of one customer, lands whole in one physical partition: c-18 and c-41 in physical partition 1, c-19 in physical partition 2, c-17 and c-40 in physical partition 3. Each physical partition holds up to 50 GB and 10,000 RU/s; each logical partition at most 20 GB. The container's throughput is shared evenly between the physical partitions.\" data-fig=\"l11-partitions\"><defs><marker id=\"arr-l11-partitions-wire\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-17</text><line x1=\"110\" y1=\"55\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"88\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-18</text><line x1=\"110\" y1=\"103\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"136\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-19</text><line x1=\"110\" y1=\"151\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"184\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-40</text><line x1=\"110\" y1=\"199\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"232\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-41</text><line x1=\"110\" y1=\"247\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"200\" y=\"125\" width=\"130\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hash of the key's value</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"76\" rx=\"6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"412\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">physical partition 1</text><rect x=\"412\" y=\"48\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-18</text><rect x=\"512\" y=\"48\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-41</text><line x1=\"330\" y1=\"150\" x2=\"396\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"400\" y=\"110\" width=\"300\" height=\"76\" rx=\"6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"412\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">physical partition 2</text><rect x=\"412\" y=\"138\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-19</text><line x1=\"330\" y1=\"150\" x2=\"396\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"400\" y=\"200\" width=\"300\" height=\"76\" rx=\"6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"412\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">physical partition 3</text><rect x=\"412\" y=\"228\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-17</text><rect x=\"512\" y=\"228\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-40</text><line x1=\"330\" y1=\"150\" x2=\"396\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><text x=\"400\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">up to 50 GB, 10,000 RU/s</text><text x=\"20\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">logical partitions: each at most 20 GB</text></svg>", "caption": "You choose the key, and so the logical partitions; Azure hashes them onto physical partitions and splits those as the container grows. A logical partition is never split."}
```

## The limits that follow

**A logical partition holds at most 20 GB.** It lives whole inside one physical partition and is never
split, so the documented limit is a hard one: a customer whose orders reach 20 GB can take no more
writes. At about 1 KB an order that is twenty million orders for one customer, which Quitanda's
customers will not reach; a key with few values reaches it far sooner, as the section after next
counts.

**A physical partition has a ceiling on storage and on throughput**, documented as 50 GB and 10,000
request units per second, the unit lesson 13 is about. The throughput a container is given is shared
evenly between its physical partitions. That is the arithmetic behind the word everybody in Cosmos DB
learns to fear:

**A hot partition is a logical partition that receives more of the load than its physical partition
can give it.** A container with 40,000 request units a second over four physical partitions gives each
one 10,000. If half of all writes go to one key value, they all land on one physical partition, that
partition runs out at 10,000 while the other three sit idle, and the requests over its share are
refused and retried. The container looks under-used on average and throttles in practice. Nothing in
the bill or the portal's average says why; the key does.

## What a good key does

The documentation's advice comes down to three properties, and the section after next measures them
for Quitanda:

- **many distinct values**, so the hash has something to spread and no logical partition approaches
  20 GB;
- **an even spread of the load**, reads and writes, across those values at any moment, not only over
  the year;
- **the value the most common query already names**, so that query is answered by one partition
  rather than by all of them.

The next section shows the third property from the inside: what a read costs when it names the key,
and what it costs when it does not.
