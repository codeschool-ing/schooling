---
title: A public zone, its delegation and its alias records
version: 1
---

**Azure DNS does not own a domain; it answers for one somebody delegated to it.** The shop buys
`shop.example` from a registrar, and the registrar's job ends with one thing: telling the parent zone,
`.example`, which name servers answer for `shop.example`. Creating the zone in Azure gives you those
name servers; writing them at the registrar is the **delegation**, and until it is done the zone in
Azure answers correctly to anybody who asks it directly and to nobody who asks the internet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l21-delegation\" aria-label=\"How a question for shop.example reaches Azure DNS. A resolver asks the root, which refers it to the servers of .example. Those hold the delegation the registrar wrote: four NS records naming ns1-01.azure-dns.com, ns2-01.azure-dns.net, ns3-01.azure-dns.org and ns4-01.azure-dns.info. The resolver asks one of them, and the zone shop.example in Azure DNS answers with its records. The name server numbers are an example.\"><defs><marker id=\"l21-delegation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-delegation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l21-delegation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resolver</text><text x=\"85.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">asks on your behalf</text><rect x=\"230.0\" y=\"20.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the root</text><rect x=\"230.0\" y=\"115.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.example</text><text x=\"310.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">holds the delegation</text><rect x=\"470.0\" y=\"20.0\" width=\"230.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Azure DNS</text><text x=\"585.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns1-01.azure-dns.com</text><text x=\"585.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns2-01.azure-dns.net</text><text x=\"585.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns3-01.azure-dns.org</text><text x=\"585.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns4-01.azure-dns.info</text><rect x=\"495.0\" y=\"150.0\" width=\"180.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"585.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.example</text><text x=\"585.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@  A  (alias)</text><text x=\"585.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">www  CNAME</text><text x=\"585.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@  MX  10</text><path d=\"M151.0 120.0 L229.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"176.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M151.0 140.0 L229.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"190.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M151.0 160.0 L300.0 215.0 L494.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-phosphor)\"></path><text x=\"300.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3  ask a server the delegation named</text><path d=\"M391.0 140.0 L469.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"400.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">NS</text></svg>", "caption": "Written at the registrar, the four NS records send every resolver to Azure."}
```

## The zone, in Bicep

A public zone is a resource with `location: 'global'`, because DNS has no region, and each record
set is a child of it. Save this as `public.bicep` in `~/azure/dns`:

```bicep
resource zone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: 'shop.example'
  location: 'global'
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' existing = {
  name: 'pip-shop-web'
}

resource apex 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: 300
    targetResource: {
      id: pip.id
    }
  }
}

resource www 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: zone
  name: 'www'
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: 'shop.example'
    }
  }
}

resource mx 'Microsoft.Network/dnsZones/MX@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: 3600
    MXRecords: [
      {
        preference: 10
        exchange: 'mail.shop.example'
      }
    ]
  }
}

output nameServers array = zone.properties.nameServers
```

```
ana@laptop:~/azure/dns$ az bicep build --file public.bicep --stdout | jq -c '(.resources[] | {type, name}), .outputs'
{"type":"Microsoft.Network/dnsZones","name":"shop.example"}
{"type":"Microsoft.Network/dnsZones/A","name":"[format('{0}/{1}', 'shop.example', '@')]"}
{"type":"Microsoft.Network/dnsZones/CNAME","name":"[format('{0}/{1}', 'shop.example', 'www')]"}
{"type":"Microsoft.Network/dnsZones/MX","name":"[format('{0}/{1}', 'shop.example', '@')]"}
{"nameServers":{"type":"array","value":"[reference(resourceId('Microsoft.Network/dnsZones', 'shop.example'), '2018-05-01').nameServers]"}}
```

Four resources: the zone and three **record sets**. A record set is all the records of one type at one
name, which is why there is one `A` set at `@` and one `MX` set at `@`, two resources with the same
name and different types. `@` means the top of the zone, `shop.example` itself.

The output `nameServers` is an expression, `reference(...)`, and not a list: **Azure picks the zone's
four name servers when the zone is created**, so nobody, the compiler included, knows them before.
They come from four different top-level domains, of the form `ns1-01.azure-dns.com`,
`ns2-01.azure-dns.net`, `ns3-01.azure-dns.org` and `ns4-01.azure-dns.info`, with numbers that differ
from zone to zone. Four parents instead of one means a failure in the operator of `.com` does not
take every Azure zone down with it.

## The delegation, and how to check it

With the zone created, the four names go into the registrar's form for `shop.example`, and the
parent starts answering. **None of this was run**: there is no zone, and no registrar. On your
machine, the check for any delegated domain is the same pair of commands:

```sh
dig NS shop.example +short
dig SOA shop.example +short
```

The first lists the name servers the internet has been told about, and they must be the four Azure
gave, all four. The second answers from the zone itself, and its first field is the name of one of
them. A delegation that lists two of the four works and is half as resilient; one that lists the
registrar's own servers means the zone in Azure is answering nobody.

**Changing a delegation is slow on purpose.** The parent's `NS` records carry a TTL, often two days,
and every resolver that cached the old answer keeps it until the TTL runs out. Moving a domain to Azure
DNS is done by copying every record into the new zone first, checking it by asking the new servers
directly with `dig @<server>`, and only then changing the registrar.

## Alias records, and the top of the zone

The table in the previous section had a rule: the top of a zone cannot be a CNAME. So
`shop.example` itself cannot be "whatever address the shop's front end has today"; it needs an `A`
record, and an address written into an `A` record is wrong the day the front end gets a new one.

**An alias record set is Azure's way out.** Instead of a value, it carries `targetResource`: the id of
an Azure resource, here the public IP `pip-shop-web`, and Azure DNS answers with whatever address
that resource has at the moment it is asked. It is still an `A` record on the wire, so it is allowed
at the top; and when the resource is deleted, the record answers nothing rather than pointing at an
address that now belongs to somebody else. That last case has a name, a **dangling record**, and it
is how a company's own subdomain ends up serving a stranger's page.

An alias can point at a public IP address, at a Traffic Manager profile, at a Front Door endpoint, or
at another record set in the same zone. `www` in the file is an ordinary CNAME to the top, which is
allowed because `www` is not the top.
