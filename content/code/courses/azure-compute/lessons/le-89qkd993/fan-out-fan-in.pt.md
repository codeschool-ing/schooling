---
title: "Fan-out, fan-in: muitas atividades, um só yield"
version: 1
---

Um pedido com seis linhas precisa de seis reservas, e a primeira versão de `order_flow` as faria uma
depois da outra, um segundo cada. A correção óbvia são threads, ou `asyncio.gather`, dentro do
orquestrador. **Nenhuma das duas é permitida, e nenhuma é necessária.** Um orquestrador não roda o
trabalho; ele o pede. Pedir seis atividades e esperar uma vez pelas seis é uma linha cada, e as seis
rodam onde o host tiver espaço para elas, em tantas instâncias quantas o plano der ao app. Isso é o
**fan-out**, agendar muitas atividades, e o **fan-in**, esperar por todas e juntar os resultados.

## O código

O pedido agora traz uma lista de `lines`, e a reserva vira uma atividade por linha. Substitua
`~/azure/shopfn/function_app.py` de novo; a função de partida e as duas últimas atividades não
mudam:

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport logging\nimport time\n\nimport azure.functions as func\nimport azure.durable_functions as df\n\napp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)\n\n\n"}, {"code": "@app.route(route='orders', methods=['POST'])\n@app.durable_client_input(client_name='client')\nasync def start_order(req: func.HttpRequest, client: df.DurableOrchestrationClient) -> func.HttpResponse:\n    order = req.get_json()\n    instance_id = await client.start_new('order_flow', order['order'], order)\n    logging.info('started %s', instance_id)\n    return client.create_check_status_response(req, instance_id)\n\n\n"}, {"code": "@app.orchestration_trigger(context_name='context')\ndef order_flow(context: df.DurableOrchestrationContext):\n    order = context.get_input()\n    started = context.current_utc_datetime\n", "note": "O pedido agora tem `lines`, e o orquestrador anota a hora em que começou a partir de `context`, nunca do relógio da máquina."}, {"code": "    tasks = [context.call_activity('reserve_line', line) for line in order['lines']]\n    reserved = yield context.task_all(tasks)\n", "note": "**O fan-out é a linha sem `yield`.** `call_activity` devolve uma tarefa e ainda não agenda nada; a lista guarda uma por linha. **O fan-in é `task_all`**: um `yield` para todas, que retoma o orquestrador quando a última termina, com os resultados na ordem da lista."}, {"code": "    seconds = (context.current_utc_datetime - started).total_seconds()\n    charged = yield context.call_activity('charge', order)\n    shipped = yield context.call_activity('ship', order)\n    return {'reserved': reserved, 'reserve_s': seconds, 'then': [charged, shipped]}\n\n\n", "note": "`reserve_s` é quanto as reservas levaram do ponto de vista da orquestração, do início ao momento em que ela foi retomada. Depois, os mesmos dois passos de antes, um após o outro."}, {"code": "@app.activity_trigger(input_name='line')\ndef reserve_line(line: dict) -> str:\n    time.sleep(1)\n    return f\"reserved {line['qty']} x {line['sku']}\"\n\n\n", "note": "Uma linha do pedido por chamada, um segundo cada, como `reserve_stock` era para o pedido inteiro."}, {"code": "@app.activity_trigger(input_name='order')\ndef charge(order: dict) -> str:\n    time.sleep(1)\n    return f\"charged {order['order']}\"\n\n\n@app.activity_trigger(input_name='order')\ndef ship(order: dict) -> str:\n    time.sleep(1)\n    return f\"shipped {order['order']}\"\n"}]}
```

**Um `call_activity` sem `yield` ainda não agenda nada.** Ele devolve uma tarefa, e a lista guarda
seis. O único `yield` entrega a lista inteira à extensão, que escreve seis pedidos na fila de work
items num só checkpoint e só acorda o orquestrador de novo quando o sexto responder. Os resultados
voltam na ordem da lista, não na ordem em que as atividades terminaram.

`reserve_s` mede as reservas com o relógio da própria orquestração, do início até a execução que
encontrou todas prontas. É seguro no replay pelo motivo que a seção anterior deu: os dois valores
vêm do histórico.

## Uma linha, e seis

Construa, troque o contêiner e mande um pedido de uma linha e um de seis:

```
ana@laptop:~/azure$ docker build -q -t shopfn:df2 shopfn
sha256:a98e3a0f5d02e973bbcfba021120cd726248c5452dbb7b555561fd51454baca9
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df2
2632ad6e0c11c6712d59592af97da8c65490ff727041a23e264b55a033e2d1af
ana@laptop:~/azure$ S4=$(curl -s -XPOST localhost:8080/api/orders -d '{"order": "A-1004", "lines": [{"sku": "mug", "qty": 2}]}' | jq -r .statusQueryGetUri)
ana@laptop:~/azure$ curl -s "$S4" | jq -c .output
{"reserved":["reserved 2 x mug"],"reserve_s":1.377018,"then":["charged A-1004","shipped A-1004"]}
ana@laptop:~/azure$ S5=$(curl -s -XPOST localhost:8080/api/orders -d '{"order": "A-1005", "lines": [{"sku": "mug", "qty": 2}, {"sku": "tee", "qty": 1}, {"sku": "lamp", "qty": 1}, {"sku": "cap", "qty": 3}, {"sku": "pen", "qty": 10}, {"sku": "bag", "qty": 1}]}' | jq -r .statusQueryGetUri)
ana@laptop:~/azure$ curl -s "$S5" | jq .output
{
  "reserved": [
    "reserved 2 x mug",
    "reserved 1 x tee",
    "reserved 1 x lamp",
    "reserved 3 x cap",
    "reserved 10 x pen",
    "reserved 1 x bag"
  ],
  "reserve_s": 1.122941,
  "then": [
    "charged A-1005",
    "shipped A-1005"
  ]
}
```

**Seis reservas levaram mais ou menos o mesmo que uma**, um segundo e pouco, já que cada atividade
dorme um segundo. A primeira versão precisava de um segundo e pouco por passo no log do host, um
depois do outro, então seis linhas em sequência seriam seis desses. O fan-out comprou a diferença sem
mudar `reserve_line` e sem thread nenhuma no código.

`then` mostra o resto do pedido seguindo como antes: `charge` espera todas as reservas, e depois
`ship` espera `charge`. Um fan-out é um passo da sequência, não uma mudança nela.

## Sessenta linhas, e o limite

Sessenta linhas é um pedido grande para uma loja e um bom teste do que o host faz com mais trabalho
do que cabe nele. Escreva o pedido com uma linha curta de Python, mande-o e leia o resultado:

```
ana@laptop:~/azure$ python3 -c "import json; print(json.dumps({'order': 'A-1006', 'lines': [{'sku': f'item-{n}', 'qty': 1} for n in range(60)]}))" > a1006.json
ana@laptop:~/azure$ S6=$(curl -s -XPOST localhost:8080/api/orders -d @a1006.json | jq -r .statusQueryGetUri)
ana@laptop:~/azure$ curl -s "$S6" | jq -c '.output | {reserve_s, lines: (.reserved | length)}'
{"reserve_s":2.532364,"lines":60}
```

Sessenta reservas de um segundo, feitas em alguns segundos e não em um. O log diz por quê. O host
registra uma linha quando cada atividade começa, e `docker logs -t` põe uma hora nela. O programa
`awk` transforma cada hora em segundos inteiros depois da primeira partida, e `uniq -c` os conta:

```
ana@laptop:~/azure$ docker logs -t shopfn 2>&1 | grep "A-1006: Function 'reserve_line (Activity)' started" | awk -F'[T:Z]' '{s = $2 * 3600 + $3 * 60 + $4; if (NR == 1) first = s; print int(s - first)}' | uniq -c
     40 0
     20 1
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o '"maxConcurrentActivityFunctions":[0-9]*'
"maxConcurrentActivityFunctions":40
ana@laptop:~/azure$ docker exec shopfn nproc
4
```

**Quarenta começaram de uma vez e o resto esperou uma vaga.** O teto é uma configuração da extensão,
`maxConcurrentActivityFunctions`, e o host imprimiu o valor na configuração ao subir. A documentação
dá como padrão 10 vezes o número de processadores num plano Premium ou Dedicated, e 10 no
Consumption; o contêiner viu quatro processadores, e quatro vezes dez dá quarenta. O valor é **por
instância do host**: num plano que acrescenta instâncias, as atividades em espera podem ir para
outra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Sessenta atividades reserve_line do pedido A-1006 desenhadas como quadrados. Quarenta começam no primeiro segundo, o limite de dez por processador em quatro processadores; as outras vinte começam à medida que vagas se abrem.\"><rect x=\"40\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"141.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">segundo 1: quarenta começam</text><text x=\"429.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">depois as outras vinte</text><text x=\"141.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">maxConcurrentActivityFunctions = 10 × 4 processadores</text><text x=\"429.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada uma espera uma das quarenta terminar</text><path d=\"M40 244 L650 244\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M650 239 L660 244 L650 249 z\" fill=\"var(--wire)\"></path><text x=\"668\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><text x=\"40\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um quadrado = um reserve_line, um segundo de trabalho</text></svg>", "caption": "Sessenta atividades, um host. A extensão começa quantas o limite permite e deixa o resto na fila de work items, onde outra instância do app poderia pegá-las."}
```

