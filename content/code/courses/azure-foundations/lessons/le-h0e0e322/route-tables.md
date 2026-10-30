---
title: Route tables that send traffic through the firewall
version: 1
---

**A route table is a resource holding user-defined routes, and it does nothing until it is attached
to a subnet.** Each route is a prefix and a next hop; a subnet has at most one route table, and one
table can serve many subnets. Once attached, its routes join the subnet's system routes and win
wherever they share a prefix, by the rule of the previous section.

The next hop of a user-defined route is one of a short list:

| next hop | where the packet goes |
|---|---|
| `VirtualAppliance` | to a private address you name: a firewall, or a machine that inspects traffic |
| `VirtualNetworkGateway` | to the network's VPN or ExpressRoute gateway, lesson 23 |
| `VnetLocal` | inside the network, as the system route would |
| `Internet` | straight out, on purpose |
| `None` | nowhere: the packet is dropped |

## The shop's design: everything leaves through the hub

The shop puts one **Azure Firewall** in the hub network, at `10.0.1.4` in `AzureFirewallSubnet`, and
sends three kinds of traffic from production to it: everything bound for the internet, everything
bound for staging, everything bound for the office.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l18-hub\" aria-label=\"The shop's routing. The production network vnet-shop-prod, 10.20.0.0/16, holds snet-web, snet-app and snet-data; traffic between them stays local. Its route table rt-shop-prod sends three prefixes to the firewall at 10.0.1.4 in AzureFirewallSubnet of the hub network vnet-shop-hub, 10.0.0.0/16: 0.0.0.0/0 for the internet, 10.30.0.0/16 for staging and 192.168.0.0/16 for the office. From the firewall, traffic continues to the internet, to staging and to the office.\"><defs><marker id=\"l18-hub-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-hub-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"250.0\" height=\"290.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"36.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><rect x=\"40.0\" y=\"74.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-web</text><rect x=\"40.0\" y=\"126.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-app</text><rect x=\"40.0\" y=\"178.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-data</text><text x=\"110.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">local between subnets</text><rect x=\"40.0\" y=\"262.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rt-shop-prod</text><rect x=\"330.0\" y=\"90.0\" width=\"170.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-hub</text><rect x=\"346.0\" y=\"140.0\" width=\"138.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Azure Firewall</text><text x=\"415.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.0.1.4</text><text x=\"415.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AzureFirewallSubnet</text><path d=\"M272.0 130.0 L328.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-amber)\"></path><path d=\"M272.0 175.0 L328.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-amber)\"></path><path d=\"M272.0 220.0 L328.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-amber)\"></path><text x=\"300.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three routes</text><rect x=\"570.0\" y=\"40.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the internet</text><path d=\"M502.0 123.0 L568.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-paper-dim)\"></path><rect x=\"570.0\" y=\"145.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">staging</text><path d=\"M502.0 165.0 L568.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-paper-dim)\"></path><rect x=\"570.0\" y=\"250.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the office</text><path d=\"M502.0 207.0 L568.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-paper-dim)\"></path><text x=\"300.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">0.0.0.0/0, 10.30.0.0/16 and 192.168.0.0/16 all point at the firewall</text></svg>", "caption": "Production's three boundaries all cross the hub's firewall; traffic inside production does not."}
```

**Traffic inside the network does not pass the firewall**, and that is a choice too: the web tier
reaching the application stays local, filtered by the NSGs of lesson 17. The firewall sees what
crosses a boundary, which is where the shop wants one log of who talked to whom. The address
`10.0.1.4` is reachable from production only once the two networks are peered, which is lesson 20;
the route table is written now, and works from that day.

Save this as `~/azure/routes/rt.bicep`:

```bicep
param location string = 'brazilsouth'

@description('The private address of the shop\'s firewall, in the hub.')
param firewallIp string = '10.0.1.4'

resource rt 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-shop-prod'
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'internet-via-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIp
        }
      }
      {
        name: 'staging-via-firewall'
        properties: {
          addressPrefix: '10.30.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIp
        }
      }
      {
        name: 'office-via-firewall'
        properties: {
          addressPrefix: '192.168.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIp
        }
      }
    ]
  }
}
```

`disableBgpRoutePropagation: true` stops the routes the gateway learns from the office reaching these
subnets, so that the only way to the office is the route through the firewall. Without it, a gateway
announcing `192.168.10.0/24` would hand production a longer prefix than the table's `/16` and a
path around the firewall. Compile it and read the routes back:

```
ana@laptop:~/azure/routes$ az bicep build --file rt.bicep --outfile rt.json && jq -c '.resources[0].properties.routes[] | [.name, .properties.addressPrefix, .properties.nextHopIpAddress]' rt.json
["internet-via-firewall","0.0.0.0/0","[parameters('firewallIp')]"]
["staging-via-firewall","10.30.0.0/16","[parameters('firewallIp')]"]
["office-via-firewall","192.168.0.0/16","[parameters('firewallIp')]"]
```

The next hops are still `[parameters('firewallIp')]`: a parameter is filled in when the template is
deployed, which is why `route.py` reads its default from the template. Now the six packets:

```
ana@laptop:~/azure/routes$ python3 route.py rt.json 203.0.113.80
User    0.0.0.0/0       VirtualAppliance 10.0.1.4  chosen
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.20.3.4
Default 10.20.0.0/16    VnetLocal                  chosen
Default 10.0.0.0/8      None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.30.1.4
User    10.30.0.0/16    VirtualAppliance 10.0.1.4  chosen
Default 10.0.0.0/8      None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.99.0.1
Default 10.0.0.0/8      None                       chosen
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.0.1.4
Default 10.0.0.0/16     VNetPeering                chosen
Default 10.0.0.0/8      None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 192.168.10.5
User    192.168.0.0/16  VirtualAppliance 10.0.1.4  chosen
Default 192.168.0.0/16  None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
```

Read them in order. The internet now goes to the firewall: the same `/0` prefix, and a user route
beats a system one. `10.20.3.4`, the database, stays local, because `/16` is longer than `/0`. Staging
goes to the firewall, by the `/16` that beats `10.0.0.0/8`. **`10.99.0.1`, which is nowhere, is
dropped**, by the `None` route of `10.0.0.0/8`, rather than following the default to the firewall.
The firewall's own address goes straight through the peering, which is as it must be: a route that
sent the firewall's address to the firewall would be a loop. And the office goes to the firewall,
whose route has the same prefix as the system `None` route and wins as a user route.

## Three ways to get this wrong

**Attaching the table to the firewall's own subnet.** A `0.0.0.0/0` towards `10.0.1.4` on
`AzureFirewallSubnet` sends the firewall's traffic back to itself. The firewall's subnet keeps its
own routes; the next section says when it gets a table of its own.

**Putting a `0.0.0.0/0` route on `GatewaySubnet`.** Microsoft's documentation says plainly that a
route table with a default route on the gateway's subnet can stop the gateway working. The gateway
needs to reach Azure's own services directly.

**Forgetting the return path.** A packet that goes out through the firewall must come back through
it, or the firewall, which keeps track of connections, drops the reply as a stranger. A machine with
a public address of its own breaks this most often: a request arrives straight at the machine, the
reply follows `0.0.0.0/0` to the firewall, and the firewall has never seen the conversation. **Once
traffic leaves through a firewall, the way in goes through it too**: the shop's customers reach the
web tier through a load balancer and the firewall, never at a machine's own address.
