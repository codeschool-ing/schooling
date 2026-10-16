---
title: Throttling and hot partitions
version: 1
---

**A request that needs more capacity than is there is throttled**: refused, typically with
`ProvisionedThroughputExceededException`, and nothing is written. The SDKs retry it with growing pauses before giving up, so a program meets
throttling first as slowness and only later as an error. Two limits produce it, and the second is the
one that surprises people.

**The first is the table's capacity, and it is softer than it looks.** AWS keeps up to five minutes of
a provisioned table's unused capacity as **burst capacity** and spends it on short surges, without
promising that it will be there. On demand, a table takes up to double its previous peak at once, and
is throttled only when traffic more than doubles that peak within about half an hour.

**The second is the partition's, and it does not move: 3,000 read units and 1,000 write units a second
per partition.** A table of 10,000 write units spread over twenty partitions has 500 a partition to
spare; the same table sends every write to one partition if they all have the same partition key, and
then it has 1,000. **A hot partition is a partition key that takes more than its share**, and it is
throttled while the table as a whole is mostly idle. AWS's adaptive capacity lends a busy partition the
capacity its neighbours are not using, at once, and splits a partition whose items are hot into two,
but neither lifts the ceiling on one key. No setting does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Left: all 1,000 writes a second for the key 2026-10-16 fill one partition up to its limit of 1,000 write units, while three other partitions are almost idle. Right: the same writes with a suffix from 0 to 9, 2026-10-16#0 to #9, spread over four partitions, each well under the limit.\" data-fig=\"l11-hot\"><defs><marker id=\"l11-hot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">one key for the day</text><line x1=\"20\" y1=\"60\" x2=\"320\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><rect x=\"30\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"34\" y=\"60.0\" width=\"48\" height=\"150.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"58\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 1</text><text x=\"58\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-10-16</text><rect x=\"102\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"106\" y=\"207.75\" width=\"48\" height=\"2.25\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"130\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 2</text><text x=\"130\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><rect x=\"174\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"178\" y=\"208.5\" width=\"48\" height=\"2\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"202\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 3</text><text x=\"202\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><rect x=\"246\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"250\" y=\"207.0\" width=\"48\" height=\"3.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"274\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 4</text><text x=\"274\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><text x=\"320\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1,000 a second per partition</text><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the same day, ten keys</text><line x1=\"390\" y1=\"60\" x2=\"690\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><rect x=\"400\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"404\" y=\"165.0\" width=\"48\" height=\"45.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"428\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 1</text><text x=\"428\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#0 #4 #8</text><rect x=\"472\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"476\" y=\"180.0\" width=\"48\" height=\"30.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"500\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 2</text><text x=\"500\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#1 #5</text><rect x=\"544\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"548\" y=\"165.0\" width=\"48\" height=\"45.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"572\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 3</text><text x=\"572\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#2 #6 #9</text><rect x=\"616\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"620\" y=\"180.0\" width=\"48\" height=\"30.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"644\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 4</text><text x=\"644\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#3 #7</text><text x=\"690\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1,000 a second per partition</text></svg>", "caption": "A partition takes 1,000 writes a second whatever the table has. Sharding the key spreads one day's orders over ten keys, and the reader pays by querying all ten."}
```

**Quitanda has one, in lesson 10's index.** `by-day` takes every order of a day under one partition
key, `2026-10-16`. At 1,000 orders a second in the evening promotion, that key alone sits exactly at
one partition's write limit, and a global index that cannot keep up throttles the writes to the table
it belongs to. The repair is **write sharding**: add a suffix from 0 to 9 to the index key,
`2026-10-16#7`, so that a day's orders are spread over ten keys and ten partitions. The price is paid
by the reader, which now queries ten keys and merges the answers. It is the same trade as lesson 9's
keys: the design is made for the patterns, and the write pattern is one of them.

## What moto does instead

**moto never throttles.** The products table is provisioned at 5 write units, and a program that
writes as fast as it can, saved as `flood.py`:

```python
import time

import boto3

db = boto3.client('dynamodb')
retries, start = 0, time.time()
for i in range(5000):
    answer = db.put_item(TableName='products', Item={'sku': {'S': f'hot-{i:04d}'}})
    retries += answer['ResponseMetadata']['RetryAttempts']
took = time.time() - start
print(f'5000 writes in {took:.1f} s, {5000 / took:.0f} a second, {retries} retried')
```

```
ana@laptop:~/aws$ python3 flood.py
5000 writes in 13.8 s, 363 a second, 0 retried
ana@laptop:~/aws$ aws dynamodb describe-table --table-name products --query 'Table.[ItemCount,ProvisionedThroughput.WriteCapacityUnits]' --output text
5002	5
```

**5,000 writes in 13.8 seconds, 363 a second, against a capacity of 5, and not one was retried.** The
5,002 items are the 5,000 and the two of the first section. AWS was not asked. By its documented
rules, those 13.8 seconds would have carried about 69 writes at 5 a second, plus at most 1,500 from
five minutes of burst capacity if the table had been idle that long. The rest would have been throttled, and boto3 would have retried them, turning a program that took 14 seconds here into one that
takes many minutes there. **A load test against moto measures your program and your laptop, never
DynamoDB.** The capacity of a design is checked with the arithmetic of this lesson, and on a real
account with a budget, not here.
