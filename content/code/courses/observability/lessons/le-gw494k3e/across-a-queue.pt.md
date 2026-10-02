---
title: Através de uma fila
version: 1
---

Uma fila quebra a imagem de uma requisição no mesmo lugar que a aula 3 achou: quem chama não espera
o trabalho que causa. O `orders` publica o pedido pago e responde à vitrine na hora, e o mailer pega
a mensagem quando chegar a vez dela. **O contexto tem de viajar dentro da mensagem**, e os dois
serviços do laboratório escrevem o mesmo inject e extract do HTTP, com os cabeçalhos da mensagem
como portador:

```schooling-example
{
  "language": "python",
  "file": "orders/app.py",
  "parts": [
    {
      "code": "def publish(order):\n    headers = {}\n    propagate.inject(headers)\n",
      "note": "O mesmo inject que por HTTP, num dicionário que vai virar os cabeçalhos da mensagem. O span corrente é o `POST /orders` do Flask."
    },
    {
      "code": "    with pika.BlockingConnection(pika.ConnectionParameters(RABBIT)) as conn:\n        channel = conn.channel()\n        channel.queue_declare(\"orders.placed\", durable=True)\n        channel.basic_publish(\n            exchange=\"\",\n            routing_key=\"orders.placed\",\n            body=json.dumps(order),\n            properties=pika.BasicProperties(headers=headers, delivery_mode=2),\n        )",
      "note": "Mensagens AMQP têm cabeçalhos próprios, e o contexto vai neles ao lado do corpo."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "mailer/worker.py",
  "parts": [
    {
      "code": "def handle(channel, method, properties, body):\n    ctx = propagate.extract(properties.headers or {})\n",
      "note": "Extract dos cabeçalhos da mensagem, quando quer que ela saia da fila. O `or {}` cobre uma mensagem publicada por alguém que não mandou cabeçalho nenhum."
    },
    {
      "code": "    with tracer.start_as_current_span(\"orders.placed process\", context=ctx, kind=SpanKind.CONSUMER) as span:",
      "note": "Um span `CONSUMER` sob o contexto extraído: o equivalente em mensageria do `SERVER`."
    }
  ]
}
```

Para ver o cabeçalho na própria mensagem, o mailer é parado, e assim a mensagem de um checkout fica
na fila. A API de gerenciamento do RabbitMQ consegue mostrar uma mensagem e devolvê-la:

```
ana@obs:~/shop$ docker compose stop mailer
 Container shop-mailer-1 Stopping 
 Container shop-mailer-1 Stopped 
```

```
ana@obs:~/shop$ curl -s -u guest:guest -H 'Content-Type: application/json' -X POST localhost:15672/api/queues/%2F/orders.placed/get -d '{"count": 1, "ackmode": "ack_requeue_true", "encoding": "auto"}' | jq '.[0] | {payload, headers: .properties.headers}'
{
  "payload": "{\"id\": 3, \"sku\": \"kettle\", \"qty\": 1, \"status\": \"paid\"}",
  "headers": {
    "traceparent": "00-f8cdb58e9faf2978f1d207747f46300b-199648611b829bd8-03"
  }
}
```

O corpo é o pedido, e ao lado dele, nos cabeçalhos AMQP, **o mesmo formato `traceparent` que as
chamadas HTTP levam**. Vinte segundos depois o mailer é iniciado de novo, pega a mensagem, e o
rastro do checkout é lido com o início de cada span em segundos a partir do primeiro:

```
ana@obs:~/shop$ docker compose start mailer
 Container shop-mailer-1 Starting 
 Container shop-mailer-1 Started 
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f8cdb58e9faf2978f1d207747f46300b | jq -r '.data[0] as $t | ($t.spans | map(.startTime) | min) as $t0 | $t.spans | sort_by(.startTime) | .[] | [$t.processes[.processID].serviceName, .operationName, "at " + ((.startTime - $t0)/1000000*10|floor/10|tostring) + " s"] | @tsv'
storefront	POST /checkout	at 0 s
orders	POST /orders	at 0 s
orders	INSERT	at 0 s
orders	POST	at 0 s
payments	POST /charge	at 0 s
orders	UPDATE	at 0 s
mailer	orders.placed process	at 22.8 s
mailer	send confirmation	at 22.8 s
```

Os spans do mailer entraram no rastro do checkout **22,8 segundos depois do resto**, e o intervalo é
informação de verdade: é quanto tempo a mensagem ficou na fila. Um rastro através de uma fila mede
uma espera que ninguém veria de outro jeito, e é isso que torna *os e-mails estão atrasados* algo
depurável.

As convenções de mensageria vão um passo além do laboratório: quem publica abre um span `PRODUCER`
em volta da publicação, e o span do consumidor pode apontar para ele. O `orders` não abre esse span,
porque nada instrumenta o `pika` aqui, então o pai do mailer é o próprio `POST /orders`. O pacote de
instrumentação para o `pika`, `opentelemetry-instrumentation-pika`, faz as duas metades e acrescenta
o span de produtor; o laboratório escreve as chamadas à mão porque vê-las uma vez é o objetivo desta
aula.
