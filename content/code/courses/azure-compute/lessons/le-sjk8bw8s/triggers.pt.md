---
title: "Triggers: o que inicia uma função, e o que acontece quando ela falha"
version: 1
---

**Uma função tem exatamente um trigger**, e o trigger decide três coisas: o que faz a função rodar,
o que ela recebe quando roda e o que uma falha significa. A última das três é a que muda o jeito de
escrever o código. Um trigger HTTP responde a alguém que está esperando, então uma falha é um erro
que essa pessoa recebe, e nada é tentado de novo. Um trigger de fila não responde a ninguém: o host
pega uma mensagem, roda a função e, **se a função falha, a mensagem volta para a fila e é tentada de
novo, cinco vezes ao todo, antes de o host tirá-la do caminho**. As duas coisas são praticadas nesta
seção, no laptop.

É fácil imaginar um trigger como algo que chama o seu código. Para HTTP isso é mais ou menos
verdade: o servidor web do host recebe um pedido e roda a função para ele. Para uma fila, não. Nada
empurra uma mensagem para a função; **o host consulta a fila**, esperando um pouco mais depois de
cada consulta vazia, até um minuto por padrão, e roda a função para cada mensagem que encontra. A
função é o mesmo Python nos dois casos. O que está em volta dela, não.

## Um trigger HTTP, falhando

O app da seção anterior continua rodando, e `take_order` supõe que o corpo é JSON. Mande algo que
não é:

```
ana@laptop:~/azure$ curl -s -i -XPOST localhost:8080/api/orders -d 'hello'
HTTP/1.1 500 Internal Server Error
Content-Length: 0
Date: Fri, 30 Oct 2026 18:40:27 GMT
Server: Kestrel

ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep "Executed 'Functions"
      Executed 'Functions.take_order' (Succeeded, Id=f55efa35-8e2c-47b9-828b-e5d6a4d816f5, Duration=117ms)
      Executed 'Functions.take_order' (Failed, Id=385b2b08-23c7-4352-afaa-cab31412f94e, Duration=59ms)
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -E '^ +Exception: '
      Exception: ValueError: HTTP request does not contain valid JSON data
```

`req.get_json()` levantou uma exceção, nada a capturou, e o host respondeu `500` com o corpo vazio.
O traceback foi para o log, onde o cliente não o vê. **Nada foi tentado de novo**: o pedido acabou,
e mandá-lo de novo é decisão de quem chamou.

## A segunda versão: uma fila entre as duas metades

