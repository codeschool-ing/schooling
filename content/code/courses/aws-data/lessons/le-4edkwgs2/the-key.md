---
title: The partition key and the sort key
version: 1
---

**A DynamoDB table is not a relational table with the joins taken away.** The habit `sql-databases`
leaves is to model the entities first and trust the query planner to find the rows whatever the
question. DynamoDB has no planner. A read that is fast names a key, and a read that does not name
one reads the whole table. So the key is the design, and it has two parts.

**The partition key is hashed, and the hash chooses a partition.** DynamoDB stores a table in
partitions, slices of storage it manages and replicates across several zones of the region, and adds
more as the table grows. When an item is written, the value of its partition key goes through an
internal hash function, and the result decides which partition holds it. Two things follow at once.
Every item with the same partition key lives in the same place. And items whose keys look like
neighbours, `CUSTOMER#c-17` and `CUSTOMER#c-18`, land wherever their hashes send them, so there is
no such read as "the customers from c-17 to c-40".

**The sort key orders the items that share a partition key**, and that group is called an **item
collection**. Inside a collection the items are kept sorted by the sort key: by UTF-8 bytes for a
string, the order S3 used for keys in lesson 1, and by value for a number. A table with both parts
has a composite primary key, and the pair must be unique; a table with only a partition key holds
one item per value.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three partition keys, CUSTOMER#c-17, c-18 and c-19, go through the hash function, and each lands in a different partition: c-18 in partition 1 with its 5 items, c-19 in partition 2 with its 13, c-17 in partition 3 with its 12. Keys that look like neighbours are not stored together; every item with the same partition key is.\" data-fig=\"l09-partitions\"><defs><marker id=\"l09-partitions-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"45\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"105\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CUSTOMER#c-17</text><line x1=\"190\" y1=\"62\" x2=\"262\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"20\" y=\"120\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"105\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CUSTOMER#c-18</text><line x1=\"190\" y1=\"137\" x2=\"262\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"20\" y=\"195\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"105\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CUSTOMER#c-19</text><line x1=\"190\" y1=\"212\" x2=\"262\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"264\" y=\"108\" width=\"120\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"324\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hash function</text><rect x=\"450\" y=\"20\" width=\"250\" height=\"66\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"462\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 1</text><rect x=\"462\" y=\"46\" width=\"226\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"472\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CUSTOMER#c-18</text><text x=\"678\" y=\"61\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">5 items</text><line x1=\"384\" y1=\"135\" x2=\"448\" y2=\"61\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"450\" y=\"100\" width=\"250\" height=\"66\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"462\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 2</text><rect x=\"462\" y=\"126\" width=\"226\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"472\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CUSTOMER#c-19</text><text x=\"678\" y=\"141\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">13 items</text><line x1=\"384\" y1=\"135\" x2=\"448\" y2=\"141\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"450\" y=\"180\" width=\"250\" height=\"66\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"462\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 3</text><rect x=\"462\" y=\"206\" width=\"226\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"472\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CUSTOMER#c-17</text><text x=\"678\" y=\"221\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">12 items</text><line x1=\"384\" y1=\"135\" x2=\"448\" y2=\"221\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/></svg>", "caption": "The hash of the partition key chooses the partition, and each item collection stays whole inside one. Which partition each key lands in is drawn here for illustration; moto has no partitions at all."}
```

## The table

Quitanda's table is called `quitanda`, and its two key attributes have deliberately dull names,
`pk` and `sk`, for a reason the section on single-table design gives:

```sh
aws dynamodb create-table --table-name quitanda \
  --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

`HASH` is the API's word for the partition key and `RANGE` for the sort key. **`--attribute-definitions`
names the key attributes and nothing else**: it is not a list of columns, and naming an attribute
there that no key or index uses is refused. `PAY_PER_REQUEST` is on-demand billing, the subject of
lesson 11.

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query "Table.[TableStatus,KeySchema,AttributeDefinitions]" --output text
ACTIVE
pk	HASH
sk	RANGE
pk	S
sk	S
ana@laptop:~/aws$ aws dynamodb create-table --table-name orders-test --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=total_cents,AttributeType=N --key-schema AttributeName=pk,KeyType=HASH --billing-mode PAY_PER_REQUEST

aws: [ERROR]: An error occurred (ValidationException) when calling the CreateTable operation: One or more parameter values were invalid: Number of attributes in KeySchema does not exactly match number of attributes defined in AttributeDefinitions
```

The table answers `ACTIVE` on the same line, which on AWS takes a few seconds and here takes none.
Behind the answer moto keeps a dictionary per table and no partitions at all. What it does reproduce
faithfully is everything this lesson relies on: the order inside a collection, the key conditions,
and the refusals.

## An item has the key, and whatever else it likes

Every attribute beyond the key is the item's own business. Write a customer's profile by hand, from
a file. `profile.json`:

```json
{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "PROFILE"}, "name": {"S": "Ana"}, "district": {"S": "Lapa"}}
```

Each value carries its type: `S` for a string, `N` for a number, and others for binary, booleans,
lists, maps and sets. The command line speaks this typed form, and the Python program in a later
section does not have to.

```
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item file://profile.json
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "PROFILE"}}'
{
    "Item": {
        "pk": {
            "S": "CUSTOMER#c-17"
        },
        "sk": {
            "S": "PROFILE"
        },
        "name": {
            "S": "Ana"
        },
        "district": {
            "S": "Lapa"
        }
    }
}
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-17"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the GetItem operation: Validation Exception
```

**`get-item` needs the whole key, both halves.** With the partition key alone it is refused, because
the table can hold many items under `CUSTOMER#c-17` and `get-item` returns exactly one. moto's message
is a bare `Validation Exception`; AWS refuses the same request with a sentence about the key not
matching the schema. Reading part of a collection is a different operation, `query`, and it is two
sections on.
