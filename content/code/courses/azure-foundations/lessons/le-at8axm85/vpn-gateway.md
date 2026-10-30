---
title: VPN Gateway, the encrypted road over the internet
version: 1
---

**There are two roads from a company's own building into an Azure network, and they differ in what
they travel over.** A **VPN** is an encrypted tunnel across the public internet: cheap, ready in an
afternoon, and as fast and as steady as the internet happens to be that day. **ExpressRoute** is a
private circuit a telecom carrier provisions between the company and Microsoft: weeks to order,
billed by the month, and it never touches the internet. Most companies start with the first, and the
ones that grow add the second, with the first kept as its backup. This lesson takes them in that
order, and **almost all of it is read rather than run**: a gateway and a circuit are things only
Azure can create, and only the Bicep in the next section was checked in the lab.

The shop's case is small and common. The office in São Paulo has its own network, `192.168.0.0/16`,
a firewall with a public address, `203.0.113.10`, and a finance system that must reach the database
in `vnet-shop-prod`. The road goes into the hub network of lesson 20, `vnet-shop-hub`, in the
subscription `shop-shared`, so that every spoke peered to the hub can use one road instead of each
building its own.

## The gateway lives in a subnet called GatewaySubnet

**A VPN gateway is a pair of virtual machines Microsoft runs for you, inside a subnet of your
network.** You never see the machines and cannot log in to them; you create the gateway resource, and
Azure places its instances in the subnet. Three rules about that subnet are Microsoft's, not
conventions:

- **its name must be exactly `GatewaySubnet`.** The name is how Azure finds it; a subnet called
  `snet-gateway` is just a subnet, and creating the gateway fails;
- **it holds nothing else.** No machine, no other service;
- **it is `/27` or larger** for every SKU but the smallest. The shop gives it `10.0.255.0/27`, at the
  top of the hub's range, which leaves room for an ExpressRoute gateway to share it later. A larger
  subnet costs nothing, and growing a small one under a running gateway is a project.

Creating a gateway takes **45 minutes or more**, by Microsoft's own documentation. A design that
assumes the road can be rebuilt in a lunch break is wrong before it starts.

## SKUs, and why the names end in AZ

The gateway's size is its SKU, and the SKU decides the throughput, the number of tunnels and the
features. Two facts matter more than the table of numbers, which is Microsoft's to change:

- **Basic is for trying things out**, and Microsoft's documentation says so: no BGP, no
  active-active, limited support, never production;
- **the SKUs ending in `AZ`** (`VpnGw1AZ` to `VpnGw5AZ`) spread the gateway's instances across the
  region's availability zones. Microsoft is moving every gateway to these, and the ones without `AZ`
  are being consolidated into them. The shop uses `VpnGw2AZ`.

A gateway also needs a public address of the Standard SKU, and a second one when both of its
instances are active, which is the next part.

## Active-standby and active-active

Every gateway has two instances. **By default one carries the tunnel and the other waits**: when the
active one fails, or Microsoft maintains it, the standby takes over, and the tunnel drops for a moment
while it does. Microsoft's documentation describes the interruption as brief, from seconds for planned
maintenance to longer for an unplanned failure.

**Active-active** makes both instances build tunnels at once, each from its own public address. With
one firewall in the office that gives two tunnels; with two firewalls, each connected to both
instances, it gives four, and losing any one device leaves traffic flowing over the rest:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l23-active-active\" aria-label=\"Dual redundancy for a site-to-site VPN. On the left, the office network 192.168.0.0/16 with two firewalls. On the right, in the hub network's GatewaySubnet 10.0.255.0/27, the VPN gateway vpng-shop with two active instances, each with its own public address. Each firewall builds a tunnel to each instance, four tunnels in all, crossing the internet in the middle. Losing any one firewall or any one instance leaves two or more tunnels up.\"><text x=\"115.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">office</text><text x=\"115.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">GatewaySubnet</text><text x=\"600.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.0.255.0/27</text><rect x=\"50.0\" y=\"100.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">firewall 1</text><rect x=\"50.0\" y=\"190.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">firewall 2</text><rect x=\"530.0\" y=\"100.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance 1</text><text x=\"600.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pip-vpng-shop-1</text><rect x=\"530.0\" y=\"190.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance 2</text><text x=\"600.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pip-vpng-shop-2</text><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">across the internet</text><path d=\"M181.0 115.0 L529.0 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M181.0 118.0 L529.0 212.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M181.0 212.0 L529.0 118.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M181.0 215.0 L529.0 215.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">four tunnels: any one device can fail</text></svg>", "caption": "Two firewalls and two active instances make four tunnels, and BGP keeps track of which are up."}
```

The price of active-active is a second public address and, in practice, **BGP**: with several tunnels
up at once, the two sides need a routing protocol to agree which networks are behind which tunnel and
to stop using one that dies. BGP is the subject of the next section's last part.

## The other kind of VPN

Everything above is **site-to-site**: one network to another, through devices on both ends, invisible
to the people using it. A gateway can also accept **point-to-site** connections, where a single
laptop runs a VPN client and joins the network from wherever it is. It is the right tool for a handful
of administrators and the wrong one for a whole office, and its sign-in can use Entra ID, which ties
it to lesson 11's conditional access.
