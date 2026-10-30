---
title: A peering is two links, and the ranges must not meet
version: 1
---

**Two virtual networks know nothing of each other until somebody joins them.** `vnet-shop-prod` and
the hub `vnet-shop-hub` of the shared subscription are as separate as two networks in two companies:
a machine in one has no route to the other, whatever their subscriptions or their tenant. **Virtual
network peering** is the join. It connects two networks over Microsoft's backbone, with no gateway,
no tunnel and no extra hop, so that a packet from `10.20.2.10` to `10.0.1.4` travels as if the two
ranges were one network.

It is cheap to describe and has three rules that every design afterwards depends on.

## A peering has two sides

**A peering is two resources, one in each network**, and it works only when both exist. The first
one created sits in the state *Initiated*; the moment its partner appears, both turn *Connected*.
That shape is not a formality. Each side is owned by whoever owns that network, so joining the
shop's production spoke to the hub in `shop-shared` needs somebody with permission on both: a
peering is an agreement, and either side can withdraw it by deleting its half.

Each side carries four switches, and they need not match:

| setting | on this side, it means |
|---|---|
| `allowVirtualNetworkAccess` | machines in the remote network may reach machines in this one; it is on unless switched off |
| `allowForwardedTraffic` | this network accepts packets the remote network forwarded on from somewhere else, such as traffic a firewall in the hub passes on from another spoke |
| `allowGatewayTransit` | this network lends its VPN or ExpressRoute gateway to the remote one; set on the hub |
| `useRemoteGateways` | this network uses the remote network's gateway instead of its own; set on a spoke, which then may not have a gateway of its own |

The last two are a pair across the peering, the hub saying "I lend" and the spoke saying "I
borrow", and lesson 23 is where the gateway they share comes from.

**The two networks may be in different regions**, which Azure calls global peering, in different
subscriptions, and in different tenants. Nothing changes in how it is made; what changes is the
price, and who has to agree.

## The ranges must not overlap

**Two networks whose address ranges share even one address cannot be peered.** A packet to an
address both networks contain would have two places to go, so Azure refuses the peering rather than
guess. It is the one rule of peering that a lab can check, because it is arithmetic, and it is the
one that ruins a design years after it was drawn: a network created in a hurry with the same range
as the hub can never be joined to anything the hub is joined to.

Make the lesson's directory, and save this as `overlap.py` in it:

```sh
mkdir -p ~/azure/peering && cd ~/azure/peering
```

```schooling-example
{"language": "python", "file": "overlap.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"overlap.py NAME=CIDR ...: which networks can be joined, and which collide.\"\"\"\nimport ipaddress\nimport itertools\nimport sys\n\n", "note": "Standard library only. `ipaddress` knows what a range is, so the program never does arithmetic on addresses itself."}, {"code": "nets = {}\nfor arg in sys.argv[1:]:\n    name, cidr = arg.split('=')\n    nets[name] = ipaddress.ip_network(cidr)\n\n", "note": "Each argument is a name and a range, such as `hub=10.0.0.0/16`. `ip_network` refuses a range written with host bits set, like `10.0.0.1/16`, which is the same refusal Azure gives."}, {"code": "for (a, na), (b, nb) in itertools.combinations(nets.items(), 2):\n    if na.overlaps(nb):\n        print(f'collide   {a} {na} and {b} {nb}')\n\n", "note": "Every pair, once. **Two ranges that share even one address cannot be peered**, because a packet to that address would have two places to go."}, {"code": "free = [n for n in nets if not any(nets[n].overlaps(nets[m]) for m in nets if m != n)]\nprint('clear of every other:', ' '.join(free))\n", "note": "The networks that collide with nobody: the ones that could be joined to any of the others today."}]}
```

Give it the shop's networks as lesson 16 planned them, the office, and two newcomers: a
development network somebody carved out of production's range, and a partner's network that
happens to use the hub's:

```
ana@laptop:~/azure/peering$ python3 overlap.py hub=10.0.0.0/16 prod=10.20.0.0/16 staging=10.30.0.0/16 office=192.168.0.0/16 dev=10.20.128.0/17 partner=10.0.0.0/16
collide   hub 10.0.0.0/16 and partner 10.0.0.0/16
collide   prod 10.20.0.0/16 and dev 10.20.128.0/17
clear of every other: staging office
```

Two collisions, and they are different kinds. **`dev` lives inside `prod`**: `10.20.128.0/17` is the
upper half of `10.20.0.0/16`, so the two can never be peered, and neither can `dev` be peered to the
hub while `prod` is, since the hub would then hold two routes to the same addresses. The partner is
the harder case, because the shop does not choose the partner's addresses. **The cure for both is a
plan of ranges written before the first network exists**, with room left for networks nobody has
asked for yet, which is why lesson 16 gave each environment a whole `/16`. Only `staging` and the
office are clear of everybody.

## What crossing a peering costs

**Data crossing a peering is billed by the gigabyte in both directions**: once leaving one network
and once arriving in the other, which is unlike the internet's free arrival of lesson 1. Global
peering, between regions, costs more per gigabyte than peering inside one region. The prices are on
Microsoft's list under virtual network peering, which lesson 1's program reads on your machine and
could not read on the one this course was recorded on. **A design that sends every request between
two spokes through a hub pays for two crossings instead of one**, and that is the trade the next
section makes on purpose.
