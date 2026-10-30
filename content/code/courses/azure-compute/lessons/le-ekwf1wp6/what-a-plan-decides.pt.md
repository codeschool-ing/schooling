---
title: O que um plano decide, e os cinco que existem
version: 1
---

Os nomes fazem os planos parecerem faixas de preço de um mesmo produto: o Consumption é o barato, o
Premium o caro, o Dedicado algum lugar no meio. **Um plano é a máquina sobre a qual um function app
roda.** Os planos diferem no que essa máquina faz: como as instâncias são acrescentadas e quantas,
se a última é tirada quando ninguém chama, quanto tempo uma função pode rodar e o que o medidor
conta. O preço vem disso. Ele pode sair para um lado ou para o outro, e essa é a conta da última
seção.

Os três nomes do título desta aula também já não são a lista. A documentação da Microsoft, lida em
2026-10-30, dá cinco opções de hospedagem para um function app e chama uma delas de legada:

| | Flex Consumption | Premium | Dedicado | Container Apps | Consumption (legado) |
|---|---|---|---|---|---|
| acrescenta instâncias | por função, por eventos | por app, por eventos, com instâncias pré-aquecidas | à mão ou por autoscale | pelas regras do próprio Container Apps | por app, por eventos |
| máximo de instâncias | 1.000 por grupo de funções, 100 por padrão | Windows 100, Linux de 20 a 100 | de 10 a 30, 100 num ASE | 10 por padrão, até 1.000 | Windows 200, Linux 100 |
| para quando ocioso | sim | não: pelo menos uma instância | não, com Always On | só com um mínimo de zero réplicas | sim |
| timeout, padrão e máximo | 30 min, ilimitado | 30 min, ilimitado | 30 min, ilimitado com Always On | 30 min, ilimitado com uma réplica mantida | 5 min, 10 min |
| você paga | execuções, e memória durante a execução; as instâncias always ready | núcleos e memória de toda instância alocada, as pré-aquecidas inclusive | o plano do App Service | a cobrança do Container Apps | execuções, e memória vezes tempo de execução |
| aceita contêiner | não | Linux | Linux | só contêiner | não |

Duas linhas de letra miúda valem para todos. "Ilimitado" quer dizer que nenhum máximo é imposto, mas
uma execução ainda tem só 60 minutos de tolerância quando a instância dela é tirada na redução de
escala, e 10 minutos durante uma atualização da plataforma. E **uma função HTTP tem 230 segundos
para responder, diga o timeout o que disser.** Esse é o timeout ocioso do balanceador de carga na
frente do app. A documentação manda trabalho mais longo para uma fila ou para o Durable Functions,
que é a aula 17.

## Flex Consumption, o plano serverless de agora

O Flex Consumption é o que a documentação recomenda para um app serverless novo, e é com ele que o
resto desta aula compara. Ele roda só em Linux. **Você escolhe o tamanho de cada instância, entre
três**: 512 MB com um quarto de núcleo, 2.048 MB com um núcleo, ou 4.096 MB com dois, e 2.048 MB é o
padrão documentado para a maioria dos apps. Memória e processador vêm juntos, então uma instância
menor também é mais lenta, e a seção `measuring-it` põe um número nisso.

Ele escala cada função sozinha, com três exceções que escalam em grupo: todas as funções HTTP de um
app juntas, todas as funções de blob que usam o Event Grid, e todas as do Durable Functions. Para a
loja isso quer dizer que `take_order` e o `make_receipt` com trigger de fila da aula 15 ganham
instâncias separadas, então um acúmulo de recibos acrescenta instâncias que nunca respondem a um
cliente. Cada grupo pode crescer até a contagem máxima de instâncias do app, 100 se você não mudar,
e nunca passa de 1.000. Todos os apps Flex de uma assinatura também dividem uma cota regional, de
250 núcleos por padrão.

Ele também se conecta a uma rede virtual, o que o Consumption antigo nunca pôde, e pode manter
instâncias **always ready**: um número de instâncias por grupo que nunca são tiradas, 0 se você não
disser outra coisa. Elas são a resposta do plano à partida a frio, e são cobradas quer alguém chame
quer não.

## Consumption, que é legado

O plano Consumption é o plano serverless original, e a documentação agora diz isso num quadro no
topo da página dele: ele é legado, e apps serverless novos devem usar o Flex Consumption. Em Linux
ele está sendo aposentado. A tabela de hospedagem já marca o Consumption em Linux como aposentado. O
aviso ao lado diz que a opção se aposenta em 30 de setembro de 2028 e não recebe recursos nem
versões de linguagem novas, e que os apps que ainda estavam no runtime versão 3 ali pararam de rodar
depois de 30 de setembro de 2026. O Consumption em Windows não é afetado.

**Para a loja isso resolve a questão.** Python só roda em Linux no Azure Functions, então um app
Python tem exatamente um plano serverless para escolher numa implantação nova: o Flex Consumption.
O Consumption continua nesta aula porque os números dele são os que a maior parte dos artigos sobre
Functions ainda cita, e as partidas a frio dele são as que esses artigos descrevem.

## Premium e Dedicado, que nunca param

