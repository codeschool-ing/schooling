---
title: Choosing a broker
version: 1
---

The first question is not which product. It is **whether the messages are work to be done or a record
of what happened**, and the answer points at a family before it points at a name.

| if the messages are… | and you need… | reach for |
| --- | --- | --- |
| tasks for workers, each done once | routing by key or pattern, per-message retry, priorities | a queue: RabbitMQ, or SQS or Service Bus if you are on that cloud already |
| events many services will read, some not written yet | replay, new readers starting from the past, very high volume | a log: Kafka, or a managed Kafka |
| a few hundred messages a minute between two services | as little to operate as possible | the provider's managed queue |
| a feed for analytics and a feed for services | both | often a log, with each service's consumer group as its "queue" |

## Quitanda's answer

Quitanda publishes `OrderPlaced` to several services, and the analytics team has asked for the order
history to build a sales model next quarter. **That second wish decides it for orders**: a log keeps the
events for whoever comes later, and a queue would have deleted them. The warehouse's pick list, on the
other hand, is work for a small team of pickers, retried per item when a picker reports a problem, and
nobody will want to replay a pick list; a queue fits it, and running both is not unusual.

## What every choice costs

Whatever the broker, the same three questions arrive with it, and the broker answers none of them on its
own:

1. What happens when a message is delivered twice, or a consumer dies halfway through one?
2. Which messages need to be processed in order, and what key keeps them so?
3. What happens to a message that fails every time it is processed?

Those are lesson 7. They are the difference between a system that uses a broker and a system that
survives one.
