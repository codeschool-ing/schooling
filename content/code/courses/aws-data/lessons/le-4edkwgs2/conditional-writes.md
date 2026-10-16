---
title: Conditional writes, and the overwrite nobody saw
version: 1
---

**A `put-item` replaces whatever item already had its key, completely and without a word.** There is
no "insert" that fails when the row exists, as there is in SQL with a primary key. The first section of
this lesson wrote c-17's profile by hand, with the name Ana and the district Lapa; then `seed.py`
wrote the same key:

```
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "PROFILE"}}' --query 'Item.[name.S,district.S,customer_id.S]' --output text
Gabi	Lapa	c-17
```

**Ana is gone, and nothing reported it.** The seed's `batch_writer` sent a put for
`CUSTOMER#c-17`/`PROFILE`, and the put replaced the whole item. The name is Gabi, the district is Lapa
only because the generator happened to pick it too, and `customer_id` is an attribute the hand-written
item never had. Had the old item carried an attribute the new one did not mention, it would have gone
as well. In an application that is the classic lost update: two
screens open on the same profile, both save, and the second one wins silently.

## attribute_not_exists, the insert that refuses

**A condition expression is checked against the item that has the same key, and the write happens
only if it is true.** `attribute_not_exists(pk)` is true only when there is no item with that key at
all, since every item that exists has a `pk`. That turns a put into an insert that refuses to
overwrite:

```
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item file://profile.json --condition-expression 'attribute_not_exists(pk)' --return-values-on-condition-check-failure ALL_OLD

aws: [ERROR]: An error occurred (ConditionalCheckFailedException) when calling the PutItem operation: The conditional request failed

Additional error details:
Item: <complex value>
Use "--cli-error-format json" or another error format to see the full details.
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CUSTOMER#c-99"}, "sk": {"S": "PROFILE"}, "name": {"S": "Ana"}}' --condition-expression 'attribute_not_exists(pk)'
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CUSTOMER#c-99"}, "sk": {"S": "PROFILE"}, "name": {"S": "Ana"}}' --condition-expression 'attribute_not_exists(pk)'

aws: [ERROR]: An error occurred (ConditionalCheckFailedException) when calling the PutItem operation: The conditional request failed
```

**The first put was refused, the second created c-99, and the third was refused again.**
`ConditionalCheckFailedException` is the answer to a condition that was false, and the item is left
exactly as it was. The flag `--return-values-on-condition-check-failure ALL_OLD` asks for the item
that stopped the write to come back with the error, so a program can show what is already there instead of asking again. The command line prints it as `<complex value>` unless it is told to format
errors as JSON. **A failed conditional write is still a write on the bill**: AWS charges the write
units of the attempt, condition true or not.

**`BatchWriteItem` takes no conditions**, which is why the seed could not have been told to leave Ana
alone. A batch is up to 25 plain puts and deletes. Where some of them must not overwrite, they go one
by one, or in a transaction, `TransactWriteItems`, which applies up to a hundred writes with
conditions, all or none, and which lesson 11 prices.

## A condition on the state, not only on existence

The same mechanism guards a change of state. Order `o-10009` was placed on 14 October and carries
`pending_since`; delivering it removes that attribute and records when. Twice:

```
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-19"}, "sk": {"S": "ORDER#2026-10-14#o-10009"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{":t": {"S": "2026-10-14T18:20"}}' --return-values ALL_NEW --query 'Attributes.[order_id.S,pending_since.S,delivered_at.S]' --output text
o-10009	None	2026-10-14T18:20
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-19"}, "sk": {"S": "ORDER#2026-10-14#o-10009"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{":t": {"S": "2026-10-14T18:45"}}' --return-values ALL_NEW

aws: [ERROR]: An error occurred (ConditionalCheckFailedException) when calling the UpdateItem operation: The conditional request failed
```

**The first update delivered the order, and the second was refused, because it was already
delivered.** A driver's app that sends the same "delivered" twice, after a retry over a bad
connection, changes nothing the second time, and the time of delivery is the first one. The same shape with a number is optimistic locking:
`version = :seen` in the condition and `version = version + 1` in the update. A write then succeeds
only if nobody changed the item since it was read, which is the repair for the two screens above.
