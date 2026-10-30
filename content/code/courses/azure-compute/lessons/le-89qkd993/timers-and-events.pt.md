---
title: "Esperar: um timer durável, um evento externo e terminate"
version: 1
---

Uma loja que aceita Pix manda um código ao cliente e depois espera, por minutos ou por um dia, até o
banco dizer que o dinheiro chegou. Orquestração de longa duração soa como se algo tivesse de ficar no
ar esse tempo todo. **Nada fica.** Uma instância em espera é uma linha na tabela Instances e, se ela
criou um timer, uma mensagem de fila que fica invisível até o momento do timer. Nenhum processo seu
roda enquanto ela espera, e no plano Consumption a documentação diz que a espera não é cobrada. O
Durable Functions tem dois jeitos de terminar uma espera, e esta seção usa os dois de uma vez: um
**timer durável**, que um relógio termina, e um **evento externo**, que alguém de fora do app
levanta.

## O código

O pedido agora espera o pagamento entre as reservas e a cobrança, por tantos segundos quantos o
`pay_within_s` do pedido disser. Substitua `~/azure/shopfn/function_app.py` mais uma vez:

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport logging\nimport time\nfrom datetime import timedelta\n\nimport azure.functions as func\nimport azure.durable_functions as df\n\napp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)\n\n\n", "note": "`timedelta` é novo: o prazo é uma hora calculada a partir de `context`."}, {"code": "@app.route(route='orders', methods=['POST'])\n@app.durable_client_input(client_name='client')\nasync def start_order(req: func.HttpRequest, client: df.DurableOrchestrationClient) -> func.HttpResponse:\n    order = req.get_json()\n    instance_id = await client.start_new('order_flow', order['order'], order)\n    logging.info('started %s', instance_id)\n    return client.create_check_status_response(req, instance_id)\n\n\n"}, {"code": "@app.orchestration_trigger(context_name='context')\ndef order_flow(context: df.DurableOrchestrationContext):\n    order = context.get_input()\n    tasks = [context.call_activity('reserve_line', line) for line in order['lines']]\n    reserved = yield context.task_all(tasks)\n\n", "note": "O fan-out da seção anterior, sem mudança."}, {"code": "    context.set_custom_status('waiting for payment')\n    deadline = context.current_utc_datetime + timedelta(seconds=order['pay_within_s'])\n    timeout = context.create_timer(deadline)\n    paid = context.wait_for_external_event('PaymentConfirmed')\n    winner = yield context.task_any([paid, timeout])\n", "note": "**Duas tarefas e um só `yield`.** `create_timer` é um timer durável que dispara em `deadline`; `wait_for_external_event` é uma tarefa que se completa quando alguém levanta o evento `PaymentConfirmed` para esta instância. `task_any` retoma com a que terminar primeiro. `set_custom_status` põe uma palavra no JSON de status para quem o consultar."}, {"code": "    if winner == timeout:\n        context.set_custom_status('expired')\n        released = yield context.call_activity('release_stock', order)\n        return {'status': 'expired', 'reserved': reserved, 'then': [released]}\n    timeout.cancel()\n\n", "note": "Se o relógio ganhou, o status diz isso, as reservas são desfeitas e a instância termina. Se o pagamento ganhou, o timer é cancelado: a documentação diz que uma instância não é marcada `Completed` enquanto um timer que ela criou continua pendente."}, {"code": "    context.set_custom_status('paid')\n    charged = yield context.call_activity('charge', {'order': order['order'], 'payment': paid.result})\n    shipped = yield context.call_activity('ship', order)\n    return {'status': 'shipped', 'reserved': reserved, 'then': [charged, shipped]}\n\n\n", "note": "`paid.result` é o corpo que o evento trouxe, e ele vai para `charge` como parte da entrada."}, {"code": "@app.activity_trigger(input_name='line')\ndef reserve_line(line: dict) -> str:\n    time.sleep(1)\n    return f\"reserved {line['qty']} x {line['sku']}\"\n\n\n@app.activity_trigger(input_name='order')\ndef release_stock(order: dict) -> str:\n    logging.info('releasing the stock of %s', order['order'])\n    return f\"released {order['order']}\"\n\n\n", "note": "`release_stock` é a compensação para um pagamento que nunca veio, e registra uma linha no log para a transcrição mostrar que rodou."}, {"code": "@app.activity_trigger(input_name='payment')\ndef charge(payment: dict) -> str:\n    time.sleep(1)\n    return f\"charged {payment['order']} with {payment['payment']['pix']}\"\n\n\n", "note": "`charge` agora recebe o número do pedido e o pagamento juntos."}, {"code": "@app.activity_trigger(input_name='order')\ndef ship(order: dict) -> str:\n    time.sleep(1)\n    return f\"shipped {order['order']}\"\n"}]}
```

**A espera é uma corrida entre duas tarefas.** `task_any` retoma o orquestrador com a que terminar
primeiro, e o código pergunta qual foi. Nenhuma das duas é um sleep: `create_timer` escreve uma
mensagem que fica visível em `deadline`, e `wait_for_external_event` não escreve nada até o evento
chegar. O prazo vem de `context.current_utc_datetime`, como a seção `replay` exigiu, então todo
replay calcula o mesmo momento.

## Três pedidos

Construa, troque o contêiner e mande três pedidos: dois que vão esperar dez minutos e um que vai
esperar vinte segundos:

```
ana@laptop:~/azure$ docker build -q -t shopfn:df3 shopfn
sha256:7b6bfb9da8351ce95a1acebd93a2f3b0d77cfa68a7524c3d0b5eb11902db4247
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df3
7155a7f5390862059f533476b13ba532515e826b44e4d9837386b71794aac872
ana@laptop:~/azure$ curl -s -o a1007.json -XPOST localhost:8080/api/orders -d '{"order": "A-1007", "lines": [{"sku": "mug", "qty": 2}], "pay_within_s": 600}'
ana@laptop:~/azure$ curl -s -o a1008.json -XPOST localhost:8080/api/orders -d '{"order": "A-1008", "lines": [{"sku": "tee", "qty": 1}], "pay_within_s": 20}'
ana@laptop:~/azure$ curl -s -o a1009.json -XPOST localhost:8080/api/orders -d '{"order": "A-1009", "lines": [{"sku": "lamp", "qty": 1}], "pay_within_s": 600}'
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1007.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Running","customStatus":"waiting for payment","output":null}
```

`customStatus` é a palavra que o orquestrador definiu antes de começar a esperar. **Quem consulta o
endereço de status vê por que a instância está `Running` sem nada rodando**, o que um status puro não
consegue dizer.

## O pagamento chega: levantar um evento

O endereço para levantar um evento veio na resposta da partida, com `{eventName}` no lugar do nome
que o orquestrador espera:

```
ana@laptop:~/azure$ jq -r .sendEventPostUri a1007.json | cut -c1-110
http://localhost:8080/runtime/webhooks/durabletask/instances/A-1007/raiseEvent/{eventName}?taskHub=TestHubName
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1007.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1234"}'
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1007.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Completed","customStatus":"paid","output":{"status":"shipped","reserved":["reserved 2 x mug"],"then":["charged A-1007 with E1234","shipped A-1007"]}}
```

O lado do banco na conversa é feito pelo `curl`. O corpo é o dado do evento, e tem de ser JSON com
um content type JSON; a documentação lista 400 para qualquer outra coisa. O 202 quer dizer que o
evento entrou na fila, não que algo o usou. A-1007 então cobrou e despachou, e `charge` tirou o id do
Pix de `paid.result`.

Três detalhes da documentação, nenhum executado aqui. **Um evento levantado antes de o orquestrador
esperar por ele não se perde**: ele fica guardado, e a espera se completa assim que o código chega
lá. Um evento levantado para um id de instância que não existe é descartado sem erro, o caso a vigiar
quando o id vem de um webhook. E **os eventos são entregues pelo menos uma vez**: depois de um
reinício ou de um scale-out o mesmo evento pode chegar duas vezes, então uma confirmação de pagamento
que pode se repetir tem de ser segura de repetir.

## O pagamento nunca vem: o timer

A-1008 recebeu vinte segundos:

```
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1008.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Completed","customStatus":"expired","output":{"status":"expired","reserved":["reserved 1 x tee"],"then":["released A-1008"]}}
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E -o "A-1008: Function 'order_flow \(Orchestrator\)' was resumed by a timer scheduled for '[^']*'|releasing the stock of A-1008"
A-1008: Function 'order_flow (Orchestrator)' was resumed by a timer scheduled for '2026-10-30T20:40:28.6951970Z'
releasing the stock of A-1008
```

**O timer ganhou**, e o log diz o momento para o qual ele foi marcado, em UTC. `release_stock`
desfez a reserva e a instância terminou com o status `expired`. Ninguém precisou se lembrar de
A-1008: o prazo ficou escrito quando a instância começou a esperar, e foi a fila do provedor que
acordou o orquestrador.

Os limites que a documentação dá para timers são dois. **Em Python um timer durável pode ter no
máximo seis dias**; uma espera mais longa é um laço de timers mais curtos, cada um verificando se o
prazo chegou. E um timer que perde a corrida precisa ser cancelado, o que `order_flow` faz com
`timeout.cancel()`. A documentação diz que a instância não é marcada `Completed` enquanto algum timer
que ela criou estiver pendente, então A-1007, pago em um segundo, teria ficado `Running` pelos dez
minutos inteiros.

Um timer também pode ser o próprio passo, sem corrida: `yield context.create_timer(when)` é o `sleep`
do orquestrador, e o único que ele pode usar.

## O cliente cancela: terminate

O terceiro pedido é parado de fora:

```
ana@laptop:~/azure$ URL=$(jq -r .terminatePostUri a1009.json | sed 's/{text}/customer+cancelled/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL"
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1009.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Terminated","customStatus":"waiting for payment","output":"customer cancelled"}
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1009.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1235"}'
HTTP 410
```

`terminate` recebe um motivo, aqui `customer cancelled`, que vira a saída da instância. **Uma
instância encerrada está terminada**: o pagamento que apareceu depois foi recusado com 410 Gone, a
resposta da documentação para uma instância que terminou ou falhou. Encerrar também não roda nenhum
código seu, então a luminária reservada de A-1009 não foi liberada. Numa loja de verdade o
cancelamento seria um evento que o orquestrador espera, para poder desfazer o que fez; `terminate` é
para uma instância que deu errado.

## Um reinício, com um pedido esperando

Uma instância que espera por dias vai passar por reinícios do host. Comece mais um pedido, reinicie
o contêiner enquanto ele espera e pague depois:

```
ana@laptop:~/azure$ curl -s -o a1010.json -XPOST localhost:8080/api/orders -d '{"order": "A-1010", "lines": [{"sku": "cap", "qty": 1}], "pay_within_s": 600}'
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1010.json)" | jq -c '{runtimeStatus, customStatus}'
{"runtimeStatus":"Running","customStatus":"waiting for payment"}
ana@laptop:~/azure$ docker restart shopfn
shopfn
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1010.json)" | jq -c '{runtimeStatus, customStatus}'
{"runtimeStatus":"Running","customStatus":"waiting for payment"}
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1010.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1236"}'
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1010.json)" | jq -c '{runtimeStatus, output}'
{"runtimeStatus":"Completed","output":{"status":"shipped","reserved":["reserved 1 x cap"],"then":["charged A-1010 with E1236","shipped A-1010"]}}
```

**A instância estava esperando antes do reinício e continuava esperando depois**, e o pagamento a
terminou. O processo que iniciou A-1010 tinha sumido; o que sobreviveu foi a linha e o histórico da
instância no Azurite, e o host que voltou os leu. O endereço continuou funcionando porque o host id
foi fixado na primeira seção: a chave fica guardada sob ele.

## Uma publicação, com um pedido esperando

Um reinício roda o mesmo código. Uma publicação, não. Suponha que a loja decida mandar o código Pix
ao cliente por uma atividade, logo antes da espera. Comece A-1011 primeiro, e deixe-o esperar. Depois
acrescente a linha a `order_flow`, sob `reserved = yield context.task_all(tasks)`:

```python
    yield context.call_activity('send_pix_code', order)
