---
title: "A definição do workflow: um documento JSON por trás do designer"
version: 1
---

O Logic Apps é vendido como integração sem código, e a primeira coisa que qualquer pessoa vê dele é
um designer: uma tela no portal onde um relógio, uma chamada HTTP e uma condição são caixas ligadas
por setas. Isso faz parecer que o desenho é o programa. **O desenho é uma vista de um documento
JSON, e o documento é o workflow.** O designer o edita, a code view do portal o mostra, e o Azure o
executa. A documentação da Microsoft o chama de *definição do workflow* e diz que ele é validado
contra o schema da **Workflow Definition Language**, WDL para encurtar.

Então um workflow pode ser escrito sem o designer, guardado num arquivo e implantado como qualquer
outro recurso, que é como esta seção escreve um. Nada do Logic Apps roda num laptop: o que roda aqui
é o compilador Bicep, e a seção termina com o que ele verifica e o que não verifica.

## A forma de uma definição

Uma definição é um objeto com poucas chaves. `triggers` guarda o que inicia uma execução, e um
workflow tem pelo menos um. `actions` guarda os passos, cada um com um nome. `parameters` declara
valores que a definição lê em tempo de execução, e `outputs` declara o que uma execução devolve.
`$schema` e `contentVersion` dão a versão da linguagem e a da própria definição. A referência do
schema dá limites para alguns deles: no máximo 10 triggers, 50 parâmetros e 10 outputs.

Uma ação tem um `type`, os seus `inputs` e um `runAfter` que diz quais ações precisam terminar
antes, e com quais status. **A ordem da execução está escrita no `runAfter`, não na ordem do
arquivo**: um objeto JSON não tem ordem, e o motor não inventa uma.

## A exportação da manhã da loja

O financeiro da loja quer os pedidos na caixa de entrada toda manhã às seis. A primeira metade desse
workflow chama a API de pedidos da loja, `GET /orders`, confere que ela respondeu com alguma coisa e
transforma a resposta em CSV. Mandar o e-mail precisa de um conector, que é a próxima seção. Salve
isto como `~/azure/daily-orders.bicep`:

