---
title: The endpoint, the zone and the link
version: 1
---

**A working private endpoint is four resources, and leaving out the last two is the classic mistake.**

```bicep
// sql-private.bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop'
}

resource endpoints 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-private-endpoints'
}

resource sql 'Microsoft.Sql/servers@2023-08-01' existing = {
  name: 'sql-shop'
}

resource pe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-sql-shop'
  location: 'brazilsouth'
  properties: {
    subnet: { id: endpoints.id }
    privateLinkServiceConnections: [
      {
        name: 'sql'
        properties: {
          privateLinkServiceId: sql.id
          groupIds: [ 'sqlServer' ]
        }
      }
    ]
  }
}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: zone
  name: 'vnet-shop'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      { name: 'sql', properties: { privateDnsZoneId: zone.id } }
    ]
  }
}
```

```
ana@laptop:~/azure/private$ bicep build sql-private.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/private$ jq -r '.resources[] | .type' sql-private.json
Microsoft.Network/privateEndpoints
Microsoft.Network/privateDnsZones
Microsoft.Network/privateDnsZones/virtualNetworkLinks
Microsoft.Network/privateEndpoints/privateDnsZoneGroups
ana@laptop:~/azure/private$ jq -r '.resources[] | select(.type == "Microsoft.Network/privateDnsZones") | .name' sql-private.json
[format('privatelink{0}', environment().suffixes.sqlServerHostname)]
```

1. **The private endpoint** is a network interface in `snet-private-endpoints`, connected to the SQL
   server. `groupIds: [ 'sqlServer' ]` names which part of the service it reaches; a storage account would
   say `blob`, a vault `vault`.
2. **The private DNS zone** is named after the service's private-link domain. The name is computed from
   `environment()`, which in Azure's public cloud gives `privatelink.database.windows.net`, so the same file
   works in a sovereign cloud with a different suffix.
3. **The virtual network link** makes the zone answer for queries from `vnet-shop`. Without it, the zone
   exists and nobody in the network uses it.
4. **The zone group** ties the endpoint to the zone, so Azure writes the endpoint's address into the zone,
   and keeps it right if the endpoint changes.

Nothing was deployed, so no address was assigned; an endpoint gets the next free address in its subnet,
such as `10.20.2.4`, an illustrative one here. With all four in place, an application in the network
connects to `sql-shop.database.windows.net` exactly as before, with no change to its connection string,
and the name answers privately.
