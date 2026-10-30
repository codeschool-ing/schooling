---
title: No Azure, e quando a abstração compensa
version: 1
---

O Dapr compensa quando o mesmo código precisa encontrar mais de um backend, ou quando vários
serviços em várias linguagens precisam do mesmo encanamento e cada um teria de escrevê-lo. **O que
ele custa é um segundo processo em cada réplica, um salto a mais em cada chamada que passa por ele,
um segundo log para ler e a própria API do Dapr como algo de que você passa a depender.** Um
serviço que fala com um broker que vai manter costuma ser mais bem servido pela biblioteca do
próprio broker. Esta seção declara o componente da loja do jeito que o Container Apps o recebe,
compila, mede os custos no laptop e termina com a decisão. A declaração é compilada; implantá-la é
lido, não executado.

## Um componente pertence ao ambiente

No seu laptop cada sidecar lia um diretório. No Container Apps, **um componente do Dapr é um recurso
do ambiente**, não de um app, e por padrão todo app com Dapr no ambiente carrega todos os
componentes. A lista `scopes` restringe isso aos app ids que devem carregá-lo. São app ids do Dapr,
o `appId` da seção 02, e não os nomes dos container apps, e a documentação da Microsoft diz que você
deve usá-los.

O arquivo tem uma forma um pouco mais curta que a que os seus sidecars liam: sem `apiVersion`, sem
`kind`, e o tipo se chama `componentType`. Aqui está o broker da loja como o Container Apps o
receberia, autenticado com uma managed identity em vez de uma connection string:

```yaml
# pubsub-aca.yaml
componentType: pubsub.azure.servicebus.queues
version: v1
metadata:
- name: namespaceName
  value: shop-sb.servicebus.windows.net
- name: azureClientId
  value: 00000000-0000-0000-0000-000000000000
scopes:
- shop
- billing
```

`namespaceName` é o nome de host completo do namespace, que o Dapr pede sempre que se autentica com
o Microsoft Entra ID em vez de uma chave. `azureClientId` é o client id de uma managed identity
atribuída pelo usuário, e a documentação da Microsoft diz que ele é obrigatório sempre que o
componente se autentica com uma. Os zeros são um marcador. **Com uma managed identity não há segredo
nenhum no componente**, e é por isso que a Microsoft a recomenda para todo serviço do Azure que a
suporte; a identidade ainda precisa de um papel no namespace, como as lições 8 e 9 de
`azure-foundations` configuram para qualquer identidade. Para um serviço que não consegue se
autenticar assim, o componente nomeia um armazenamento de segredos, como o Key Vault, que a lição 17
de `azure-operations` cobre. Entregar o arquivo a um ambiente é um comando, e ele encontra a recusa
de sempre neste curso:

```
ana@laptop:~/azure$ az containerapp env dapr-component set --resource-group shop --name shop-env --dapr-component-name pubsub --yaml pubsub-aca.yaml
ERROR: Please run 'az login' to setup account.
```

O mesmo componente em Bicep é um filho do ambiente, `daprComponents`. Este arquivo o declara ao lado
da identidade, e ao lado do billing como um container app com o Dapr ligado. Salve como
`~/azure/dapr.bicep`:

```bicep
// dapr.bicep
param location string = 'brazilsouth'

resource env 'Microsoft.App/managedEnvironments@2026-01-01' existing = {
  name: 'shop-env'
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'shop-dapr'
  location: location
}

resource pubsub 'Microsoft.App/managedEnvironments/daprComponents@2026-01-01' = {
  parent: env
  name: 'pubsub'
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      { name: 'namespaceName', value: 'shop-sb.servicebus.windows.net' }
      { name: 'azureClientId', value: identity.properties.clientId }
    ]
    scopes: [
      'shop'
      'billing'
    ]
  }
}

resource billing 'Microsoft.App/containerApps@2026-01-01' = {
  name: 'billing'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    environmentId: env.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'billing'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'billing'
          image: 'shopregistry.azurecr.io/billing:1.0'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}
```

`existing` se refere ao ambiente que a lição 8 declarou, `shop-env`, sem declará-lo de novo. O
componente tira o client id da própria identidade, então os dois não podem se desencontrar. O
bloco `dapr` são as quatro configurações da seção 02. `minReplicas: 1` está ali por um motivo do
Dapr: **um assinante escalado a zero não tem sidecar rodando para receber mensagens**, então ele ou
mantém uma réplica ou ganha uma regra de escala pelo tamanho da fila, que é como a lição 8 escalou
por qualquer coisa que não seja HTTP. O compilador confere e depois mostra que os scopes chegaram ao
template:

```
ana@laptop:~/azure$ bicep build dapr.bicep
ana@laptop:~/azure$ jq '.resources[] | select(.type | endswith("daprComponents")) | .properties.scopes' dapr.json
[
  "shop",
  "billing"
]
```

Silêncio é aprovação. Dois erros, e o que o compilador faz de cada um:

```
ana@laptop:~/azure$ sed 's/appId:/appID:/' dapr.bicep > typo.bicep; bicep build typo.bicep
/home/ana/azure/typo.bicep(44,9) : Warning BCP089: The property "appID" is not allowed on objects of type "Dapr". Did you mean "appId"? [https://aka.ms/bicep/core-diagnostics#BCP089]
ana@laptop:~/azure$ sed 's/servicebus.queues/servicebus.queue/' dapr.bicep > queue.bicep; bicep build queue.bicep; ls queue.*
queue.bicep
queue.json
```

