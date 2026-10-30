---
title: System routes, and how one is chosen
version: 1
---

**Every subnet in Azure has a route table before anybody writes one.** Azure fills it with **system
routes**, and they are why lesson 16's network worked with nothing configured: a machine in
`snet-app` reaches `snet-data` because a system route says the network's own range is local, and it
reaches the internet because another says everything else goes there. The routes have no device
behind them: there is no router to log in to, and `10.20.2.1`, the subnet's gateway address, is
answered by Azure's own network.

The system routes of a subnet in `vnet-shop-prod` are these:

| prefix | next hop | what it says |
|---|---|---|
| `10.20.0.0/16` | virtual network | the network's own range stays inside it |
| `0.0.0.0/0` | internet | everything not matched by a longer prefix goes out |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.64.0.0/10` | none | private ranges nobody has claimed are dropped, not sent to the internet |

and more appear as the network grows: a route for each peered network in lesson 20, routes learned
from a VPN or ExpressRoute gateway in lesson 23, routes for the service endpoints of lesson 19.

**A next hop of `None` drops the packet.** That row is easy to read past and it is a safety rule: a
typo that sends traffic to `10.99.0.1`, an address in no network, is thrown away inside Azure rather
than offered to the internet.

## Longest prefix, then the source

When several routes contain the destination, Azure picks one in two steps:

1. **the longest prefix wins**: a route for `10.20.0.0/16` beats one for `10.0.0.0/8`, which beats
   `0.0.0.0/0`, because a longer prefix describes the destination more exactly;
2. **between routes with the same prefix, a user-defined route beats one learned by BGP, which beats
   a system route.** That is how somebody replaces the system route for `0.0.0.0/0`: by writing a
   route with the same prefix.

One exception sits in Microsoft's documentation and matters later: system routes for the network
itself, for peered networks and for service endpoints are preferred even over a more specific route
learned by BGP. An office cannot take over the shop's own range by announcing a longer prefix of it.

## Asking the model

Azure shows a machine's merged routes as its **effective routes**, and Network Watcher's *next hop*
answers for one destination; both need a machine in Azure. The lab has a model instead. Make the
lesson's directory and save this as `~/azure/routes/route.py`:

```sh
mkdir -p ~/azure/routes && cd ~/azure/routes
```

```schooling-example
{"language": "python", "file": "route.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"route.py ROUTE-TABLE DEST: the course's model of how Azure picks a route out of snet-app.\n\nA model of Azure's documented rules, not Azure. ROUTE-TABLE is a compiled template, or - for none.\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "**The course's model, not Azure**: it applies the documented way of choosing a route to one subnet, `snet-app`, and reads your route table out of a compiled template."}, {"code": "SYSTEM = [\n    ('Default', '10.20.0.0/16', 'VnetLocal', ''),\n    ('Default', '10.0.0.0/16', 'VNetPeering', ''),\n    ('Default', '0.0.0.0/0', 'Internet', ''),\n    ('Default', '10.0.0.0/8', 'None', ''),\n    ('Default', '172.16.0.0/12', 'None', ''),\n    ('Default', '192.168.0.0/16', 'None', ''),\n    ('Default', '100.64.0.0/10', 'None', ''),\n]\n", "note": "The system routes Azure gives every subnet of `vnet-shop-prod`: its own range, the hub it will be peered with in lesson 20, the internet for everything else, and `None`, which drops the packet, for the private ranges nobody has claimed."}, {"code": "RANK = {'User': 0, 'BGP': 1, 'Default': 2}\n\n\n", "note": "When two routes have the same prefix, a user-defined route beats one learned by BGP, which beats a system route."}, {"code": "def user_routes(path):\n    if path == '-':\n        return []\n    template = json.load(open(path))\n    table = next(r for r in template['resources']\n                 if r['type'] == 'Microsoft.Network/routeTables')\n    found = []\n    for r in table['properties']['routes']:\n        p = r['properties']\n        ip = p.get('nextHopIpAddress', '')\n        if ip.startswith(\"[parameters('\"):\n            ip = template['parameters'][ip[13:-3]]['defaultValue']\n        found.append(('User', p['addressPrefix'], p['nextHopType'], ip))\n    return found\n\n\n", "note": "Turns the routes of a compiled route table into the same shape. A next hop written as a parameter is read from the parameter's default, which is what a deployment without an override would use."}, {"code": "def main():\n    dest = ipaddress.ip_address(sys.argv[2])\n    routes = user_routes(sys.argv[1]) + SYSTEM\n    found = [r for r in routes if dest in ipaddress.ip_network(r[1])]\n    found.sort(key=lambda r: (-ipaddress.ip_network(r[1]).prefixlen, RANK[r[0]]))\n    for i, (source, prefix, hop, ip) in enumerate(found):\n        mark = 'chosen' if i == 0 else ''\n        print(f'{source:<8}{prefix:<16}{hop:<17}{ip:<10}{mark}'.rstrip())\n\n\nmain()\n", "note": "Keeps the routes whose prefix contains the destination, sorts them **longest prefix first** and then by source, and marks the first. Every route that matched is printed, so you can see what the winner beat."}]}
```

With no route table of yours, `-`, ask where a packet for an internet address goes:

```
ana@laptop:~/azure/routes$ python3 route.py - 203.0.113.80
Default 0.0.0.0/0       Internet                   chosen
```

Straight out, by the only route that contains it: **the route to the internet is there before anybody
writes one**, the same shape of default that lesson 17 found in the NSG rules. Whether a machine can
use it is a separate question, the one lesson 16 answered with private subnets: in the shop's
subnets a machine has no address of its own to leave with, so the route leads nowhere until an
explicit way out exists. The next section makes that way out the firewall, and writes the route
table that sends everything to it.
