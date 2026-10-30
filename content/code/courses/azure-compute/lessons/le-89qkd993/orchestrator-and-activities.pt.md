---
title: Um orquestrador, suas atividades e a função que os inicia
version: 1
---

O nome sugere uma função que roda por muito tempo: um pedido a inicia, e ela fica no ar até o
pacote sair. **Nada no Durable Functions roda por muito tempo.** Um pedido vira uma **instância de
orquestração**, que é um registro na conta de armazenamento, e algumas funções curtas que rodam por
um instante e param. O registro diz até onde o pedido chegou. As funções o leem, fazem o próximo
passo e o escrevem de volta. É isso que deixa um pedido durar uma semana num plano que dá cinco
minutos a uma função.

O Durable Functions é uma extensão do host do Functions, e funciona com três tipos de função no
mesmo app. Uma **função cliente** inicia uma instância e pode perguntar por ela; aqui é a função
HTTP que recebe o pedido. Uma **função orquestradora** diz, em Python comum, por quais passos o
pedido passa e em que ordem. As **funções de atividade** fazem os passos: reservar o estoque, cobrar
o cliente, despachar o pacote. O orquestrador nunca faz um passo ele mesmo, e uma atividade nunca
sabe o que vem depois dela.

A lição 15 dividiu o mesmo trabalho com uma fila: uma função recebia o pedido e uma segunda o
pegava. Isso funciona para uma passagem. Com três passos, viram três filas e três funções, e nada no
app sabe onde está um dado pedido. A lição 16 deu o outro motivo: **uma função HTTP tem 230 segundos
para responder**, e a documentação manda o trabalho mais longo para uma fila ou para o Durable
Functions. Esta seção monta o fluxo de pedidos da loja dos dois jeitos ao mesmo tempo, como código e
como registro, e o roda no laptop com a montagem da lição 15.

## Mais uma linha no requirements.txt

O lado Python é um pacote, `azure-functions-durable`. Acrescente-o ao arquivo da lição 15, fixado na
versão com que estas transcrições foram gravadas:

```sh
echo azure-functions-durable==1.7.0 >> ~/azure/shopfn/requirements.txt
```

```
ana@laptop:~/azure$ cat shopfn/requirements.txt
azure-functions
azure-functions-durable==1.7.0
```

1.7.0 foi a versão que o `pip` instalou em 2026-10-30. A documentação pede 1.2.2 ou posterior, com o
extension bundle na versão 4 ou posterior, que o `host.json` já diz. **A outra metade é a extensão, e
ela já está na imagem**: o Durable Functions para Python, como toda linguagem que não é .NET, recebe a
extensão do bundle que a lição 15 abriu, e o `host.json` não muda. Nem o `Dockerfile`.

## O código

