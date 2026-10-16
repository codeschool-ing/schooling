---
title: Time to live, Lambda and Kinesis
version: 1
---

## Items that delete themselves

**Time to live deletes an item after the moment written in one of its attributes, and the deletion
arrives in the stream as a `REMOVE`.** The attribute holds a time as seconds since 1970, and the table
names which attribute it is. Quitanda's carts are the case: a cart left alone for a week should go, and
nobody should have to run a job for it. moto accepts all of it:

```
ana@laptop:~/aws$ aws dynamodb update-time-to-live --table-name quitanda --time-to-live-specification Enabled=true,AttributeName=expires_at
{
    "TimeToLiveSpecification": {
        "Enabled": true,
        "AttributeName": "expires_at"
    }
}
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CART#c-18"}, "sk": {"S": "CART"}, "expires_at": {"N": "1760000000"}}'
ana@laptop:~/aws$ date -d @1760000000
Thu Oct  9 05:53:20 -03 2025
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CART#c-18"}, "sk": {"S": "CART"}}' --query 'Item.expires_at.N'
"1760000000"
```

**The cart expired on 9 October 2025 and is still there.** moto records the setting and deletes
nothing, and nothing about real expiry was run here. On AWS, TTL deletes an expired item in the
background, typically within a few days of the time in the attribute rather than at it, so a read
that must not see an expired item filters on `expires_at` itself. The deletion costs no write units. It
reaches the stream as a `REMOVE` whose record carries a `userIdentity` naming the service,
`dynamodb.amazonaws.com`, which is how a consumer tells an expiry from a customer emptying the cart.
The markers that `totals.py` leaves are the other use: written with an `expires_at` two days ahead,
longer than the stream keeps a record, they would clean themselves up.

## Lambda as the consumer

**A Lambda function is attached to a stream by an event source mapping**, a record that tells Lambda
to poll the stream's shards and call the function with batches. The function needs code, a role it
runs as, and the mapping. `handler.py`:

```python
def handler(event, context):
    return len(event['Records'])
```

`trust.json`, which lets Lambda take on the role:

```json
{"Version": "2012-10-17", "Statement": [{"Effect": "Allow",
  "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}
```

```
ana@laptop:~/aws$ python3 -m zipfile -c function.zip handler.py
ana@laptop:~/aws$ aws iam create-role --role-name quitanda-totals --assume-role-policy-document file://trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/quitanda-totals"
ana@laptop:~/aws$ aws lambda create-function --function-name quitanda-totals --runtime python3.12 --handler handler.handler --role arn:aws:iam::123456789012:role/quitanda-totals --zip-file fileb://function.zip --query State
"Active"
ana@laptop:~/aws$ aws lambda create-event-source-mapping --function-name quitanda-totals --event-source-arn "$ARN" --starting-position TRIM_HORIZON --batch-size 100 --maximum-retry-attempts 2 --bisect-batch-on-function-error --query '[State,BatchSize,MaximumRetryAttempts,BisectBatchOnFunctionError]' --output text
Enabled	100	2	True
ana@laptop:~/aws$ aws lambda list-event-source-mappings --query 'EventSourceMappings[].[State,LastProcessingResult]' --output text
Enabled	None
```

**The mapping is `Enabled`, and it will never call the function here.** moto creates functions and
mappings as records, and runs a function's code only inside Docker, which this lab does not use; no
batch was delivered and `LastProcessingResult` is empty. Everything the previous section says about
retries is AWS's documented behaviour and was not run. The mapping carries the two settings it
described: two retries, and a failing batch split in half.

## Kinesis Data Streams for DynamoDB

**The other way out of a table is into a Kinesis data stream**, the service of lesson 20, which keeps
records for up to a year and lets many consumers read them. moto does not implement it:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name quitanda-changes --shard-count 1
ana@laptop:~/aws$ aws dynamodb enable-kinesis-streaming-destination --table-name quitanda --stream-arn arn:aws:kinesis:sa-east-1:123456789012:stream/quitanda-changes 2>&1 | head -2

aws: [ERROR]: An error occurred (500) when calling the EnableKinesisStreamingDestination operation (reached max retries: 2): <!doctype html>
```

**The `500` is moto failing, and it is the honest answer.** By AWS's documentation the trade is
retention and fan-out against two guarantees: in a Kinesis stream the records of one item may arrive
out of order and more than once, so a consumer orders them by `ApproximateCreationDateTime` and removes
duplicates itself. DynamoDB Streams gives ordering and no duplicates within its 24 hours; Kinesis gives
a year and more readers. Neither removes the consumer's duplicates of the previous section.

## What reading a stream costs

```
ana@laptop:~/aws$ python3 prices.py dynamodb
AWS public price list, sa-east-1, USD, excluding tax

DynamoDB, USD
  on demand, per million write request units            0.93750  million
  on demand, per million read request units             0.18750  million
  provisioned, per WCU-hour                            0.000975  WCU-hour
  provisioned, per RCU-hour                            0.000195  RCU-hour
  storage beyond 25 GB                                  0.37500  GB-month
  storage, Standard-IA table class                      0.15000  GB-month
  streams, per million read requests beyond free        0.30000  million
  point-in-time recovery                                0.30000  GB-month
```

**Reading a DynamoDB stream is charged per `GetRecords` call**, at 0.30 dollars per million beyond a
monthly free allowance, whatever the call returned, so a reader that polls an idle shard pays for
empty answers. Four calls a second on one shard for a 30-day month is 4 × 86,400 × 30 = 10,368,000 calls,
3.11 dollars at that price. By AWS's pricing page, the calls Lambda makes for a trigger are not charged
at all, which is one more reason Lambda is the usual consumer.
