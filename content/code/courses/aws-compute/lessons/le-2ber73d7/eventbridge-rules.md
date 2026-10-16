---
title: "EventBridge rules: a pattern decides who is called"
version: 1
---

The sources so far each name the function they call. **EventBridge turns that round: whoever
publishes an event names nobody, and a rule on the bus decides, by matching a pattern against the
event, which targets receive it.** The shop's checkout publishes `OrderPlaced` and knows nothing of
the function that checks large orders for fraud; that function is attached by a rule that matches
orders over a thousand reais. Lesson 21 compares buses with queues and topics; this section is the
rule that calls a function.

## A pattern is a shape the event must fit

Save this as `~/aws/pattern.json`:

```json
{
  "source": ["shop.orders"],
  "detail-type": ["OrderPlaced"],
  "detail": {
    "total": [{"numeric": [">", 1000]}]
  }
}
```

**A pattern lists only the fields it cares about, and every field listed must match.** Each value is
a list of what is accepted: `source` must be `shop.orders`, `detail-type` must be `OrderPlaced`,
and inside `detail`, the event's own content, `total` must be a number greater than 1000. A field
the pattern does not mention can hold anything, and an event without a field the pattern does
mention does not match. The rule, the permission and the target:

```
ana@laptop:~/aws$ aws events put-rule --name big-orders --event-pattern file://pattern.json --query RuleArn
"arn:aws:events:sa-east-1:123456789012:rule/big-orders"
ana@laptop:~/aws$ aws lambda add-permission --function-name orders --statement-id big-orders --action lambda:InvokeFunction --principal events.amazonaws.com --source-arn arn:aws:events:sa-east-1:123456789012:rule/big-orders --query Statement --output text | jq -c .Condition
{"ArnLike":{"AWS:SourceArn":"arn:aws:events:sa-east-1:123456789012:rule/big-orders"}}
ana@laptop:~/aws$ aws events put-targets --rule big-orders --targets Id=orders,Arn=arn:aws:lambda:sa-east-1:123456789012:function:orders
{
    "FailedEntryCount": 0,
    "FailedEntries": []
}
```

The permission is the same idea as the bucket's in section 03, with the rule as the only source
that may invoke `orders`, and EventBridge then invokes it asynchronously, so a failed event gets
Lambda's two retries and the destination of section 02. moto records the rule and the target and,
as before, calls no function.

## Testing a pattern, and what moto does not answer

EventBridge has an API for exactly the question a pattern raises, whether a given event matches
it. Ask it about an order of 99.9:

```
ana@laptop:~/aws$ aws events test-event-pattern --event-pattern file://pattern.json --event '{"id": "1", "account": "123456789012", "source": "shop.orders", "time": "2026-10-16T12:00:00Z", "region": "sa-east-1", "resources": [], "detail-type": "OrderPlaced", "detail": {"total": 99.9}}'; echo "exit status $?"
exit status 0
```

**Nothing came back, and the command still exited with status 0.** On AWS, `test-event-pattern`
answers `{"Result": false}` for this event, and `true` for one over a thousand. moto 5.2.3 has the
call in its list and an empty body behind it, so it answers with no result at all, and a script that
only checked the exit status would read silence as success. This was not run against AWS.

## Watching what a rule matches

moto does match patterns when an event is published, and it delivers to an SQS target. So, as with
the bucket, a queue can stand in for the function and show which events got through. The function
target comes off for the experiment, since moto's attempt to run it would get in the way:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name rule-witness --query QueueUrl
"http://localhost:4567/123456789012/rule-witness"
ana@laptop:~/aws$ aws events put-targets --rule big-orders --targets Id=witness,Arn=arn:aws:sqs:sa-east-1:123456789012:rule-witness --query FailedEntryCount
0
ana@laptop:~/aws$ aws events remove-targets --rule big-orders --ids orders --query FailedEntryCount
0
ana@laptop:~/aws$ aws events put-events --entries '[{"Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"order\": \"A-1\", \"total\": 1299.9}"}, {"Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"order\": \"A-2\", \"total\": 99.9}"}, {"Source": "shop.payments", "DetailType": "OrderPlaced", "Detail": "{\"order\": \"A-3\", \"total\": 5000}"}]' --query FailedEntryCount
0
ana@laptop:~/aws$ aws sqs receive-message --queue-url http://localhost:4567/123456789012/rule-witness --max-number-of-messages 10 --query 'Messages[].Body' | jq -r '.[]' | jq -c '{source, detail}'
{"source":"shop.orders","detail":{"order":"A-1","total":1299.9}}
```

Three events published, one delivered. `A-1` matched every field. `A-2` failed the numeric test,
`99.9` not being greater than 1000. `A-3` had the right `detail-type` and a total of 5000, and came
from `shop.payments`, so it failed on `source`. **A rule matches on every field it names, and
nothing else is consulted**, which is also how a rule goes wrong: misspell `detail-type` in the
pattern and nothing ever matches, with no error anywhere, which is the reason to test a pattern
against real events before trusting it.

## Choosing a trigger

| you need | use |
| --- | --- |
| a caller that waits for the answer | a function URL or API Gateway, synchronous |
| to react to something one service does, such as an upload | that service's own notification, asynchronous |
| to buffer work and control the rate, in batches | SQS and an event source mapping |
| every change to a table, in order | DynamoDB Streams and an event source mapping |
| to react to events whose publisher should not know who listens | an EventBridge rule |

Each row is one of section 02's three shapes, and the shape carries its retries with it. The choice
of trigger is made once and lived with for as long as the function runs, which is why it is worth
deciding by who waits and who retries, rather than by which service the event happens to start in.
