---
title: Routes, and which one a packet takes
version: 1
---

**A route says where packets for a range of addresses go next.** Every network has a table of them, global
like the network, and every packet leaving a machine is matched against it. Three kinds fill the table:

| kind | made by | example |
|---|---|---|
| **subnet routes** | Google, one per subnet range, for as long as the subnet exists | `10.10.0.0/20`, to the subnet itself |
| **the default route** | Google, when the network is made; it can be deleted | `0.0.0.0/0`, to `default-internet-gateway` |
| **custom routes** | a person: **static** routes written by hand, or **dynamic** routes learned by a Cloud Router over BGP, lesson 21 | `192.168.0.0/16`, to a VPN tunnel |

The **default internet gateway** is not a machine. It is the name of the way out of the network towards
addresses outside it, the internet and Google's own public APIs among them, and a route pointing at it is
what lets a packet leave at all.

## Which route decides

For each packet, the routes whose destination contains the address are candidates, and **the most specific
destination wins**: a `/20` beats a `/16`, which beats `/0`. Only among routes with the same destination does
**priority** count, lowest number first, the same rule as lesson 16's. Two custom routes with the same
destination and the same priority share the traffic between their next hops. In an ordinary network a
subnet route is what its own range is reached by: a subnet's addresses are reached inside the network.

Save the planner's table as `~/gcp/routes/routes.json`. It has the two subnets of lesson 15, the default
route, a route for Google's private API range, and two routes to the office through two VPN tunnels, the
second there in case the first fails:

```sh
mkdir -p ~/gcp/routes && cd ~/gcp/routes
```

```json
[
  {"name": "default-route", "kind": "default", "dest": "0.0.0.0/0", "priority": 1000,
   "next_hop": "default-internet-gateway"},
  {"name": "planner-sao-paulo", "kind": "subnet", "dest": "10.10.0.0/20", "next_hop": "the subnet"},
  {"name": "planner-santiago", "kind": "subnet", "dest": "10.11.0.0/20", "next_hop": "the subnet"},
  {"name": "private-googleapis", "kind": "static", "dest": "199.36.153.8/30", "priority": 1000,
   "next_hop": "default-internet-gateway"},
  {"name": "office-primary", "kind": "static", "dest": "192.168.0.0/16", "priority": 100,
   "next_hop": "tunnel office-1"},
  {"name": "office-backup", "kind": "static", "dest": "192.168.0.0/16", "priority": 200,
   "next_hop": "tunnel office-2"}
]
```

And the program that picks a route, as `route.py`:

```schooling-example
{"language": "python", "file": "route.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Picks the route a packet leaving a machine would take, as Google does.\n\n    python3 route.py ADDRESS [ADDRESS ...]\n\nThe network's routes are read from routes.json.\n\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "How it is called: one or more destination addresses, each answered with the route a packet to it would leave by."}, {"code": "routes = json.load(open('routes.json'))\nfor r in routes:\n    r['net'] = ipaddress.ip_network(r['dest'])\n\n", "note": "Read the network's routes, and turn each destination into a network the standard library can compare addresses against."}, {"code": "def best(address):\n    found = [r for r in routes if address in r['net']]\n    if not found:\n        return None\n    longest = max(r['net'].prefixlen for r in found)\n    found = [r for r in found if r['net'].prefixlen == longest]\n    subnet = [r for r in found if r['kind'] == 'subnet']\n    return subnet[0] if subnet else min(found, key=lambda r: r['priority'])\n\n", "note": "Google's order. The routes whose destination contains the address; of those, the most specific, the longest prefix; among equals, a subnet route before anything else, and otherwise the lowest priority number. No route at all means the packet is dropped."}, {"code": "for arg in sys.argv[1:]:\n    route = best(ipaddress.ip_address(arg))\n    if route is None:\n        print(f'{arg:15} no route: dropped')\n    else:\n        print(f\"{arg:15} {route['dest']:16} {route['name']:19} -> {route['next_hop']}\")\n", "note": "One line per address: the destination that matched, the route's name, and where it sends the packet."}]}
```

Four destinations: a machine in Santiago, a public address, one of Google's private API addresses, and a
machine in the office:

```
ana@laptop:~/gcp/routes$ python3 route.py 10.11.3.4 8.8.8.8 199.36.153.9 192.168.4.20
10.11.3.4       10.11.0.0/20     planner-santiago    -> the subnet
8.8.8.8         0.0.0.0/0        default-route       -> default-internet-gateway
199.36.153.9    199.36.153.8/30  private-googleapis  -> default-internet-gateway
192.168.4.20    192.168.0.0/16   office-primary      -> tunnel office-1
```

The office address matched two routes with the same `/16`, and **priority chose the primary tunnel**. If
`office-primary` disappeared, `office-backup` would take over without anybody changing anything, which is
what the different priorities are for.

## A network with no way out

Production at the planner has no business reaching the internet directly, so its network deletes the default
route. Do the same to the table:

```
ana@laptop:~/gcp/routes$ jq 'map(select(.name != "default-route"))' routes.json > r.json && mv r.json routes.json
ana@laptop:~/gcp/routes$ python3 route.py 8.8.8.8 199.36.153.9
8.8.8.8         no route: dropped
199.36.153.9    199.36.153.8/30  private-googleapis  -> default-internet-gateway
```

**The public address now has no route and is dropped, and Google's API range still leaves**, through the
custom route with its own `/30`. That route is the reason the table has it: a machine reaching Cloud Storage
or Pub/Sub without a public address does so through the default internet gateway too, and deleting the
default route without replacing that part of it cuts production off from Google's own services. The last section of
this lesson is about that range.
