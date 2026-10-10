---
title: Dead letters, and messages nobody could handle
version: 1
---

**A message that cannot be handled has to go somewhere other than back to the front of the queue.**
A packer that rejects an order with an unreadable address and asks for it to be requeued gets the
same order back at once, rejects it again, and spends the rest of the day doing that, while the
orders behind it wait. The usual wrong fix is to acknowledge the bad message and log it, which
deletes the only copy. RabbitMQ's answer is a **dead-letter exchange**: a queue can name an exchange
to which it republishes every message it gives up on, and a queue bound there collects them for a
person or a program to look at.

A queue gives up on a message for three reasons, and the message carries which one in a header
called `x-death`:

| reason | what happened |
|---|---|
| `rejected` | a consumer rejected it with `requeue=False` |
| `expired` | it sat in the queue longer than its time to live, the **TTL** |
| `maxlen` | the queue was full, at the length it was given, and this was the oldest |

This program builds a queue of shipping labels with a dead-letter exchange and a TTL of two seconds,
puts three orders on it, rejects one, handles one and leaves the third alone. Save it as
`~/work/rabbit_dead.py`:

```schooling-example
{
  "file": "rabbit_dead.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"rabbit_dead.py: a queue whose rejected and expired messages go to a dead-letter queue.\"\"\"\nimport time\n\nimport pika\n\nconn = pika.BlockingConnection(pika.ConnectionParameters(\"localhost\"))\nch = conn.channel()\nch.exchange_declare(exchange=\"pf.dead\", exchange_type=\"fanout\")\nch.queue_declare(queue=\"labels.dead\")\nch.queue_bind(queue=\"labels.dead\", exchange=\"pf.dead\")",
      "note": "The dead-letter side: a fanout exchange and one queue bound to it, where everything given up on ends up."
    },
    {
      "code": "ch.queue_declare(queue=\"labels\", arguments={\n    \"x-dead-letter-exchange\": \"pf.dead\",\n    \"x-message-ttl\": 2000,\n})\n\nfor order in [\"web-0001\", \"web-0002\", \"web-0003\"]:\n    ch.basic_publish(exchange=\"\", routing_key=\"labels\", body=order)",
      "note": "**The queue's arguments are where both behaviours are set**: where its dead letters go, and how long, in milliseconds, a message may wait. They are fixed when the queue is created; declaring it again with different arguments is refused."
    },
    {
      "code": "method, _, body = ch.basic_get(queue=\"labels\")\nprint(f\"took {body.decode()}, the address is unreadable: reject it\")\nch.basic_reject(delivery_tag=method.delivery_tag, requeue=False)\nmethod, _, body = ch.basic_get(queue=\"labels\")\nprint(f\"took {body.decode()}, printed the label: ack it\")\nch.basic_ack(delivery_tag=method.delivery_tag)",
      "note": "One order rejected without requeueing, one acknowledged. **`requeue=False` is the difference between a dead letter and an endless loop.**"
    },
    {
      "code": "print(\"nobody takes web-0003; waiting 3 seconds\")\ntime.sleep(3)\nwhile (m := ch.basic_get(queue=\"labels.dead\", auto_ack=True))[0]:\n    death = m[1].headers[\"x-death\"][0]\n    print(f\"dead letter {m[2].decode()}: reason {death['reason']}, from queue {death['queue']}\")\nconn.close()",
      "note": "Wait past the TTL, then read the dead-letter queue and the reason each message carries."
    }
  ]
}
```

```
ubuntu@stream:~/work$ python rabbit_dead.py
```

Two dead letters for two different reasons, and the one that was handled is not among them. The
rejected order kept its body, so somebody can fix the address and publish it again; the expired one
says it expired, so nobody wastes time looking for a bug in the packer.

## TTL is a decision, not a cleanup

A TTL says **after this long, the message is no longer worth doing**. That is true of some work —
a price-change notice superseded by the next one, a reminder for an event that has passed — and
false of most: an order that waited too long still has to be packed. Without a dead-letter exchange,
an expired message is simply deleted, which is a quiet way to lose orders on the busiest day of the
year, exactly when the queue is longest. With one, expiry becomes a list somebody can work through.

**Nothing retries by itself.** A dead letter stays in its queue until something reads it. Lesson 16
does the same for Kafka with a dead-letter *topic*, written by the consumer rather than by the
broker, because a log has no per-message rejection to hang it on. The two arrive at the same
operational rule: a dead-letter queue that is not watched is a slower way of deleting messages, so
its length belongs on the same screen as the main queue's.
