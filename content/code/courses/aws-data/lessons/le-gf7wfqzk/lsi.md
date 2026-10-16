---
title: Local secondary indexes
version: 1
---

**A local secondary index keeps the table's partition key and sorts the same item collection by a
different attribute.** Where a global index reorganises the whole table, a local one is a second
order for each collection: c-17's items, sorted by `total_cents` instead of by `sk`. "A customer's
largest orders" is then a query on the index, read backwards.

**It can only be created with the table.** `update-table` has no parameter for one, on AWS or in the
command line, so a local index that was not in the first design is a new table and a reload. Here that
is cheap, so the table is dropped and made again with one:

```sh
aws dynamodb delete-table --table-name quitanda > /dev/null
aws dynamodb create-table --table-name quitanda \
  --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S \
                          AttributeName=total_cents,AttributeType=N \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --local-secondary-indexes '[{"IndexName": "by-total",
      "KeySchema": [{"AttributeName": "pk", "KeyType": "HASH"},
                    {"AttributeName": "total_cents", "KeyType": "RANGE"}],
      "Projection": {"ProjectionType": "ALL"}}]' \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

On AWS, `delete-table` deletes every item and both indexes, and nothing asks twice. That is the price
of an index missing from the first design, and the reason lesson 9 writes the patterns down first.

```
ana@laptop:~/aws$ python3 seed.py
3 customers: 3 profiles, 9 orders, 18 order lines, 30 items
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-total --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --no-scan-index-forward --query 'Items[].[total_cents.N,sk.S]' --output text
23490	ORDER#2026-10-05#o-10002
5760	ORDER#2026-10-03#o-10001
2489	ORDER#2026-10-12#o-10003
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-total --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --no-scan-index-forward --limit 1 --consistent-read --query 'Items[0].[order_id.S,total_cents.N]' --output text
o-10002	23490
```

**c-17's three orders, largest first, and the profile and the lines are not there**, because they have
no `total_cents`: a local index is sparse in the same way a global one is. The second query asked for
`--consistent-read` and got it. That is the one thing only a local index offers, because it lives in
the same partition as the items it sorts and is written in the same operation. It also shares the
table's capacity rather than having its own, and a query on it may ask for attributes that were not
projected, which DynamoDB then fetches from the table at the cost of another read.

## The limit that comes with it

**A table with a local index caps each item collection at 10 GB.** The items of one partition key,
plus their copies in every local index, may not exceed it, and a write that would cross it fails with
`ItemCollectionSizeLimitExceededException`. A customer's orders will not reach 10 GB; a collection
keyed on something that grows forever, a device's readings or a shop's events, can. moto does not
enforce the limit, and it was not run here.

**So a local index is the exception, chosen for a reason.** Strong consistency on an alternative sort
order is that reason. Otherwise a global index does the same job for the same collection, with the
table's partition key as its own, no size limit, its own capacity, and the possibility of being added
the day the question arrives. AWS allows up to five local indexes per table and, by default, twenty
global ones.
