---
title: A peering does not pass anything on
version: 1
---

**If production is peered to the hub, and staging is peered to the hub, production still cannot
reach staging.** That is the sentence people get wrong, because every other network they know
passes traffic along: a router that knows two neighbours connects them. A peering is not a router.
It is a statement about two networks, and it says nothing about a third.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l20-transitive\" aria-label=\"Three networks. The hub vnet-shop-hub, 10.0.0.0/16, sits at the top. vnet-shop-prod, 10.20.0.0/16, and vnet-shop-staging, 10.30.0.0/16, sit below it, each joined to the hub by a peering drawn as a solid line with two arrowheads. Between production and staging a dashed line says there is no route: each spoke learns the hub's range and not the other spoke's.\"><defs><marker id=\"l20-transitive-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"270.0\" y=\"16.0\" width=\"180.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-hub</text><text x=\"360.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.0.0/16</text><text x=\"360.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-shared</text><rect x=\"40.0\" y=\"190.0\" width=\"180.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"130.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><text x=\"130.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-prod</text><rect x=\"500.0\" y=\"190.0\" width=\"180.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-staging</text><text x=\"590.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.0.0/16</text><text x=\"590.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-staging</text><path d=\"M200.0 189.0 L290.0 89.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-transitive-af-ah-phosphor)\" marker-start=\"url(#l20-transitive-af-ah-phosphor)\"></path><path d=\"M520.0 189.0 L430.0 89.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-transitive-af-ah-phosphor)\" marker-start=\"url(#l20-transitive-af-ah-phosphor)\"></path><text x=\"205.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">peering</text><text x=\"515.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">peering</text><path d=\"M222.0 226.0 L498.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 5\"></path><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">no route</text><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a peering passes nothing on</text></svg>", "caption": "Each spoke learns the hub's range. Neither learns the other's."}
```

Azure gives each network the routes to the ranges of the networks **it is peered with directly**,
and stops there. `vnet-shop-prod` learns `10.0.0.0/16` from its peering with the hub, and nothing
about `10.30.0.0/16`, because it has no peering with staging. A packet for `10.30.1.5` leaving
production finds no route to that range and goes the way of anything without a route. The hub knows
both ranges, but **the hub is not a device**: nothing in it forwards a packet from one peering to
another unless somebody puts a device there.

## Three ways across

There are three ways to let two spokes talk, and they differ in what they cost and in who gets to
see the traffic.

- **Peer them directly.** A third peering, production to staging, and the two talk without the hub.
  It works for two. For a whole estate it is a **mesh**: every network peered with every other,
  `n × (n − 1) / 2` peerings for `n` networks, each one two resources, each one a decision somebody
  has to remember when a network is added. Ten networks are forty-five peerings.
- **Route through a device in the hub.** Put a firewall in the hub, Azure Firewall or a virtual
  appliance, and give each spoke a route table that sends the other spokes' ranges to the firewall's
  private address. The firewall receives the packet, decides whether it may pass, and sends it on
  down the other peering; the destination's side must then accept it, which is what
  `allowForwardedTraffic` is for. Lesson 18 builds that route table and that firewall. The cost is a
  firewall that runs by the hour, and two crossings of a peering for every packet; the gain is one
  place that sees and judges everything that moves between spokes.
- **Let Azure run the hub.** **Azure Virtual WAN** is a hub Microsoft operates, with its own routers,
  in which connected networks reach each other without route tables of your own, and **Azure Virtual
  Network Manager** creates and keeps peerings across many networks from one description, mesh or
  hub-and-spoke, so that a new spoke joins the right group without anybody writing its peerings by
  hand. Both are services of their own, and this course names them so that you recognise them; it
  does not teach them.

**Whether production should reach staging at all is the first question**, and for the shop the
answer is no. The two environments are separate subscriptions in separate branches of lesson 2's tree
precisely so that a mistake in one does not reach the other. **Non-transitivity is the default the
shop wants**, and the only traffic between spokes it will allow goes through the hub's firewall,
where it is written down.

## What the lab can and cannot show

A peering carries packets, and the lab has none to carry: there is no Azure network on this computer
to send a packet across. What the lab can show is the arithmetic of the previous section and the
shape of the peerings in the next one, both sides, in Bicep and in Terraform. **The behaviour this
section describes, the missing route between two spokes, is Microsoft's documented behaviour and was
not run here.** In a real subscription the place to see it is a machine's **effective routes**,
which list every route a network interface uses and where it came from; a range learned over a
peering appears with the next hop type `VNetPeering`, and the range of a spoke two steps away does
not appear at all.
