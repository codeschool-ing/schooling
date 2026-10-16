---
title: "Pollers: SQS batches and stream shards"
version: 1
---

With a queue or a stream, nothing calls the function; Lambda reads the source for it. **The unit of
work is then a batch, and the hard question is what one bad record does to the rest of its
batch.** For SQS the answer can be "nothing", if the handler says which messages failed. For a
stream it is "everything behind it", unless the mapping is told how to give up. Both answers are
settings of the event source mapping, and moto keeps them.

## The mapping for a queue

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name orders --query QueueUrl
"http://localhost:4567/123456789012/orders"
ana@laptop:~/aws$ aws lambda create-event-source-mapping --function-name orders --event-source-arn arn:aws:sqs:sa-east-1:123456789012:orders --batch-size 10 --maximum-batching-window-in-seconds 5 --function-response-types ReportBatchItemFailures --query "{State:State,BatchSize:BatchSize,Window:MaximumBatchingWindowInSeconds,Responses:FunctionResponseTypes}"
{
    "State": "Enabled",
    "BatchSize": 10,
    "Window": 5,
    "Responses": [
        "ReportBatchItemFailures"
    ]
}
```

Three settings, each a trade. **`--batch-size 10`** is the most messages one invocation receives,
and fewer invocations of more messages cost fewer requests. **`--maximum-batching-window-in-seconds
5`** lets the poller wait up to five seconds to fill a batch, which saves invocations when traffic
is thin and adds up to five seconds of delay to each message; without it, a batch goes as soon as
there is anything to send. And **`ReportBatchItemFailures`** changes what the function's answer
means, which is the rest of this section.

moto records the mapping and polls nothing, so what follows ran in the emulator instead, with an
event in the shape AWS documents for SQS. It was written by hand for this lesson, three messages of
which the second is not an order. Save it as `~/aws/sqs-event.json`:

```json
{
  "Records": [
    {
      "messageId": "m-1",
      "receiptHandle": "rh-1",
      "body": "{\"id\": \"A-1\", \"total\": 1299.9}",
      "attributes": {
        "ApproximateReceiveCount": "1"
      },
      "messageAttributes": {},
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:sa-east-1:123456789012:orders",
      "awsRegion": "sa-east-1"
    },
    {
      "messageId": "m-2",
      "receiptHandle": "rh-2",
      "body": "not an order",
      "attributes": {
        "ApproximateReceiveCount": "1"
      },
      "messageAttributes": {},
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:sa-east-1:123456789012:orders",
      "awsRegion": "sa-east-1"
    },
    {
      "messageId": "m-3",
      "receiptHandle": "rh-3",
      "body": "{\"id\": \"A-3\", \"total\": 45.0}",
      "attributes": {
        "ApproximateReceiveCount": "1"
      },
      "messageAttributes": {},
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:sa-east-1:123456789012:orders",
      "awsRegion": "sa-east-1"
    }
  ]
}
```

## One bad message in a batch

By default, a batch succeeds or fails as a whole. If the handler raises, every message in the batch
becomes visible on the queue again once its visibility timeout runs out, and the next batch
delivers them all a second time, including the ones that were fine. **Behind a retry, the good
messages are processed twice and the bad one keeps failing**, until the queue's redrive policy
moves it to a dead-letter queue after so many receives, which lesson 21 sets up.

The partial batch response avoids both. This handler deals with each message on its own and
answers with the ones it could not do. Save it as `~/aws/orders/orders.py`:

```schooling-example
{"language": "python", "file": "orders.py", "parts": [{"code": "import json\n\n\ndef handler(event, context):\n    failures = []\n", "note": "One SQS batch is one event. `failures` collects the messages this invocation could not handle, and nothing else."}, {"code": "    for record in event['Records']:\n        try:\n            order = json.loads(record['body'])\n            print(f\"order {order['id']}: {order['total']}\")\n", "note": "Each record is one message, its text in `body`. The work for one message sits inside its own `try`, so one bad message cannot take the others down with it."}, {"code": "        except (ValueError, KeyError) as err:\n            print(f\"cannot read {record['messageId']}: {err!r}\")\n            failures.append({'itemIdentifier': record['messageId']})\n", "note": "A message that fails is named by its `messageId`. Raising here instead would fail the whole batch, and every message in it would come back."}, {"code": "    return {'batchItemFailures': failures}\n", "note": "**The partial batch response.** With `ReportBatchItemFailures` on the mapping, Lambda deletes every message not in this list and leaves the listed ones in the queue. An empty list means the whole batch succeeded."}]}
```

```
ana@laptop:~/aws$ docker run --rm -d --name orders -p 9000:8080 -v "$PWD/orders":/var/task:ro public.ecr.aws/lambda/python:3.12 orders.handler
d7028bb9fe9c27ad9a049a055504fa5128a9380959d5d2be507c1bfb15502aef
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d @sqs-event.json; echo
{"batchItemFailures": [{"itemIdentifier": "m-2"}]}
ana@laptop:~/aws$ docker logs orders 2>&1 | grep -E '^(order|cannot)'
order A-1: 1299.9
cannot read m-2: JSONDecodeError('Expecting value: line 1 column 1 (char 0)')
order A-3: 45.0
ana@laptop:~/aws$ docker stop orders
orders
```

`A-1` and `A-3` were handled, `m-2` could not be read, and the answer names `m-2` alone. On AWS,
with `ReportBatchItemFailures` on the mapping, Lambda now deletes the two good messages from the
queue and leaves `m-2` to come back on its own. **Without that setting the same answer means
success for all three**, and `m-2` is deleted unread: the response is only read when the mapping
asks for it. Raising an exception still fails the whole batch either way.

## Streams: the shard is a line

DynamoDB Streams and Kinesis are not queues. A stream is divided into **shards**, the records in a
shard are kept in order, and the mapping reads each shard with a position in it, moving forward
only when a batch succeeds. Create a table whose changes go to a stream, and a mapping for it:

```
ana@laptop:~/aws$ aws dynamodb create-table --table-name carts --attribute-definitions AttributeName=id,AttributeType=S --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES --query TableDescription.LatestStreamArn
"arn:aws:dynamodb:sa-east-1:123456789012:table/carts/stream/2026-10-16T16:50:22.203886"
ana@laptop:~/aws$ STREAM=$(aws dynamodb describe-table --table-name carts --query Table.LatestStreamArn --output text)
ana@laptop:~/aws$ aws lambda create-event-source-mapping --function-name orders --event-source-arn "$STREAM" --starting-position TRIM_HORIZON --batch-size 100 --bisect-batch-on-function-error --maximum-retry-attempts 2 --query "{State:State,Start:StartingPosition,Bisect:BisectBatchOnFunctionError,Retries:MaximumRetryAttempts}"
{
    "State": "Enabled",
    "Start": "TRIM_HORIZON",
    "Bisect": true,
    "Retries": 2
}
ana@laptop:~/aws$ aws lambda list-event-source-mappings --function-name orders --query "EventSourceMappings[].[EventSourceArn,State,BatchSize]" --output text
arn:aws:sqs:sa-east-1:123456789012:orders	Enabled	10
arn:aws:dynamodb:sa-east-1:123456789012:table/carts/stream/2026-10-16T16:50:22.203886	Enabled	100
```

**`--starting-position TRIM_HORIZON`** starts at the oldest record the stream still holds, where
`LATEST` would start at the next one written. A DynamoDB stream keeps records for 24 hours; a
mapping that falls further behind than that loses what expired.

The difference from SQS is what a failure does. **A batch that fails is retried, and nothing behind
it in that shard is read until it succeeds**, because skipping it would break the order the stream
exists to keep. One record the function cannot handle would stop its shard for a day, and the
record's age is the alarm that says so. Three settings bound that:

- **`--maximum-retry-attempts 2`** gives up on a batch after two retries;
- **`--bisect-batch-on-function-error`** splits a failing batch in two and retries the halves, so
  the one bad record ends up alone and the good ones around it get through;
- an **on-failure destination**, an SQS queue or SNS topic, receives a description of the records
  given up on, so they can be looked at instead of lost.

moto accepted the first two and runs none of them, since it reads no stream for a function. The
behaviour above is AWS's, from its documentation, and was not run here. The last command shows the
function with both of its mappings, one per source.

## What the batch costs you in the handler

Every poller hands over a list. The handler is a loop, and the loop's error handling is the design:
**catch per record, report per record**, as `orders.py` does, for SQS and also for streams, where
the same `batchItemFailures` answer tells the mapping the sequence number to resume from. A handler
that processes a batch with one `try` around the whole loop has chosen, without saying so, that one
bad record fails every record with it.
