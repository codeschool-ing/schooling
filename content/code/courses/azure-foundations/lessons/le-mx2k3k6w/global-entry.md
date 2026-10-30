---
title: Global entry, seen from the public DNS, and the decision
version: 1
---

**Traffic Manager and Front Door both work by owning the name a user looks up**, so the public DNS,
which anybody can ask, shows where they stand in front of a service. Two of Microsoft's own names
are enough, and `dig` from lesson 1 asks without an account. `+noall +answer` keeps only the answer.
`+nottlid` leaves out the seconds each record has left in caches, which change on every query. And
`grep CNAME` keeps the names and drops the addresses at the end of the chain, which differ from one
place and one minute to the next:

```
ana@laptop:~/azure/balancing$ dig portal.azure.com +noall +answer +nottlid | grep CNAME
portal.azure.com.	IN	CNAME	portal-prod-02-linkage.trafficmanager.net.
portal-prod-02-linkage.trafficmanager.net. IN CNAME azureportal.z01.azurefd.net.
azureportal.z01.azurefd.net. IN	CNAME	azurefd-p-prod.trafficmanager.net.
azurefd-p-prod.trafficmanager.net. IN CNAME shed.s-part-19.p-0010.p-msedge.net.
shed.s-part-19.p-0010.p-msedge.net. IN CNAME p-0010.p-msedge.net.
```

Read the chain from the top. The Azure portal's name is an alias for a name in
**`trafficmanager.net`**: a Traffic Manager profile decides first. Its answer is a name in
**`azurefd.net`**, an endpoint of **Front Door**. Front Door's own name goes through Traffic Manager
again, which picks among Front Door's networks of edge locations, and the last names, in
`msedge.net`, are those edges. So the portal stacks the two global services: DNS steering chooses the
entry, and a layer 7 proxy at the edge carries the request in.

```
ana@laptop:~/azure/balancing$ dig mcr.microsoft.com +noall +answer +nottlid | grep CNAME
mcr.microsoft.com.	IN	CNAME	mcr.trafficmanager.net.
mcr.trafficmanager.net.	IN	CNAME	mcr-0001.mcr-msedge.net.
```

Microsoft's container registry, where Microsoft publishes its container images, is
simpler: one Traffic Manager profile, `mcr`, naming a set of servers of the registry's own. No proxy
in between: after the DNS answer, the client talks to those servers directly.

**A Traffic Manager name is unique across all of Azure**, like a storage account's, because it is a
name in a zone Microsoft runs. One that nobody has created does not exist at all:

```
ana@laptop:~/azure/balancing$ dig shop-azure-foundations-l22.trafficmanager.net +noall +comments | grep -o "status: [A-Z]*"
status: NXDOMAIN
```

`NXDOMAIN` is the DNS saying the name does not exist. Creating a profile with that name would make
it answer within a minute, from Traffic Manager's own name servers. **Creating one was not run**; a
profile is a resource of Resource Manager like any other.

## The decision

Most choices fall out of three questions asked in order:

1. **Is it HTTP?** If not, the layer 7 services are out: a database, a game server or a message
   broker behind a balancer gets Load Balancer in one region, and Traffic Manager, or the
   cross-region tier of Load Balancer, if it spans regions.
2. **Is it one region or several?** One region and HTTP is Application Gateway. Several regions and
   HTTP is Front Door, which also gives the cache and the edge WAF.
3. **Does anything need the caller's real address?** Load Balancer keeps it as the source. The
   proxies replace it with their own and carry the original in a header, which the application has
   to read and must not trust when it arrives from anywhere else.

The services also combine, and the shop's design is the usual combination:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l22-shop-path\" aria-label=\"The path of a customer's request in the shop's design, from left to right. A customer looks up shop.example and connects to the nearest Front Door edge location. Front Door carries the request to brazilsouth, to an Application Gateway in the subnet snet-agw. The gateway sends /api/ to the application pool and the pages to the web pool in snet-web. Web machines call the application tier through an internal Load Balancer in snet-app. All of it except the edge is inside vnet-shop-prod.\"><defs><marker id=\"l22-shop-path-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-shop-path-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22-shop-path-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16.0\" y=\"110.0\" width=\"100.0\" height=\"50.0\" rx=\"25\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">customer</text><text x=\"66.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop.example</text><rect x=\"140.0\" y=\"100.0\" width=\"118.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Front Door</text><text x=\"199.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nearest edge</text><path d=\"M117.0 135.0 L139.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><rect x=\"280.0\" y=\"30.0\" width=\"424.0\" height=\"252.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"296.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><text x=\"690.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">brazilsouth</text><path d=\"M259.0 135.0 L295.0 135.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-phosphor)\"></path><rect x=\"296.0\" y=\"96.0\" width=\"120.0\" height=\"78.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">App Gateway</text><text x=\"356.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-agw</text><text x=\"356.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">splits /api/</text><rect x=\"444.0\" y=\"64.0\" width=\"108.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">web pool</text><text x=\"498.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-web</text><rect x=\"444.0\" y=\"196.0\" width=\"108.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">internal LB</text><text x=\"498.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-app</text><rect x=\"580.0\" y=\"196.0\" width=\"108.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"634.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">app pool</text><text x=\"634.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-app</text><path d=\"M417.0 120.0 L443.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><path d=\"M417.0 150.0 L430.0 150.0 L430.0 266.0 L634.0 266.0 L634.0 253.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-amber)\"></path><path d=\"M498.0 121.0 L498.0 195.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><path d=\"M553.0 224.0 L579.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><text x=\"600.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">/api/ goes straight to the app pool</text></svg>", "caption": "Front Door chooses the region, Application Gateway the pool, and the internal load balancer the machine."}
```

Customers reach `shop.example` through **Front Door**, which caches images at the edge and sends
requests to **Application Gateway** in `brazilsouth`, which splits `/api/` from the pages and hands
both to their pools. Between the tiers an **internal Load Balancer** stands in front of the
application machines. Traffic Manager is not in the path: with Front Door already choosing the
region, a second DNS layer would only add a cache to wait out.

**Each layer costs money by the hour and by the gigabyte**, and a combination is several bills. A
service with one region and few users is often better served by one Application Gateway and nothing
in front of it; the course quotes no price for any of the four, for the reason lesson 1 gave, and
Microsoft's price list is where to compare them.
