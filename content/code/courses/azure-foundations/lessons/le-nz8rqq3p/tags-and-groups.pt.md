---
title: Service tags e application security groups
version: 1
---

**Uma regra escrita com endereços descreve a rede como ela era no dia em que a regra foi escrita.** A
camada web tem duas máquinas hoje, `10.20.1.4` e `10.20.1.5`; no mês que vem tem cinco, e uma regra
que lista dois endereços está errada sem ninguém ter mexido nela. O Azure dá dois jeitos de escrever
uma regra sobre *o que* uma coisa é em vez de *onde* ela está, um para coisas que a Microsoft roda e
um para coisas que você roda.

## Service tags: as listas de endereços da Microsoft, por nome

**Uma service tag é um nome para um conjunto de endereços que a Microsoft mantém**, usado numa regra
no lugar de um endereço. Quatro importam neste curso:

| tag | o que ela representa |
|---|---|
| `VirtualNetwork` | os intervalos da própria rede, as redes com peering com ela, os intervalos de um escritório ligado a ela, e o endereço `168.63.129.16` do host do Azure |
| `AzureLoadBalancer` | `168.63.129.16`, o endereço de onde vêm as sondas de saúde do Azure, e só as sondas |
| `Internet` | tudo o que está fora da rede e é alcançável pela internet pública, incluindo os endereços públicos do próprio Azure |
| `Storage`, `Storage.BrazilSouth` | os endereços públicos do Azure Storage, em todo lugar ou numa região |

A última linha mostra a forma que muitas tags têm: um serviço e, opcionalmente, uma região depois de
um ponto. `Storage.BrazilSouth` deixa as máquinas da loja alcançarem o storage de São Paulo e de
nenhum outro lugar. As tags são atualizadas pela Microsoft à medida que os endereços dela mudam, e
esse é o objetivo delas, e as listas por trás são publicadas como um arquivo JSON e por uma API, para
firewalls fora do Azure que precisem dos mesmos endereços. **`VirtualNetwork` é mais larga do que o
nome**: ela cresce toda vez que uma rede faz peering ou um escritório é ligado, e a última seção desta
lição encontra a consequência de ela conter o endereço do próprio host do Azure.

## Application security groups: as suas máquinas, por papel

**Um application security group, um ASG, é um rótulo que você põe em interfaces de rede**, e uma
regra pode citá-lo como origem ou destino. O `asg-shop-web` guarda as interfaces dos servidores web e o
`asg-shop-app` as da aplicação; uma regra dizendo *de `asg-shop-web` para `asg-shop-app` na 8080*
continua verdadeira por mais máquinas que entrem ou saiam de cada grupo, porque a participação é
definida na interface quando a máquina é construída.

Duas restrições vêm com eles, e as duas são sobre redes: toda interface de um ASG precisa estar na
mesma rede virtual, e uma regra que cita um ASG de cada lado precisa das interfaces dos dois grupos na
mesma rede. Um ASG é um papel dentro de uma rede, não entre redes.

## O NSG da camada de aplicação, em Bicep

Crie o diretório da lição, e salve isto como `~/azure/nsg/nsg.bicep`:

```sh
mkdir -p ~/azure/nsg && cd ~/azure/nsg
```

```bicep
param location string = 'brazilsouth'

resource asgWeb 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'asg-shop-web'
  location: location
}

resource asgApp 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'asg-shop-app'
  location: location
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-shop-app'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebToApp'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [{ id: asgWeb.id }]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [{ id: asgApp.id }]
          destinationPortRange: '8080'
        }
      }
      {
        name: 'AllowLoadBalancerProbe'
        properties: {
          priority: 3900
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyVnetInBound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowStorageOut'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage.BrazilSouth'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyInternetOut'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}
```

Na entrada, ele deixa a camada web entrar na 8080 e fecha a porta da rede inteira do
`AllowVnetInBound` com um deny em 4000; a regra em 3900 é explicada pela última seção. Na saída, ele
permite o storage de São Paulo na 443 e nega o resto da internet, fechando a outra regra padrão. **Os
intervalos entre as prioridades são de propósito**: uma regra necessária numa emergência pode entrar
em 150 ou em 3950 sem renumerar nada. Compile-o num template que a próxima seção lê:

```
ana@laptop:~/azure/nsg$ az bicep build --file nsg.bicep --outfile nsg.json && jq -c '.resources[] | {type, name}' nsg.json
{"type":"Microsoft.Network/applicationSecurityGroups","name":"asg-shop-web"}
{"type":"Microsoft.Network/applicationSecurityGroups","name":"asg-shop-app"}
{"type":"Microsoft.Network/networkSecurityGroups","name":"nsg-shop-app"}
```

Três recursos, e os ASGs vieram primeiro: as regras se referem a eles pelo id, então o Bicep fez o NSG
depender dos dois e os escreveu antes. Prender o NSG à `snet-app` é mais uma linha, uma propriedade
`networkSecurityGroup` com o id dele na sub-rede do `vnet.bicep` da lição 16, e pôr uma interface num
ASG é uma propriedade da interface, definida quando uma máquina é construída, o que este curso não
faz.
