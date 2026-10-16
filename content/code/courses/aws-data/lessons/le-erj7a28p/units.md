---
title: Read units and write units
version: 1
---

**DynamoDB does not charge for requests or for time; it charges for units, and a unit is a size.** A
read unit is one strongly consistent read of an item up to 4 KB. A write unit is one write of an item
up to 1 KB. Everything else is a multiple of those two, and the multiples are the whole of the
arithmetic:

| the operation | what it costs |
|---|---|
| read, strongly consistent | 1 unit per 4 KB of the item, rounded up |
| read, eventually consistent, the default | half of that |
| read inside a transaction | twice the strongly consistent price |
| write, put, update or delete | 1 unit per 1 KB of the item, rounded up |
| write inside a transaction | twice that |

**The rounding is per item for a `get-item`, a `put-item` and each item of a batch, and per page for a
`query` or a `scan`.** In a page the sizes of all the items read are added up first and the total is
rounded, which is what lesson 10's `pages.py` counted. An update is charged on the larger of the item
before and the item after. A write that a condition refused is still charged, as lesson 9 said. And
every index that holds the item adds its own write, as lesson 10 said.

## One item, priced by hand

Quitanda's product catalogue keeps a long description on each product. The table for it is keyed on
the product's code, and is on demand like lesson 9's:

```sh
aws dynamodb create-table --table-name products \
  --attribute-definitions AttributeName=sku,AttributeType=S \
  --key-schema AttributeName=sku,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

**An item's size is the length of every attribute's name plus its value.** A coffee with a description
of 9,000 characters has `sku` (3) and `coffee-500g` (11), then `description` (11) and the 9,000: **9,025
bytes**. So, by the table above:

| | units |
|---|---|
| writing it | 9,025 / 1,024 = 8.8, so **9** |
| reading it, strongly consistent | 9,025 / 4,096 = 2.2, so **3** |
| reading it, eventually consistent | **1.5** |
| reading it in a transaction | **6** |
| writing it in a transaction | **18** |

**A short description changes every line.** At 900 characters the same item is 925 bytes: one write
unit and half a read unit. The size of an item is the first decision about its price, which is why
large, rarely read attributes, a photo or a long text, usually live in S3 with only their key in the
item.

## What moto says instead

Ask moto for the units of the same operations, with `--return-consumed-capacity TOTAL`, on the same
item. The command that writes the item to a file is the one in the first line:

```
ana@laptop:~/aws$ python3 -c "import json; print(json.dumps({'sku': {'S': 'coffee-500g'}, 'description': {'S': 'x' * 9000}}))" > coffee.json
ana@laptop:~/aws$ wc -c coffee.json
9056 coffee.json
ana@laptop:~/aws$ aws dynamodb put-item --table-name products --item file://coffee.json --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits
1.0
ana@laptop:~/aws$ aws dynamodb get-item --table-name products --key '{"sku": {"S": "coffee-500g"}}' --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits
0.5
ana@laptop:~/aws$ aws dynamodb get-item --table-name products --key '{"sku": {"S": "coffee-500g"}}' --consistent-read --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits
0.5
ana@laptop:~/aws$ aws dynamodb transact-get-items --transact-items '[{"Get": {"TableName": "products", "Key": {"sku": {"S": "coffee-500g"}}}}]' --return-consumed-capacity TOTAL --query 'ConsumedCapacity[0].CapacityUnits'
2.0
ana@laptop:~/aws$ aws dynamodb transact-write-items --transact-items '[{"Put": {"TableName": "products", "Item": {"sku": {"S": "tea-250g"}}}}]' --return-consumed-capacity TOTAL --query ConsumedCapacity
[]
```

**1, 0.5, 0.5, 2 and an empty list, where AWS would say 9, 1.5, 3, 6 and 18.** The file is 9,056 bytes
of JSON, the item inside it 9,025 by AWS's rule, and moto answered a write of it with the number it
gives every write. Its reads are a flat half unit, strongly consistent or not. Its transactional read
is a flat two, and its transactional write reports nothing. **moto's `ConsumedCapacity` is a constant
per operation, not a measurement**, so in this course the units are always counted by hand or by a
program such as `pages.py`, and never read off moto. A number with the right shape and the wrong
value is the most convincing thing moto produces.
