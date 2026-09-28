---
title: "Hybrid: one workload on both sides"
version: 1
---

Two environments owned by one company are not hybrid by being owned by one company. A firm with a
datacentre for its ERP and a public account for its marketing site, never connected, has two
separate estates. **Hybrid starts when one workload spans both**: when something on one side
cannot do its job without something on the other.

The arrangements that make people join them are few and recognisable:

- an online shop whose storefront runs in a public region, close to its customers and able to grow
  for a sale, while the stock and the orders stay in the ERP database in the company's building;
- cloud bursting, NIST's example: the private side runs the load until it is full and the excess
  goes to public capacity for as long as it lasts;
- backup and disaster recovery, where the copies and a standby environment live in a public region
  and production stays at home;
- a factory whose machine controllers must stay on the shop floor, sending their readings to a
  public region where the analysis runs.

## What crosses the seam

Join two environments and three things have to cross between them.

**The network comes first**, because nothing else crosses without it. The two address spaces are
joined and routed to each other, in one of two ways. A site-to-site VPN is an encrypted IPsec
tunnel over the public internet: cheap to set up, with latency and throughput that move with
whatever the internet is doing. A dedicated link is a private circuit from your datacentre, or from
a facility where you have a presence, to the provider's network; AWS calls its version Direct
Connect, Azure ExpressRoute and Google Cloud Interconnect. It carries a fee for the port whether or
not traffic flows and can take weeks to arrange, and in return its capacity and latency hold
still. Either way, **the private
address ranges on the two sides must not overlap**: if the office network and the cloud network
both use the same range, the routers on each side cannot tell which one a packet is for. Lesson 6
builds the cloud side of that network.

Identity is second. People and programs on one side need access to resources on the other, and
keeping two separate lists of users is how an account belonging to somebody who left survives on
one side. The usual answer is *federation*: the cloud side trusts the company's directory to say
who somebody is, and only decides what they may do. Lesson 7 covers roles and policies.

Data is third, and the one that decides the design. Which copy is the truth, how the other side
is kept up to date, and how often somebody reads across the link. **Every read across the seam
costs time**, and in one direction it costs money, which is the next section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A hybrid arrangement. On the left, on premises: an ERP database, the company directory and a file server. On the right, a public cloud region: a web front end, application servers and object storage. Between them, three things cross the seam. Network: an IPsec VPN over the internet, or a dedicated link. Identity: sign-in on the cloud side trusts the company directory. Data: replication, backups and reports. Underneath, the provider's side of the bill: traffic into the region costs 0.0000 USD per GB, traffic out to the internet starts at 0.1500 USD per GB in sa-east-1.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"214\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">on premises</text><rect x=\"34\" y=\"60\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ERP database</text><rect x=\"34\" y=\"116\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">company directory</text><rect x=\"34\" y=\"172\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">file server</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"214\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">public region</text><rect x=\"514\" y=\"60\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">web front end</text><rect x=\"514\" y=\"116\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">application servers</text><rect x=\"514\" y=\"172\" width=\"172\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">object storage</text><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">network: IPsec VPN, or a dedicated link</text><path d=\"M224 92 L496 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#hs-ah)\" marker-end=\"url(#hs-ah)\"></path><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identity: sign-in trusts the directory</text><path d=\"M224 148 L496 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#hs-ah)\" marker-end=\"url(#hs-ah)\"></path><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data: replication, backups, reports</text><path d=\"M224 204 L496 204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#hs-ah)\" marker-end=\"url(#hs-ah)\"></path><path d=\"M20 252 L700 252\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M230 276 L496 276\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"236\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">into the region: 0.0000 USD per GB</text><path d=\"M496 302 L230 302\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"490\" y=\"292\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">out to the internet: from 0.1500 USD per GB</text></svg>", "caption": "What a hybrid arrangement has to carry across the seam, and which side of the bill each direction lands on. The prices are the sa-east-1 lines of the public list; a dedicated link has a price list of its own, not quoted here."}
```

## The seam is a dependency

The storefront above looks up the stock on every product page. If the VPN drops, the storefront
does not slow down; it stops, in a public region that is perfectly healthy. Joining two
environments means their failures are joined too, and the link is a third thing that can fail.

The designs that live with it well keep the traffic across the seam **few, coarse and
asynchronous**: a copy of the stock refreshed every few minutes on the cloud side, orders put in a
queue that the ERP drains when it can, reports sent across once a night. A page that needs one
crossing per request is a page that the link can take down.

A last shape of hybrid is worth recognising by name. AWS Outposts, Azure Stack and Google
Distributed Cloud put the provider's hardware, running the provider's software and answering the
provider's API, inside your building. The seam is still there, now between that rack and the
region that manages it.