O plano Premium se chama Elastic Premium no Resource Manager e tem três tamanhos de instância: EP1
com um núcleo e 3,5 GB, EP2 com dois e 7 GB, EP3 com quatro e 14 GB. Ele escala por eventos como os
planos de consumo. Mas **todo plano Premium sempre tem pelo menos uma instância cobrada**, então
nunca escala a zero. A contagem always ready do app mais exigente do plano é o mínimo do plano, até
20 por app, e um buffer de instâncias pré-aquecidas, uma por padrão, é iniciado à frente da carga
HTTP. Em São Paulo, `brazilsouth`, um plano Premium em Linux escala até 20 instâncias no máximo.
Cuidado com a letra: a documentação avisa que um plano chamado `P1V2` não é Premium e sim um plano
Dedicado, e não escala por eventos de jeito nenhum.

Um plano Dedicado é um plano comum do App Service, Basic, Standard, Premium ou Isolated (Free e
Shared não são suportados), com function apps nele ao lado de web apps. Você paga pelo plano,
quantos apps ele tiver e por mais ociosos que estejam, e o escala à mão ou com regras de autoscale
como o scale set da aula 4. Sem a configuração **Always On**, o runtime fica ocioso depois de
alguns minutos e só um pedido HTTP o acorda, o que deixa um trigger de timer sem rodar, em silêncio.
A aula 18 é sobre esses planos.

A quinta opção, o Container Apps, roda o contêiner do function app como um container app, pelo
parâmetro `--environment` que a aula 15 leu na ajuda do CLI. A escala e a cobrança são as do próprio
Container Apps, da aula 8, e a partida a frio depende de um número: se o mínimo de réplicas é zero.

## Onde a decisão fica escrita

Na linha de comando, o plano é escolhido pelos parâmetros de `az functionapp create`. A ajuda é real
no laptop. Estes são os que pertencem ao Flex Consumption:

```
ana@laptop:~/azure$ az functionapp create --help | grep -E '^    --(flexconsumption-location|instance-memory|maximum-instance-count|always-ready-instances) '
    --always-ready-instances                       : Space-separated configuration for the number of
    --flexconsumption-location -f                  : Geographic location where function app will be
    --instance-memory                              : The instance memory size in MB. See
    --maximum-instance-count                       : The maximum number of instances.
```

Um plano Premium é criado antes, como plano, e o próprio exemplo do CLI faz um EP1 que pode crescer
até dez instâncias:

```
ana@laptop:~/azure$ az functionapp plan create --help | grep -A2 'elastic premium'
    Create an elastic premium app service plan with burst out capability up to 10 instances.
        az functionapp plan create -g MyResourceGroup -n MyPlan --min-instances 1 --max-burst 10
        --sku EP1
```

Nenhum dos dois foi rodado contra o Azure: os dois precisam de uma assinatura. Em Bicep, um plano é
um recurso `Microsoft.Web/serverfarms`, e a tabela da documentação dá o `sku` dele: `FC1` com a
camada `FlexConsumption`, de `EP1` a `EP3` com `ElasticPremium`, um tamanho do App Service como `B1`
para o Dedicado, e `Y1` com `Dynamic` para o Consumption. No Flex, as decisões desta seção ficam no
app, em `functionAppConfig`. Salve isto como `flex.bicep`:

```bicep
// flex.bicep
param location string = 'brazilsouth'
param deployContainer string = 'https://shopfnstore.blob.${environment().suffixes.storage}/deploy'

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'shop-flex'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: 'shop-fn'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: deployContainer
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.12'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 100
        alwaysReady: [
          {
            name: 'http'
            instanceCount: 1
          }
        ]
      }
    }
  }
}
```

Compile, depois troque dois dos números por valores que a documentação exclui, 1.024 MB para uma
instância e 2.000 para o teto, e compile de novo:

```
ana@laptop:~/azure$ bicep build flex.bicep
ana@laptop:~/azure$ sed -i 's/instanceMemoryMB: 2048/instanceMemoryMB: 1024/; s/maximumInstanceCount: 100/maximumInstanceCount: 2000/' flex.bicep
ana@laptop:~/azure$ bicep build flex.bicep
ana@laptop:~/azure$ jq ".resources[1].properties.functionAppConfig.scaleAndConcurrency" flex.json
{
  "instanceMemoryMB": 1024,
  "maximumInstanceCount": 2000,
  "alwaysReady": [
    {
      "name": "http",
      "instanceCount": 1
    }
  ]
}
```

**As duas compilações ficam em silêncio, e o template leva os números errados.** Os tipos de recurso
dizem que `instanceMemoryMB` e `maximumInstanceCount` são números, e foi um número que eles
receberam; quais números o Flex Consumption oferece, 512, 2.048 ou 4.096 MB e no máximo 1.000
instâncias, está escrito na documentação e em lugar nenhum dos tipos. Se o Azure recusaria este
template, e com que mensagem, não dá para descobrir num laptop. Volte os dois valores antes de
seguir. `alwaysReady` é a configuração da partida a frio, uma instância mantida para o grupo `http`,
e é o assunto da próxima seção.
