---
title: What a record carries
version: 1
---

**The view type decides how much of the item each record carries, and it is chosen when the stream is
switched on.** There are four:

| view type | each record carries |
|---|---|
| `KEYS_ONLY` | the item's key, and nothing else |
| `NEW_IMAGE` | the item as it is after the change |
| `OLD_IMAGE` | the item as it was before the change |
| `NEW_AND_OLD_IMAGES` | both |

**A consumer that keeps a running total needs both.** A `MODIFY` that raised an order from 24.89 to
40.79 reais is a change of 15.90, and only the old image says what it was before. With `NEW_IMAGE` the
consumer would have to remember every order's last total itself; with `KEYS_ONLY` it would have to read
the item back from the table, and by then the item may have changed again. Here is the `MODIFY` of the
previous section whole:

```
ana@laptop:~/aws$ aws dynamodbstreams get-records --shard-iterator "$(aws dynamodbstreams get-shard-iterator --stream-arn "$ARN" --shard-id "$SHARD" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)" --query 'Records[31]'
{
    "eventID": "7679416eebb84a44a2743179ed5b4a04",
    "eventName": "MODIFY",
    "eventVersion": "1.0",
    "eventSource": "aws:dynamodb",
    "awsRegion": "us-east-1",
    "dynamodb": {
        "ApproximateCreationDateTime": "2026-10-16T13:28:15.082000-03:00",
        "Keys": {
            "pk": {
                "S": "CUSTOMER#c-17"
            },
            "sk": {
                "S": "ORDER#2026-10-12#o-10003"
            }
        },
        "NewImage": {
            "pk": {
                "S": "CUSTOMER#c-17"
            },
            "sk": {
                "S": "ORDER#2026-10-12#o-10003"
            },
            "order_id": {
                "S": "o-10003"
            },
            "order_day": {
                "S": "2026-10-12"
            },
            "total_cents": {
                "N": "4079"
            },
            "line_count": {
                "N": "3"
            }
        },
        "OldImage": {
            "pk": {
                "S": "CUSTOMER#c-17"
            },
            "sk": {
                "S": "ORDER#2026-10-12#o-10003"
            },
            "order_id": {
                "S": "o-10003"
            },
            "order_day": {
                "S": "2026-10-12"
            },
            "total_cents": {
                "N": "2489"
            },
            "line_count": {
                "N": "2"
            }
        },
        "SequenceNumber": "1100000000017454423040",
        "SizeBytes": 641,
        "StreamViewType": "NEW_AND_OLD_IMAGES"
    }
}
```

**Everything the consumer of the next section needs is in it**: the event's name, its id, the key, and
the two images, with `total_cents` 2489 before and 4079 after. `SizeBytes` is the record's size, and
`ApproximateCreationDateTime` is roughly when the change was made. One field is wrong in a
way worth noticing: `awsRegion` says `us-east-1` for a table in São Paulo, which is moto's, not AWS's.
A program that routed records by that field would work against one of them only.

**The view type cannot be changed on a stream that is enabled.** moto refuses with its own words:

```
ana@laptop:~/aws$ aws dynamodb update-table --table-name quitanda --stream-specification StreamEnabled=true,StreamViewType=KEYS_ONLY

aws: [ERROR]: An error occurred (ResourceInUseException) when calling the UpdateTable operation: Cannot enable stream
```

AWS refuses too. The way to a different view type is to disable the stream and enable a new one,
which gets a new label and a new ARN and starts empty, while the old one stays readable for its last
24 hours. That sequence was not run here. A consumer has to be moved to the new stream deliberately,
and the changes made between the two can only be found in whichever stream was enabled at the time.