```

e a atividade no fim do arquivo:

```python
@app.activity_trigger(input_name='order')
def send_pix_code(order: dict) -> str:
    return f"sent a Pix code for {order['order']}"
```

Construa a nova versão, troque o contêiner e pague A-1011:

```
ana@laptop:~/azure$ curl -s -o a1011.json -XPOST localhost:8080/api/orders -d '{"order": "A-1011", "lines": [{"sku": "pen", "qty": 5}], "pay_within_s": 600}'
ana@laptop:~/azure$ grep -n send_pix_code shopfn/function_app.py
26:    yield context.call_activity('send_pix_code', order)
70:def send_pix_code(order: dict) -> str:
ana@laptop:~/azure$ docker build -q -t shopfn:df4 shopfn
sha256:aa2f9a049ecab552ce6f41bdbd62c403e13b1ae65746b683391131b5491573a4
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df4
647c3355d7022e6e3cf4b144ac67489a94a5447dee150bcd31f0b4a18a8870df
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1011.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1237"}'
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1011.json)" | jq -r '.runtimeStatus, .output'
Failed
Non-Deterministic workflow detected: A previous execution of this orchestration scheduled a timer task with sequence number 1 named but the current orchestration replay instead produced a ScheduleTaskOrchestratorAction action with this sequence number. Was a change made to the orchestrator code after this instance had already started running?
```

**A-1011 falhou, e a mensagem diz por quê.** O histórico dele dizia que o passo depois das reservas
era um timer; o código novo, repetido sobre esse histórico, pediu uma atividade ali. Nada estava
errado com o código novo, e os pedidos iniciados depois da publicação o rodariam sem problema. O que
quebrou é que o histórico da instância antiga foi escrito pelo código antigo.

Não executado neste curso: as saídas que a documentação dá. Uma mudança que acrescenta, remove ou
reordena chamadas a atividades, timers ou eventos num orquestrador é uma **mudança incompatível** para
toda instância em andamento. A resposta recomendada é o **versionamento de orquestrações**: defina
`defaultVersion` no `host.json`, e cada instância nova carrega essa versão pela vida inteira, para o
orquestrador poder decidir por `context.version` e manter o caminho antigo para as instâncias antigas.
Em Python ele exige o extension bundle na 4.30.0 ou posterior. As outras duas são uma **publicação
lado a lado**, o código novo num app novo ou num task hub novo enquanto o antigo se esvazia, e, só em
desenvolvimento, parar toda instância em andamento.

## Quando esta é a ferramenta, e quando não é

Não executado neste curso: precisa de uma assinatura.

O Durable Functions é código. A orquestração mora no `function_app.py`, é testada e revisada como
qualquer outro Python, e roda nos planos da lição 16 sem recurso extra no provedor padrão. Um timer
que dispara num app escalado a zero o acorda: a documentação diz que é a mensagem do timer ficando
visível que ativa o app de novo. O preço são as regras da seção `replay` e o versionamento acima, que
nenhum linter verifica por você.

As alternativas fazem outra troca. A fila da lição 15 entre duas funções é mais simples para uma
passagem só e não tem histórico para repetir. **Os Logic Apps, lição 19, escrevem o fluxo como um
documento em vez de código**, com conectores para outros serviços e um designer, e fazem a própria
espera. Uma sequência de poucos passos em código, mantida por desenvolvedores, com esperas e
fan-outs, é para o que o Durable Functions serve.
