---
title: "Event buses: rules that choose the targets"
version: 1
---

A topic and a bus both deliver one message to several places, which makes EventBridge look like
SNS with a different name. **The difference is who decides where an event goes.** With SNS, the
subscriber subscribes and filters for itself. With EventBridge, the producer only says what
happened, as a structured event, and **rules** on the bus decide which targets receive it by
matching its content. The producer knows no consumer, and a new consumer is a new rule that nobody
upstream has to change.

## A bus of the shop's own

Every account has a bus called `default`, where AWS services publish their own events: an EC2
instance changing state, an object created in S3, a Step Functions execution failing. A
**custom bus** is for the application's events, so that its rules are not mixed with AWS's:

```
ana@laptop:~/aws$ aws events create-event-bus --name shop --query EventBusArn --output text
arn:aws:events:sa-east-1:123456789012:event-bus/shop
```

A rule is a **pattern**, a JSON document that has the shape of the events it matches. Each field
lists the values that match, and a value can also be a test, such as `numeric`. This rule matches
orders above 1000:

```
ana@laptop:~/aws$ aws events put-rule --name big-orders --event-bus-name shop --event-pattern '{"source": ["shop.orders"], "detail-type": ["OrderPlaced"], "detail": {"total": [{"numeric": [">", 1000]}]}}' --query RuleArn --output text
arn:aws:events:sa-east-1:123456789012:rule/shop/big-orders
```

**A pattern matches when every field it names matches.** Fields the pattern leaves out can hold
anything, and an event without a field the pattern names does not match. The rule's target is a
queue where somebody reviews large orders:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name review --query QueueUrl --output text
http://localhost:4567/123456789012/review
ana@laptop:~/aws$ aws events put-targets --rule big-orders --event-bus-name shop --targets Id=review,Arn=arn:aws:sqs:sa-east-1:123456789012:review --query FailedEntryCount
0
```

On AWS, as with SNS, the queue needs a policy that lets `events.amazonaws.com` send to it, and
moto does not check it. A rule can have up to five targets, and a target can be a Lambda function,
a Step Functions state machine, an SNS topic, another bus, or an API destination that calls an
HTTPS address outside AWS.

## Putting events on the bus

An event has a source, a detail type and a detail, which is the application's own JSON as a
string. Save two orders as `~/aws/entries.json`:

```json
[
  {"EventBusName": "shop", "Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"id\": \"42\", \"total\": 1500}"},
  {"EventBusName": "shop", "Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"id\": \"43\", \"total\": 300}"}
]
```

```
ana@laptop:~/aws$ aws events put-events --entries file://entries.json --query FailedEntryCount
0
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/review" --max-number-of-messages 10 --query "Messages[].Body" --output text | jq .
{
  "id": "f2f06ca8-9757-4aa3-b44a-5a25e9165420",
  "time": "2026-10-16T16:47:14Z",
  "version": "0",
  "detail-type": "OrderPlaced",
  "source": "shop.orders",
  "region": "sa-east-1",
  "resources": [],
  "detail": {
    "id": "42",
    "total": 1500
  }
}
```

**One event reached the review queue, and the other went nowhere.** The order of 300 matched no
rule, and an event that matches no rule is dropped: there is no queue behind the bus that keeps
it, unless you create an archive, which keeps events for replaying later. The event that arrived
is EventBridge's envelope, with an `id`, a `time`, the `source` and `detail-type` that the rule
matched, and the `detail` as JSON rather than as a string. A real one also carries the `account`;
moto leaves it out.

AWS can test a pattern against an event without sending anything, with
`aws events test-event-pattern`. moto 5.2.3 gives that command an empty reply, so in the lab a
pattern is tested by sending events, as above.

## Rules on a schedule, and the scheduler

A rule can also fire on a schedule, `rate(5 minutes)` or a `cron` expression, with no event at
all. For new work AWS points to **EventBridge Scheduler** instead, a separate service in which
each schedule is a resource of its own with a time zone and a retry policy, and which can start a
single run at a given moment. A nightly report run as a Standard workflow of lesson 20, started at
03:00 São Paulo time, is one Scheduler schedule.

## Which of the three

**A queue when one consumer must do the work, a topic when several known consumers each need a
copy, a bus when the consumers are not known in advance and the content decides.** The three are
used together all the time: a rule's target is a queue, so that the consumer behind it gets the
retries and the dead-letter queue of the first section; a topic fans out to queues, so that each
team keeps its pace. The price is in the next section, and on the sheet a custom event costs more
than an SNS publish, so the bus is not the default for a high-volume stream with fixed consumers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Three shapes side by side. A queue: a producer sends to the queue work, and of two workers only one receives each message. A topic: a publisher sends to the topic orders, which copies the message to the queues billing and shipping; the shipping subscription has a filter that drops digital orders. An event bus: events go to the bus shop, the rule big-orders matches totals above 1000 and sends them to the queue review, and an event with total 300 matches no rule and goes nowhere.\"><defs><marker id=\"shapes-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"shapes-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"16\" y=\"12\" width=\"220\" height=\"236\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"126\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">queue</text><text x=\"126\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one message, one consumer takes it</text><rect x=\"252\" y=\"12\" width=\"220\" height=\"236\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"362\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">topic</text><text x=\"362\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one message, a copy per subscription</text><rect x=\"488\" y=\"12\" width=\"220\" height=\"236\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"598\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">event bus</text><text x=\"598\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one event, every rule that matches</text><rect x=\"36\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"81\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">producer</text><path d=\"M81 100 L81 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"36\" y=\"128\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"81\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work</text><path d=\"M70 158 L54 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><path d=\"M92 158 L110 196\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#shapes-a)\"></path><rect x=\"20\" y=\"198\" width=\"76\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"58\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"102\" y=\"198\" width=\"76\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"140\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker</text><rect x=\"286\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"331\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">publish</text><path d=\"M331 100 L331 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"286\" y=\"128\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"331\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><path d=\"M316 158 L290 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><path d=\"M346 158 L372 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"258\" y=\"198\" width=\"84\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"300\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">billing</text><rect x=\"348\" y=\"198\" width=\"84\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"390\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shipping</text><text x=\"390\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">filter drops digital</text><rect x=\"522\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"567\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">put-events</text><path d=\"M567 100 L567 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"522\" y=\"128\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"567\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><path d=\"M560 158 L540 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"490\" y=\"198\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"540\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">review</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">big-orders</text><path d=\"M590 158 L640 190\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#shapes-a)\"></path><text x=\"650\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">total 300: no rule</text></svg>", "caption": "Who receives what. A queue hands each message to one consumer; a topic gives every subscription its own copy, filtered per subscription; a bus sends each event to the targets of every rule whose pattern it matches, and to nobody if none does."}
```
