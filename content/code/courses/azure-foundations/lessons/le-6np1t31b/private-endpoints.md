---
title: A private endpoint, and what it is made of
version: 1
---

**A private endpoint is a network interface in your subnet that stands for one part of one
resource.** Not a storage account in general: the blob service of `stshopprod`, and nothing else.
Azure gives the interface an address from the subnet, connects it through **Azure Private Link** to
the service on Microsoft's side, and from then on a packet sent to that address arrives at the
account as if the account lived in the subnet.

Three things make one up, and each is a property in the file below:

- **the subnet it sits in.** The shop keeps every private endpoint in `snet-pe`, `10.20.4.0/24`, so
  that the addresses of the platform's services are one range that a firewall rule or a route can
  name. The interface takes the next free address, and Azure keeps the first four and the last of
  every subnet, so the first endpoint there gets `10.20.4.4`;
- **the resource and the sub-resource.** `privateLinkServiceId` is the account's id and `groupIds`
  says which of its services: `blob`, `file`, `queue`, `table`, `dfs`. A second service of the same
  account is a second private endpoint;
- **the connection's approval.** An endpoint asks the resource's owner to accept it. When the
  person creating it also has permission on the resource, the request is approved on the spot;
  otherwise it waits in the state *Pending* until the owner approves it, which is how a partner's
  tenant can be given a private road to one of the shop's accounts without being given anything else.

## The endpoint and its zone, in Bicep

Save this as `pe.bicep` in `~/azure/private-link`:

```bicep
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-prod'
}

resource snetPe 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-pe'
}

resource st 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stshopprod'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-stshopprod-blob'
  location: location
  properties: {
    subnet: {
      id: snetPe.id
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: st.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
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
    registrationEnabled: false
  }
}

resource group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: zone.id
        }
      }
    ]
  }
}
```

```
ana@laptop:~/azure/private-link$ az bicep build --file pe.bicep --stdout | jq -c '.resources[] | {type, name}'
{"type":"Microsoft.Storage/storageAccounts","name":"stshopprod"}
{"type":"Microsoft.Network/privateEndpoints","name":"pe-stshopprod-blob"}
{"type":"Microsoft.Network/privateDnsZones","name":"[format('privatelink.blob.{0}', environment().suffixes.storage)]"}
{"type":"Microsoft.Network/privateDnsZones/virtualNetworkLinks","name":"[format('{0}/{1}', format('privatelink.blob.{0}', environment().suffixes.storage), 'link-vnet-shop-prod')]"}
{"type":"Microsoft.Network/privateEndpoints/privateDnsZoneGroups","name":"[format('{0}/{1}', 'pe-stshopprod-blob', 'default')]"}
```

Five resources, and only two of them are the endpoint:

| resource | what it is |
|---|---|
| `stshopprod` | the account, with **`publicNetworkAccess` set to `Disabled`**: the public road is closed, and only private endpoints reach it |
| `pe-stshopprod-blob` | the endpoint: a subnet, a resource, and one `groupIds` entry |
| the private DNS zone | a zone called `privatelink.blob.core.windows.net`, which the next section explains |
| the virtual network link | what makes `vnet-shop-prod` see that zone |
| `default` under the endpoint | the **zone group**, which tells Azure to write the endpoint's address into the zone and keep it there |

The zone's name came out as an expression, `format('privatelink.blob.{0}', environment().suffixes.storage)`.
That is the file asking Resource Manager which cloud it is in: `core.windows.net` is the storage
suffix of the global Azure, and the sovereign clouds of lesson 1 have suffixes of their own. Write
the name out by hand instead, to see why the file does not:

```sh
sed "s/'privatelink.blob.\${environment().suffixes.storage}'/'privatelink.blob.core.windows.net'/" pe.bicep > hard.bicep
```

```
ana@laptop:~/azure/private-link$ az bicep lint --file hard.bicep
WARNING: /home/ana/azure/private-link/hard.bicep(48,27) : Warning no-hardcoded-env-urls: Environment URLs should not be hardcoded. Use the environment() function to ensure compatibility across clouds. Found this disallowed host: "core.windows.net" [https://aka.ms/bicep/linter-diagnostics#no-hardcoded-env-urls]
```

**A warning, not an error**: the file still compiles, and in the global Azure it would work. The
linter is Bicep's second pass, a set of rules about good practice rather than validity, and
`no-hardcoded-env-urls` is the rule that keeps a template portable between clouds.

## What it costs, and what it does not cover

A service endpoint is free. **A private endpoint is billed for every hour it exists and for every
gigabyte it carries**, in and out, at prices on Microsoft's list, which the machine this course was recorded on could not
read (lesson 1 says why, and gives the program that reads it on yours). For one account
that is small. For a platform where every database, vault and storage service gets three or four
endpoints, in production and in staging, it is a line on the bill worth a budget of its own.

Two settings around it are easy to miss:

- **Network policies on the endpoint's subnet.** Network security groups and route tables did not
  apply to private endpoints when the feature first shipped, and the subnet property
  `privateEndpointNetworkPolicies` is what switches them on. Lessons 17 and 18 are where those
  filters and routes come from; set the property, or they stop at the endpoint's door.
- **Private Link service**, the other half of the name. It is the same mechanism pointed the other
  way: a service of your own behind a Standard load balancer, offered to other networks and other
  tenants as something they can make private endpoints to. Lesson 22 has the load balancer.
- **Front Door Premium**, the global entrance of lesson 22, uses the same mechanism to reach its
  origins: it connects to an origin through Private Link, a connection the origin's owner approves
  like any other, so a web application or a storage account behind it can keep its public access off
  and still be served to the world through the edge.

**Nothing here was created**, and the address `10.20.4.4` is the one Azure's rules say the first
endpoint in that subnet receives, not one this lab was given.
