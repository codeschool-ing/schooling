---
title: DynamoDB, what the key does not allow
version: 1
---

The table is fast for every question that starts from a buyer. Here are two that do not:

```
ana@lab:~/tickets$ ddb query --table-name tickets --key-condition-expression 'ticket = :t' --expression-attribute-values '{":t": {"S": "show-1#seat-42"}}'

An error occurred (ValidationException) when calling the Query operation: Query condition missed key schema element
ana@lab:~/tickets$ ddb scan --table-name tickets --filter-expression 'begins_with(ticket, :s)' --expression-attribute-values '{":s": {"S": "show-1#"}}' --return-consumed-capacity TOTAL --query '{Count: Count, ScannedCount: ScannedCount, CapacityUnits: ConsumedCapacity.CapacityUnits}'
{
    "Count": 3,
    "ScannedCount": 5,
    "CapacityUnits": 0.5
}
ana@lab:~/tickets$ docker rm -f dynamo
dynamo
```

**A query by the sort key alone is refused.** "Who holds seat 42 of show 1?" names a ticket and no
buyer, and DynamoDB answers with a `ValidationException`: a query must name the partition key,
because that is how it finds the one partition to read. There is no planner that would fall back
to reading everything.

**A scan reads everything.** It walks every item of the table, then applies the filter.
`ScannedCount` is 5 and `Count` is 3: it read the whole table to return three items, and **the
capacity is charged on what was read, not on what was returned**. On five items that is half a
unit. On fifty million items it is the whole table's worth of reads on every call, and a scan in
the path of a request is the most common way a DynamoDB bill surprises its owner.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The tickets table laid out by key. Three partitions, one per buyer: ana with three items sorted by ticket, show-1 seat-42, show-1 seat-43 and show-7 seat-3; bia with one; caio with one. A query for ana and tickets beginning with show-1 reads two adjacent items in one partition. A scan reads all five items in every partition.\"><rect x=\"20\" y=\"30\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">buyer = ana</text><rect x=\"35\" y=\"62\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1#seat-42</text><rect x=\"35\" y=\"96\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1#seat-43</text><rect x=\"35\" y=\"130\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">show-7#seat-3</text><rect x=\"255\" y=\"30\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">buyer = bia</text><rect x=\"270\" y=\"62\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">show-1#seat-44</text><rect x=\"490\" y=\"30\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">buyer = caio</text><rect x=\"505\" y=\"62\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">show-7#seat-4</text><text x=\"125\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">query: 2 read, 2 returned</text><text x=\"480\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">scan: all 5 read, 3 returned</text></svg>", "caption": "A query reads a slice of one partition; a scan reads every item and filters afterwards."}
```

## Another way in: a secondary index

When a second access pattern matters, "who holds this seat", the answer is a **global secondary
index**: a second copy of the items, maintained by DynamoDB, keyed by different attributes, here
the ticket. It is lesson 4's "one table per query" done by the database instead of by the program.
It costs a second write for every write, and **it is updated asynchronously**: a query on the index
right after a write may not see it yet, which is lesson 2's replica lag in a new place.

## What would differ in the real service

DynamoDB Local answers the same requests with the same shapes, and it is one process on your
machine. The service is not:

- **partitions are real.** Each partition has limits on reads and writes per second; a partition
  key that takes most of the traffic, the hot show again, is throttled while the rest of the table
  is idle;
- **capacity is money.** In `PAY_PER_REQUEST` mode every read and write is billed; in provisioned
  mode you reserve a rate and requests beyond it are refused. Local reports capacity units and
  charges nothing;
- **reads are eventually consistent by default.** A read can ask for strong consistency, at twice
  the cost, which is lesson 3's trade printed on the price list.

Remove the container when you are done, as the last command above did.
