---
title: ExpressRoute, the private circuit, and how not to have one of it
version: 1
---

**An ExpressRoute circuit is a private connection between a company's network and Microsoft's, built
by a carrier, that never crosses the public internet.** It is not a cable you plug in: it is an
agreement among three parties, and a resource in Azure that records it. **Nothing in this section was
run**, and the lab has no way to show any part of it; it is taught from Microsoft's documentation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l23-expressroute\" aria-label=\"The parts of an ExpressRoute circuit, from left to right. The office router connects through the connectivity provider's network to a peering location, such as Sao Paulo, where two Microsoft edge routers, primary and secondary, sit. From there Microsoft's network carries private peering to an ExpressRoute gateway in the hub's GatewaySubnet, beside the VPN gateway, and Microsoft peering to Microsoft's public services. Nothing in the path crosses the internet.\"><defs><marker id=\"l23-expressroute-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l23-expressroute-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16.0\" y=\"115.0\" width=\"110.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"71.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">office router</text><text x=\"71.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the company</text><rect x=\"150.0\" y=\"105.0\" width=\"130.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"215.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provider</text><text x=\"215.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the carrier's network</text><rect x=\"304.0\" y=\"60.0\" width=\"150.0\" height=\"170.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"379.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">peering location</text><text x=\"379.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sao Paulo</text><rect x=\"320.0\" y=\"112.0\" width=\"118.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"379.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">primary router</text><rect x=\"320.0\" y=\"170.0\" width=\"118.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"379.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">secondary router</text><rect x=\"500.0\" y=\"40.0\" width=\"204.0\" height=\"134.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"602.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">GatewaySubnet</text><rect x=\"516.0\" y=\"72.0\" width=\"172.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ExpressRoute gateway</text><text x=\"602.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">private peering</text><rect x=\"516.0\" y=\"122.0\" width=\"172.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPN gateway, as backup</text><rect x=\"500.0\" y=\"196.0\" width=\"204.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Microsoft's public services</text><text x=\"602.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Microsoft peering</text><path d=\"M127.0 143.0 L149.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><path d=\"M281.0 133.0 L319.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><path d=\"M281.0 153.0 L300.0 153.0 L300.0 191.0 L319.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><path d=\"M439.0 133.0 L472.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M439.0 191.0 L472.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M472.0 92.0 L472.0 223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M472.0 92.0 L515.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-phosphor)\"></path><path d=\"M472.0 223.0 L499.0 223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both peerings ride both connections; no path crosses the internet</text></svg>", "caption": "One circuit is two connections to two routers, in one building, which is why one circuit is not enough."}
```

## Three parties and a meeting point

A circuit joins the company to Microsoft at a **peering location**: a carrier-neutral datacentre where
Microsoft's edge routers sit beside the carriers'. Microsoft's documentation lists four in the São
Paulo and Rio region: **Sao Paulo** (Equinix SP2), **Sao Paulo2** (TIVIT), **Campinas** (Ascenty) and
**Rio de Janeiro** (Equinix RJ2), the first three mapped to `brazilsouth` and the last to
`brazilsoutheast`. The carrier, Microsoft calls it the **connectivity provider**, brings the company's
traffic from its building to that location.

Ordering one runs in this order. The company creates the circuit resource in Azure, naming the
provider, the peering location and a **bandwidth** from a fixed list, 50 Mbps to 10 Gbps. Azure answers
with a **service key**, a GUID that is the only thing the three parties exchange; Microsoft's
documentation says plainly that it is not a secret. The company gives the key to the provider, the
provider builds its side, and the circuit's state changes to *Provisioned*. Only then does anything
flow. The middle step is a contract and a field engineer, measured in weeks.

## Two peerings on one circuit

A circuit carries one or two **peerings**, each a pair of BGP sessions:

- **private peering** reaches the private addresses of your virtual networks. It is the one the shop
  wants: the finance system talks to `10.20.3.0/24` as if it were down the corridor;
- **Microsoft peering** reaches Microsoft's public services, such as Microsoft 365 or a storage
  account's public address, over the circuit instead of the internet. Since those are public
  addresses, the company's side must present public addresses too, usually by translating its own.

The circuit reaches the network through a gateway, the same kind of resource as the VPN's but of type
`ExpressRoute`, with SKUs of its own, and it lives in the **same `GatewaySubnet`**. That is the reason
the shop made the subnet `/27`: a VPN gateway and an ExpressRoute gateway can share it, and the usual
design keeps both.

## Every circuit is already two, and that is not enough

**Each circuit is two connections**, primary and secondary, to two different Microsoft routers at the
same peering location, and Microsoft runs both active at once. So the circuit itself has no single
router to lose. What it does have is everything that is the company's and the carrier's: if both
connections end on one router in the office, or travel in one cable along one street, one failure takes
both. Microsoft's documentation is specific about it: terminating primary and secondary on the same
device compromises the redundancy the circuit was built with.

**And the peering location itself is one building.** A fire there takes down both connections of every
circuit that meets in it. The answers, from cheapest to most resilient:

1. **a site-to-site VPN as backup**, over the internet, through the VPN gateway beside the ExpressRoute
   one. When the circuit's routes disappear, BGP sends traffic down the tunnel;
2. **a second circuit at a second peering location**, Sao Paulo and Campinas for instance, each with its
   own carrier, so that no building, no carrier and no street is shared;
3. both, which is what Microsoft recommends for the systems that cannot stop.

## What the circuit does not do

**ExpressRoute is private, and private is not encrypted.** The circuit keeps traffic off the internet;
it does not encrypt it. A company that needs encryption on the circuit runs an IPsec tunnel through it
with a VPN gateway, or, with ExpressRoute Direct, where it owns ports on Microsoft's routers, uses
MACsec on the link. The decision is the same one lesson 19 makes about private endpoints: leaving the
internet is a reduction in who can see the traffic, not a guarantee that nobody can.

The other thing it does not do is make anything cheaper by itself. A circuit is billed monthly by its
bandwidth, on top of the gateway by the hour; whether the data crossing it is billed as well depends on
the plan chosen, metered or unlimited. That is the price list's to say and this course's to leave there,
for the reason lesson 1 gave.