```schooling-example
{"language": "bicep", "file": "daily-orders.bicep", "parts": [{"code": "// daily-orders.bicep\nparam location string = 'brazilsouth'\nparam shopUrl string = 'https://shop.example.com'\n\nresource dailyOrders 'Microsoft.Logic/workflows@2019-05-01' = {\n  name: 'shop-daily-orders'\n  location: location\n  properties: {\n    state: 'Enabled'\n    parameters: {\n      shopUrl: {\n        value: shopUrl\n      }\n    }\n", "note": "Um logic app Consumption é um recurso do tipo `Microsoft.Logic/workflows`, e guarda um workflow. `properties.parameters` preenche os parâmetros do próprio workflow no deploy: aqui o parâmetro `shopUrl` do Bicep vira o parâmetro de mesmo nome do workflow."}, {"code": "    definition: {\n      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'\n      contentVersion: '1.0.0.0'\n      parameters: {\n        shopUrl: {\n          type: 'String'\n          defaultValue: ''\n        }\n      }\n", "note": "Tudo o que está sob `definition` é o documento em Workflow Definition Language, o que o designer desenha. Os `parameters` dele são declarados aqui e lidos em tempo de execução com `parameters('shopUrl')`, e assim o endereço da loja não fica escrito no workflow."}, {"code": "      triggers: {\n        Every_morning: {\n          type: 'Recurrence'\n          recurrence: {\n            frequency: 'Day'\n            interval: 1\n            startTime: '2026-11-02T06:00:00'\n            timeZone: 'E. South America Standard Time'\n            schedule: {\n              hours: [6]\n              minutes: [0]\n            }\n          }\n        }\n      }\n", "note": "O trigger. `frequency` e `interval` dizem uma vez por dia; `schedule` fixa às 06:00, e `timeZone`, o nome Windows do horário de Brasília, faz disso seis horas em São Paulo e não em UTC. Um fuso só vale junto com um `startTime`."}, {"code": "      actions: {\n        Get_orders: {\n          type: 'Http'\n          runAfter: {}\n          inputs: {\n            method: 'GET'\n            uri: '@{parameters(\\'shopUrl\\')}/orders'\n            retryPolicy: {\n              type: 'fixed'\n              count: 3\n              interval: 'PT1M'\n            }\n          }\n        }\n", "note": "Uma ação HTTP, o `GET /orders` da loja. Um `runAfter` vazio faz dela a primeira ação. `@{...}` põe o valor de uma expressão dentro de uma string. A política de retry tenta mais três vezes, com um minuto entre elas, depois de um 408, um 429, um 5xx ou uma conexão perdida, o bastante para a API voltar de um deploy."}, {"code": "        Any_orders: {\n          type: 'If'\n          runAfter: {\n            Get_orders: ['Succeeded']\n          }\n          expression: {\n            and: [\n              {\n                greater: ['@length(body(\\'Get_orders\\'))', 0]\n              }\n            ]\n          }\n", "note": "Uma condição é uma ação do tipo `If`. Ela roda quando `Get_orders` termina em `Succeeded`, e a sua `expression` é uma árvore: `and` de um teste, `greater` do tamanho do corpo da resposta e zero."}, {"code": "          actions: {\n            Export: {\n              type: 'Table'\n              runAfter: {}\n              inputs: {\n                format: 'CSV'\n                from: '@body(\\'Get_orders\\')'\n              }\n            }\n            Summary: {\n              type: 'Compose'\n              runAfter: {\n                Export: ['Succeeded']\n              }\n              inputs: {\n                day: '@{formatDateTime(convertFromUtc(utcNow(), \\'E. South America Standard Time\\'), \\'yyyy-MM-dd\\')}'\n                orders: '@length(body(\\'Get_orders\\'))'\n                csv: '@body(\\'Export\\')'\n              }\n            }\n          }\n", "note": "O ramo verdadeiro. `Export` transforma o array de pedidos em CSV, uma coluna para cada propriedade de um pedido. `Summary` é um Compose: monta um valor, o dia em São Paulo, a contagem e o CSV, e não faz mais nada. Dentro de um ramo, um `runAfter` vazio quer dizer primeira do ramo."}, {"code": "          else: {\n            actions: {\n              No_orders: {\n                type: 'Compose'\n                runAfter: {}\n                inputs: 'no orders to send'\n              }\n            }\n          }\n        }\n      }\n      outputs: {}\n    }\n  }\n}\n", "note": "O ramo falso tem um único Compose, para que uma execução num dia sem pedidos diga isso no histórico em vez de terminar sem nada para mostrar. `outputs` está vazio: este workflow não devolve nada a ninguém."}]}
```

Toda expressão é uma string entre aspas simples, e toda aspa simples dentro de uma se escreve `\'`.
Esse é o escape do Bicep, não do workflow: o template compilado leva a `'` simples. Compile:

```
ana@laptop:~/azure$ bicep build daily-orders.bicep
ana@laptop:~/azure$ ls daily-orders.*
daily-orders.bicep
daily-orders.json
```

**Nenhum aviso, e um template ao lado do arquivo.** O compilador verificou o recurso: o tipo e a
versão de API são conhecidos dele, e `name`, `location`, `state`, `parameters` e `definition` são
propriedades que um workflow tem. O `jq` lê a definição de volta do template, ação por ação:

```
ana@laptop:~/azure$ jq -c ".resources[0].properties.definition.actions | to_entries[] | {name: .key, type: .value.type, runAfter: .value.runAfter}" daily-orders.json
{"name":"Get_orders","type":"Http","runAfter":{}}
{"name":"Any_orders","type":"If","runAfter":{"Get_orders":["Succeeded"]}}
ana@laptop:~/azure$ jq -c ".resources[0].properties.definition.actions.Any_orders.actions | to_entries[] | {name: .key, runAfter: .value.runAfter}" daily-orders.json
{"name":"Export","runAfter":{}}
{"name":"Summary","runAfter":{"Export":["Succeeded"]}}
```