`appID` é recusado, com o nome certo sugerido, porque o compilador conhece as propriedades do bloco
`dapr`. O singular `pubsub.azure.servicebus.queue` compilou sem uma palavra: `componentType` é uma
string qualquer, e o compilador não tem como saber para quais strings o Dapr tem componente. O
sidecar tem, e não inicia:

```
ana@laptop:~/azure$ mkdir typo
ana@laptop:~/azure$ sed 's/servicebus.queues/servicebus.queue/' components-sb/pubsub.yaml > typo/pubsub.yaml
ana@laptop:~/azure$ docker run --rm --network shop-net -v ~/azure/typo:/components daprio/daprd:1.17.16 ./daprd --app-id typo --resources-path /components 2>&1 | grep -o 'level=fatal msg="[^"]*'
level=fatal msg="Fatal error from runtime: process component pubsub error: [INIT_COMPONENT_FAILURE]: initialization error occurred for pubsub (pubsub.azure.servicebus.queue/v1): [CREATE_COMPONENT_FAILURE]: initialization error occurred for pubsub (pubsub.azure.servicebus.queue/v1): couldn't find message bus pubsub.azure.servicebus.queue/v1
```

Esse é o `daprd` 1.17.16 de código aberto recusando o nome. **Escreva o tipo exatamente como a
referência do próprio Dapr o escreve.** O singular merece o aviso porque a página da própria
Microsoft sobre componentes do Dapr no Container Apps o usa no exemplo, e essa página não diz se a
build do Azure o aceita.

O que um componente pode nomear é mais estreito no Container Apps do que no Dapr. A documentação da
Microsoft suporta só os componentes que lista como Tier 1, com suporte completo, e Tier 2, com
suporte em regime de melhor esforço; leia essa lista antes de desenhar algo em torno de um
componente.

## O que custa

Os sidecars ainda estão rodando, então meça dois dos custos no laptop. Primeiro a memória, com o
total que o `docker stats` imprime depois da barra cortado fora:

```
ana@laptop:~/azure$ docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' shop shop-dapr billing billing-dapr | cut -d/ -f1
shop 14.02MiB 
shop-dapr 23.85MiB 
billing 13.98MiB 
billing-dapr 23.96MiB 
```

Cada sidecar ocupa mais memória que o programa que ele serve. Esses são os números do laptop, para
um programa de cinquenta linhas, e a documentação não diz quanto da CPU e da memória de uma réplica
o sidecar ocupa no Container Apps, então não os leve para lá. O que vale lá também é o formato:
**toda réplica de todo app com Dapr carrega um segundo processo**, e ao lado de um programa pequeno
ele pode ser o maior dos dois.

Depois o salto. O primeiro laço pede `/healthz` direto à loja, duzentas vezes, e imprime a média; o
segundo pede ao próprio sidecar da loja que chame a mesma página, que é a invocação de serviço do
Dapr:

```
ana@laptop:~/azure$ for i in $(seq 200); do curl -s -o /dev/null -w '%{time_total}\n' localhost:8080/healthz; done | awk '{s += $1} END {printf "%.2f ms\n", s / NR * 1000}'
3.07 ms
ana@laptop:~/azure$ for i in $(seq 200); do curl -s -o /dev/null -w '%{time_total}\n' localhost:3500/v1.0/invoke/shop/method/healthz; done | awk '{s += $1} END {printf "%.2f ms\n", s / NR * 1000}'
5.14 ms
```

A diferença é o que custa uma passagem por um sidecar, em loopback, neste laptop; os números mudam
entre execuções. Entre dois apps no Container Apps uma invocação de serviço passa por dois
sidecars, o de quem chama e o de quem é chamado, e em troca cada chamada ganha descoberta pelo app
id e uma criptografia que o Container Apps gerencia.

Os outros dois custos não aparecem numa medição. **Há uma segunda coisa para depurar.** O 500 da
seção 04 era do sidecar; o log da loja nunca o mencionou, e uma assinatura que não iniciasse só
apareceria no log do sidecar do assinante. Toda réplica agora tem dois logs, e um problema pode
estar em qualquer um. E **você depende da API do Dapr**, não só da do broker: os caminhos `/v1.0/`,
o envelope CloudEvent e o arranjo `shop||order-1` no Redis, que um programa que leia esse
armazenamento sem o Dapr precisa conhecer. No Container Apps essa API é atualizada sem você pedir, no
calendário da Microsoft. Um recurso que o broker tem e o building block não nomeia, como as sessões
do Service Bus, é alcançado por metadados do componente, quando é, e cada uso desses amarra o
código de volta a um broker.

## Quando compensa

A loja dá um caso para cada lado. Billing e audit rodam no Redis no laptop de cada desenvolvedor e
no Service Bus no Azure; a diferença é um arquivo por ambiente, com o tipo de componente certo
dentro, e o código é testado do mesmo jeito nos dois lugares. Isso compensa. Compensa também para
uma segunda equipe escrevendo em outra linguagem, que ganha a mesma API de estado e pub/sub sem
aprender um segundo SDK. Uma API de pedidos que só vai falar com um namespace do Service Bus ganha
um processo e um salto e perde o uso direto do broker; a biblioteca `azure-servicebus` da lição 20
a serve melhor. A lição 22 é sobre costuras portáveis em geral, e esta é um tipo delas.

Antes de seguir, remova tudo o que esta lição iniciou:

```
ana@laptop:~/azure$ docker rm -f shop shop-dapr billing billing-dapr audit audit-dapr redis servicebus mssql > /dev/null
ana@laptop:~/azure$ docker network rm shop-net
shop-net
```
