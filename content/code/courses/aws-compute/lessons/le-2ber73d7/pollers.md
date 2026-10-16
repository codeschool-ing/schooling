---
title: x
version: 1
---

```schooling-example
{"language": "python", "file": "orders.py", "parts": [{"code": "import json\n\n\ndef handler(event, context):\n    failures = []\n", "note": "One SQS batch is one event. `failures` collects the messages this invocation could not handle, and nothing else."}, {"code": "    for record in event['Records']:\n        try:\n            order = json.loads(record['body'])\n            print(f\"order {order['id']}: {order['total']}\")\n", "note": "Each record is one message, its text in `body`. The work for one message sits inside its own `try`, so one bad message cannot take the others down with it."}, {"code": "        except (ValueError, KeyError) as err:\n            print(f\"cannot read {record['messageId']}: {err!r}\")\n            failures.append({'itemIdentifier': record['messageId']})\n", "note": "A message that fails is named by its `messageId`. Raising here instead would fail the whole batch, and every message in it would come back."}, {"code": "    return {'batchItemFailures': failures}\n", "note": "**The partial batch response.** With `ReportBatchItemFailures` on the mapping, Lambda deletes every message not in this list and leaves the listed ones in the queue. An empty list means the whole batch succeeded."}]}
```

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
