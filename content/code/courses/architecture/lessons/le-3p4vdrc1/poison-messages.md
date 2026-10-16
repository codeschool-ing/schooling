---
title: The message that fails every time
version: 1
---

At least once has one more failure, and it is the one that stops a whole queue. A **poison message** is
one that can never be processed: a body that is not valid JSON, an order id that does not exist, a
field the consumer does not understand. If the consumer simply fails and lets the broker redeliver,
the message comes back, fails again, comes back again. On a queue with order, it blocks everything
behind it; on any queue, it burns a consumer in a loop for ever.

**A failure that will never succeed has to be told apart from one that might**, and the two go to
different places:

| the failure | example | what to do |
| --- | --- | --- |
| transient | the database timed out, the card processor answered 503 | retry, with a delay, lesson 11 |
| permanent | the body cannot be parsed, the product does not exist | set the message aside for a person |

## The dead-letter queue

The place aside is a **dead-letter queue**. In RabbitMQ a queue declares `x-dead-letter-exchange`, as
`charges` does in `topology.py`, and a message the consumer rejects with `requeue=False`, or one that
expires, is republished there instead of being dropped. `pay.py` treats a body that is not JSON as
permanent and rejects it.

Publish one broken payment request and run the consumer:

```
ana@vm:~/lab/delivery$ $R publish.py q-4 899 --broken
confirmed by the broker: q-4
ana@vm:~/lab/delivery$ $R pay.py
rejected q-4: not JSON, sent to the dead-letter queue
ana@vm:~/lab/delivery$ docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet
name	messages
charges.dead	1
charges	0
```

The broker confirmed `q-4`, because it was a perfectly good message as far as the broker could tell. The
consumer could not parse it, said so, and rejected it. **`charges` is empty and keeps flowing;
`charges.dead` holds the one message nobody could handle**, with its headers recording where it came
from and why it died.

## A dead-letter queue is a promise to look

A dead-letter queue that nobody reads is a slower way of dropping messages. It needs an alert when it
is not empty, a person who looks at what arrived, and a way to send a message back to its queue once the
cause is fixed. Managed queues have the same idea under the same name: SQS's redrive policy moves a
message after a set number of receives, and Service Bus and Pub/Sub have dead-letter settings of their
own.

When you are done with the lesson, stop its broker and remove its volume:

```sh
docker compose down -v
```