A loja não quer o cliente esperando enquanto um recibo é calculado. Então `take_order` confere o
pedido, grava-o numa fila chamada `orders` e responde na hora, e uma segunda função, `make_receipt`,
o tira da fila e faz o trabalho. Substitua o `~/azure/shopfn/function_app.py` por este. As linhas
que começam com `@app.queue_output` e `@app.blob_output` são bindings, assunto da próxima seção; por
enquanto, leia-as como "grave na fila" e "grave um recibo":

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport json\nimport logging\n\nimport azure.functions as func\n\napp = func.FunctionApp()\n\nPRICES = {'mug': 2990, 'tee': 5900, 'cap': 4500}\n\n\n", "note": "O mesmo começo, e os três produtos da loja com os preços em centavos. Uma loja de verdade guarda os preços em outro lugar; aqui eles mantêm o exemplo num arquivo só."}, {"code": "@app.route(route='orders', methods=['POST'], auth_level=func.AuthLevel.ANONYMOUS)\n@app.queue_output(arg_name='queued', queue_name='orders', connection='ShopStorage')\ndef take_order(req: func.HttpRequest, queued: func.Out[str]) -> func.HttpResponse:\n", "note": "O mesmo trigger, e abaixo dele um binding de saída para a fila `orders`. O `arg_name` dele é o segundo parâmetro: `queued` é onde a função põe a mensagem."}, {"code": "    try:\n        order = req.get_json()\n        ok = isinstance(order.get('order'), str) and isinstance(order.get('qty'), int)\n    except (ValueError, AttributeError):\n        ok = False\n    if not ok:\n        return func.HttpResponse('{\"error\": \"not an order\"}\\n', status_code=400,\n                                 mimetype='application/json')\n", "note": "Agora o corpo é conferido: um pedido precisa de um `order` em texto e de um `qty` inteiro. Qualquer outra coisa recebe um `400` escolhido pelo código, em vez do `500` do host. O produto não é conferido aqui."}, {"code": "    queued.set(json.dumps(order))\n    body = json.dumps({'accepted': order['order']})\n    return func.HttpResponse(body + '\\n', status_code=202, mimetype='application/json')\n\n\n", "note": "`set()` entrega o pedido ao binding, e o host o grava na fila. `202` diz ao cliente que o pedido foi aceito e não está pronto."}, {"code": "@app.queue_trigger(arg_name='msg', queue_name='orders', connection='ShopStorage')\n@app.blob_output(arg_name='receipt', path='receipts/{order}.json', connection='ShopStorage')\ndef make_receipt(msg: func.QueueMessage, receipt: func.Out[str]) -> None:\n", "note": "**A segunda função.** O trigger dela é a mesma fila, e a saída é um blob cujo nome vem da mensagem, `receipts/{order}.json`."}, {"code": "    order = json.loads(msg.get_body())\n    logging.info('order %s, attempt %d', order['order'], msg.dequeue_count)\n    cents = PRICES[order['sku']] * order['qty']\n    receipt.set(json.dumps({'order': order['order'], 'qty': order['qty'], 'cents': cents}))\n", "note": "`msg.get_body()` é a mensagem, e `dequeue_count` é quantas vezes o host a tirou da fila. Um produto sem preço levanta `KeyError`, e nada o captura."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O caminho de um pedido. Um cliente o envia; o trigger HTTP roda take_order, cuja saída para a fila o grava na fila orders. O host consulta essa fila, e o trigger de fila roda make_receipt, cuja saída para blob grava receipts/A-1001.json. Uma mensagem que falha cinco vezes vai para orders-poison. As duas funções são o seu código; toda seta é trabalho do host.\"><defs><marker id=\"op-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"op-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um cliente</text><rect x=\"210\" y=\"40\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">take_order</text><rect x=\"440\" y=\"40\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"510\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><path d=\"M132 60 L206 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"170\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trigger HTTP</text><path d=\"M352 60 L436 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"394\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">saída para a fila</text><rect x=\"440\" y=\"160\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">make_receipt</text><path d=\"M510 82 L510 156\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"522\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trigger de fila:</text><text x=\"522\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o host consulta</text><rect x=\"170\" y=\"160\" width=\"190\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"265\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">receipts/A-1001.json</text><path d=\"M438 180 L364 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"401\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">saída para blob</text><rect x=\"440\" y=\"270\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"510\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-poison</text><path d=\"M510 202 L510 266\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#op-ah-a)\"></path><text x=\"522\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">depois de cinco</text><text x=\"522\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tentativas falhas</text><rect x=\"20\" y=\"252\" width=\"22\" height=\"14\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"259\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu código</text><path d=\"M20 288 L42 288\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"50\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trabalho do host</text></svg>", "caption": "Um pedido passando pelas duas funções desta seção. O código são as duas caixas âmbar; toda seta entre elas, incluindo as cinco tentativas e a ida para a fila poison, é do host."}
```

Construa uma segunda imagem, troque o contêiner e passe a segunda configuração que o código agora
nomeia:

```
ana@laptop:~/azure$ docker build -q -t shopfn:2 shopfn
sha256:5815df7545d3f903ceea40142f0ac9bff14d3244769c09e579c3c0fb42c604d8
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e ShopStorage="$FN_STORAGE" shopfn:2
68ea96a372f6f321ac057cb1798bf8912db70e122bfb84b9cc1ec40e00b58e0d
```

`ShopStorage` aponta para o mesmo Azurite que a `AzureWebJobsStorage` aqui. Mantê-la como
configuração separada custa um `-e` no laptop e se paga no Azure, como a próxima seção explica.

## Um trigger de fila, dando certo

```
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}'
{"accepted": "A-1001"}
HTTP 202
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d 'hello'
{"error": "not an order"}
HTTP 400
```

O primeiro pedido foi aceito com `202`, o código HTTP de "aceito, ainda não feito", e o corpo que
não era pedido recebeu um `400` do código em vez de um `500` do host. Um instante depois o host
encontrou a mensagem na fila:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E 'Trigger Details|order A-|Executed .Functions.make_receipt'
      Trigger Details: MessageId: 1541566d-ea27-47c0-b5e8-537b06fa6ce0, DequeueCount: 1, InsertedOn: 2026-10-30T18:40:41.000+00:00
      order A-1001, attempt 1
      Executed 'Functions.make_receipt' (Succeeded, Id=4a3f5024-24c7-483c-bbfb-62ac1bec7beb, Duration=579ms)
```

`Trigger Details` é o host descrevendo a mensagem antes de a função vê-la: o id, quantas vezes ela
já foi tirada da fila e quando foi posta lá. A linha da própria função lê o mesmo `dequeue_count` da
mensagem que recebeu.

**O que cada trigger entrega à função é um objeto com tipo**, documentado por trigger. Estes são os
dois que este app usa:

| trigger | tipo | o que ele traz |
| --- | --- | --- |
| HTTP | `func.HttpRequest` | `method`, `url`, `headers`, `params` (a query string), `route_params`, `get_body()` e `get_json()` |
| fila | `func.QueueMessage` | `get_body()`, `id`, `dequeue_count`, `insertion_time`, `expiration_time`, `time_next_visible`, `pop_receipt` |

## Um trigger de fila, falhando cinco vezes

O segundo pedido nomeia um produto que a loja não vende. `take_order` não confere produtos, então
aceita o pedido; `make_receipt` procura o preço e falha:

```
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "lamp", "qty": 1}'
{"accepted": "A-1002"}
HTTP 202
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E 'order A-1002|reached MaxDequeueCount'
      order A-1002, attempt 1
      order A-1002, attempt 2
      order A-1002, attempt 3
      order A-1002, attempt 4
      order A-1002, attempt 5
      Message has reached MaxDequeueCount of 5. Moving message to queue 'orders-poison'.
```