As duas ações de primeiro nível e a ordem delas estão todas na primeira saída. `Get_orders` tem
`runAfter` vazio, então roda primeiro, assim que o trigger dispara. `Any_orders` espera `Get_orders`
terminar em `Succeeded`. A segunda saída é o ramo verdadeiro da condição, cujas ações têm um
`runAfter` próprio. `Export` tem um vazio, o que dentro de um ramo quer dizer que ela roda primeiro
ali.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A ordem de execução do workflow daily-orders, desenhada a partir dos seus runAfter. O trigger Every_morning, uma Recurrence às 06:00 em São Paulo, inicia a execução. Get_orders, um HTTP GET com três retries a um minuto de distância, tem runAfter vazio e roda primeiro. Any_orders, um If, roda depois de Get_orders ter sucesso e contém dois ramos. No ramo verdadeiro, Export gera uma tabela CSV e tem runAfter vazio, então roda primeiro no seu ramo; Summary, um Compose, roda depois de Export ter sucesso. No ramo else, No_orders, um Compose, roda sozinho. Uma nota diz que a ordem das chaves no arquivo não é a ordem da execução.\"><defs><marker id=\"ro-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12\" y=\"100\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"82.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Every_morning</text><text x=\"82.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Recurrence</text><text x=\"82.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">06:00 em São Paulo</text><rect x=\"180\" y=\"100\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Get_orders</text><text x=\"255.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP GET /orders</text><text x=\"255.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 retries, 1 min entre eles</text><path d=\"M154 130 L176 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ro-ah)\"></path><text x=\"166\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runAfter: {}</text><rect x=\"392\" y=\"14\" width=\"316\" height=\"272\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"408\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Any_orders</text><text x=\"496\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">If: há algum pedido?</text><path d=\"M332 130 L388 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ro-ah)\"></path><text x=\"360\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Succeeded</text><rect x=\"404\" y=\"48\" width=\"292\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">verdadeiro</text><rect x=\"414\" y=\"92\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"474.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Export</text><text x=\"474.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Table, CSV</text><rect x=\"568\" y=\"92\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"628.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Summary</text><text x=\"628.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Compose</text><path d=\"M536 115 L564 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ro-ah)\"></path><text x=\"474\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">primeira do seu ramo</text><text x=\"628\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia, contagem, CSV</text><rect x=\"404\" y=\"192\" width=\"292\" height=\"82\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">else</text><rect x=\"414\" y=\"218\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"489.0\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">No_orders</text><text x=\"489.0\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Compose, uma linha</text><text x=\"16\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">O arquivo lista as ações como chaves de um</text><text x=\"16\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">objeto, em qualquer ordem. As setas são o runAfter.</text></svg>", "caption": "A execução que daily-orders.bicep declara. Cada seta é uma entrada de runAfter, e as caixas dentro de Any_orders são os seus dois ramos, cada um com uma ordem própria. Nada aqui vem da posição de uma ação no arquivo.", "same": ["Recurrence", "HTTP GET /orders", "else", "Table, CSV", "Compose"]}
```

`Succeeded` é um dos quatro status que o `runAfter` pode nomear, ao lado de `Failed`, `Skipped` e
`TimedOut`. O motor marca `Failed` uma ação que falha e `Skipped` toda ação que esperava por ela,
então uma ação que deve rodar quando algo deu errado lista esse status: `"runAfter": {"Get_orders":
["Failed", "TimedOut"]}` é a forma de um alerta. Um orquestrador da lição 17 escreveria a mesma
ideia em Python, como um `try` em volta de uma chamada.

## Expressões e funções

Um valor que só se conhece quando o workflow roda é uma **expressão**: uma string que começa com
`@`. A regra da documentação é que `"@parameters('myAge')"` devolve o valor com o tipo dele, um
número se o parâmetro for número, e `"@{parameters('myAge')}"` o devolve como string. Texto em volta
de uma expressão precisa das chaves: `@{parameters('shopUrl')}/orders` monta um endereço, e a
documentação marca a mesma expressão escrita sem elas como incorreta.

Dentro de uma expressão há funções, e a definição acima usa sete delas:

| função | o que ela dá aqui |
| --- | --- |
| `parameters('shopUrl')` | o valor que o recurso preencheu no deploy |
| `body('Get_orders')` | o corpo da resposta dessa ação, o array de pedidos da loja |
| `length(...)` | quantos itens o array tem |
| `greater(a, b)` | verdadeiro se `a` for maior que `b`, escrito na condição como `"greater": [a, b]` |
| `utcNow()` | a hora agora, em UTC |
| `convertFromUtc(t, zone)` | o mesmo instante num fuso horário do Windows, aqui o de São Paulo |
| `formatDateTime(t, 'yyyy-MM-dd')` | a data no formato que o financeiro pediu |

`body('Export')` é a segunda delas de novo, lendo outra ação. A referência agrupa as demais por
finalidade: strings, coleções, lógica, conversão, matemática, datas, URIs, JSON e XML, e funções de
*workflow* como `triggerBody()`, `item()` dentro de um laço, e `result()`, que devolve os resultados
das ações de um scope. Um operador importa mais que os outros: `?` antes de uma propriedade, como em
`triggerBody()?['total']`, devolve null quando a propriedade não existe em vez de fazer a execução
falhar.

Para o compilador, tudo isso é texto. Pedindo toda string da definição que começa com `@`:

```
ana@laptop:~/azure$ jq "[.resources[0].properties.definition | .. | strings | select(startswith(\"@\"))]" daily-orders.json
[
  "@{parameters('shopUrl')}/orders",
  "@length(body('Get_orders'))",
  "@body('Get_orders')",
  "@{formatDateTime(convertFromUtc(utcNow(), 'E. South America Standard Time'), 'yyyy-MM-dd')}",
  "@length(body('Get_orders'))",
  "@body('Export')"
]
```

Seis strings, sem as barras: no template uma aspa é uma `'` simples. O `greater` da condição não
está entre elas, porque é a chave de um objeto e não uma string. Se a função que cada string nomeia
existe é o Azure quem decide, não o compilador.

