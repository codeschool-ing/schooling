---
title: Private zones, automatic registration and the resolver for the office
version: 1
---

**A private zone answers only the virtual networks it is linked to, and nobody on the internet can
ask it anything.** Lesson 19 used one to take over the middle link of a storage account's name. The
shop uses another for names of its own: `shop.internal`, a zone in which `db.shop.internal` is the
database's address and every machine in production has its name written down without anybody
writing it.

## The zone, a link and a record, in Bicep

Save this as `private.bicep` in `~/azure/dns`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-prod'
}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'shop.internal'
  location: 'global'
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: zone
  name: 'link-vnet-shop-prod'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: true
  }
}

resource db 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: zone
  name: 'db'
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: '10.20.3.10'
      }
    ]
  }
}
```

```
ana@laptop:~/azure/dns$ az bicep build --file private.bicep --stdout | jq -c '.resources[] | {type, name, registration: .properties.registrationEnabled}'
{"type":"Microsoft.Network/privateDnsZones","name":"shop.internal","registration":null}
{"type":"Microsoft.Network/privateDnsZones/virtualNetworkLinks","name":"[format('{0}/{1}', 'shop.internal', 'link-vnet-shop-prod')]","registration":true}
{"type":"Microsoft.Network/privateDnsZones/A","name":"[format('{0}/{1}', 'shop.internal', 'db')]","registration":null}
```

Three resources, and the middle one does the work. A **virtual network link** joins the zone to
`vnet-shop-prod`, and from then on Azure's resolver at `168.63.129.16`, which every machine in that
network asks by default, answers names in `shop.internal` from the zone. The record `db` holds the
address the database was given in `snet-data`.

**`registrationEnabled: true` is automatic registration.** Every virtual machine that starts in the
linked network gets an `A` record in the zone with its own name and private address, and the record is
removed when the machine is deleted. Nobody keeps a list, so the list is never out of date. Two limits
come with it: **a network can register into one private zone only**, and it registers virtual
machines, not the platform services or the private endpoints of lesson 19, whose records come from
their zone groups.

## The same name, inside and outside

Nothing stops the shop from having a public zone `shop.example` and a private zone `shop.example` at
the same time. A machine in a linked network then gets the private answers, and the internet gets the
public ones: **split-horizon DNS**, the same mechanism as lesson 19's, applied to a name you own. It is
useful and easy to get wrong in one specific way. **A private zone answers every name in it, and
says "no such name" for every name it does not hold**; it does not fall through to the public zone.
A private `shop.example` with only `api` in it makes `www.shop.example` disappear for every machine in
the linked network, while it works perfectly from everybody's laptop.

## When the question comes from outside Azure

`168.63.129.16` answers only machines inside Azure: the address means nothing from the office. Lesson
19 ended on a laptop on the VPN that asks the office's DNS for a storage account's name and gets the
public answer. **Azure DNS Private Resolver** is the piece that closes that gap. It lives in the hub,
in subnets of its own, and has two halves:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l21-resolver\" aria-label=\"The office asking Azure's private names. A laptop in the office asks the office DNS server. A conditional forwarder sends questions for shop.internal and for the privatelink zones over the VPN to the Private Resolver's inbound endpoint in the hub, which answers from Azure's resolver and the linked private zones. In the other direction, the outbound endpoint and a forwarding ruleset send questions for corp.shop.example to the office DNS server.\"><defs><marker id=\"l21-resolver-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-resolver-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l21-resolver-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 30 H250 V250 H20 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"36.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the office</text><text x=\"234.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><rect x=\"45.0\" y=\"70.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><rect x=\"45.0\" y=\"160.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">office DNS server</text><text x=\"135.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.1.10</text><path d=\"M105.0 111.0 L105.0 159.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-paper-dim)\"></path><path d=\"M440 30 H700 V250 H440 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"456.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vnet-shop-hub</text><rect x=\"465.0\" y=\"70.0\" width=\"210.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">inbound endpoint</text><text x=\"570.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Private Resolver</text><rect x=\"465.0\" y=\"140.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">private zones, linked</text><rect x=\"465.0\" y=\"195.0\" width=\"210.0\" height=\"45.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">outbound endpoint</text><text x=\"570.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">and its ruleset</text><path d=\"M226.0 175.0 L340.0 120.0 L464.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-phosphor)\"></path><text x=\"320.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">shop.internal</text><text x=\"320.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">privatelink zones</text><path d=\"M570.0 121.0 L570.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-paper-dim)\" marker-start=\"url(#l21-resolver-af-ah-paper-dim)\"></path><path d=\"M464.0 218.0 L340.0 230.0 L226.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-amber)\"></path><text x=\"340.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">corp.shop.example</text></svg>", "caption": "Each side forwards the other the names only it knows, over the VPN."}
```

- **an inbound endpoint**, a private address in the hub that answers DNS questions with everything
  Azure's resolver knows, private zones included. The office's DNS gets a **conditional forwarder**:
  questions for `shop.internal` and for each `privatelink` zone go to that address over the VPN;
- **an outbound endpoint with a forwarding ruleset**, for the opposite direction: rules such as
  "questions for `corp.shop.example` go to `192.168.1.10`", so that machines in Azure can resolve the
  names only the office's DNS knows.

**Nothing in this section was created**, and no question was asked of a private zone: they answer only
from inside a linked Azure network, which the lab is not. What was checked is the shape of the zone and
its link, and what the lesson says about answers is Microsoft's documented behaviour. Lesson 23 builds
the VPN that the office's questions travel over.
