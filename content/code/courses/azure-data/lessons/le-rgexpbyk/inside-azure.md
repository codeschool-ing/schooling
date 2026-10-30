---
title: Between regions, gateways and endpoints
version: 1
---

**Inside Azure, where the bytes go decides whether they cost anything at all.** Reading an account
from a machine in the same region costs no bandwidth, and only the operations are billed. Leaving the
region costs per GB. And two pieces of networking that many subscriptions have, the NAT gateway and
the private endpoint, charge for every gigabyte they carry, even when the destination is the storage
account next door.

**This section is taught from Microsoft's pricing pages for bandwidth, NAT Gateway and Private Link,
and nothing in it was run**: the lab has no network for a byte to cross. Its sums use illustrative
prices, and say so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Where a byte from a storage account in brazilsouth goes, and what each route charges, according to Microsoft's pricing pages. Inside the region, a nightly job in a private subnet can reach the account three ways: through a NAT gateway, which charges per GB processed; through a service endpoint, which is free; or through a private endpoint, which charges per GB processed in both directions. Out of the region, a copy to another region is charged per GB, geo-redundant replication to the paired region is charged per GB as geo-replication transfer, and transfer to the internet is free for the first 100 GB of the month and charged per GB after that.\" data-fig=\"l07-routes\"><defs><marker id=\"arr-l07-routes-amber\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--amber)\"></path></marker><marker id=\"arr-l07-routes-phosphor\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"500\" height=\"285\" rx=\"10\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">brazilsouth</text><rect x=\"34\" y=\"60\" width=\"140\" height=\"230\" rx=\"6\" fill=\"none\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></rect><text x=\"44\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">private subnet</text><rect x=\"48\" y=\"145\" width=\"112\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"104\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nightly job</text><rect x=\"350\" y=\"145\" width=\"156\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">storage account</text><path d=\"M 104 145 L 104 100 L 215 100\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"215\" y=\"86\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NAT gateway</text><path d=\"M 315 100 L 428 100 L 428 141\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><text x=\"265\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">per GB processed</text><line x1=\"160\" y1=\"165\" x2=\"346\" y2=\"165\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-routes-phosphor)\"></line><text x=\"253\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">service endpoint: free</text><path d=\"M 104 185 L 104 240 L 215 240\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"215\" y=\"226\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">private endpoint</text><path d=\"M 315 240 L 428 240 L 428 189\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><text x=\"265\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">per GB processed, both ways</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">another region</text><text x=\"630\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">per GB</text><path d=\"M 506 165 L 536 165 L 536 55 L 556 55\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><rect x=\"560\" y=\"132\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">paired region</text><text x=\"630\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">geo-replication, per GB</text><path d=\"M 506 165 L 536 165 L 536 147 L 556 147\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><rect x=\"560\" y=\"224\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">internet</text><text x=\"630\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">first 100 GB a month free,</text><text x=\"630\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">then per GB</text><path d=\"M 506 165 L 536 165 L 536 239 L 556 239\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path></svg>", "caption": "Inside the region the route decides the charge, and the free route is a setting on the subnet. Everything that leaves the region is billed per GB, by the account that sends it."}
```

## Regions

**Transfer between two Azure regions is charged per GB, by the region it leaves.** Microsoft's
bandwidth page prices it by where the two regions are, within one continent or between continents.
Quitanda's legal team
asked once for a copy of the 5 TB lake in `eastus`, for a partner who works there. At an illustrative
0.08 USD per GB that is 5,120 × 0.08 = 409.60 for the copy, once, and every change copied after it
pays the same rate.

**Geo-redundant replication is the same transfer, made automatically.** An account on GRS or GZRS
copies every write to its paired region, which for `brazilsouth` is `southcentralus`, in Texas, as
lesson 1 noted, and the sheet bills it as geo-replication data transfer, per GB. Quitanda's ZRS keeps
its three copies in Brazil and pays for them in the capacity price, so that line never appears on its
bill.

Traffic between the availability zones of one region has a line of its own on the bandwidth page.
Read there whether it is charged in your region before counting on either answer; this course did not
check it.

## The NAT gateway, and the free way past it

**A NAT gateway charges for every GB it processes**, on top of an hourly price for existing. Machines
in a private subnet with one attached reach the internet through it, and, with nothing else
configured, they reach a storage account through it too, because the account's address is a public
one. At an illustrative 0.05 USD per GB processed, Quitanda's nightly job, which reads 2 TB a month
from the lake, pays 2,048 × 0.05 = 102.40 a month in processing alone, for traffic that never left
São Paulo.

**A service endpoint costs nothing and takes that traffic off the gateway.** It is a setting on the
subnet, `Microsoft.Storage`, that sends traffic for storage accounts in the region over Azure's own
network instead of through the gateway, and the account's firewall can then admit that subnet by
name. Microsoft documents no charge for it. The 102.40 becomes 0.00, and nothing else about the job
changes. It is the cheapest change in this lesson, and one of the most often missed, because nothing
breaks without it; the bill is merely larger.

**A private endpoint is the other way past, and it is not free.** It gives the account an address
inside your own network, so the traffic never touches a public address at all, which is what a
security team usually asks for. It is billed per hour and per GB processed, in both directions. At an
illustrative 0.01 USD per GB, the same job pays 2,048 × 0.01 = 20.48 a month. Choosing between the
two is a security decision with a price on it, and `azure-foundations` lesson 19 is where both are
built.