## O que o compilador não lê

**O compilador verifica o recurso em volta da definição e nada dentro dela.** O tipo do recurso
declara `definition` como um valor de qualquer forma, então as palavras dentro dela não são
comparadas com nada. Aqui estão duas cópias do arquivo, uma com um passo escrito errado num
`runAfter` e outra com uma função escrita errado nos dois lugares em que é usada:

```
ana@laptop:~/azure$ sed "s/Get_orders: \[/Get_order: [/" daily-orders.bicep > typo.bicep; bicep build typo.bicep
ana@laptop:~/azure$ sed "s/@length(/@lenght(/" daily-orders.bicep > lenght.bicep; bicep build lenght.bicep
ana@laptop:~/azure$ grep -c lenght lenght.json
2
```

As duas compilaram sem uma palavra, e a função errada está no template, duas vezes, pronta para o
deploy. A ação nomeada no primeiro `runAfter` não existe, e nenhuma função chamada `lenght` existe
também. O serviço do Logic Apps valida uma definição quando um workflow é salvo, mas o que essa
validação pega além da forma do schema a documentação não lista, e um laptop não consegue descobrir.
**Então, nesta lição, uma compilação limpa prova o recurso e não diz nada sobre o workflow.**

O que o compilador pega é a sua própria linguagem. Uma definição copiada da code view do portal usa
aspas duplas, e o Bicep não tem nenhuma:

```
ana@laptop:~/azure$ sed "s/'no orders to send'/\"no orders to send\"/" daily-orders.bicep > quotes.bicep; bicep build quotes.bicep; echo "exit $?"
/home/ana/azure/quotes.bicep(91,25) : Error BCP103: The following token is not recognized: """. Strings are defined using single quotes in bicep. [https://aka.ms/bicep/core-diagnostics#BCP103]
/home/ana/azure/quotes.bicep(91,25) : Error BCP009: Expected a literal value, an array, an object, a parenthesized expression, or a function call at this location. [https://aka.ms/bicep/core-diagnostics#BCP009]
/home/ana/azure/quotes.bicep(91,43) : Error BCP103: The following token is not recognized: """. Strings are defined using single quotes in bicep. [https://aka.ms/bicep/core-diagnostics#BCP103]
exit 1
ana@laptop:~/azure$ ls quotes.*
quotes.bicep
```

Esses são erros, não avisos: o status de saída é 1, e nenhum template foi escrito. O Bicep também
tem `loadJsonContent('workflow.json')`, que lê para dentro do template, na compilação, uma definição
guardada num arquivo JSON próprio, sem escape nenhum. A verificação é a mesma dos dois jeitos:
nenhuma.

Fazer o deploy do arquivo é um comando, não executado neste curso porque precisa de uma assinatura:

```sh
az deployment group create --resource-group shop-rg --template-file daily-orders.bicep --parameters shopUrl=https://shop.example.com
```
