---
title: DynamoDB, a key in two parts
version: 1
---

DynamoDB stores **items** in **tables**. Every item has a **primary key**, and the key is the whole
design: it decides where the item lives and is the only thing a fast read can ask by. A key has one
or two parts:

- the **partition key**, hashed to choose the partition that holds the item, as in lesson 2's
  sharding;
- an optional **sort key**, which keeps the items of one partition key sorted, as in Cassandra's
  clustering key of lesson 4.

The box office's access pattern here is "a buyer's tickets", and "a buyer's tickets for one show".
So the partition key is the buyer, and the sort key is the ticket, written as `show-1#seat-42`:
the show first, so that one buyer's tickets for one show sit next to each other in sort order.
**Packing two values into one sort key, in the order the query narrows by, is the most common move
in DynamoDB design.**

## Running it

DynamoDB Local is one container. Its client is the AWS command line, which also runs in a
container, so a shell alias saves typing it every time. The alias runs `aws dynamodb` inside the
`amazon/aws-cli` image, on DynamoDB Local's network, with your current directory mounted so that it
can read files from it, and with credentials that DynamoDB Local accepts and ignores:

```sh
alias ddb='docker run --rm --network container:dynamo -v "$PWD":/aws -w /aws -e AWS_ACCESS_KEY_ID=local -e AWS_SECRET_ACCESS_KEY=local -e AWS_DEFAULT_REGION=sa-east-1 amazon/aws-cli:2.31.0 dynamodb --endpoint-url http://localhost:8000'
```

An alias lasts as long as the terminal; type it again in a new one. The tickets to load, as the
request DynamoDB's `batch-write-item` expects, in YAML so that it can carry a comment:

```yaml
# tickets.yaml
RequestItems:
  tickets:
    - PutRequest:
        Item: {buyer: {S: ana}, ticket: {S: "show-1#seat-42"}, cents: {N: "18000"}}
    - PutRequest:
        Item: {buyer: {S: ana}, ticket: {S: "show-1#seat-43"}, cents: {N: "18000"}}
    - PutRequest:
        Item: {buyer: {S: ana}, ticket: {S: "show-7#seat-3"}, cents: {N: "9000"}}
    - PutRequest:
        Item: {buyer: {S: bia}, ticket: {S: "show-1#seat-44"}, cents: {N: "18000"}}
    - PutRequest:
        Item: {buyer: {S: caio}, ticket: {S: "show-7#seat-4"}, cents: {N: "9000"}}
```

Each attribute carries its type: `S` for a string, `N` for a number, which DynamoDB transmits as a
string so that no precision is lost on the way. Now the server, the table and the items:

```
ana@lab:~/tickets$ docker run -d --name dynamo amazon/dynamodb-local:3.3.0
843f57821680feb59b0bd8fdb773edee88c17a1cced7180e177b23f1cea25a26
ana@lab:~/tickets$ ddb create-table --table-name tickets --attribute-definitions AttributeName=buyer,AttributeType=S AttributeName=ticket,AttributeType=S --key-schema AttributeName=buyer,KeyType=HASH AttributeName=ticket,KeyType=RANGE --billing-mode PAY_PER_REQUEST --query TableDescription.TableStatus --output text
ACTIVE
ana@lab:~/tickets$ ddb batch-write-item --cli-input-yaml file://tickets.yaml
{
    "UnprocessedItems": {}
}
```

`create-table` names the two key attributes, which are the only ones a table declares; everything
else in an item is free. `PAY_PER_REQUEST` is the billing mode in which the real service charges per
read and write rather than for reserved capacity, which section 06 returns to. `ACTIVE` means the
table is ready, and `UnprocessedItems` empty means every item was written.

## The question it is built for

One buyer's tickets for show 1:

```
ana@lab:~/tickets$ ddb query --table-name tickets --key-condition-expression 'buyer = :b AND begins_with(ticket, :s)' --expression-attribute-values '{":b": {"S": "ana"}, ":s": {"S": "show-1#"}}' --return-consumed-capacity TOTAL
{
    "Items": [
        {
            "ticket": {
                "S": "show-1#seat-42"
            },
            "cents": {
                "N": "18000"
            },
            "buyer": {
                "S": "ana"
            }
        },
        {
            "ticket": {
                "S": "show-1#seat-43"
            },
            "cents": {
                "N": "18000"
            },
            "buyer": {
                "S": "ana"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": {
        "TableName": "tickets",
        "CapacityUnits": 0.5
    }
}
```

A **query** names one partition key value, `buyer = ana`, and may narrow the sort key, here
`begins_with(ticket, "show-1#")`. Two tickets came back, read in sort order from one partition.
`ScannedCount` is how many items DynamoDB read, and `Count` how many it returned: two and two,
**nothing wasted**. `ConsumedCapacity` is what the request cost, in the units the service bills.
