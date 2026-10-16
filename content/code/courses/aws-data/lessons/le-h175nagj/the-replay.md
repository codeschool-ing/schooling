---
title: A consumer that crashes, counted twice and then once
version: 1
---

**This section makes a duplicate happen and then makes it harmless, in a program you can run.** The
setting is Quitanda's payments: a Kinesis stream of one record per paid order, and a consumer that
keeps each customer's running total in DynamoDB. The totals are the kind of number somebody reports
to finance, so counting an order twice is not a rounding error; it is a wrong invoice.

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed in this one, with moto started empty. A stream of one shard, and two tables, one
for the totals and one for the order ids already processed:

```sh
aws kinesis create-stream --stream-name payments --shard-count 1
aws dynamodb create-table --table-name quitanda-totals --billing-mode PAY_PER_REQUEST \
  --attribute-definitions AttributeName=customer_id,AttributeType=S \
  --key-schema AttributeName=customer_id,KeyType=HASH > /dev/null
aws dynamodb create-table --table-name quitanda-processed --billing-mode PAY_PER_REQUEST \
  --attribute-definitions AttributeName=order_id,AttributeType=S \
  --key-schema AttributeName=order_id,KeyType=HASH > /dev/null
```

## The producer, with one retry in it

Save it as `~/aws/pay.py`:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "import json\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\n\n", "note": "One shard is enough to show everything this lesson is about, and keeps the consumer to one iterator. The stream is created by the commands above this block."}, {"code": "PAYMENTS = [\n    ('o-301', 'c-17', 4590), ('o-302', 'c-02', 12800), ('o-303', 'c-17', 990),\n    ('o-304', 'c-05', 2350), ('o-305', 'c-02', 1500), ('o-306', 'c-17', 7200),\n]\n", "note": "Six payments for three customers. The idempotency key is the order id: an order is paid once, so a second record for the same order is a duplicate whatever caused it."}, {"code": "RETRIED = {'o-303'}\n\nfor order, customer, cents in PAYMENTS:\n    data = json.dumps({'order_id': order, 'customer_id': customer, 'cents': cents}).encode()\n    for _ in range(2 if order in RETRIED else 1):\n        r = kinesis.put_record(StreamName='payments', PartitionKey=customer, Data=data)\n        print(f\"{order} {customer} {cents:>6}  seq {r['SequenceNumber']}\")\n", "note": "**`o-303` is sent twice**, as a producer does when its first `PutRecord` timed out and it cannot tell whether the record was written. Kinesis gives the second copy a sequence number of its own."}]}
```

```
ana@laptop:~/aws$ python3 pay.py
o-301 c-17   4590  seq 1
o-302 c-02  12800  seq 2
o-303 c-17    990  seq 3
o-303 c-17    990  seq 4
o-304 c-05   2350  seq 5
o-305 c-02   1500  seq 6
o-306 c-17   7200  seq 7
```

**Seven records for six payments.** Sequence numbers 3 and 4 hold the same payment, and the correct
totals are the sums of the six: 12,780 cents for `c-17`, 14,300 for `c-02` and 2,350 for `c-05`.
Those are the numbers to compare against below.

## The consumer

Save it as `~/aws/totals.py`:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "import json\nimport os\nimport sys\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\ndynamodb = boto3.client('dynamodb')\nmode = sys.argv[1]\ncrash_after = int(sys.argv[2]) if len(sys.argv) > 2 else None\nSHARD = 'shardId-000000000000'\n\n", "note": "**A consumer that adds each payment to its customer's total.** `plain` adds every record it reads; `dedupe` first records the order id and adds only if that order was never seen. A second argument makes it crash after that many records, the way a process dies when its machine is replaced."}, {"code": "if os.path.exists('checkpoint.txt'):\n    start = {'ShardIteratorType': 'AFTER_SEQUENCE_NUMBER',\n             'StartingSequenceNumber': open('checkpoint.txt').read()}\nelse:\n    start = {'ShardIteratorType': 'TRIM_HORIZON'}\nit = kinesis.get_shard_iterator(StreamName='payments', ShardId=SHARD, **start)['ShardIterator']\n\n", "note": "The checkpoint is the sequence number of the last record finished, kept in a file. With no checkpoint the consumer starts at `TRIM_HORIZON`; with one, just after it. The Kinesis Client Library keeps the same thing in a DynamoDB table."}, {"code": "add = {'TableName': 'quitanda-totals',\n       'UpdateExpression': 'ADD cents :c'}\n\n\n", "note": "`ADD` is the sink that is not idempotent: applied twice, it counts twice."}, {"code": "def apply(e):\n    key = {'customer_id': {'S': e['customer_id']}}\n    value = {':c': {'N': str(e['cents'])}}\n    if mode == 'plain':\n        dynamodb.update_item(Key=key, ExpressionAttributeValues=value, **add)\n        return 'added'\n    try:\n        dynamodb.transact_write_items(TransactItems=[\n            {'Put': {'TableName': 'quitanda-processed',\n                     'Item': {'order_id': {'S': e['order_id']}},\n                     'ConditionExpression': 'attribute_not_exists(order_id)'}},\n            {'Update': {'Key': key, 'ExpressionAttributeValues': value, **add}},\n        ])\n        return 'added'\n    except dynamodb.exceptions.TransactionCanceledException:\n        return 'duplicate, skipped'\n\n\n", "note": "**The dedupe and the effect are one transaction.** The `Put` into `quitanda-processed` carries `attribute_not_exists`, so it fails if the order id is already there, and when any part of a transaction fails, none of it happens. Two separate writes would leave a gap: a crash between them would either count an order without recording it, or record it and never count it."}, {"code": "done, last = 0, None\nwhile it:\n    out = kinesis.get_records(ShardIterator=it)\n    for rec in out['Records']:\n        if crash_after is not None and done == crash_after:\n            print(f'crash after {done} records, before the checkpoint')\n            os._exit(1)\n        e = json.loads(rec['Data'])\n        print(f\"seq {rec['SequenceNumber']}  {e['order_id']} {e['customer_id']} {e['cents']:>6}  {apply(e)}\")\n        done, last = done + 1, rec['SequenceNumber']\n    if not out['Records'] and out['MillisBehindLatest'] == 0:\n        break\n    it = out.get('NextShardIterator')\nif last:\n    open('checkpoint.txt', 'w').write(last)\n    print(f'checkpoint at seq {last}')\n", "note": "The loop reads to the end of the shard, as `consumer.py` in lesson 20 did. **The checkpoint is written once, at the end**, which is what makes this at-least-once: everything read before a crash is read again."}]}
```

