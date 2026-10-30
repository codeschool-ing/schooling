---
title: The public road, a service endpoint and a private endpoint
version: 1
---

**A storage account has a public address whether you want one or not.** Lesson 2 showed where it
comes from: the account's name becomes part of a host name, and `stshopprod` answers at
`stshopprod.blob.core.windows.net` to anybody on the internet who knows the name. The wrong
picture is that a resource in the same subscription as your virtual network is somehow inside it.
It is not. A storage account, a database or a key vault is a **platform service**: it lives on
Microsoft's side of the line, it has a public endpoint, and the shop's application in `snet-app`
reaches it the same way a laptop in a café does, unless somebody builds another road.

There are three roads, and this lesson is about the difference between them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l19-three-roads\" aria-label=\"Three roads from the application in snet-app to the storage account stshopprod. On the left, the virtual network vnet-shop-prod holds snet-app and snet-pe. On the right, on Microsoft's side of the line, the storage account has a public endpoint. The public road leaves the network for the public endpoint, which is open to the internet. The service endpoint road reaches the same public endpoint over the backbone, carrying the subnet's identity. The private endpoint road goes to a network interface at 10.20.4.4 inside snet-pe, which Private Link connects to the account, and the public endpoint can be switched off.\"><defs><marker id=\"l19-three-roads-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-three-roads-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l19-three-roads-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l19-three-roads-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 30 H350 V320 H20 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"36.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">virtual network</text><text x=\"334.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vnet-shop-prod</text><path d=\"M40 66 H190 V216 H40 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"115.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">snet-app</text><rect x=\"65.0\" y=\"104.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">application</text><path d=\"M40 236 H330 V306 H40 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"56.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">snet-pe</text><rect x=\"200.0\" y=\"248.0\" width=\"116.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">private endpoint</text><text x=\"258.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.4.4</text><path d=\"M400.0 20.0 L400.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Microsoft's side</text><rect x=\"450.0\" y=\"120.0\" width=\"230.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stshopprod</text><rect x=\"470.0\" y=\"154.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">public endpoint</text><rect x=\"470.0\" y=\"198.0\" width=\"190.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Private Link</text><path d=\"M166.0 112.0 L300.0 70.0 L560.0 70.0 L560.0 119.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-roads-af-ah-amber)\"></path><text x=\"430.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1  the public road</text><path d=\"M166.0 126.0 L360.0 150.0 L469.0 168.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 3\" marker-end=\"url(#l19-three-roads-af-ah-paper)\"></path><text x=\"212.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  service endpoint</text><path d=\"M115.0 135.0 L115.0 225.0 L190.0 225.0 L199.0 262.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-roads-af-ah-phosphor)\"></path><text x=\"56.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3  private</text><text x=\"56.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">endpoint</text><path d=\"M317.0 270.0 L420.0 270.0 L420.0 214.0 L469.0 214.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-roads-af-ah-phosphor)\"></path><text x=\"565.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">internet</text><path d=\"M565.0 288.0 L565.0 241.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l19-three-roads-af-ah-paper-dim)\"></path></svg>", "caption": "Roads 1 and 2 end at the same public endpoint. Only road 3 lets it be closed."}
```

- **The public road.** The application resolves the name, gets a public address, and the packets
  leave the virtual network for Microsoft's public endpoint. They stay on Microsoft's network for
  most of the way, but the endpoint is open to the world and only the account's keys, tokens and
  firewall stand in front of it.
- **A service endpoint.** A switch on a subnet that tells Azure: traffic from here to this kind of
  service goes over the backbone **carrying the subnet's identity**. The service still answers on its
  public address, and its firewall can now say "allow `snet-app`" instead of a list of IP addresses.
- **A private endpoint.** A network interface, with a private address from one of your subnets,
  that **is** the storage account inside your network. The application talks to `10.20.4.4`, the
  packets never leave the virtual network's address space, and the account's public endpoint can be
  switched off entirely.

**Leaving the internet is not encryption.** A private endpoint changes where the packets travel and
who can reach the door; it does not change what is in them. The connection to the account is still
HTTPS, and must be: a private road keeps strangers off it, and TLS keeps whoever is on it from reading
what passes. Lesson 22 meets the same distinction at the edge.

## A service endpoint, in Bicep

The lesson works in its own directory:

```sh
mkdir -p ~/azure/private-link && cd ~/azure/private-link
```

A service endpoint is two settings in two places: on the subnet, which service it opens a road to,
and on the service, which subnets it accepts. Save this as `se.bicep`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-prod'
}

resource snetApp 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-app'
  properties: {
    addressPrefix: '10.20.2.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          'brazilsouth'
        ]
      }
    ]
  }
}

resource st 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stshopprod'
  location: 'brazilsouth'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: snetApp.id
          action: 'Allow'
        }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/private-link$ az bicep build --file se.bicep --stdout | jq '.resources[] | {type, endpoints: .properties.serviceEndpoints, acls: .properties.networkAcls}'
{
  "type": "Microsoft.Network/virtualNetworks/subnets",
  "endpoints": [
    {
      "service": "Microsoft.Storage",
      "locations": [
        "brazilsouth"
      ]
    }
  ],
  "acls": null
}
{
  "type": "Microsoft.Storage/storageAccounts",
  "endpoints": null,
  "acls": {
    "defaultAction": "Deny",
    "virtualNetworkRules": [
      {
        "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-shop-prod', 'snet-app')]",
        "action": "Allow"
      }
    ]
  }
}
```

`existing` names a network that is already there, `vnet-shop-prod` from lesson 16, without
creating it. The subnet then switches on `Microsoft.Storage`, and the account sets `defaultAction`
to `Deny` with one exception, the subnet's id, which the compiler turned into a `resourceId(...)`
expression for Resource Manager to finish. **Declaring a subnet in a second file replaces what the
first file said about it**: a deployment of `se.bicep` would leave `snet-app` with no network
security group and no route table, because this file mentions neither. In a real template the
subnet is declared once, beside its network, and the service endpoint is one more property there.

## What a service endpoint does not do

A service endpoint is free, quick to switch on, and narrower than it sounds:

- **It works only for traffic that starts in that subnet.** A machine in a peered network
  (lesson 20) or in the office at the other end of a VPN (lesson 23) does not use it, and the
  account's firewall does not let it in.
- **The service keeps its public address**, and anything else allowed through the account's
  firewall still reaches it from the internet.
- **It opens a road to the whole service, not to one account.** A subnet with `Microsoft.Storage`
  switched on can reach every storage account in the region over that road, including one that
  belongs to somebody else and was created to receive the shop's data. A **service endpoint
  policy** narrows it to named accounts; without one, that is a route out for anybody who controls
  code running in the subnet.

A private endpoint answers all three, at a price per hour and per gigabyte, and the next section
builds one.

**None of this was deployed.** The compiler checked that every property exists on its type and
that the subnet's id is something the account can refer to. Whether `10.20.2.0/24` fits inside the
network, and whether the account's name is still free, are questions for Resource Manager.
