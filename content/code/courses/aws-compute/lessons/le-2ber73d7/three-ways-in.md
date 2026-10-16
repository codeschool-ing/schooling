---
title: Three ways an event gets in
version: 1
---

Lambda has a long list of services that can start a function, and it is tempting to learn them one
by one. **There are only three shapes underneath, and the shape decides who waits, who retries and
where a failed event ends up.** A source either calls the function and waits for the answer, hands
the event over and walks away, or is read by Lambda itself. Learn the three and each new source is
a question of which one it is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Three ways an event reaches a Lambda function. Synchronous push, from API Gateway, a function URL or an invoke: the caller sends the event and waits for the answer or the error. Asynchronous push, from S3, SNS or EventBridge: the source hands the event to Lambda's own queue and is told it was accepted; Lambda calls the function and retries, then sends a failure to a destination. Poller, for SQS, DynamoDB Streams and Kinesis: an event source mapping run by Lambda reads the queue or stream and calls the function with batches.\"><defs><marker id=\"w-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"w-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">synchronous push</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">API Gateway, a function URL, aws lambda invoke</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">asynchronous push</text><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">S3, SNS, EventBridge</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a poller</text><text x=\"20\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQS, DynamoDB Streams, Kinesis</text><rect x=\"20\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the caller</text><rect x=\"420\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the function</text><path d=\"M152 72 L418 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M418 90 L152 90\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah-a)\"></path><text x=\"285\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the event</text><text x=\"285\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the answer, or the error</text><text x=\"570\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the caller waits, and retries</text><rect x=\"20\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the source</text><rect x=\"220\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"285\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Lambda's queue</text><rect x=\"420\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the function</text><rect x=\"590\" y=\"170\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">destination</text><path d=\"M152 190 L218 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M352 190 L418 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M552 190 L588 190\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah-a)\"></path><text x=\"185\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accepted at once</text><text x=\"385\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calls, retries twice</text><rect x=\"20\" y=\"280\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">queue or stream</text><rect x=\"220\" y=\"280\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"285\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">event source mapping</text><rect x=\"420\" y=\"280\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the function</text><path d=\"M218 300 L152 300\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M352 300 L418 300\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><text x=\"185\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lambda polls it</text><text x=\"385\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a batch per call</text><text x=\"570\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the record stays until done</text></svg>", "caption": "Who waits, and who retries. In a synchronous push the caller holds the connection and owns the retry; in an asynchronous push Lambda queues the event and retries it; with a poller Lambda reads the source itself, and a failed record stays in its queue or shard."}
```

## Synchronous push: the caller waits

API Gateway, a function URL and `aws lambda invoke` all call the function and **hold the connection
until it answers**. The answer, or the error, goes straight back to the caller, exactly as the
emulator's `curl` received it in lesson 14. Lambda does not retry anything here: if the function
fails, the caller is told, and whether to try again is the caller's decision. A web request through
API Gateway is the usual case, and its own timeout, shorter than Lambda's fifteen minutes, is one
of lesson 19's subjects.

## Asynchronous push: Lambda takes the event and the retries

S3, SNS and EventBridge invoke a function **asynchronously**. Lambda puts the event on a queue of
its own and answers the source at once that it was accepted, then calls the function from that
queue. If the function fails, Lambda tries again, twice by default, with a wait between attempts;
an event that still fails, or that waits longer than its maximum age, six hours by default, is
dropped, unless the function has somewhere to send it. Both numbers and the place to send failures
are a function's settings, and moto keeps them:

```
ana@laptop:~/aws$ aws lambda put-function-event-invoke-config --function-name thumbs --maximum-retry-attempts 1 --maximum-event-age-in-seconds 3600 --destination-config '{"OnFailure": {"Destination": "arn:aws:sqs:sa-east-1:123456789012:thumbs-failed"}}'
{
    "LastModified": "2026-10-16T13:50:02.926000-03:00",
    "FunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:thumbs",
    "MaximumRetryAttempts": 1,
    "MaximumEventAgeInSeconds": 3600,
    "DestinationConfig": {
        "OnFailure": {
            "Destination": "arn:aws:sqs:sa-east-1:123456789012:thumbs-failed"
        }
    }
}
```

One retry instead of two, an hour instead of six, and an **on-failure destination**: an SQS queue
that receives the event and the error when Lambda gives up. **This is the setting to look for first
on any asynchronous function**, because without it a failed event leaves nothing behind but a line
in the log. A destination can also be an SNS topic, another function or an EventBridge bus, and an
on-success destination is possible too. The older mechanism, a dead-letter queue on the function,
does the failure half of the same job.

What moto does not do is the queueing itself: it never calls the function, so no retry was run
here, and the configuration above is a record. **The consequence of retries, though, is yours on
AWS**: the same event may run the function more than once, so an asynchronous handler has to be
safe to run twice on the same event. Lesson 21 calls that idempotence and builds on it.

## A poller: Lambda reads the source

SQS, DynamoDB Streams and Kinesis do not call anything. A queue or a stream waits to be read, and
the reader is an **event source mapping**: a poller Lambda runs on your behalf, which reads the
source, gathers records into a batch and invokes the function synchronously with it. Failure
handling belongs to the mapping and to the source: a message the function did not finish stays in
its queue and becomes visible again, and a stream record stays in its shard and is retried, so
nothing is lost by default, and the questions become how long a bad record is retried and what it
holds up meanwhile. Section 04 is about those questions.

## Which one a source is

| source | shape | who retries |
| --- | --- | --- |
| API Gateway, function URL, `invoke` | synchronous push | the caller |
| S3, SNS, EventBridge | asynchronous push | Lambda, twice by default |
| SQS | poller | the mapping, through the queue's visibility timeout |
| DynamoDB Streams, Kinesis | poller | the mapping, holding the shard until it succeeds or gives up |

**The table is the reason two functions with the same code behave differently in production.** A
handler that raises on a bad event costs a web user one error page behind API Gateway, two more
attempts and a destination behind S3, and behind a stream, a shard that stops moving until somebody
looks. The rest of this lesson takes each shape with a real source and runs the handler for each
one in the emulator, with the event that source sends.
