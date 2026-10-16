---
title: Ordering, duplicates and the consumer that does not care
version: 1
---

The comfortable assumption is that a message is delivered once and in the order it was sent.
**A standard SQS queue promises neither.** It delivers every message at least once, and
occasionally twice, and in roughly the order sent but not exactly. The first section showed one
cause of the second delivery, a consumer that does not delete in time; another is inside SQS,
which stores each message on several servers and can, rarely, hand out a copy one of them still
holds. In exchange a standard queue takes nearly unlimited throughput. Both promises can be bought
back, with a FIFO queue, and both can be made not to matter, with a consumer that does the same
work only once whatever arrives.

## FIFO: order per group, and duplicates dropped

A FIFO queue's name ends in `.fifo`, and every message carries two extra ids. The **message group
id** says which messages must stay in order relative to each other; the **deduplication id** says
which sends are the same message:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name orders.fifo --attributes FifoQueue=true --query QueueUrl --output text
http://localhost:4567/123456789012/orders.fifo
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-paid --message-body paid --query SequenceNumber --output text
91989792316542591463
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-paid --message-body paid --query SequenceNumber --output text
72866415318839542837
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-shipped --message-body shipped --query SequenceNumber --output text
63939971528844063907
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-43 --message-deduplication-id 43-paid --message-body paid --query SequenceNumber --output text
04655964262658135292
```

The second send repeated `42-paid`, a retry of a send whose answer was lost, and both sends were
accepted. Then a receive:

```
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/orders.fifo" --max-number-of-messages 10 --attribute-names MessageGroupId --query "Messages[].[Attributes.MessageGroupId, Body]" --output text
order-42	paid
order-42	shipped
order-43	paid
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-body paid

aws: [ERROR]: An error occurred (MissingParameter) when calling the SendMessage operation: The request must contain the parameter MessageGroupId.
```

**Three messages, not four**: the repeated `42-paid` was dropped, because a FIFO queue remembers a
deduplication id for five minutes. Within the group `order-42`, `paid` comes before `shipped`, and
while a message of a group is being processed the queue hands out no later message of that group,
so two consumers never handle the same order's events out of order. Groups are independent of each
other, which is where a FIFO queue's parallelism comes from: one group per order, per customer or
per account, never one group for everything. A FIFO queue without a group id is refused, as the
last command shows. With `ContentBasedDeduplication` turned on, the queue makes the
deduplication id itself from a hash of the body, and two identical bodies within five minutes
count as one.

The guarantee has edges. Deduplication covers five minutes and one queue; a producer that retries
after six minutes, or a consumer that fails after doing the work and before deleting, still
produces a second delivery. **FIFO narrows duplicates; it does not abolish them.**

## The consumer that does not care

So the reliable answer is on the consuming side: an **idempotent consumer**, one for which
handling the same message twice has the effect of handling it once. The usual way is the one
lesson 20 used for retries, an idempotency key carried in the message and a record of the keys
already done. Save this as `~/aws/consumer.py`:

```schooling-example
{"language": "python", "file": "consumer.py", "parts": [{"code": "import json\nimport sqlite3\n\nimport boto3\n\nQUEUE = \"https://sqs.sa-east-1.amazonaws.com/123456789012/payments\"\nsqs = boto3.client(\"sqs\")\n", "note": "boto3 is the AWS SDK for Python, and it is already in `~/aws/venv` because moto needs it. Like the command line, it reads `AWS_ENDPOINT_URL`, the keys and the region from the environment, so this file names no endpoint and holds no key."}, {"code": "db = sqlite3.connect(\"done.db\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS done (key TEXT PRIMARY KEY)\")\n\n\ndef charge(order):\n    print(f\"charging order {order['id']}: {order['total']} cents\")\n\n\n", "note": "The record of what has been done, in a SQLite file. The primary key is what makes it work: a second insert of the same key fails, and the database checks that, not the program. `charge` stands in for the call to a payment provider."}, {"code": "while True:\n    reply = sqs.receive_message(QueueUrl=QUEUE, MaxNumberOfMessages=10, WaitTimeSeconds=1)\n    messages = reply.get(\"Messages\", [])\n    if not messages:\n        break\n", "note": "Up to ten messages per request, waiting up to a second for them. A real consumer waits 20 seconds and never stops; this one stops when the queue is empty, so that a run in the lab ends."}, {"code": "    for m in messages:\n        order = json.loads(m[\"Body\"])\n        try:\n            with db:\n                db.execute(\"INSERT INTO done VALUES (?)\", (order[\"key\"],))\n                charge(order)\n        except sqlite3.IntegrityError:\n            print(f\"skipping {order['key']}: already done\")\n        sqs.delete_message(QueueUrl=QUEUE, ReceiptHandle=m[\"ReceiptHandle\"])\n", "note": "The key goes in first and the work happens inside the same transaction, so a charge that raises an error rolls the key back and the message comes round again. A key that is already there means the work was done: skip it, and delete the message either way."}]}
```

Three payments arrive in a standard queue, one of them twice:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name payments --query QueueUrl --output text
http://localhost:4567/123456789012/payments
ana@laptop:~/aws$ for o in 42 42 43; do aws sqs send-message --queue-url "$Q/payments" --message-body "{\"key\": \"charge-$o\", \"id\": \"$o\", \"total\": 1500}" --query MessageId --output text; done
4e73cb0a-def5-4a73-8dd9-2aea1c0779a2
adfadf9b-6e5c-44c6-8507-55a645ec9754
272f3aca-2e6d-4ac3-bd2b-62cb547de84f
```

