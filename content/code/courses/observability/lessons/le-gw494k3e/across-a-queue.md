---
title: Across a queue
version: 1
---

A queue breaks the picture of a request in the same place lesson 3 found: the caller does not wait
for the work it causes. `orders` publishes the paid order and answers the storefront at once, and
the mailer takes the message whenever it gets to it. **The context has to ride inside the message.**
The lab's two services write the same inject and extract as HTTP, with the message's headers as the
carrier:

```schooling-example
{
  "language": "python",
  "file": "orders/app.py",
  "parts": [
    {
      "code": "def publish(order):\n    headers = {}\n    propagate.inject(headers)\n",
      "note": "The same inject as over HTTP, into a dictionary that will become the message's headers. The current span is Flask's `POST /orders`."
    },
    {
      "code": "    with pika.BlockingConnection(pika.ConnectionParameters(RABBIT)) as conn:\n        channel = conn.channel()\n        channel.queue_declare(\"orders.placed\", durable=True)\n        channel.basic_publish(\n            exchange=\"\",\n            routing_key=\"orders.placed\",\n            body=json.dumps(order),\n            properties=pika.BasicProperties(headers=headers, delivery_mode=2),\n        )",
      "note": "AMQP messages have headers of their own, and the context rides in them beside the body."
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
      "note": "Extract from the message's headers, whenever the message is taken off the queue. `or {}` covers a message published by somebody who sent no headers at all."
    },
    {
      "code": "    with tracer.start_as_current_span(\"orders.placed process\", context=ctx, kind=SpanKind.CONSUMER) as span:",
      "note": "A `CONSUMER` span under the extracted context: the messaging counterpart of `SERVER`."
    }
  ]
}
```

To see the header on the message itself, the mailer is stopped, so a checkout's message stays on
the queue. RabbitMQ's management API can show a message and put it back:

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

The body is the order, and beside it, in the AMQP headers, **the same `traceparent` format the HTTP
calls carry**. Twenty seconds later the mailer is started again and takes the message. The
checkout's trace is then read with each span's start in seconds from the first:

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

The mailer's spans joined the checkout's trace **22.8 seconds after the rest**, and the gap is real
information: it is how long the message sat in the queue. A trace across a queue measures waiting
nobody would see otherwise, which is what makes *the e-mails are late* debuggable.

The messaging conventions go one step further than the lab does: the publisher opens a `PRODUCER`
span around the publish, and the consumer's span can name it. `orders` opens no such span, because
nothing instruments `pika` here, so the mailer's parent is `POST /orders` itself. The
instrumentation package for `pika`, `opentelemetry-instrumentation-pika`, does both halves and adds
the producer span. The lab writes the calls by hand because seeing them once is the point of this
lesson.
