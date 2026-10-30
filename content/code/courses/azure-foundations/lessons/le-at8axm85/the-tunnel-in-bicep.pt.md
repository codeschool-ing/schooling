---
title: O túnel, escrito em Bicep
version: 1
---

**Uma VPN site a site no Azure são quatro recursos, e só um deles é o túnel.** O gateway é a ponta do
Azure. Um **local network gateway** é a descrição, pelo Azure, da *sua* ponta: o endereço público do
firewall do escritório e o que fica atrás dele. Uma **conexão** junta os dois e carrega o segredo
compartilhado. E o gateway precisa da sua sub-rede e dos seus endereços públicos antes de tudo isso.

Crie o diretório da lição:

```sh
mkdir -p ~/azure/hybrid && cd ~/azure/hybrid
```

Salve isto como `vpn.bicep`. Ele acrescenta a sub-rede do gateway à rede hub, que já existe, e monta o
resto:

```bicep
param location string = resourceGroup().location

@secure()
@description('The pre-shared key both ends of the tunnel agree on. Given at deployment, never written here.')
param sharedKey string

resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-hub'
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: hub
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: '10.0.255.0/27'
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for n in [1, 2]: {
  name: 'pip-vpng-shop-${n}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource vpng 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: 'vpng-shop'
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    activeActive: true
    enableBgp: true
    bgpSettings: {
      asn: 65515
    }
    ipConfigurations: [for n in [0, 1]: {
      name: 'ipconfig${n + 1}'
      properties: {
        subnet: {
          id: gatewaySubnet.id
        }
        publicIPAddress: {
          id: pip[n].id
        }
      }
    }]
  }
}

resource office 'Microsoft.Network/localNetworkGateways@2024-05-01' = {
  name: 'lgw-shop-office'
  location: location
  properties: {
    gatewayIpAddress: '203.0.113.10'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.255.1/32'
      ]
    }
    bgpSettings: {
      asn: 65010
      bgpPeeringAddress: '192.168.255.1'
    }
  }
}

resource connection 'Microsoft.Network/connections@2024-05-01' = {
  name: 'cn-shop-office'
  location: location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpng.id
      properties: {}
    }
    localNetworkGateway2: {
      id: office.id
      properties: {}
    }
    sharedKey: sharedKey
    enableBgp: true
  }
}
```

Cinco coisas nele valem uma frase cada.

- **`existing`** cita um recurso sem criá-lo: a rede hub foi montada em outra lição, e este arquivo só
  precisa pendurar uma sub-rede debaixo dela. O nome da sub-rede é `GatewaySubnet`, exatamente.
- **`[for n in [1, 2]: ...]`** faz dois endereços públicos a partir de um bloco, `pip-vpng-shop-1` e
  `pip-vpng-shop-2`, e `pip[n].id` os pega de novo nas duas `ipConfigurations` do gateway. Dois
  endereços porque `activeActive` é `true`.
- **`asn: 65515`** é o número BGP do gateway. É o número que o Azure dá por padrão a um VPN gateway, e o
  firewall do escritório usa um número privado próprio, `65010`, no local network gateway.
- **`localNetworkAddressSpace` guarda um `/32`**, o endereço que o firewall do escritório usa para o BGP,
  e não o `192.168.0.0/16` do escritório. Com o BGP ligado, o firewall diz ao Azure quais redes estão
  atrás dele, e a única rota que o Azure precisa saber de antemão é a que alcança a sessão BGP do
  firewall.
- **`sharedKey` é um parâmetro marcado com `@secure()`**, sem valor padrão. O valor dele é dado quando o
  arquivo é implantado, e o template nunca o carrega.

Compile e leia o que o template diz sobre os seus parâmetros e recursos:

```
ana@laptop:~/azure/hybrid$ az bicep build --file vpn.bicep --stdout | jq -c '.parameters, [.resources[] | {type, name}]'
{"location":{"type":"string","defaultValue":"[resourceGroup().location]"},"sharedKey":{"type":"securestring","metadata":{"description":"The pre-shared key both ends of the tunnel agree on. Given at deployment, never written here."}}}
[{"type":"Microsoft.Network/virtualNetworks/subnets","name":"[format('{0}/{1}', 'vnet-shop-hub', 'GatewaySubnet')]"},{"type":"Microsoft.Network/publicIPAddresses","name":"[format('pip-vpng-shop-{0}', createArray(1, 2)[copyIndex()])]"},{"type":"Microsoft.Network/virtualNetworkGateways","name":"vpng-shop"},{"type":"Microsoft.Network/localNetworkGateways","name":"lgw-shop-office"},{"type":"Microsoft.Network/connections","name":"cn-shop-office"}]
```

**O `sharedKey` virou um `securestring`**, que o Resource Manager mantém fora do histórico da
implantação e dos logs dela. Os dois endereços são um recurso com um `copyIndex()` no nome, um laço que o
template carrega para o Resource Manager desenrolar.

## O erro que o compilador pega

Uma chave compartilhada é uma senha que as duas pontas do túnel guardam. O erro conveniente é escrevê-la
no arquivo, para uma implantação não precisar de argumento a mais. Cometa esse erro de propósito, numa
cópia:

```sh
sed 's/^param sharedKey string$/param sharedKey string = '"'"'office-tunnel-2026'"'"'/' vpn.bicep > leaky.bicep
```

```
ana@laptop:~/azure/hybrid$ az bicep build --file leaky.bicep --stdout > /dev/null
WARNING: /home/ana/azure/hybrid/leaky.bicep(5,24) : Warning secure-parameter-default: Secure parameters should not have hardcoded defaults (except for empty or newGuid()). [https://aka.ms/bicep/linter-diagnostics#secure-parameter-default]
```

**O arquivo ainda compilou, e o linter reclamou**: `secure-parameter-default` diz que um parâmetro
seguro não pode trazer um valor escrito, porque esse valor agora está no arquivo, no repositório onde ele
for gravado e em toda cópia dos dois. É um aviso e não um erro, então nada impede uma implantação; um
pipeline que trata os avisos do Bicep como falhas é como uma equipe impede. Apague a cópia com
`rm leaky.bicep`.

**Implantar o `vpn.bicep` não foi executado**: como todo recurso deste curso, ele precisa do Resource
Manager, e aqui precisaria também de um firewall de verdade em `203.0.113.10`, um endereço de uma faixa
reservada para documentação, para responder.

## BGP, num parágrafo e numa regra

Sem BGP, cada lado guarda uma lista estática das redes do outro, digitada por alguém, e uma rede
acrescentada no escritório fica inalcançável a partir do Azure até alguém digitá-la de novo do lado do
Azure. **Com BGP, as duas pontas contam uma à outra o que alcançam**, continuam contando a cada poucos
segundos, e retiram uma rota no momento em que o túnel dela morre. É isso que torna viáveis vários túneis
ao mesmo tempo: cada lado sempre sabe quais túneis estão vivos. A única regra que o BGP acrescenta é
sobre números: as duas pontas precisam de **números de sistema autônomo diferentes**, e uma rede privada
os tira da faixa privada, e é por isso que o escritório é `65010` e o Azure fica com o seu `65515`.
