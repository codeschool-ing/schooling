---
title: "Queues: receive, hide, delete"
version: 1
---

A queue is easy to picture as a pipe: a message goes in one end and comes out the other. The
picture misses the step that matters. **Receiving a message from SQS does not remove it.** It
hides the message for a while, the visibility timeout, and the consumer has to delete it before
the time runs out. A consumer that crashes in the middle never deletes, the message reappears,
and another consumer gets it. That one rule is how a queue survives its consumers, and it is
also why every message can arrive more than once.

## A queue with somewhere to put the failures

A message that fails every time it is tried would otherwise come back for the queue's whole
retention period, four days by default. So the work queue gets a **dead-letter queue** first, and
a redrive policy that says when to give up. `$Q` saves typing the start of every queue's address,
in the form AWS uses, which moto accepts:

```
ana@laptop:~/aws$ Q=https://sqs.sa-east-1.amazonaws.com/123456789012
ana@laptop:~/aws$ aws sqs create-queue --queue-name work-dlq --query QueueUrl --output text
http://localhost:4567/123456789012/work-dlq
```

Save the settings as `~/aws/attrs.json`. The redrive policy is a JSON document written as a
string inside JSON, which is why it carries its own escaped quotes:

```json
{
  "VisibilityTimeout": "3",
  "RedrivePolicy": "{\"deadLetterTargetArn\": \"arn:aws:sqs:sa-east-1:123456789012:work-dlq\", \"maxReceiveCount\": \"3\"}"
}
```

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name work --attributes file://attrs.json --query QueueUrl --output text
http://localhost:4567/123456789012/work
```

`VisibilityTimeout` is three seconds so that the lab moves quickly; the default is 30 seconds, and
the right value is longer than the slowest time a consumer takes to finish one message.
**`maxReceiveCount` is how many receives a message gets** before the queue moves it to the
dead-letter queue instead of handing it out again.

## The normal path: receive, then delete

A message is received with a **receipt handle**, a string that names this one receipt of it, and
the handle is what `delete-message` needs:

```
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/work" --message-body "order 41" --query MessageId --output text
a836dce7-ac4d-407a-8043-18b2af7ddd87
ana@laptop:~/aws$ RH=$(aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].ReceiptHandle" --output text)
ana@laptop:~/aws$ aws sqs delete-message --queue-url "$Q/work" --receipt-handle "$RH"
ana@laptop:~/aws$ sleep 4; aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].Body" --output text
None
```

After the delete, waiting longer than the visibility timeout brings nothing back: the work is
done and the message is gone. The `None` is the command line's way of printing a reply with no
messages in it.

## The path a failure takes

Now a message that nobody deletes. Each turn of the loop receives it, tries to receive it again
at once, and waits four seconds, longer than the timeout:

```
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/work" --message-body "order 42" --query MessageId --output text
4d7ecbb2-3174-4088-9fa3-6a6da1b9a4b6
ana@laptop:~/aws$ for i in 1 2 3 4; do aws sqs receive-message --queue-url "$Q/work" --attribute-names ApproximateReceiveCount --query "Messages[0].[Body, Attributes.ApproximateReceiveCount]" --output text; aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].Body" --output text; sleep 4; done
order 42	1
None
order 42	2
None
order 42	3
None
None
None
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/work-dlq" --query "Messages[0].Body" --output text
order 42
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of message order 42 in the queue work, with a visibility timeout of 3 seconds and maxReceiveCount 3. Three times a consumer receives it, the receive count goes to 1, 2 and 3, and the message is hidden for 3 seconds; nobody deletes it, so it becomes visible again. At the fourth receive the count would pass 3, and the queue moves the message to work-dlq instead of delivering it.\"><defs><marker id=\"redrive-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"redrive-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"16\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">queue work</text><path d=\"M16 60 L704 60\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><circle cx=\"40\" cy=\"60\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"40\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">receive</text><text x=\"40\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">count 1</text><rect x=\"48\" y=\"50\" width=\"150\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"123\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">hidden 3 s</text><circle cx=\"220\" cy=\"60\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"220\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">receive</text><text x=\"220\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">count 2</text><rect x=\"228\" y=\"50\" width=\"150\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"303\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">hidden 3 s</text><circle cx=\"400\" cy=\"60\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">receive</text><text x=\"400\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">count 3</text><rect x=\"408\" y=\"50\" width=\"150\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"483\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">hidden 3 s</text><circle cx=\"580\" cy=\"60\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"580\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fourth receive</text><path d=\"M580 106 L580 148\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#redrive-a)\"></path><rect x=\"500\" y=\"150\" width=\"160\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"580\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moved to work-dlq</text><text x=\"220\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nobody deleted it</text></svg>", "caption": "A received message is not gone, only hidden. Each time the visibility timeout runs out without a delete, it comes back and its count goes up; past maxReceiveCount the queue gives up on it and moves it aside."}
```

Read it in pairs. The first receive of each turn gets `order 42` with its count, and the second
gets nothing, **because the message is hidden, not gone**. After three seconds it is back, and the
count has gone up. On the fourth turn the count would pass `maxReceiveCount`, so the queue moved
the message to `work-dlq` instead, and both receives came back empty. moto did all of this for
real, with real seconds.

The dead-letter queue is a place to look, not a place to forget. A message there is one the
system could not process, and somebody should know it arrived: an alarm on the dead-letter
queue's `ApproximateNumberOfMessagesVisible` above zero is the usual answer, which
`aws-operations` lessons 8 to 10 build with CloudWatch. Once the cause is fixed, AWS can move the
messages back to the source queue with a redrive task, `aws sqs start-message-move-task`.

## Polling that does not cost much

Every `receive-message` is a request, and requests are what SQS charges for, including the ones
that come back empty. A consumer that asks in a tight loop on an idle queue pays for each `None`.
**Long polling** waits on the server instead: with `--wait-time-seconds 20`, or the queue
attribute `ReceiveMessageWaitTimeSeconds`, a receive on an empty queue waits up to 20 seconds for
a message before answering. An idle consumer then makes three requests a minute instead of one
for every pass of its loop, and the last section of this lesson does the arithmetic.

A consumer is often a Lambda function rather than a loop. Lesson 15 connected one through an
event source mapping, which does the receiving, the long polling and the deleting for you, and
returns failed messages to the queue item by item with `batchItemFailures`. The rules above are
still the ones it follows.