Substitua `~/azure/shopfn/function_app.py` por este arquivo. As duas funções da lição 15 saem do app:
o pedido agora passa por uma orquestração em vez de uma fila.

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport logging\nimport time\n\nimport azure.functions as func\nimport azure.durable_functions as df\n\napp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)\n\n\n", "note": "`df.DFApp` é o `func.FunctionApp` da lição 15 com os decoradores do Durable Functions acrescentados, vindos do pacote `azure.durable_functions`. `http_auth_level` é o nível que toda função HTTP do app recebe se não disser outro; `ANONYMOUS` não pede chave, como na lição 15."}, {"code": "@app.route(route='orders', methods=['POST'])\n@app.durable_client_input(client_name='client')\nasync def start_order(req: func.HttpRequest, client: df.DurableOrchestrationClient) -> func.HttpResponse:\n    order = req.get_json()\n    instance_id = await client.start_new('order_flow', order['order'], order)\n    logging.info('started %s', instance_id)\n    return client.create_check_status_response(req, instance_id)\n\n\n", "note": "**A função cliente.** É uma função HTTP comum com mais um decorador, `durable_client_input`, que lhe entrega um cliente do task hub. `start_new` nomeia o orquestrador, dá à instância um id, aqui o próprio número do pedido, e passa o pedido como entrada. Ela volta assim que a partida fica registrada, antes de qualquer passo rodar, e `create_check_status_response` responde 202 com os endereços para perguntar pela instância."}, {"code": "@app.orchestration_trigger(context_name='context')\ndef order_flow(context: df.DurableOrchestrationContext):\n    order = context.get_input()\n    logging.info('order_flow for %s, replaying=%s', order['order'], context.is_replaying)\n", "note": "**O orquestrador.** Um gerador, não uma função `async`: a documentação proíbe corrotinas aqui. Ele não recebe nada além de `context`, e a entrada sai dele. A linha de log está ali para a seção `replay`, que explica por que ela é impressa mais de uma vez."}, {"code": "    reserved = yield context.call_activity('reserve_stock', order)\n    charged = yield context.call_activity('charge', order)\n    shipped = yield context.call_activity('ship', order)\n    return [reserved, charged, shipped]\n\n\n", "note": "Cada `yield` devolve um pedido à extensão: rode esta atividade, com esta entrada. O orquestrador para ali, e a linha seguinte só roda quando o resultado chega. Três yields, três passos em ordem, e o que `return` devolve vira a saída da instância."}, {"code": "@app.activity_trigger(input_name='order')\ndef reserve_stock(order: dict) -> str:\n    time.sleep(1)\n    return f\"reserved {order['qty']} x {order['sku']}\"\n\n\n", "note": "**Uma atividade** é onde está o trabalho: aqui um segundo de sono faz as vezes de uma chamada ao serviço de estoque. `input_name` nomeia o parâmetro que recebe a entrada. O que ela devolve é escrito no histórico da instância, e por isso uma atividade devolve algo pequeno e em forma de JSON."}, {"code": "@app.activity_trigger(input_name='order')\ndef charge(order: dict) -> str:\n    time.sleep(1)\n    return f\"charged {order['order']}\"\n\n\n@app.activity_trigger(input_name='order')\ndef ship(order: dict) -> str:\n    time.sleep(1)\n    return f\"shipped {order['order']}\"\n", "note": "Os outros dois passos, com o mesmo formato. Nenhum dos dois sabe que faz parte de uma orquestração."}]}
```

**Um orquestrador é uma lista de passos escrita como código, e cada `yield` é um lugar onde ele
para.** Os passos são atividades chamadas pelo nome; o que elas devolvem volta como valor do
`yield`. Nada no arquivo diz onde o estado fica guardado. Esse é o trabalho da extensão, e a próxima
seção lê o que ela escreveu.

## Iniciando

Os mesmos comandos da lição 15, com uma tag nova. Se os contêineres da lição 15 ainda estiverem
rodando, remova-os antes com `docker rm -f shopfn azurite`. Comece com um Azurite vazio:

```
ana@laptop:~/azure$ source storage.sh
ana@laptop:~/azure$ docker network create functions
87504a6dca9b7913198e6f6ba622c911173ae1a943901ba8b105c375c10028eb
ana@laptop:~/azure$ docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
4d296a6d66d7596e311f20be950cb642c0f74a1eb1fec60959c0be8c688b028f
ana@laptop:~/azure$ docker build -q -t shopfn:df1 shopfn
sha256:c90ef17f875b69fd1239fbf5bf03193a2cb1e024c5182896d159bf36d7d1a2ed
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" shopfn:df1
a06840800a293e55475b6dc0be8082fbc7d497202e2dc4dc5e4e8ff978767e2c
```

O host encontrou cinco funções, e a extensão do Durable Functions está no bundle, em várias partes:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -A6 "Found the following functions"
      Found the following functions:
      Host.Functions.charge
      Host.Functions.order_flow
      Host.Functions.reserve_stock
      Host.Functions.ship
      Host.Functions.start_order
      
ana@laptop:~/azure$ docker exec shopfn sh -c "ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin" | grep -E "^(DurableTask\.(AzureStorage|Netherite|SqlServer)|Microsoft\.Azure\.WebJobs\.Extensions\.DurableTask(\.AzureManaged)?)\.dll"
DurableTask.AzureStorage.dll
DurableTask.Netherite.dll
DurableTask.SqlServer.dll
Microsoft.Azure.WebJobs.Extensions.DurableTask.AzureManaged.dll
Microsoft.Azure.WebJobs.Extensions.DurableTask.dll
```

`DurableTask.AzureStorage` é o provedor de armazenamento que esta lição usa, o que guarda as
instâncias numa conta de armazenamento. Os arquivos `Netherite`, `SqlServer` e `AzureManaged` são os
outros três provedores, que a próxima seção lê. Os quatro vêm com o bundle, e o `host.json` escolhe
entre eles; sem dizer nada, é o Azure Storage.

## Uma configuração que o Azure põe por você

Agora mande um pedido:

```
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}'
HTTP 500
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o 'Webhooks are not configured[^)]*)'
Webhooks are not configured. This may occur if the environment variable `WEBSITE_HOSTNAME` is not set (should be automatically set for Azure Functions)
```

**O pedido foi recusado, e o motivo é uma configuração que esta máquina não tem.** A resposta da
função cliente traz endereços para perguntar pela instância, e para escrevê-los a extensão precisa
do nome de host do próprio app. No Azure a plataforma define `WEBSITE_HOSTNAME` em todo app, e a
documentação do App Service o lista como somente leitura. Num contêiner num laptop ninguém define,
então dê a ele o endereço que o seu terminal usa, `localhost:8080`. Dê ao app um host id ao mesmo
tempo:

```
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df1
4ac19378b6a36743e8d477654b80deae70012bf37204b919c97ca6cf3d104cec
```

`AzureFunctionsWebHost__hostid` é a segunda configuração. A lição 15 mostrou que, num laptop, o id
do host começa com o id do contêiner, então cada contêiner novo é um host novo. No Azure o id vem do
nome do app e não muda. Isso importa aqui porque o host guarda as chaves sob esse id, e os endereços
que a função cliente devolve carregam uma delas; com um id fixo, eles continuam funcionando depois
que o contêiner é trocado, e a seção `timers-and-events` depende disso.

