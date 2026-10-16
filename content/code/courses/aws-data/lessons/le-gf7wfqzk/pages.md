---
title: Pages, Limit and LastEvaluatedKey
version: 1
---

**Every read that can return more than one item returns pages, and a program that reads one page
believes it read everything.** The first section showed pages of 1 MB, which is the server's limit.
`--limit` is the caller's: at most that many items per page. An app's "show more" button is exactly
this, five orders at a time:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --limit 5 --no-paginate --query '[Items[].sk.S,LastEvaluatedKey]'
[
    [
        "ORDER#2026-10-03#o-10001",
        "ORDER#2026-10-03#o-10001#LINE#1",
        "ORDER#2026-10-03#o-10001#LINE#2",
        "ORDER#2026-10-03#o-10001#LINE#3",
        "ORDER#2026-10-05#o-10002"
    ],
    {
        "pk": {
            "S": "CUSTOMER#c-17"
        },
        "sk": {
            "S": "ORDER#2026-10-05#o-10002"
        }
    }
]
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --limit 5 --no-paginate --exclusive-start-key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "ORDER#2026-10-05#o-10002"}}' --query '[Items[].sk.S,LastEvaluatedKey]'
[
    [
        "ORDER#2026-10-05#o-10002#LINE#1",
        "ORDER#2026-10-05#o-10002#LINE#2",
        "ORDER#2026-10-05#o-10002#LINE#3",
        "ORDER#2026-10-12#o-10003",
        "ORDER#2026-10-12#o-10003#LINE#1"
    ],
    {
        "pk": {
            "S": "CUSTOMER#c-17"
        },
        "sk": {
            "S": "ORDER#2026-10-12#o-10003#LINE#1"
        }
    }
]
```

**The answer carried the key of the last item it returned, and the next request started after it.**
`LastEvaluatedKey` is the position, and sending it back as `--exclusive-start-key` continues from
there; the second page began at the line after `ORDER#2026-10-05#o-10002`. A page that comes back
without `LastEvaluatedKey` is the last one, and that is the only reliable signal. The 1 MB page of the
first section and the five-item page here are the same mechanism, and `pages.py` is its loop.

**`--no-paginate` is what made the command line show one page.** Without it the command line follows
`LastEvaluatedKey` by itself, as it did for the scan in the first section, and the CLI's own
`--max-items` and `--starting-token` page the result for a person reading a terminal. A program using
boto3's client gets one page per call and has to loop.

## The limit is counted before the filter

**`Limit` caps the items read, not the items returned.** With a filter, a page can come back short or
empty while more matches lie further on:

```
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --limit 100 --no-paginate --query '[Count,ScannedCount]' --output text
5	100
```

**A hundred items read, five returned, and the page says nothing about the 733 other orders of the
day.** A program that asked for `Limit` 100 meaning "the first hundred orders of 1 October", and took
one page as the answer, would show five and stop. The same trap hides inside the 1 MB page: a filtered
scan whose matches sit far apart returns pages with `Count` 0 and a `LastEvaluatedKey`, and a loop
that stops at the first empty page stops early. The loop stops on the missing key, never on an empty
page.

**A `LastEvaluatedKey` is the table's key, and handing it to a browser hands over the key.** Here it
names a customer. An app that pages for a user usually encodes it or keeps it on the server. It also checks that the next request is still for that user's partition, because a key sent back by a client
is a key the client could have written.
