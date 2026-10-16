---
title: Peering or Transit Gateway, by count, by route and by price
version: 1
---

**Peering costs nothing to have and grows by pairs; a Transit Gateway costs something every hour
and grows by one attachment per network.** With two or three VPCs, peering is cheaper and simpler.
With many, or the moment one network has to be reached *through* another, the hub wins, and the
price list says how much it charges for winning.

## The prices

Both are in the VPC offer of 17 September 2026:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-TransitGateway-Hours SAE1-TransitGateway-Bytes SAE1-VpcPeering-In-Bytes SAE1-VpcPeering-Out-Bytes
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-TransitGateway-Hours
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
SAE1-TransitGateway-Bytes
          0 to       Inf GigaBytes 0.0200
          0 to       Inf GigaBytes 0.0200
          0 to       Inf GigaBytes 0.0200
          0 to       Inf GigaBytes 0.0200
SAE1-VpcPeering-In-Bytes
          0 to       Inf GB   0.0100
SAE1-VpcPeering-Out-Bytes
          0 to       Inf GB   0.0100
ana@laptop:~/aws$ python3 -c "import json, os; d = json.load(open(os.path.expanduser('~/.cache/aws-prices/AmazonVPC-20260917190528-sa-east-1.json'))); print(*sorted(p['attributes']['operation'] for p in d['products'].values() if p['attributes'].get('usagetype') == 'SAE1-TransitGateway-Hours'), sep='\\n')"
TransitGatewayConcentratorVPN
TransitGatewayConnect
TransitGatewayDirectConnect
TransitGatewayPeering
TransitGatewayVPC
TransitGatewayVPN
```

`price.py` printed **six lines for the hours and four for the bytes**, all at the same price. They
are separate products in the offer, one for each kind of attachment. The second command lists
them by name: a VPC, a VPN, a Direct Connect link, a Connect attachment, a peering between two hubs
and a VPN concentrator. Whatever is attached, **0.09 dollars an hour per attachment and 0.02 per
gigabyte the hub processes**.

The two peering lines are **0.01 a gigabyte in each direction**. AWS's documentation says that
traffic over a peering inside one zone is free, so these lines are what crossing zones over a
peering costs, the same 0.01 each way as any crossing between zones in lesson 1. Peering has no
hourly line at all.

## Two VPCs

Production and staging exchange about 500 GB a month, all of it crossing zones, to take the worst
case:

| | peering | Transit Gateway |
|---|---|---|
| by the hour | nothing | 2 attachments × 730 × 0.09 = 131.40 |
| by the gigabyte | 500 × (0.01 + 0.01) = 10.00 | 500 × 0.02 = 10.00 processed |
| **a month** | **10.00** | **141.40**, before crossing zones |

**For one pair, peering is the obvious answer**: a Transit Gateway charges 131.40 a month for being
in the middle of a conversation that needs nobody in the middle.

## Ten VPCs

Pairs grow faster than networks. Ten VPCs that all talk to each other need 10 × 9 / 2 = **45
peerings**, each requested and accepted, and every route table of every VPC carries **nine routes**,
one per peer; an eleventh VPC adds ten more peerings and a route to every table in the organisation.
AWS caps the peerings of one VPC by quota as well, 50 by default. The hub needs **ten attachments**
and one line per VPC in its own table, propagated by itself:

| ten VPCs | peering | Transit Gateway |
|---|---|---|
| connections to create | 45 | 10 |
| routes in each VPC table | 9 | 1, for `10.0.0.0/8` or whatever the plan's block is |
| by the hour, a month | nothing | 10 × 730 × 0.09 = 657.00 |
| per gigabyte | 0.01 each way across zones | 0.02 processed |

That 657 dollars a month buys **one place where the routing is decided**, which, with two people
running the platform, is worth a good deal of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l20-mesh-or-hub\" aria-label=\"Five VPCs joined two ways. On the left, every pair peered: ten lines between five VPCs. On the right, the same five VPCs each attached once to a Transit Gateway in the middle: five lines. With n VPCs, a full mesh of peerings needs n times n minus one over two connections; the hub needs n attachments, each charged by the hour.\"><path d=\"M197.8 72.9 L257.3 116.2\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M186.8 80.9 L232.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M173.2 80.9 L128.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M162.2 72.9 L102.7 116.2\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M268.3 150.0 L245.6 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M257.3 142.0 L139.0 228.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M253.1 129.1 L106.9 129.1\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M216.8 240.9 L143.2 240.9\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M221.0 228.0 L102.7 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M114.4 220.0 L91.7 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"180.0\" cy=\"60.0\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"180.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1</text><circle cx=\"275.1\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"275.1\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2</text><circle cx=\"238.8\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"238.8\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v3</text><circle cx=\"121.2\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"121.2\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v4</text><circle cx=\"84.9\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"84.9\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v5</text><path d=\"M540.0 82.0 L540.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M614.2 135.9 L568.5 150.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M585.8 223.1 L557.6 184.3\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M494.2 223.1 L522.4 184.3\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M465.8 135.9 L511.5 150.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><circle cx=\"540.0\" cy=\"160.0\" r=\"28\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"540.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TGW</text><circle cx=\"540.0\" cy=\"60.0\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"540.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1</text><circle cx=\"635.1\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"635.1\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2</text><circle cx=\"598.8\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"598.8\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v3</text><circle cx=\"481.2\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"481.2\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v4</text><circle cx=\"444.9\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"444.9\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v5</text><text x=\"180.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">peering: 10 connections</text><text x=\"180.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing by the hour</text><text x=\"540.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Transit Gateway: 5 attachments</text><text x=\"540.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 × 65.70 = 328.50 a month</text></svg>", "caption": "Pairs grow as n(n-1)/2, attachments as n. Ten VPCs are 45 peerings or 10 attachments."}
```

## When each one wins

- **Peering** when the VPCs are few, the traffic between them is heavy and every pair simply talks
  to every other. It has no hourly cost, no processing charge, and nothing in the middle to fail.
- **Transit Gateway** when the VPCs are many or keep arriving, when the routing must be
  **transitive**, such as one VPN to the office (lesson 24) that every VPC uses, and when the shop
  needs **segments**, staging kept away from production while both reach shared tools, which only
  the hub's route tables can say.
- **Neither** when one service is all that has to be shared, one way. That is PrivateLink, lesson
  19, and it does not care whether the ranges overlap.

The shop, with production, staging and a disaster-recovery copy, starts with **peering**. The day
the office VPN arrives, or a fourth and fifth account do, it moves to the hub, and the move is the
`replace-route` of the previous section, one table at a time.