## Um pedido, do começo ao fim

`-D -` imprime os cabeçalhos da resposta e `-o` salva o corpo. O `grep` fica com três dos
cabeçalhos, e o `sed` tira a chave do endereço, pelo motivo dado mais abaixo:

```
ana@laptop:~/azure$ curl -s -D - -o a1001.json -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}' | grep -E '^(HTTP|Location|Retry-After)' | sed -E 's/&code[^&[:space:]]*//'
HTTP/1.1 202 Accepted
Location: http://localhost:8080/runtime/webhooks/durabletask/instances/A-1001?taskHub=TestHubName&connection=Storage
Retry-After: 10
ana@laptop:~/azure$ STATUS=$(jq -r .statusQueryGetUri a1001.json)
ana@laptop:~/azure$ for i in $(seq 30); do curl -s "$STATUS" | jq -r .runtimeStatus; sleep 1; done | uniq -c
     14 Pending
      3 Running
     13 Completed
```

**A resposta voltou na hora, com 202 Accepted, antes de qualquer passo rodar.** `Location` é onde
perguntar pela instância e `Retry-After`, quantos segundos esperar antes de perguntar. É o padrão
HTTP assíncrono da documentação: o cliente consulta o endereço de `Location`, que responde 202
enquanto a instância roda e 200 quando ela termina. O laço perguntou uma vez por segundo e contou
cada status repetido em sequência; o primeiro pedido depois que o host subiu esperou em `Pending` por catorze das
trinta consultas até a extensão pegá-lo, e então rodou os três passos em cerca de um segundo cada.

O corpo traz o id da instância, que é o número do pedido porque o código o passou, e um conjunto de
endereços:

```
ana@laptop:~/azure$ jq -r 'keys[]' a1001.json
id
purgeHistoryDeleteUri
restartPostUri
resumePostUri
rewindPostUri
sendEventPostUri
statusQueryGetUri
suspendPostUri
terminatePostUri
ana@laptop:~/azure$ echo "$STATUS" | sed -E "s/&code[^&]*//"
http://localhost:8080/runtime/webhooks/durabletask/instances/A-1001?taskHub=TestHubName&connection=Storage
```

Eles são a API HTTP de gerenciamento da extensão, um endereço por coisa que se pode fazer a uma
instância. Esta lição usa três: o status, levantar um evento e encerrar. Todo endereço carrega o
task hub, `TestHubName`, a conexão e um parâmetro `code` com uma **chave de sistema** que dá direito a
toda operação dessa API em toda instância. **Trate a chave como segredo**: quem tiver estes endereços
pode parar qualquer pedido. O conselho da documentação é deixá-la fora de tudo o que o navegador de
um cliente vê, e estas transcrições nunca a imprimem: o `sed` apaga o parâmetro antes. Faça o mesmo
antes de colar um endereço num chamado ou num chat.

Quando a instância termina:

```
ana@laptop:~/azure$ curl -s "$STATUS" | jq .
{
  "name": "order_flow",
  "instanceId": "A-1001",
  "runtimeStatus": "Completed",
  "input": "{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}",
  "customStatus": null,
  "output": [
    "reserved 2 x mug",
    "charged A-1001",
    "shipped A-1001"
  ],
  "createdTime": "2026-10-30T20:37:52Z",
  "lastUpdatedTime": "2026-10-30T20:38:09Z"
}
```

`output` é o que `order_flow` devolveu, os três resultados em ordem. `input` é o pedido que o
cliente passou, guardado como entrada da instância. Sem o parâmetro `showHistory=true` no endereço,
o status deixa o histórico de fora; a próxima seção o lê na tabela.

## Uma instância por pedido

O número do pedido é o id da instância, e **um id é único dentro do task hub**. Mande o mesmo pedido
duas vezes, rápido:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "tee", "qty": 1}'
HTTP 202
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "tee", "qty": 1}'
HTTP 500
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o 'An Orchestration instance with the status [A-Za-z]* already exists'
An Orchestration instance with the status Running already exists
```

A segunda partida foi recusada enquanto a primeira ainda estava `Pending`. Usar o número do pedido
como id é o que a documentação sugere quando uma instância corresponde um a um a algo do negócio,
como uma ordem de compra. Isso transforma a nova tentativa de um cliente para o mesmo pedido num
erro em vez de uma segunda cobrança. A proteção só vale enquanto a instância roda:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "tee", "qty": 1}'
HTTP 202
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o '"overridableExistingInstanceStates":"[A-Za-z]*"'
"overridableExistingInstanceStates":"NonRunningStates"
```

Depois que A-1002 terminou, a mesma partida foi aceita e o pedido rodou de novo desde o começo. A
configuração da extensão diz quais estados podem ser iniciados de novo, e neste host é
`NonRunningStates`. Então uma duplicata que chega depois que a primeira cópia terminou não é pega
pelo id, e são as atividades que têm de pegá-la, uma das regras a que a seção `fan-out-fan-in`
volta.
