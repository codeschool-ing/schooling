---
title: A virtual network is a range of addresses in one region
version: 1
---

**A virtual network, a VNet in Azure's own shorthand, is a range of private addresses that belongs
to one subscription and lives in one region.** Machines placed in it get addresses from that range,
talk to each other without anybody opening a door, and talk to nothing outside it until somebody
does. It is the floor every network lesson of this course stands on, and it carries no traffic of
its own: it is a set of rules about which addresses exist and where a packet for each of them goes.

Three properties decide most of what comes later:

- **It is regional, and it spans every zone of its region.** `vnet-shop-prod` lives in
  `brazilsouth`, and a subnet of it is available in zones 1, 2 and 3 at once. A design that spreads
  machines over three zones does not need three subnets for it, which is the first place Azure
  differs from the picture other clouds draw.
- **Its range is yours to choose, from the private ranges.** Microsoft recommends the three blocks
  of RFC 1918, `10.0.0.0/8`, `172.16.0.0/12` and `192.168.0.0/16`, and accepts the shared space of
  RFC 6598, `100.64.0.0/10`. A few ranges are refused outright, among them `168.63.129.16/32`, the
  address Azure's own DNS and health checks answer on inside every network.
- **The range can grow.** Address ranges can be added to a VNet, and removed, after it exists; a
  subnet can be resized as long as nothing is deployed in it. Running out is a nuisance rather than
  a rebuild, provided the new range collides with nothing.

## The one rule that is expensive to break

**Two networks that will ever be connected must not overlap.** Connecting means peering, the
subject of lesson 20, or a VPN or a private circuit to an office, lesson 23. In every case each side
has to know that an address belongs to the other, and an address that exists on both sides belongs
to neither. Azure refuses the peering; the office's router simply sends the packets to the wrong
place.

The shop's plan gives each network its own block of `10.0.0.0/8` and keeps the office out of it:

| network | range | where |
|---|---|---|
| `vnet-shop-hub` | `10.0.0.0/16` | `shop-shared`: the firewall, the gateways, lesson 18 and 23 |
| `vnet-shop-prod` | `10.20.0.0/16` | `shop-prod`: the shop itself |
| `vnet-shop-staging` | `10.30.0.0/16` | `shop-staging`: releases before they go out |
| the office | `192.168.0.0/16` | São Paulo, joined in lesson 23 |

Checking a plan for overlaps is arithmetic, and Python's `ipaddress` module does it. Make the
lesson's directory and ask whether production's range collides with each of the others, and with
the whole of `10.0.0.0/8`:

```sh
mkdir -p ~/azure/vnet && cd ~/azure/vnet
```

```
ana@laptop:~/azure/vnet$ for n in 10.0.0.0/16 10.30.0.0/16 192.168.0.0/16 10.0.0.0/8; do python3 -c "import ipaddress as i, sys; print(sys.argv[1], i.ip_network('10.20.0.0/16').overlaps(i.ip_network(sys.argv[1])))" $n; done
10.0.0.0/16 False
10.30.0.0/16 False
192.168.0.0/16 False
10.0.0.0/8 True
```

The last line is the trap the table avoids. **A `/8` contains every `/16` that starts with `10.`**,
so an office that announces the whole of `10.0.0.0/8` because "we use 10-dot addresses" overlaps
every network in Azure that the shop will ever build. Ask the office for the ranges it really uses,
before the first VNet, because afterwards one of the two has to be renumbered.

## Creating one, and what the lab can say

A VNet is a resource of `Microsoft.Network`, created in a resource group:

```
ana@laptop:~/azure/vnet$ az network vnet create --name vnet-shop-prod --resource-group rg-shop-prod --address-prefixes 10.20.0.0/16
ERROR: Please run 'az login' to setup account.
```

**Not created**, as every request to Resource Manager in this lab. With an account the command
answers with the new network as JSON, its `addressSpace` and an empty list of subnets, and costs
nothing: a VNet and its subnets are free. What costs money is what you put in them and what you
connect them to, which lessons 18 to 23 price. The section after next writes the same network in
Bicep, where the lab can at least check its shape.
