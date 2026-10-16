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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The visibility timeout of an SQS queue over six seconds. At 0 seconds worker A receives web-0001 and the message becomes invisible for 5 seconds. Worker B asks at once and gets nothing. Worker A crashes and never deletes it. At 5 seconds the message is visible again; at 6 seconds worker B receives it, with a receive count of 2, and deletes it.\" data-fig=\"l15-visibility\"><line x1=\"120\" y1=\"185\" x2=\"696.0\" y2=\"185\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"120\" y1=\"181\" x2=\"120\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"120\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"210\" y1=\"181\" x2=\"210\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"210\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"300\" y1=\"181\" x2=\"300\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"300\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"390\" y1=\"181\" x2=\"390\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><line x1=\"480\" y1=\"181\" x2=\"480\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"480\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"570\" y1=\"181\" x2=\"570\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"570\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"660\" y1=\"181\" x2=\"660\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"660\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seconds</text><rect x=\"120\" y=\"92\" width=\"450\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"345.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">invisible: visibility timeout 5 s</text><text x=\"576\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">visible again</text><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker A</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker B</text><circle cx=\"120\" cy=\"55\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"130\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">receives</text><circle cx=\"255.0\" cy=\"55\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"265.0\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">crashes, no delete</text><line x1=\"120\" y1=\"55\" x2=\"255.0\" y2=\"55\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><circle cx=\"124.5\" cy=\"150\" r=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"130\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">asks: 0 messages</text><circle cx=\"660\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"650\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">receives, count 2</text><text x=\"650\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">deletes</text></svg>", "caption": "SQS has no connection to watch, so a received message is hidden for a fixed time, and an undeleted one comes back when the time runs out."}
```

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
worker A got web-0001, and crashes without deleting it
worker B, at once: 0 messages
worker B, 6 s later: got web-0001, received 2 times
after delete: 0 messages
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
sent 'rec-1 bk-02 -1' with deduplication id rec-1
sent 'rec-1 bk-02 -1' with deduplication id rec-1
sent 'rec-2 bk-02 -1' with deduplication id rec-2
received ['rec-1 bk-02 -1', 'rec-2 bk-02 -1']
```

Three sent, two received: the second `rec-1` was dropped because its deduplication id had been seen.
**AWS keeps those ids for five minutes**, by its own documentation; a retry that arrives later is a
new message. That was not tested here, because the emulator's clock is not AWS's. It is the same
bounded window as lesson 8's deduplication table, chosen for you.

## SNS: one message, every subscriber

```
ubuntu@stream:~/work$ python sqs_demo.py fanout
stock-updates: ['{"sale": "rec-000001", "cents": 5490}']
loyalty-points: ['{"sale": "rec-000001", "cents": 5490}']
EXIT 0
```

One publish, one copy in each subscribed queue. **SNS plus a queue per reader is the AWS spelling of
RabbitMQ's fanout exchange**, and it has the same limit: a queue subscribed tomorrow does not
receive today's sales. When you are done, stop moto with Ctrl+C in the second shell; it keeps
everything in memory, so every queue and topic it made disappears with it.
