---
title: A global secondary index
version: 1
---

**A global secondary index is a second, partial copy of the table's items, under keys of its own,
kept up to date by DynamoDB on every write.** It is not the index of `sql-databases`, which a
planner uses when it judges it worthwhile. DynamoDB has no planner: a read uses an index only when the
request names it, and a query on the table never looks at one.

**An index has its own partition key and its own sort key, and neither has to be unique.** For A5 the
question starts from a day, so the index is partitioned by `order_day` and sorted by `order_id`. Two
orders of the same day share a partition key there, which is the point. Only items that carry both
attributes are copied into it: the orders, and not the profiles or the lines, which have no
`order_day`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"On the left, the table: the collection of CUSTOMER#c-17 holds its profile and the orders o-10001 of 3 October and o-10002 of 5 October with their lines; the collection of CUSTOMER#c-19 holds o-10006 of 3 October and o-10009 of 14 October. On the right, the index by-day: the partition 2026-10-03 holds o-10001 and o-10006, from two different customers, and the partition 2026-10-14 holds o-10009. Profiles and lines have no order_day and are not copied.\" data-fig=\"l10-index\"><defs><marker id=\"l10-index-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the table, partitioned by customer</text><text x=\"440\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the index by-day, partitioned by order_day</text><rect x=\"20\" y=\"32\" width=\"300\" height=\"152\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"30\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CUSTOMER#c-17</text><rect x=\"30\" y=\"54\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001</text><rect x=\"30\" y=\"80\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…#o-10001#LINE#1..3</text><text x=\"302\" y=\"91\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 lines</text><rect x=\"30\" y=\"106\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002</text><rect x=\"30\" y=\"132\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…#o-10002#LINE#1..3</text><text x=\"302\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 lines</text><rect x=\"30\" y=\"158\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PROFILE</text><rect x=\"20\" y=\"196\" width=\"300\" height=\"126\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"30\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CUSTOMER#c-19</text><rect x=\"30\" y=\"218\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10006</text><rect x=\"30\" y=\"244\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…#o-10006#LINE#1..2</text><text x=\"302\" y=\"255\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 lines</text><rect x=\"30\" y=\"270\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"281\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-14#o-10009</text><rect x=\"30\" y=\"296\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"307\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PROFILE</text><rect x=\"440\" y=\"60\" width=\"260\" height=\"74\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"450\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order_day = 2026-10-03</text><rect x=\"450\" y=\"82\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10001</text><text x=\"682\" y=\"93\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-17</text><rect x=\"450\" y=\"108\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10006</text><text x=\"682\" y=\"119\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-19</text><rect x=\"440\" y=\"150\" width=\"260\" height=\"48\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"450\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order_day = 2026-10-05</text><rect x=\"450\" y=\"172\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10002</text><text x=\"682\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-17</text><rect x=\"440\" y=\"214\" width=\"260\" height=\"48\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"450\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order_day = 2026-10-14</text><rect x=\"450\" y=\"236\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10009</text><text x=\"682\" y=\"247\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-19</text><path d=\"M310,65 C380,65 380,93 448,93\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><path d=\"M310,229 C380,229 380,119 448,119\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><path d=\"M310,117 C380,117 380,183 448,183\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><path d=\"M310,281 C380,281 380,247 448,247\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><text x=\"440\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">profiles and lines: not in the index</text></svg>", "caption": "The same orders under a second key. Each order of a day is copied into that day's partition of the index, whichever customer it belongs to; items without order_day stay behind."}
```

**The projection says which attributes travel into the index.** `KEYS_ONLY` copies the index's keys
and the table's; `INCLUDE` adds the attributes it names; `ALL` copies whole items. A query on a global
index returns only what was projected, and cannot reach back into the table for the rest, so the
projection is decided by what the question needs. The stock planner needs each order's total:

```sh
aws dynamodb update-table --table-name quitanda \
  --attribute-definitions AttributeName=order_day,AttributeType=S AttributeName=order_id,AttributeType=S \
  --global-secondary-index-updates '[{"Create": {"IndexName": "by-day",
      "KeySchema": [{"AttributeName": "order_day", "KeyType": "HASH"},
                    {"AttributeName": "order_id", "KeyType": "RANGE"}],
      "Projection": {"ProjectionType": "INCLUDE", "NonKeyAttributes": ["total_cents"]}}}]' > /dev/null
```

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query "Table.GlobalSecondaryIndexes[].[IndexName,IndexStatus,Projection.ProjectionType,Projection.NonKeyAttributes[0]]" --output text
by-day	ACTIVE	INCLUDE	total_cents
```

**moto reports the index `ACTIVE` on the next line, and AWS would not.** Adding an index to a table
that already holds items starts a **backfill**: AWS reads the whole table and writes every qualifying item into the index. Until it is done the index is `CREATING` and refuses
queries, for minutes
on a small table and hours on a large one. That was not run here; moto builds the index in the same
call.

## Reading it

```
ana@laptop:~/aws$ python3 pages.py 2026-10-01 by-day
page 1: read    738 items, returned    738,    66,997 bytes returned, last page
1 page, 738 items read, 738 returned, 66,997 bytes returned, 8.5 read units for them
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-day --key-condition-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --max-items 2 --query 'Items[]' --output json
[
    {
        "pk": {
            "S": "CUSTOMER#c-20"
        },
        "sk": {
            "S": "ORDER#2026-10-01#o-10010"
        },
        "order_day": {
            "S": "2026-10-01"
        },
        "order_id": {
            "S": "o-10010"
        },
        "total_cents": {
            "N": "7467"
        }
    },
    {
        "pk": {
            "S": "CUSTOMER#c-23"
        },
        "sk": {
            "S": "ORDER#2026-10-01#o-10015"
        },
        "order_day": {
            "S": "2026-10-01"
        },
        "order_id": {
            "S": "o-10015"
        },
        "total_cents": {
            "N": "16227"
        }
    }
]
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-day --key-condition-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --consistent-read --select COUNT

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Consistent reads are not supported on global secondary indexes
```

**One page, 738 items read and 738 returned, 8.5 read units.** The scan read 34,100 items for the same
answer and cost 364.5. Each item came back with the table's keys, the index's keys and `total_cents`,
which is what the projection promised; the customer is in `pk`, because the table's key always
travels. The screen that refreshes every minute now costs 43,200 × 8.5 = 367,200 read units a month,
about seven cents, and it grows with the number of orders in a day rather than with the history.

**A global index is eventually consistent, and that is refused rather than approximated.** The write
lands in the table first and reaches the index a moment later, within a fraction of a second under
normal conditions by AWS's documentation, and longer when the index is short of capacity. A read that
needs to see its own write a millisecond later reads the table.

## What the index costs instead

**Every write to an item the index holds is also a write to the index.** Loading the 10,029 orders
again would be 10,029 more write units, and an update that changes `order_day` is two writes in the
index: the old entry removed, the new one inserted. The index is also stored and billed like a table,
at the same price per GB as the storage line of the price sheet, with about a hundred bytes of
overhead per item on top. And with provisioned capacity, the subject of lesson 11, it has capacity of
its own: an index that cannot keep up slows the writes to the table it belongs to. Lesson 11 also
returns to its key, because a whole day's orders under one partition key is the shape a hot partition
takes.
