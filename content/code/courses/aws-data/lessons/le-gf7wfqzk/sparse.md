---
title: A sparse index
version: 1
---

**An index holds only the items that have its key, and that is a feature, not a gap.** A relational
index has an entry for every row, NULLs included. A global secondary index on an attribute that most
items lack is small, cheap, and answers "which items are in this state" without reading the ones that
are not. The orders of 14 October in Quitanda's table carry `pending_since` until they are delivered,
and nothing else carries it. So an index keyed on it holds the open orders and nothing more:

```sh
aws dynamodb update-table --table-name quitanda \
  --attribute-definitions AttributeName=pending_since,AttributeType=S AttributeName=order_id,AttributeType=S \
  --global-secondary-index-updates '[{"Create": {"IndexName": "pending",
      "KeySchema": [{"AttributeName": "pending_since", "KeyType": "HASH"},
                    {"AttributeName": "order_id", "KeyType": "RANGE"}],
      "Projection": {"ProjectionType": "KEYS_ONLY"}}}]' > /dev/null
```

An index is created in its own `update-table`, one per call, which is AWS's rule as well as moto's.
`KEYS_ONLY` because the dispatch screen needs the keys to fetch an order and nothing else.

```
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --index-name pending --select COUNT --query '[Count,ScannedCount]' --output text
722	722
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'attribute_exists(pending_since)' --select COUNT --query '[Count,ScannedCount]' --output text
255	11439
241	11445
226	11216
```

**A scan of the index read 722 items and found 722**: every item in it is an open order, so there is
nothing to filter. The same question asked of the table, a scan with `attribute_exists(pending_since)`,
found the same 722 in three pages and read all 34,100 items to do it. Scanning a sparse index is one of
the few scans that are honest work.

**And an order leaves the index by itself when it is delivered.** Removing the attribute is the
delivery of lesson 9's last section; DynamoDB removes the index entry in the same write:

```
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-19"}, "sk": {"S": "ORDER#2026-10-14#o-10009"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{":t": {"S": "2026-10-14T19:05"}}'
{
    "ConsumedCapacity": {
        "TableName": "quitanda",
        "CapacityUnits": 0.5
    }
}
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --index-name pending --select COUNT --query Count
721
```

**721.** Nothing deleted anything from the index; the item stopped qualifying. That is the whole
technique: an attribute that exists only while an item is in a state, and an index on it. Its cost
follows the state rather than the table: an order pays index writes twice, once when it becomes pending
and once when it stops, and the index stores only what is open now.

**moto also answered the update with a `ConsumedCapacity` nobody asked for.** AWS returns that block
only when the request asks for it with `--return-consumed-capacity`, and lesson 11 shows that the
number in it, here 0.5 for a write, is not what AWS would charge.
