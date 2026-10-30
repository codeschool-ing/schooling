---
title: O endpoint, a zona e o link
version: 1
---

**Um private endpoint que funciona são quatro recursos, e deixar de fora os dois últimos é o erro clássico.**

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

1. **O private endpoint** é uma interface de rede em `snet-private-endpoints`, conectada ao servidor SQL. `groupIds: [
   'sqlServer' ]` diz qual parte do serviço ele alcança; uma conta de armazenamento diria `blob`, um cofre `vault`.
2. **A zona DNS privada** leva o nome do domínio de private link do serviço. O nome é calculado a partir de `environment()`, que
   na nuvem pública do Azure dá `privatelink.database.windows.net`, então o mesmo arquivo funciona numa nuvem soberana com outro
   sufixo.
3. **O link com a rede virtual** faz a zona responder às consultas vindas de `vnet-shop`. Sem ele, a zona existe e ninguém na rede
   a usa.
4. **O zone group** amarra o endpoint à zona, para o Azure escrever o endereço do endpoint na zona, e mantê-lo certo se o endpoint
   mudar.

Nada foi implantado, então nenhum endereço foi atribuído; um endpoint ganha o próximo endereço livre da sub-rede, como
`10.20.2.4`, aqui ilustrativo. Com os quatro no lugar, uma aplicação na rede se conecta a `sql-shop.database.windows.net`
exatamente como antes, sem mudar a connection string, e o nome responde de forma privada.
