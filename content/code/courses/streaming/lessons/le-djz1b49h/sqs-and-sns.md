---
title: SQS and SNS, a queue and a fan-out you do not run
version: 1
---

**Amazon SQS is a queue as a service, and SNS is a fan-out as a service.** There is no server to
install, patch or size: you create a queue with an API call, and Amazon charges per request. The
model is RabbitMQ's with different names and one important difference in how a message is taken.

**In SQS nothing is pushed to a consumer, and nothing is acknowledged.** A consumer asks for
messages; each one it receives becomes **invisible** to everybody else for the queue's *visibility
timeout*; and the consumer deletes it when the work is done. A consumer that dies, or takes longer
than the timeout, does not delete it, so the message becomes visible again and somebody else
receives it. RabbitMQ notices a dead consumer by its connection closing; SQS has no connection to
watch, so it uses a clock. That is at-least-once delivery again, with a timer instead of a socket.

## The emulator

Everything below runs against moto, the emulator installed earlier in this lesson, and **not against
AWS**. Start it in the **second shell** and leave it there; it answers on port 5000:

```
ubuntu@stream:~/work$ moto_server -p 5000
```

The program talks to it with `boto3`, exactly as it would talk to AWS, except for the
`endpoint_url` and the made-up credentials. Removing those two is all it would take to point it at
a real account — and at a real bill. Save it as `~/work/sqs_demo.py`:

```schooling-example
{
  "file": "sqs_demo.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"sqs_demo.py: SQS and SNS, against the moto emulator on localhost:5000 (not AWS).\n\n    python sqs_demo.py visibility | fifo | fanout\n\"\"\"\nimport json\nimport sys\nimport time\n\nimport boto3\n\nAWS = dict(endpoint_url=\"http://localhost:5000\", region_name=\"us-east-1\",\n           aws_access_key_id=\"testing\", aws_secret_access_key=\"testing\")\nsqs = boto3.client(\"sqs\", **AWS)\nsns = boto3.client(\"sns\", **AWS)",
      "note": "**The endpoint and the fake keys are the only things that make this moto rather than AWS.** Both clients, SQS and SNS, go to the same emulator."
    },
    {
      "code": "def receive(url, wait=0):\n    r = sqs.receive_message(QueueUrl=url, MaxNumberOfMessages=10, WaitTimeSeconds=wait,\n                            MessageSystemAttributeNames=[\"ApproximateReceiveCount\"])\n    return r.get(\"Messages\", [])",
      "note": "Receive up to ten messages, and ask for how many times each one has been received, which SQS counts for you."
    },
    {
      "code": "def visibility():\n    url = sqs.create_queue(QueueName=\"labels\",\n                           Attributes={\"VisibilityTimeout\": \"5\"})[\"QueueUrl\"]\n    sqs.send_message(QueueUrl=url, MessageBody=\"web-0001\")\n    m = receive(url)[0]\n    print(f\"worker A got {m['Body']}, and crashes without deleting it\")\n    print(f\"worker B, at once: {len(receive(url))} messages\")\n    time.sleep(6)\n    m = receive(url)[0]\n    count = m[\"Attributes\"][\"ApproximateReceiveCount\"]\n    print(f\"worker B, 6 s later: got {m['Body']}, received {count} times\")\n    sqs.delete_message(QueueUrl=url, ReceiptHandle=m[\"ReceiptHandle\"])\n    print(f\"after delete: {len(receive(url))} messages\")",
      "note": "**The visibility timeout, played out.** A queue whose messages hide for 5 seconds; worker A receives one and never deletes it; worker B looks at once, then after 6 seconds."
    },
    {
      "code": "def fifo():\n    url = sqs.create_queue(QueueName=\"stock.fifo\",\n                           Attributes={\"FifoQueue\": \"true\"})[\"QueueUrl\"]\n    for sale, dedup in [(\"rec-1 bk-02 -1\", \"rec-1\"), (\"rec-1 bk-02 -1\", \"rec-1\"),\n                        (\"rec-2 bk-02 -1\", \"rec-2\")]:\n        sqs.send_message(QueueUrl=url, MessageBody=sale, MessageGroupId=\"recife\",\n                         MessageDeduplicationId=dedup)\n        print(f\"sent {sale!r} with deduplication id {dedup}\")\n    got = [m[\"Body\"] for m in receive(url)]\n    print(f\"received {got}\")",
      "note": "**A FIFO queue**: its name must end in `.fifo`. The group id orders messages, and a deduplication id seen before is dropped. The same sale is sent twice, as a retrying till would."
    },
    {
      "code": "def fanout():\n    topic = sns.create_topic(Name=\"sales\")[\"TopicArn\"]\n    urls = {}\n    for name in [\"stock-updates\", \"loyalty-points\"]:\n        urls[name] = sqs.create_queue(QueueName=name)[\"QueueUrl\"]\n        arn = sqs.get_queue_attributes(QueueUrl=urls[name], AttributeNames=[\"QueueArn\"])\n        sns.subscribe(TopicArn=topic, Protocol=\"sqs\", Endpoint=arn[\"Attributes\"][\"QueueArn\"],\n                      Attributes={\"RawMessageDelivery\": \"true\"})\n    sns.publish(TopicArn=topic, Message=json.dumps({\"sale\": \"rec-000001\", \"cents\": 5490}))\n    for name, url in urls.items():\n        print(f\"{name}: {[m['Body'] for m in receive(url)]}\")",
      "note": "**SNS fan-out.** One topic, two SQS queues subscribed to it, one message published. Raw delivery passes the body as it was published rather than wrapped in SNS's own JSON envelope."
    },
    {
      "code": "{\"visibility\": visibility, \"fifo\": fifo, \"fanout\": fanout}[sys.argv[1]]()",
      "note": "Run the part named on the command line."
    }
  ]
}
```

## Visibility, and the receive count

```
ubuntu@stream:~/work$ python sqs_demo.py visibility
```

Worker B sees nothing while the message is hidden, and gets it once the timeout has passed, with a
receive count of 2. **The timeout has to be longer than the work takes.** If packing an order takes
40 seconds and the timeout is 30, every order is handed to a second packer while the first is still
on it — duplicates on every message, with no crash anywhere. A queue can also be given a
**redrive policy**, SQS's dead-letter queue: after a set number of receives, the message moves to
another queue instead of coming back again.

## FIFO, and a deduplication window

A standard SQS queue promises neither order nor a single delivery: a message may arrive twice and
out of order, and the consumer copes. A **FIFO queue** promises both within a *message group*, at a
lower throughput. Two of the three sends below are the same sale, as a till retrying after a timeout
would send it:

```
ubuntu@stream:~/work$ python sqs_demo.py fifo
```

Three sent, two received: the second `rec-1` was dropped because its deduplication id had been seen.
**AWS keeps those ids for five minutes**, by its own documentation; a retry that arrives later is a
new message. That was not tested here, because the emulator's clock is not AWS's. It is the same
bounded window as lesson 8's deduplication table, chosen for you.

## SNS: one message, every subscriber

```
ubuntu@stream:~/work$ python sqs_demo.py fanout
```

One publish, one copy in each subscribed queue. **SNS plus a queue per reader is the AWS spelling of
RabbitMQ's fanout exchange**, and it has the same limit: a queue subscribed tomorrow does not
receive today's sales. When you are done, stop moto with Ctrl+C in the second shell; it keeps
everything in memory, so every queue and topic it made disappears with it.
