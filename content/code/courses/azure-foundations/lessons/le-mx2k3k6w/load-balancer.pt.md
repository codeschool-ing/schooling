---
title: Um Standard Load Balancer com front end redundante entre zonas
version: 1
---

**Um load balancer são quatro listas, e a regra é a que junta as outras três.** Um front end diz onde
o tráfego chega, um backend pool diz para onde ele pode ir, uma probe diz quais membros do pool estão
aptos, e uma regra diz: o tráfego que chega a este front end nesta porta vai para este pool naquela
porta, enquanto a probe disser que sim. Todo o resto é detalhe, e a maior parte está na regra.

Crie o diretório da lição:

```sh
mkdir -p ~/azure/balancing && cd ~/azure/balancing
```

Salve isto como `lb.bicep`. É o load balancer público da loja, na frente da camada web, com um
endereço público que os clientes alcançam na porta 443:

```bicep
param location string = resourceGroup().location

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-shop-web'
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
}

resource lb 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'lb-shop-web'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fe-web'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'be-web'
      }
    ]
    probes: [
      {
        name: 'probe-http'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/healthz'
          intervalInSeconds: 5
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rule-https'
        properties: {
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb-shop-web', 'fe-web')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb-shop-web', 'be-web')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb-shop-web', 'probe-http')
          }
          disableOutboundSnat: true
        }
      }
    ]
  }
}
```

Leia-o como as quatro listas. `frontendIPConfigurations` tem um front end, `fe-web`, cujo endereço é o
IP público `pip-shop-web` declarado acima dele. `backendAddressPools` tem um pool vazio, `be-web`: as
máquinas da camada web entram nele pelo lado delas, pelas suas interfaces de rede, que é como o Azure
liga uma máquina a um pool. `probes` tem a `probe-http`, que pede `/healthz` por HTTP a cada membro a
cada cinco segundos. E `loadBalancingRules` tem a regra que cita um de cada, pelo id dentro do load
balancer.

Compile e pergunte ao template o que cada recurso diz sobre zonas:

```
ana@laptop:~/azure/balancing$ az bicep build --file lb.bicep --stdout | jq -c '.resources[] | {type, name, zones, sku: .sku.name}'
{"type":"Microsoft.Network/publicIPAddresses","name":"pip-shop-web","zones":["1","2","3"],"sku":"Standard"}
{"type":"Microsoft.Network/loadBalancers","name":"lb-shop-web","zones":null,"sku":"Standard"}
```

## Onde estão as zonas

**O load balancer não tem zonas próprias, e o front end dele é redundante entre zonas mesmo
assim.** As `zones` do load balancer voltaram `null`, e o endereço público carrega as três. No Azure,
o front end de um load balancer Standard herda o comportamento de zona do endereço que usa. Um
endereço nas zonas 1, 2 e 3 é **redundante entre zonas**, servido pelas três, e sobrevive à perda de
qualquer uma. Um endereço numa zona só é **zonal**, e cai junto com ela. O próprio load balancer é uma
peça regional da rede do Azure, não uma máquina sentada numa zona, e é por isso que ele não tem nada a
dizer sobre o assunto.

O pool é a outra metade. Um front end redundante entre zonas na frente de três máquinas todas na zona
1 mudou o ponto único de falha de lugar sem removê-lo. **O front end sobrevive a uma zona; o serviço
só sobrevive se o pool também sobreviver**, o que quer dizer máquinas em pelo menos duas zonas, e uma
probe que percebe quando as máquinas de uma zona param de responder.

## O que a regra esconde

Duas configurações da regra parecem detalhe e decidem comportamento:

- **`disableOutboundSnat: true`** impede que as máquinas do pool usem o endereço deste front end nas
  conexões que *elas* abrem para a internet. A Microsoft recomenda exatamente isso, e dá ao tráfego de
  saída um caminho próprio: um NAT gateway na sub-rede, ou uma regra de saída. Sem isso, um pool
  ocupado fica sem portas de origem num único endereço compartilhado, e as conexões de saída começam a
  falhar de um jeito que parece defeito do serviço remoto.
- **Nenhuma persistência de sessão** está definida, então vale o padrão: cada fluxo novo é posto pelo
  hash da sua quíntupla. Um usuário que abre duas conexões pode chegar a duas máquinas. Uma aplicação
  que guarda a sessão na memória de uma máquina precisa de uma persistência por IP do cliente ou,
  melhor, de uma sessão que more em outro lugar.

**O compilador conferiu o formato e nada mais.** Que `Standard` é um SKU que a região vende, que um
endereço público com `zones` é permitido em `brazilsouth`, que o caminho da probe existe nas máquinas:
cada um é um fato sobre o Azure, e só uma implantação descobriria. Implantar o arquivo seria
`az deployment group create --resource-group rg-shop-prod --template-file lb.bicep`, e **isso não foi
executado**, pelo motivo que toda lição dá: é um pedido ao Resource Manager.

## Um interno, e um Application Gateway, em palavras

O load balancer interno na frente da camada de aplicação é o mesmo arquivo com uma mudança: o front end
recebe um endereço privado da `snet-app` em vez de um IP público, por um `subnet` e um
`privateIPAddress` no lugar de `publicIPAddress`. Todo o resto, o pool, a probe, a regra, é idêntico,
e essa é a graça das quatro listas.

Um Application Gateway em Bicep é mais longo, porque um proxy reverso tem mais listas: listeners para
cada nome de host e porta, configurações HTTP de como ele fala com os backends, regras de roteamento
que ligam um listener a um pool, e um URL path map quando `/api/` vai para outro lugar. Ele é
implantado na `snet-agw` e nada mais pode dividir essa sub-rede. Esta lição o deixa em palavras; o
formato é a mesma ideia, em maior quantidade.