## Without the dedupe

`plain`, told to crash after four records, then started again, as a supervisor restarts a process
that died:

```
ana@laptop:~/aws$ python3 totals.py plain 4
seq 1  o-301 c-17   4590  added
seq 2  o-302 c-02  12800  added
seq 3  o-303 c-17    990  added
seq 4  o-303 c-17    990  added
crash after 4 records, before the checkpoint
ana@laptop:~/aws$ ls checkpoint.txt
ls: cannot access 'checkpoint.txt': No such file or directory
ana@laptop:~/aws$ python3 totals.py plain
seq 1  o-301 c-17   4590  added
seq 2  o-302 c-02  12800  added
seq 3  o-303 c-17    990  added
seq 4  o-303 c-17    990  added
seq 5  o-304 c-05   2350  added
seq 6  o-305 c-02   1500  added
seq 7  o-306 c-17   7200  added
checkpoint at seq 7
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text
c-02	27100
c-05	2350
c-17	20340
```

**Every number is wrong, and nothing printed an error.** The first run added four records and died
before writing a checkpoint, so `checkpoint.txt` does not exist and the second run began at
`TRIM_HORIZON`, adding those four again. `c-17` came out at 20,340 instead of 12,780: `o-301` counted
twice by the replay, and `o-303` four times, twice for the producer's retry and twice again for the
replay. `c-02` is 27,100 instead of 14,300. Only `c-05` is right, because its payment came after the
crash. This is at-least-once delivery working exactly as designed, into a sink that is not
idempotent.