A página de desempenho da documentação tem um aviso para Python: que um app Python só roda uma
função por vez numa máquina, então nove de dez atividades em fan-out ficariam esperando. **Não foi o
que este laptop mostrou**: quarenta rodaram de uma vez num único worker Python. Meça no tamanho de
instância em que você publica antes de confiar em qualquer um dos dois números, e se as atividades
forem lentas, o conselho da mesma página é ajustar o teto ao que o worker realmente roda.

## O que o histórico paga por isso

Cada atividade são dois eventos no histórico, o pedido e o resultado:

```
ana@laptop:~/azure$ az storage entity query -t TestHubNameHistory --filter "PartitionKey eq 'A-1006'" --query 'length(items)'
171
```

Cento e setenta e uma linhas para um pedido. Cada execução seguinte do orquestrador lê todas de volta antes de dar
o próximo passo, então uma orquestração que faz fan-out para milhares de itens deixa cada replay
lento e a memória de cada instância grande. As respostas da documentação são três: manter pequeno o
que as atividades devolvem (uma referência a um blob e não o blob), baixar a concorrência, ou dividir
o trabalho em **sub-orquestrações**, orquestradores chamados com `context.call_sub_orchestrator`,
cada um com um histórico próprio. Não executado aqui.

Uma falha dentro de um fan-out encerra o `task_all` inteiro: a documentação diz que em Python a
primeira atividade que falha faz a tarefa se completar com erro, que o orquestrador captura com `try`
e `except` como qualquer exceção. Uma atividade também pode ser chamada com
`context.call_activity_with_retry` e um `df.RetryOptions` que diz quanto esperar antes da primeira
nova tentativa e quantas tentativas fazer. Uma nova tentativa é a segunda execução de uma atividade
para a mesma entrada, e por isso a seção anterior pediu que as atividades sejam seguras de rodar duas
vezes. Nenhuma das duas coisas foi executada aqui.

