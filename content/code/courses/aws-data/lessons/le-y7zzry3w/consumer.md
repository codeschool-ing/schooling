---
title: A consumer that keeps a running total
version: 1
---

**A stream reader is a loop over shards and iterators, and what it does with each record is the
application.** Quitanda's app shows each customer what they have spent this month. Summing a customer's
orders on every screen is a query that grows with the history; keeping one number per customer, moved
by every change to an order, is a single `get-item`. The stream is what keeps that number honest: every
change to an order, by any program, reaches it.

The totals live in a table of their own, so that writing them does not add records to the stream being
read:

```sh
aws dynamodb create-table --table-name quitanda-totals \
  --attribute-definitions AttributeName=pk,AttributeType=S \
  --key-schema AttributeName=pk,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

**The program reads every shard from the oldest record, and for each change to an order adds the
difference to that customer's total.** Save it as `~/aws/totals.py`:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Keep a running total per customer from the stream of the table `quitanda`.\n\n    python3 totals.py           # apply each change once, however often it is read\n    python3 totals.py --naive   # apply whatever arrives, as a careless consumer would\n\nReads every shard from the oldest record still kept, and writes the totals\ninto the table `quitanda-totals`. Needs the stream view NEW_AND_OLD_IMAGES.\n\"\"\"\nimport sys\n\nimport boto3\nfrom botocore.exceptions import ClientError\n\ndb = boto3.client('dynamodb')\nstreams = boto3.client('dynamodbstreams')\nTOTALS = 'quitanda-totals'\nnaive = '--naive' in sys.argv\n\n\n", "note": "The manual. A stream reader that keeps one number per customer, the total of their orders, in a table of its own."}, {"code": "def change(record):\n    keys = record['dynamodb']['Keys']\n    sk = keys['sk']['S']\n    if not sk.startswith('ORDER#') or '#LINE#' in sk:\n        return None\n    def total(image):\n        return int(record['dynamodb'].get(image, {}).get('total_cents', {}).get('N', 0))\n    return keys['pk']['S'], total('NewImage') - total('OldImage')\n\n\n", "note": "**One record is one change to one item.** Only orders move a total, so profiles and lines are skipped by their sort key. An `INSERT` has only a new image, a `REMOVE` only an old one, a `MODIFY` both, so in every case the change is the new total minus the old, with a missing image counting as zero."}, {"code": "def apply(customer, cents, event_id):\n    add = {'Update': {'TableName': TOTALS, 'Key': {'pk': {'S': customer}},\n                      'UpdateExpression': 'ADD total_cents :c',\n                      'ExpressionAttributeValues': {':c': {'N': str(cents)}}}}\n    seen = {'Put': {'TableName': TOTALS, 'Item': {'pk': {'S': 'EVENT#' + event_id}},\n                    'ConditionExpression': 'attribute_not_exists(pk)'}}\n    try:\n        db.transact_write_items(TransactItems=[add] if naive else [seen, add])\n        return True\n    except ClientError as e:\n        if e.response['Error']['Code'] == 'TransactionCanceledException':\n            return False\n        raise\n\n\n", "note": "**The change is added in a transaction with a marker of the record's `eventID`**, written only if no marker for it exists yet. A record applied before cancels its own transaction, and the total is left alone. `--naive` sends the addition alone, which is what a consumer without the marker does."}, {"code": "arn = db.describe_table(TableName='quitanda')['Table']['LatestStreamArn']\nshards = streams.describe_stream(StreamArn=arn)['StreamDescription']['Shards']\napplied = skipped = 0\nfor shard in shards:\n    iterator = streams.get_shard_iterator(StreamArn=arn, ShardId=shard['ShardId'],\n                                          ShardIteratorType='TRIM_HORIZON')['ShardIterator']\n    while iterator:\n        batch = streams.get_records(ShardIterator=iterator)\n        if not batch['Records']:\n            break\n        for record in batch['Records']:\n            found = change(record)\n            if found and apply(*found, record['eventID']):\n                applied += 1\n            elif found:\n                skipped += 1\n        iterator = batch.get('NextShardIterator')\n\n", "note": "**Every shard, from `TRIM_HORIZON`**, the oldest record the stream still keeps. Each `get_records` returns a batch and the iterator for the next one. This reader stops at the first empty batch, which is right for a program run by hand once the writes have finished and wrong for an open shard on AWS, where an empty batch only means nothing new yet; a long-running reader keeps polling."}, {"code": "print(f'{len(shards)} shard(s): {applied} changes applied, {skipped} already applied')\nfor item in db.scan(TableName=TOTALS)['Items']:\n    if item['pk']['S'].startswith('CUSTOMER#'):\n        print(f\"  {item['pk']['S']:<16}{int(item['total_cents']['N']) / 100:>10.2f}\")\n", "note": "What it did, and the totals as they now stand, in reais."}]}
```

```
ana@laptop:~/aws$ python3 totals.py
1 shard(s): 11 changes applied, 0 already applied
  CUSTOMER#c-17       275.69
  CUSTOMER#c-18        72.27
  CUSTOMER#c-19       321.59
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":o": {"S": "ORDER#"}}' --query "sum(Items[?!contains(sk.S, '#LINE#')].to_number(total_cents.N))"
27569
```

**Eleven changes applied, and c-17 stands at 275.69 reais.** Nine were the orders the seed inserted, one
the `MODIFY` that raised the order of 12 October, and one the `REMOVE` of the order of 3 October; the
twenty-five profiles and lines in the stream were skipped by their keys. The query below the totals
asks the table itself, adding up c-17's orders with a JMESPath `sum` in the command line, and answers
27569 cents: the same number by a different road. A running total that has never been compared with
the data it summarises is a number nobody can vouch for, and on AWS the comparison is the check that
finds a consumer that missed a record.

**moto listed the totals in key order** because its scan is a dictionary; on AWS the three rows could
come back in any order.
