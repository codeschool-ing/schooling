---
title: RabbitMQ in three pieces, and a worker that dies
version: 1
---

**In RabbitMQ a producer never writes to a queue.** It publishes to an **exchange**, the exchange
decides which queues get a copy, and consumers read from queues. A **binding** is the rule that
joins a queue to an exchange. That indirection is what the next section uses for routing; for a
plain work queue, RabbitMQ has a **default exchange**, named with the empty string, that delivers a
message to the queue whose name equals its routing key. So publishing to `""` with the key
`packing` puts the message in the queue `packing`, and the exchange stays out of sight.

The website's side puts orders on the queue. Save this as `~/work/rabbit_send.py`:

```python
"""rabbit_send.py: put Ponto Final's online orders on a RabbitMQ queue, to be packed.

    python rabbit_send.py [--count N]
"""
import argparse
import json

import pika

args = argparse.ArgumentParser()
args.add_argument("--count", type=int, default=6)
args = args.parse_args()

conn = pika.BlockingConnection(pika.ConnectionParameters("localhost"))
ch = conn.channel()
ch.queue_declare(queue="packing", durable=True)

for n in range(1, args.count + 1):
    order = {"order": f"web-{n:04d}", "shop": "recife", "books": n % 3 + 1}
    ch.basic_publish(
        exchange="",
        routing_key="packing",
        body=json.dumps(order),
        properties=pika.BasicProperties(delivery_mode=pika.DeliveryMode.Persistent),
    )
print(f"queued {args.count} orders")
conn.close()
```

`queue_declare` creates the queue if it does not exist and does nothing if it does, so both sides
call it and either can start first. **`durable=True` makes the queue survive a restart of the
server, and a persistent delivery mode does the same for each message**; RabbitMQ needs both, and a
durable queue full of non-persistent messages comes back empty.

The packer's side, as `~/work/rabbit_work.py`:

```schooling-example
@file rabbit_work.py
@lang python
--- A packer, with a name so its output can be told apart, a time per order, and a way to crash on purpose.
"""rabbit_work.py: a packer. Takes orders off the queue one at a time.

    python rabbit_work.py NAME [--seconds S] [--crash-after N]
"""
import argparse
import json
import os
import time

import pika

args = argparse.ArgumentParser()
args.add_argument("name")
args.add_argument("--seconds", type=float, default=1)
args.add_argument("--crash-after", type=int, default=0)
args = args.parse_args()
--- **`prefetch_count=1` lets the server send this consumer one unacknowledged message at a time.** Without it, RabbitMQ pushes as many as it can, and a slow packer holds orders a free one could be packing.
conn = pika.BlockingConnection(pika.ConnectionParameters("localhost"))
ch = conn.channel()
ch.queue_declare(queue="packing", durable=True)
ch.basic_qos(prefetch_count=1)
done = 0
--- The work. `method.redelivered` is the server saying it has handed this message out before.
def pack(ch, method, properties, body):
    global done
    order = json.loads(body)
    again = " (redelivered)" if method.redelivered else ""
    print(f"{args.name}: packing {order['order']}{again}", flush=True)
    time.sleep(args.seconds)
--- With `--crash-after N`, the packer finishes N orders and then dies in the middle of the next one, **after the work and before the acknowledgement**, the worst moment there is. `os._exit` ends the process at once, as a kill would.
    if args.crash_after and done == args.crash_after:
        print(f"{args.name}: crashed before acknowledging {order['order']}", flush=True)
        os._exit(1)
--- **`basic_ack` is the moment the message is deleted.** Until it arrives the server keeps the order, marked as unacknowledged, for this consumer only.
    ch.basic_ack(delivery_tag=method.delivery_tag)
    done += 1
--- Register the callback and wait for messages, for ever. Ctrl+C closes the connection politely, which hands back anything not yet acknowledged.
ch.basic_consume(queue="packing", on_message_callback=pack)
try:
    ch.start_consuming()
except KeyboardInterrupt:
    print(f"{args.name}: stopped after {done} orders")
    conn.close()
```

## Two packers, and one that dies

Queue six orders and ask the server what it holds. `messages_ready` are waiting for a consumer,
`messages_unacknowledged` have been handed out and not yet acknowledged:

```
ubuntu@stream:~/work$ python rabbit_send.py
```

Now two packers. In the **second shell**, Ana, who packs everything she is given:

```
ubuntu@stream:~/work$ python rabbit_work.py ana
```

And in a **third shell** — open one more, the way you opened the second — Bia, who will crash
during her second order:

```
ubuntu@stream:~/work$ python rabbit_work.py bia --crash-after 1
```

After a few seconds Bia's shell is back at the prompt:

```
ubuntu@stream:~/work$ python rabbit_work.py bia --crash-after 1
```

Ana is still waiting for more. In the first shell, ask the server again:

```
ubuntu@stream:~/work$ sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged consumers
```

The queue is empty, and one consumer, Ana, is still attached. Stop her with Ctrl+C, and her shell
shows what she did:

```
ubuntu@stream:~/work$ python rabbit_work.py ana
```

Follow `web-0004`. The server gave it to Bia; Bia packed it and died before saying so. **The
connection closing was enough for the server to know**: an unacknowledged message whose consumer
has gone goes back on the queue, and Ana got it, marked `redelivered`. Nothing was lost. And
`web-0004` was packed twice — once by Bia, whose work went nowhere, once by Ana. That is
at-least-once delivery, lesson 7's guarantee, from a different broker; the `redelivered` flag is a
hint that the work may already have happened, and making the packing itself idempotent is
lesson 8's answer, not the broker's.

**The six messages are gone from the server.** There is no offset to rewind and no `--from-beginning`
to add: the orders exist now only in whatever the packers did with them.
