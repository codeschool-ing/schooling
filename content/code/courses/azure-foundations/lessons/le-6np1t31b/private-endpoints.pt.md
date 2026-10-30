---
title: Um private endpoint, e do que ele é feito
version: 1
---

**Um private endpoint é uma interface de rede na sua sub-rede que representa uma parte de um
recurso.** Não uma storage account em geral: o serviço de blob da `stshopprod`, e nada mais. O Azure
dá à interface um endereço da sub-rede, a liga pelo **Azure Private Link** ao serviço do lado da
Microsoft, e a partir daí um pacote mandado para aquele endereço chega à conta como se a conta morasse
na sub-rede.

Três coisas o compõem, e cada uma é uma propriedade no arquivo abaixo:

- **a sub-rede onde ele fica.** A loja guarda todos os private endpoints na `snet-pe`,
  `10.20.4.0/24`, para que os endereços dos serviços da plataforma sejam uma faixa que uma regra de
  firewall ou uma rota consegue citar. A interface pega o próximo endereço livre, e o Azure reserva os
  quatro primeiros e o último de toda sub-rede, então o primeiro endpoint ali recebe `10.20.4.4`;
- **o recurso e o sub-recurso.** `privateLinkServiceId` é o id da conta e `groupIds` diz qual dos
  serviços dela: `blob`, `file`, `queue`, `table`, `dfs`. Um segundo serviço da mesma conta é um
  segundo private endpoint;
- **a aprovação da conexão.** Um endpoint pede ao dono do recurso que o aceite. Quando quem o cria
  também tem permissão no recurso, o pedido é aprovado na hora; senão ele espera no estado *Pending*
  até o dono aprová-lo, que é como o tenant de um parceiro pode receber um caminho privado até uma das
  contas da loja sem receber mais nada.

## O endpoint e a sua zona, em Bicep

Salve isto como `pe.bicep` em `~/azure/private-link`:

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

Cinco recursos, e só dois deles são o endpoint:

| recurso | o que é |
|---|---|
| `stshopprod` | a conta, com **`publicNetworkAccess` em `Disabled`**: o caminho público está fechado, e só private endpoints chegam a ela |
| `pe-stshopprod-blob` | o endpoint: uma sub-rede, um recurso, e uma entrada em `groupIds` |
| a zona de DNS privada | uma zona chamada `privatelink.blob.core.windows.net`, que a próxima seção explica |
| o link de rede virtual | o que faz a `vnet-shop-prod` enxergar essa zona |
| `default` debaixo do endpoint | o **zone group**, que manda o Azure escrever o endereço do endpoint na zona e mantê-lo lá |

O nome da zona saiu como uma expressão, `format('privatelink.blob.{0}', environment().suffixes.storage)`.
É o arquivo perguntando ao Resource Manager em qual nuvem ele está: `core.windows.net` é o sufixo de
storage do Azure global, e as nuvens soberanas da lição 1 têm sufixos próprios. Escreva o nome à mão,
para ver por que o arquivo não faz isso:

```sh
sed "s/'privatelink.blob.\${environment().suffixes.storage}'/'privatelink.blob.core.windows.net'/" pe.bicep > hard.bicep
```

```
ana@laptop:~/azure/private-link$ az bicep lint --file hard.bicep
WARNING: /home/ana/azure/private-link/hard.bicep(48,27) : Warning no-hardcoded-env-urls: Environment URLs should not be hardcoded. Use the environment() function to ensure compatibility across clouds. Found this disallowed host: "core.windows.net" [https://aka.ms/bicep/linter-diagnostics#no-hardcoded-env-urls]
```

**Um aviso, não um erro**: o arquivo ainda compila, e no Azure global funcionaria. O linter é a
segunda passada do Bicep, um conjunto de regras de boa prática em vez de validade, e
`no-hardcoded-env-urls` é a regra que mantém um template portável entre nuvens.

## O que custa, e o que não cobre

Um service endpoint é gratuito. **Um private endpoint é cobrado por cada hora em que existe e por cada
gigabyte que carrega**, na entrada e na saída, a preços da lista da Microsoft, que a máquina onde este
curso foi gravado não conseguiu ler (a lição 1 diz por quê, e dá o programa que a lê na sua). Para uma
conta é pouco. Para uma plataforma em que cada banco, cofre e serviço de storage ganha três ou quatro
endpoints, em produção e em staging, é uma linha da fatura que merece um orçamento próprio.

Duas configurações em volta dele passam despercebidas com facilidade:

- **Políticas de rede na sub-rede do endpoint.** Network security groups e tabelas de rotas não se
  aplicavam a private endpoints quando o recurso saiu, e a propriedade da sub-rede
  `privateEndpointNetworkPolicies` é o que os liga. As lições 17 e 18 são de onde vêm esses filtros e
  rotas; ligue a propriedade, ou eles param na porta do endpoint.
- **Private Link service**, a outra metade do nome. É o mesmo mecanismo apontado para o outro lado: um
  serviço seu atrás de um load balancer Standard, oferecido a outras redes e a outros tenants como algo
  para o qual eles podem criar private endpoints. A lição 22 tem o load balancer.

**Nada aqui foi criado**, e o endereço `10.20.4.4` é o que as regras do Azure dizem que o primeiro
endpoint daquela sub-rede recebe, não um que este laboratório recebeu.
