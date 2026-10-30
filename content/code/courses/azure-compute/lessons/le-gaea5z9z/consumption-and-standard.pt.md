---
title: "Consumption e Standard: dois produtos com um nome só"
version: 1
---

Quando você cria um logic app, escolhe Consumption ou Standard, e a escolha parece um tier:
a mesma coisa, menor ou maior. **São dois produtos que leem a mesma linguagem.** Um logic app
Consumption é um workflow rodando num serviço que todo cliente do Azure divide, cobrado por operação
que executa. Um logic app Standard é uma app da família do Functions, rodando em computação
reservada para ela, com quantos workflows você puser nela, e cobrada por essa computação por hora,
rode alguma coisa ou não. A definição das seções anteriores roda em qualquer um dos dois. Quase tudo
em volta dela muda.

## O que cada um é

| | Consumption | Standard |
| --- | --- | --- |
| roda em | Logic Apps multitenant, dividido por todos os clientes | Logic Apps single-tenant, o runtime como extensão do runtime do Azure Functions |
| o recurso | `Microsoft.Logic/workflows` | `Microsoft.Web/sites`, do kind `workflowapp`, num plano |
| workflows por recurso | um | vários, dividindo a computação da app |
| cobrado por | cada execução de trigger ou ação, depois de uma quantidade inicial grátis das built-in | vCPU e memória do plano, mais cada chamada de conector gerenciado |
| tipos de workflow | stateful | stateful e stateless |
| uma rede virtual | sem acesso direto | integração com VNet, private endpoints |
| num laptop | nada | o runtime, pelo Visual Studio Code |

O resumo da própria documentação para o Consumption é "o mais fácil para começar, pague pelo que
usar, totalmente gerenciado". O Standard troca isso por controle. Ele tem versões built-in de
conectores como Service Bus, Event Hubs e SQL Server, que rodam no mesmo processo do workflow. Tem
um endereço de saída estático próprio, limites maiores de duração de execução e tamanho de
mensagem, e dados que ficam na região em que foram implantados.

## O Standard é uma app num plano

O tipo do recurso diz a que família um produto pertence. Um logic app Standard é declarado do jeito
que a web app da lição 18 é, um plano e um site nele. Salve isto como `~/azure/standard.bicep`:

```bicep
// standard.bicep
param location string = 'brazilsouth'

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'shop-workflows-plan'
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
}

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: 'shop-workflows'
  location: location
  kind: 'functionapp,workflowapp'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        { name: 'APP_KIND', value: 'workflowApp' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'dotnet' }
      ]
    }
  }
}
```

```
ana@laptop:~/azure$ bicep build standard.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, kind, sku}" standard.json
{"type":"Microsoft.Web/serverfarms","kind":null,"sku":{"name":"WS1","tier":"WorkflowStandard"}}
{"type":"Microsoft.Web/sites","kind":"functionapp,workflowapp","sku":null}
```

Compila limpo, e o template não está completo. A documentação lista `AzureWebJobsStorage` como
configuração obrigatória, a connection string de uma conta de armazenamento, exatamente como nas
function apps da lição 15; ela ficou de fora aqui porque precisa de uma conta de armazenamento
declarada ao lado. As outras três configurações são os valores obrigatórios da documentação:
`APP_KIND` é `workflowApp`, e o runtime do worker é `dotnet` para todo logic app Standard. Os
workflows não estão neste template: cada um é uma pasta nos arquivos da app com um `workflow.json`
que guarda o mesmo tipo de definição, implantada como os arquivos de uma function app são.

A CLI traça a mesma linha entre os dois. Os comandos do Standard estão na própria CLI, em
`az logicapp`, e pedem um plano do App Service; os do Consumption estão numa extensão que este lab
nunca adicionou:

```
ana@laptop:~/azure$ az logicapp create --help | grep -A3 -- "--plan -p"
    --plan -p                            : Name or resource id of the logicapp app service plan. Use
                                           'appservice plan create' to get one. If using an App
                                           Service plan from a different resource group, the full
                                           resource id must be used and not the plan name.
ana@laptop:~/azure$ az logic --help 2>&1 | head -1
ERROR: 'logic' is misspelled or not recognized by the system.
```

`az extension add --name logic` a adiciona. Não é executado aqui: todo comando dela precisa de uma
assinatura.

O plano é o preço. **O Workflow Standard tem três tiers, e a documentação dá o tamanho deles**: o
WS1 tem 1 vCPU e 3,5 GB de memória, o WS2 tem 2 e 7 GB, o WS3 tem 4 e 14 GB. O plano é cobrado por
esses recursos rodem os workflows ou não, como o plano Premium da lição 16.

## Stateful e stateless

Um workflow Standard é criado como um de dois tipos. Um workflow **stateful** grava as entradas, as
saídas e o status de cada ação num armazenamento externo, então as execuções podem ser lidas depois
e uma execução interrompida pode ser retomada quando o serviço volta. Um workflow **stateless** os
guarda só em memória. É mais rápido e mais barato, e a documentação dá a ele uma execução de cinco
minutos por padrão contra os 90 dias de um stateful. Ela também lista o que um workflow stateless
não faz: ele só aceita triggers de push, então nada de Recurrence, e não consulta um
`202 Accepted`. Uma execução
interrompida por uma queda se perde, e quem chamou tem que mandar de novo. Todo workflow Consumption
é stateful.

## O histórico de execuções é o depurador

No Azure não há breakpoint nem linha de log sua, então **o registro de uma execução é como se depura
um workflow**. Um workflow stateful guarda uma entrada por execução, com o seu status, e dentro dela
o status, as entradas e as saídas de cada ação, como o Azure as viu. Um `Get_orders` que falhou
mostra a requisição que mandou e a resposta que recebeu; uma ação `Skipped` mostra que algo antes
dela falhou. O trigger tem um histórico próprio, onde uma consulta de polling que não achou nada
fica *Skipped* e não iniciou execução. O Consumption guarda execuções por 90 dias por padrão,
contados do início da execução.

Uma execução terminada pode ser **reenviada** com as mesmas entradas, do começo ou a partir de uma
ação, no portal. A documentação lista as condições: o workflow precisa ser stateful ou ter o
histórico ligado, a nova execução usa a versão da definição que a original usou mesmo que ela tenha
mudado desde então, e uma ação que cria alguma coisa cria de novo. Um workflow stateless não guarda
histórico a menos que ele seja ligado, por um tempo, para depurar.

## A aritmética de uma execução

**O Consumption cobra execuções, então vale contá-las.** As regras da documentação são curtas:

- cada trigger e cada ação que roda é uma execução, a execução do workflow tenha sucesso ou não;
  ações que nunca rodaram porque a execução parou não são cobradas;
- um retry é mais uma execução: uma ação que roda com 5 retries é cobrada como 6;
- um laço é cobrado por item: um `foreach` sobre 10 itens com uma ação dentro é 10 × 1, mais 1
  pelo próprio laço, então 11.

A exportação da manhã da loja é um trigger, `Get_orders`, `Any_orders`, `Export`, `Summary` e
`Send_export`: seis execuções por dia, umas 180 por mês, mais numa manhã em que `Get_orders` precisa
de retry. Seja qual for o preço de uma execução na sua região, 180 delas é o tipo de número para o
qual o Consumption foi feito, e um plano WS1 cobra todas as horas do mês pelos mesmos seis passos.
Os preços estão na página de preços do Azure e na calculadora, e este curso não cita nenhum. A lição
21 mostra como pôr preços reais numa comparação de todas as opções deste curso.