## With the dedupe

The same two runs in `dedupe` mode, from a fresh table of totals and no checkpoint. moto answered the
`delete-table` with `ACTIVE`, where AWS answers `DELETING` and takes a moment; the table was gone
either way when it was created again:

```
ana@laptop:~/aws$ rm checkpoint.txt && aws dynamodb delete-table --table-name quitanda-totals --query TableDescription.TableStatus
"ACTIVE"
ana@laptop:~/aws$ aws dynamodb create-table --table-name quitanda-totals --billing-mode PAY_PER_REQUEST --attribute-definitions AttributeName=customer_id,AttributeType=S --key-schema AttributeName=customer_id,KeyType=HASH --query TableDescription.TableStatus
"ACTIVE"
ana@laptop:~/aws$ python3 totals.py dedupe 4
seq 1  o-301 c-17   4590  added
seq 2  o-302 c-02  12800  added
seq 3  o-303 c-17    990  added
seq 4  o-303 c-17    990  duplicate, skipped
crash after 4 records, before the checkpoint
ana@laptop:~/aws$ python3 totals.py dedupe
seq 1  o-301 c-17   4590  duplicate, skipped
seq 2  o-302 c-02  12800  duplicate, skipped
seq 3  o-303 c-17    990  duplicate, skipped
seq 4  o-303 c-17    990  duplicate, skipped
seq 5  o-304 c-05   2350  added
seq 6  o-305 c-02   1500  added
seq 7  o-306 c-17   7200  added
checkpoint at seq 7
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text
c-02	14300
c-05	2350
c-17	12780
```

**The totals are the correct ones**, 12,780, 14,300 and 2,350, through the same producer retry and
the same crash. In the first run, the second copy of `o-303` failed the condition, because its order
id was already in `quitanda-processed`, and the transaction cancelled both its writes. In the second
run, the replay of the first four records failed the same way, one by one, and only the three records
nobody had processed were added. The consumer is still at-least-once; the effect is now exactly once.

**And it survives the worst case, a replay of the whole stream:**

```
ana@laptop:~/aws$ rm checkpoint.txt && python3 totals.py dedupe
seq 1  o-301 c-17   4590  duplicate, skipped
seq 2  o-302 c-02  12800  duplicate, skipped
seq 3  o-303 c-17    990  duplicate, skipped
seq 4  o-303 c-17    990  duplicate, skipped
seq 5  o-304 c-05   2350  duplicate, skipped
seq 6  o-305 c-02   1500  duplicate, skipped
seq 7  o-306 c-17   7200  duplicate, skipped
checkpoint at seq 7
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text
c-02	14300
c-05	2350
c-17	12780
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-processed --select COUNT --query Count
6
```

Seven records read, seven skipped, the totals unchanged, and six order ids recorded, one per
payment. **That is what idempotent means: running it again changes nothing.** It is also what makes
reprocessing safe. Lesson 20's advice to keep a week of retention for a second chance is only half
of it; the other half is a consumer that can be pointed back at `TRIM_HORIZON` without corrupting
what it already wrote.

## What the dedupe table costs

**One more write per record, and a table that grows.** Every payment now costs a conditional `Put` and an `Update` inside a transaction, and DynamoDB bills a transactional write at twice an ordinary one. So the consumer's write bill is about four times the `plain` one; lesson 11's prices make that
a number for a given volume. The table of processed ids grows by one item per event for ever, unless
each item carries a time to live a little longer than the longest replay anyone would run, such as
the stream's retention plus a margin, after which DynamoDB deletes it for free. A duplicate older
than that window is no longer caught, which is the trade, and it is made consciously by choosing the
window.