**Cinco tentativas, uma atrás da outra, e então a mensagem foi movida para `orders-poison`.** Quem
fez as tentativas foi o host, não o código: cada vez que a função levantou uma exceção, o host
devolveu a mensagem, pegou-a de novo e contou. As linhas do próprio host mostram um sucesso, o
primeiro pedido, e cinco falhas com a mesma causa:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep "Executed 'Functions.make_receipt'"
      Executed 'Functions.make_receipt' (Succeeded, Id=4a3f5024-24c7-483c-bbfb-62ac1bec7beb, Duration=579ms)
      Executed 'Functions.make_receipt' (Failed, Id=17acea7e-796c-4716-a19d-abebfd270b4e, Duration=50ms)
      Executed 'Functions.make_receipt' (Failed, Id=24ad1b7e-3e38-45a5-a3e4-b7da7ceab7f5, Duration=14ms)
      Executed 'Functions.make_receipt' (Failed, Id=56a98279-60cf-409c-b258-34538154c3ba, Duration=5ms)
      Executed 'Functions.make_receipt' (Failed, Id=c33cd194-af50-45a1-912c-f4df94945df9, Duration=5ms)
      Executed 'Functions.make_receipt' (Failed, Id=9429da22-74f0-44e2-9b2c-40b5ca4a2656, Duration=8ms)
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -E '^ +Exception: '
      Exception: KeyError: 'lamp'
```

A fila `orders-poison` tem o nome da original com `-poison` no fim, e guarda a mensagem que a função
não conseguiu tratar, para que uma pessoa possa olhá-la, ou para que outra função seja disparada por
ela e dê o alarme:

```
ana@laptop:~/azure$ az storage queue list --only-show-errors --query "[].name" -o tsv
orders
orders-poison
ana@laptop:~/azure$ az storage message peek -q orders-poison --only-show-errors
[
  {
    "content": "ewogICJvcmRlciI6ICJBLTEwMDIiLAogICJza3UiOiAibGFtcCIsCiAgInF0eSI6IDEKfQ==",
    "dequeueCount": 0,
    "expirationTime": "2026-11-06T18:40:44+00:00",
    "id": "941a8280-30d8-4e06-8de4-0361cb1c7700",
    "insertionTime": "2026-10-30T18:40:44+00:00",
    "popReceipt": null,
    "timeNextVisible": null
  }
]
```

A mensagem mantém o conteúdo, que a próxima seção lê. Nada no app vai tirá-la de `orders-poison`:
ela fica lá até alguém apagá-la ou até expirar, uma semana depois de ter sido posta lá, pelas datas
acima.

## As configurações por trás desse comportamento

O cinco e a rajada são configurações da extensão de filas, e o host as imprime quando começa:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -A8 '^      QueuesOptions'
      QueuesOptions
      {
        "BatchSize": 16,
        "NewBatchThreshold": 32,
        "MaxPollingInterval": "00:01:00",
        "MaxDequeueCount": 5,
        "VisibilityTimeout": "00:00:00",
        "MessageEncoding": "Base64"
      }
ana@laptop:~/azure$ docker exec shopfn nproc
4
```

`MaxDequeueCount` é o cinco. `VisibilityTimeout` zero é o motivo de as tentativas virem em rajada:
**uma mensagem que falhou fica visível de novo na hora**, então uma causa que passa em poucos
segundos, um banco de dados reiniciando, por exemplo, pode gastar as cinco tentativas antes de
passar. `BatchSize` é quantas mensagens o host tira da fila de uma vez, e o host busca mais quando
as mensagens ainda em trabalho caem para `NewBatchThreshold`. A documentação dá o padrão dele como N
× `BatchSize` / 2, onde N é o número de vCPUs nos planos App Service e Premium e 1 no plano
Consumption. O 32 daqui bate com 16 × 4 / 2 para os quatro processadores que o `nproc` informou.
`MaxPollingInterval` é o máximo que o host espera entre consultas a uma fila vazia, e
`MessageEncoding` é da próxima seção.

Cada uma delas se ajusta no `host.json`, em `extensions.queues`. Para esperar trinta segundos entre
tentativas e desistir depois de três, o arquivo teria um bloco `extensions` como este ao lado do
`extensionBundle`. Ele aparece sozinho aqui, e esta aula não o usa:

```json
{
  "version": "2.0",
  "extensions": {
    "queues": {
      "maxDequeueCount": 3,
      "visibilityTimeout": "00:00:30"
    }
  }
}
```

**A nova tentativa serve para causas que passam, e a fila poison para as que não passam.** Um
produto desconhecido vai falhar em toda tentativa, e tentar de novo não ajuda em nada. Uma função
que sabe distinguir as duas faz melhor recusando ela mesma a mensagem ruim, registrando o motivo e
retornando normalmente, o que a apaga da fila. O que `make_receipt` faz em vez disso, levantar uma
exceção por falta de preço, gasta cinco tentativas numa resposta que podia ter tido na primeira.
