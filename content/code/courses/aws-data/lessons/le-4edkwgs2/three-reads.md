---
title: get-item, query and scan
version: 1
---

**There are three ways to read a table, and only two of them use the key.** `get-item` returns one
item, named by its whole key. `query` returns a slice of one item collection: it takes exactly one
partition key, with `=`, and optionally one condition on the sort key. `scan` reads every item in the
table, in an order nobody should rely on, and can filter what it hands back. The first two cost what
they return; the third costs the whole table every time.

## query, and the conditions it allows

**The sort-key conditions are `=`, `<`, `<=`, `>`, `>=`, `BETWEEN` and `begins_with`, and that is the
complete list.** No `contains`, no `OR`, no condition on a second attribute. Each of them describes a
contiguous run of the sorted collection, which is why they are cheap: DynamoDB finds the start of the
run and reads forward. Pattern A3, one order and its lines, is a prefix:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":o": {"S": "ORDER#2026-10-05#o-10002"}}' --query 'Items[].[sk.S,total_cents.N,product.S,qty.N]' --output text
ORDER#2026-10-05#o-10002	23490	None	None
ORDER#2026-10-05#o-10002#LINE#1	None	coffee-500g	3
ORDER#2026-10-05#o-10002#LINE#2	None	rice-5kg	3
ORDER#2026-10-05#o-10002#LINE#3	None	eggs-12	3
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND sk BETWEEN :a AND :b' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":a": {"S": "ORDER#2026-10-01"}, ":b": {"S": "ORDER#2026-10-08"}}' --query '[Count,ScannedCount]' --output text
8	8
```

**The first query is A3 and the second is A2.** `begins_with` with the order's prefix returned the
order and its three lines, four items in one request. `BETWEEN ORDER#2026-10-01 AND ORDER#2026-10-08`
returned the two orders of the first week with their lines: eight items. `BETWEEN` includes both ends,
and the upper end works here because no sort key is exactly `ORDER#2026-10-08`; every order of that
day would be `ORDER#2026-10-08#o-…`, which sorts after it and is left out. That is byte order doing
the work of a date comparison. `Count` is what came back and `ScannedCount` what was read, and in a
query with no filter they are the same number.

The two conditions DynamoDB refuses are the ones that cannot be a contiguous run:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'sk = :s' --expression-attribute-values '{":s": {"S": "PROFILE"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Query condition missed key schema element: pk
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'begins_with(pk, :p)' --expression-attribute-values '{":p": {"S": "CUSTOMER#"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Query key condition not supported
```

A sort key on its own names no partition, and `begins_with` on a partition key would mean every
partition whose hash happens to start nowhere in particular. Both are refused before anything is read.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The item collection of CUSTOMER#c-17: twelve items in sort-key order, three orders each followed by its lines, and PROFILE last. A2, BETWEEN ORDER#2026-10-01 AND ORDER#2026-10-08, covers the first eight items. A3, begins_with the prefix of order o-10002, covers items five to eight. A4, reading newest first under ORDER# with a limit of one, stops on item eleven, the second line of order o-10003, not an order. A1, get-item on PROFILE, is the twelfth item.\" data-fig=\"l09-collection\"><defs><marker id=\"l09-collection-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"120\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">pk = CUSTOMER#c-17</text><rect x=\"120\" y=\"40\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001</text><rect x=\"120\" y=\"62\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001#LINE#1</text><rect x=\"120\" y=\"84\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001#LINE#2</text><rect x=\"120\" y=\"106\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001#LINE#3</text><rect x=\"120\" y=\"128\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002</text><rect x=\"120\" y=\"150\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002#LINE#1</text><rect x=\"120\" y=\"172\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002#LINE#2</text><rect x=\"120\" y=\"194\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002#LINE#3</text><rect x=\"120\" y=\"216\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-12#o-10003</text><rect x=\"120\" y=\"238\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-12#o-10003#LINE#1</text><rect x=\"120\" y=\"260\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"/><text x=\"128\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-12#o-10003#LINE#2</text><rect x=\"120\" y=\"282\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"292.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PROFILE</text><line x1=\"95\" y1=\"44.0\" x2=\"95\" y2=\"298.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-collection-ah)\"/><text x=\"88\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sorted by sk</text><path d=\"M384,42 H392 V212 H384\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"/><path d=\"M412,130 H420 V212 H412\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"/><line x1=\"392\" y1=\"94.0\" x2=\"446\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"452\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A2, between two dates: 8 items</text><line x1=\"420\" y1=\"182.0\" x2=\"446\" y2=\"182.0\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"452\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A3, one order and its lines: 4</text><line x1=\"372\" y1=\"270.0\" x2=\"446\" y2=\"270.0\" stroke=\"var(--amber)\" stroke-width=\"1\"/><text x=\"452\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">A4, newest first, limit 1: a line</text><line x1=\"372\" y1=\"292.0\" x2=\"446\" y2=\"292.0\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"452\" y=\"292.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A1, get-item: exactly one</text></svg>", "caption": "One item collection, and the four reads of this lesson as runs of it. A query is always one contiguous run, which is why A4 lands on a line."}
```

## Newest first, and the line that came back instead

**`--no-scan-index-forward` reads a collection backwards**, and with `--limit 1` it is pattern A4,
the latest order:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":o": {"S": "ORDER#"}}' --no-scan-index-forward --limit 1 --query 'Items[].[sk.S,product.S]' --output text
ORDER#2026-10-12#o-10003#LINE#2	eggs-12
```

**It returned a line, not an order.** The last item under `ORDER#` in c-17's collection is the second
line of the order of 12 October, because the lines sort after their order and reading backwards meets
them first. The query did exactly what it was asked; the design did not fit the question. There are
two repairs. One is in the read: ask for four items newest first, which covers an order with its three
lines, and keep the first one whose key has no `#LINE#`, paying for the lines on every call. The other
is in the key, where it belongs: had the order's own item sorted after its lines, under a key such as
`ORDER#2026-10-12#o-10003#ORDER`, the last item under `ORDER#` would always be an order. Finding this
when the patterns are written costs a sentence; finding it after the table holds a million customers
costs a migration.

## scan, and what a filter does not save

**A filter is applied after the read, so it decides what you get and not what you pay for.**
Looking for a customer by name is not one of the patterns, and the table answers it the only way it
can:

```
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'name = :n' --expression-attribute-values '{":n": {"S": "Gabi"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Scan operation: Invalid ConditionExpression: Attribute name is a reserved keyword; reserved keyword: name
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression '#n = :n' --expression-attribute-names '{"#n": "name"}' --expression-attribute-values '{":n": {"S": "Gabi"}}' --query '[Count,ScannedCount,Items[0].pk.S]' --output text
1	30	CUSTOMER#c-17
```

**The first scan was refused before it read anything, because `name` is a reserved word.** DynamoDB
reserves several hundred words of its expression language, and among them are `name`, `status`,
`date`, `total`, `count` and `size`, which are exactly the names people give attributes. The repair is
a placeholder: `#n` in the expression and `{"#n": "name"}` beside it. moto keeps AWS's list and
refuses the same words.

**The second scan found one item and read thirty.** `Count` is 1 and `ScannedCount` is 30: the whole
table was read, and the filter threw 29 items away afterwards. On thirty items that is nothing; on a
table of every Quitanda customer it is the whole table on every search, and lesson 10 puts a price on
it. moto also returns a scan in key order, which is a side effect of its dictionary. AWS returns it in
the order of the partition hashes, so a program that relies on a scan's order works here and not there.