## Nos planos da lição 16

Não executado neste curso: precisa de uma assinatura.

Orquestradores e atividades escalam de jeitos diferentes, e a documentação é explícita sobre os dois.
**Uma atividade não tem estado e pode rodar em qualquer instância**: toda instância do app disputa a
fila de work items, então as atividades em fan-out se espalham pelas instâncias que o plano tiver
acrescentado. **O orquestrador de uma instância roda num host por vez**, o que tem o lease da sua
fila de controle. O provedor Azure Storage tem quatro partições por padrão e no máximo
dezesseis, então no máximo dezesseis instâncias do app rodam orquestradores ao
mesmo tempo. O conselho é manter os orquestradores leves e pôr o trabalho pesado nas atividades, que
não têm esse teto.

Nos planos em si:

- **Flex Consumption** escala todas as funções Durable de um app juntas, como um grupo, que a lição
  16 nomeou. Para o Durable Functions no provedor Azure Storage, a documentação recomenda uma
  instância always ready para o grupo `durable` e um intervalo de polling de fila de dez segundos ou
  menos, porque um plano que escala a zero fica sabendo de trabalho novo consultando.
- **Consumption** tem o padrão de 10 atividades por instância, e cobra cada replay como uma
  execução.
- **Premium e Dedicated** rodam 10 por processador por padrão, e nunca param.

Nenhum deles muda o código. O plano decide quantos hosts existem; a orquestração decide que trabalho
existe.
