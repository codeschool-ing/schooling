---
title: Cutting the range into subnets
version: 1
---

**A subnet is a slice of the VNet's range, and everything that gets an address in Azure gets it
from a subnet.** A machine's network interface, a private endpoint, a load balancer's private front
end, a firewall: each is placed in one subnet and takes an address from it. The subnet is also where
the next two lessons attach their rules, a network security group in lesson 17 and a route table in
lesson 18, so **a subnet is the unit of a policy**: things that need the same filtering and the
same routes share one, and things that need different ones do not.

The shop cuts `vnet-shop-prod` by tier, which is the cut most designs start from:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l16-subnets\" aria-label=\"The virtual network vnet-shop-prod, 10.20.0.0/16, in the region brazilsouth, drawn over the region's three availability zones. Four subnets run across all three zones: snet-web 10.20.1.0/24, snet-app 10.20.2.0/24, snet-data 10.20.3.0/24, delegated to PostgreSQL, and snet-pe 10.20.4.0/24, for private endpoints. Each offers 251 usable addresses. The rest of the range is left free.\"><rect x=\"16.0\" y=\"14.0\" width=\"688.0\" height=\"332.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"32.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">region</text><text x=\"688.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsouth</text><rect x=\"200.0\" y=\"46.0\" width=\"156.0\" height=\"286.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zone 1</text><rect x=\"368.0\" y=\"46.0\" width=\"156.0\" height=\"286.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zone 2</text><rect x=\"536.0\" y=\"46.0\" width=\"156.0\" height=\"286.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"614.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zone 3</text><text x=\"36.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"36.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><rect x=\"36.0\" y=\"128.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-web</text><text x=\"150.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"440.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the web tier</text><text x=\"674.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 usable</text><rect x=\"36.0\" y=\"174.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-app</text><text x=\"150.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><text x=\"440.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the application</text><text x=\"674.0\" y=\"191.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 usable</text><rect x=\"36.0\" y=\"220.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-data</text><text x=\"150.0\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"440.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">delegated to PostgreSQL</text><text x=\"674.0\" y=\"237.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 usable</text><rect x=\"36.0\" y=\"266.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-pe</text><text x=\"150.0\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.4.0/24</text><text x=\"440.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">private endpoints, lesson 19</text><text x=\"674.0\" y=\"283.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 usable</text><text x=\"360.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the rest of the range stays free for what nobody has planned yet</text></svg>", "caption": "One network, four subnets, and every subnet in all three zones at once."}
```

## Five addresses are never yours

**Azure takes five addresses from every subnet, whatever its size**: the first four and the last.

| address in `snet-app` | what Azure uses it for |
|---|---|
| `10.20.2.0` | the network address |
| `10.20.2.1` | the default gateway, the subnet's door to everything else |
| `10.20.2.2` and `10.20.2.3` | to map Azure's DNS into the network |
| `10.20.2.255` | the broadcast address, though Azure carries no broadcast |

So a `/24` holds 256 addresses and offers 251, and the smallest subnet Azure allows, a `/29`,
offers three of its eight. The arithmetic is short and easy to get wrong in a hurry, so the plan is
checked by a program. Save this as `~/azure/vnet/plan.py`:

```schooling-example
{"language": "python", "file": "plan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"plan.py VNET NAME=RANGE ...: check a subnet plan against a VNet, counting addresses Azure's way.\"\"\"\nimport ipaddress\nimport sys\n\nRESERVED = 5\n\n\n", "note": "Standard library only. `RESERVED` is the number of addresses Azure takes from **every** subnet, whatever its size: the first four and the last."}, {"code": "def subnet(vnet, arg, taken):\n    name, _, text = arg.partition('=')\n    try:\n        net = ipaddress.ip_network(text)\n    except ValueError as e:\n        return f'{name}: refused, {e}'\n", "note": "`ip_network` refuses a range that does not start on its own boundary, such as `10.20.5.0/23`, and says so. Azure refuses it as well."}, {"code": "    if not net.subnet_of(vnet):\n        return f'{name}: refused, {net} is not inside {vnet}'\n    for other, used in taken:\n        if net.overlaps(used):\n            return f'{name}: refused, {net} overlaps {other} ({used})'\n    if net.prefixlen > 29:\n        return f'{name}: refused, /{net.prefixlen} is smaller than the /29 Azure allows'\n", "note": "The three rules Azure applies to a subnet: inside the network's range, overlapping no other subnet, and no smaller than a `/29`, eight addresses of which three are usable."}, {"code": "    taken.append((name, net))\n    first, last = net.network_address + 4, net.broadcast_address - 1\n    return f'{name:<20}{str(net):<16}{str(first):<15}{str(last):<15}{net.num_addresses - RESERVED:>6}'\n\n\n", "note": "The first address a machine can get is the fifth of the range, and the last is the one before the end. What is printed is what is left to use."}, {"code": "def main():\n    vnet = ipaddress.ip_network(sys.argv[1])\n    taken = []\n    print(f'{\"subnet\":<20}{\"range\":<16}{\"first usable\":<15}{\"last usable\":<15}{\"usable\":>6}')\n    for arg in sys.argv[2:]:\n        print(subnet(vnet, arg, taken))\n    left = vnet.num_addresses - sum(n.num_addresses for _, n in taken)\n    print(f'{vnet} holds {vnet.num_addresses} addresses; {left} are in no subnet yet')\n\n\nmain()\n", "note": "One line per subnet, in the order given, and a last line with what remains of the network for the subnets nobody has thought of yet."}]}
```

Give it production's range and the four tiers:

```
ana@laptop:~/azure/vnet$ python3 plan.py 10.20.0.0/16 snet-web=10.20.1.0/24 snet-app=10.20.2.0/24 snet-data=10.20.3.0/24 snet-pe=10.20.4.0/24
subnet              range           first usable   last usable    usable
snet-web            10.20.1.0/24    10.20.1.4      10.20.1.254       251
snet-app            10.20.2.0/24    10.20.2.4      10.20.2.254       251
snet-data           10.20.3.0/24    10.20.3.4      10.20.3.254       251
snet-pe             10.20.4.0/24    10.20.4.4      10.20.4.254       251
10.20.0.0/16 holds 65536 addresses; 64512 are in no subnet yet
```

**Four `/24`s use under 2% of a `/16`**, and that is deliberate. A subnet can be resized only
while it is empty, so the cheap time to leave room is now: the 64,512 addresses left over are where
a fifth tier, a bigger web tier or a service that demands a subnet of its own will go. The range
`10.20.0.0/24` is left unused on purpose too, so the first subnet nobody planned for has an obvious
home.

Then a plan with four mistakes in it, the kind each made once by somebody in a hurry:

```
ana@laptop:~/azure/vnet$ python3 plan.py 10.20.0.0/16 snet-web=10.20.1.0/24 snet-cache=10.20.1.128/25 snet-jobs=10.20.5.0/23 snet-tiny=10.20.9.0/30 snet-batch=10.30.0.0/24
subnet              range           first usable   last usable    usable
snet-web            10.20.1.0/24    10.20.1.4      10.20.1.254       251
snet-cache: refused, 10.20.1.128/25 overlaps snet-web (10.20.1.0/24)
snet-jobs: refused, 10.20.5.0/23 has host bits set
snet-tiny: refused, /30 is smaller than the /29 Azure allows
snet-batch: refused, 10.30.0.0/24 is not inside 10.20.0.0/16
10.20.0.0/16 holds 65536 addresses; 65280 are in no subnet yet
```

`snet-cache` lands inside `snet-web`. `10.20.5.0/23` does not start where a `/23` can start, which
is an even third number. A `/30` is below Azure's minimum. And `10.30.0.0/24` is staging's range,
outside this network altogether. **Each of these Azure itself would refuse too**, at the moment of
creating the subnet; the program says so before anybody asks.

## Subnets with names Azure chooses

Some services insist on a subnet of their own, with **a name they decide** and a minimum size. The
shop's hub network carries three of them, which lessons 18 and 23 fill:

```
ana@laptop:~/azure/vnet$ python3 plan.py 10.0.0.0/16 AzureFirewallSubnet=10.0.1.0/26 AzureBastionSubnet=10.0.2.0/26 GatewaySubnet=10.0.255.0/27
subnet              range           first usable   last usable    usable
AzureFirewallSubnet 10.0.1.0/26     10.0.1.4       10.0.1.62          59
AzureBastionSubnet  10.0.2.0/26     10.0.2.4       10.0.2.62          59
GatewaySubnet       10.0.255.0/27   10.0.255.4     10.0.255.30        27
10.0.0.0/16 holds 65536 addresses; 65376 are in no subnet yet
```

| subnet | it holds | the size asked for |
|---|---|---|
| `AzureFirewallSubnet` | Azure Firewall, lesson 18 | at least a `/26` |
| `AzureBastionSubnet` | Azure Bastion, the service that opens a remote session to a machine with no public address | at least a `/26` |
| `GatewaySubnet` | the VPN and ExpressRoute gateways, lesson 23 | a `/27` or larger is Microsoft's advice |

**The name is the contract**: a firewall deployed into a subnet called `snet-firewall` is refused,
however large the subnet is. The names are spelt exactly as in the table, capitals included, and
nothing else may be placed in those subnets.