The consumer drains the queue:

```
ana@laptop:~/aws$ python3 consumer.py
charging order 42: 1500 cents
skipping charge-42: already done
charging order 43: 1500 cents
```

It charged order 42 once, skipped its copy and charged 43. Later, the same payment arrives again,
as it would after a producer's retry:

```
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/payments" --message-body '{"key": "charge-42", "id": "42", "total": 1500}' --query MessageId --output text
bb2eeeaa-6a24-4784-98b0-928a401f7e8b
ana@laptop:~/aws$ python3 consumer.py
skipping charge-42: already done
```

It was skipped too, because the record of
`charge-42` is in `done.db` and not in the queue's memory. **The check is a unique key in a store
that outlives the message.** In production that store is a database the consumers share, often a
DynamoDB table written with a condition that the key does not yet exist, so that two consumers
holding two copies at the same moment cannot both win.

## What it costs

The sheet, as published on 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py integration | sed -n 14,18p
Queues, topics and buses
  SQS standard                                       0.4  per million
  SQS FIFO                                           0.5  per million
  SNS publish, after the first million               0.5  per million
  EventBridge custom event                             1  per million
```

A message that is sent, received and deleted costs three SQS requests. At 10 million orders a
month that is 30 million requests: 30 × 0.4 = 12.00 USD on a standard queue and 30 × 0.5 = 15.00
USD on a FIFO queue. Empty receives cost the same as full ones, which is where long polling earns
its place: a consumer asking ten times a second on an idle queue makes 10 × 2,592,000 =
25,920,000 requests in a 30-day month, 10.37 USD for nothing, against 2,592,000 / 20 = 129,600
with a 20-second wait, 0.05 USD.

Publishing the same 10 million orders to an SNS topic costs 9 × 0.5 = 4.50 USD, the first
million being free, and AWS does not charge for SNS deliveries to SQS queues. Putting them on an
EventBridge bus as custom events costs 10 × 1 = 10.00 USD. **Each request is counted in steps of
64 KB** on all three services, so a 100 KB message is billed as two.

## Which queue, then

A standard queue, with an idempotent consumer, is the default: it is cheaper, it scales without
thinking about groups, and the consumer has to be idempotent anyway. **A FIFO queue is for the
case where order within a key is the requirement**, such as an account's debits and credits or an
order's state changes, and then the group id is the decision that matters, because it decides
both the order and the parallelism.
