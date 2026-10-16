---
title: A delivery stream, and the objects it writes
version: 1
---

**Firehose is the part of a streaming pipeline you do not write.** A Kinesis data stream, in
lesson 20, keeps records and waits for a program to read them; a **delivery stream** reads what it
receives, gathers it into files and writes the files somewhere, most often S3, with no consumer
code at all. AWS renamed it from Kinesis Data Firehose to Amazon Data Firehose in 2024, and the
command line still calls it `aws firehose`. The wrong picture to drop first is that it writes one
object per record. It writes one object per **buffer**: records are held until enough bytes or
enough seconds have accumulated, and then they are written together.

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed in this one, with moto started empty. A delivery stream needs
a destination, and the destination is described in a file. Save this one in
`~/aws`:

`orders-to-s3.json`:

```json
{
  "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
  "BucketARN": "arn:aws:s3:::quitanda-raw-prod",
  "Prefix": "raw/orders/",
  "ErrorOutputPrefix": "errors/orders/",
  "BufferingHints": {"SizeInMBs": 64, "IntervalInSeconds": 300},
  "CompressionFormat": "UNCOMPRESSED"
}
```

**Four of those lines are the whole idea.** `BucketARN` and `Prefix` say where the objects go,
`BufferingHints` says when a buffer is written, and `ErrorOutputPrefix` says where records go that
could not be delivered as asked. `RoleARN` names the IAM role Firehose assumes to write into the
bucket; moto never checks that the role exists, and on AWS it has to exist and trust
`firehose.amazonaws.com`, the pattern of `aws-foundations` lesson 9.

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-to-s3 --delivery-stream-type DirectPut --extended-s3-destination-configuration file://orders-to-s3.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-to-s3"
}
ana@laptop:~/aws$ aws firehose describe-delivery-stream --delivery-stream-name orders-to-s3 --query 'DeliveryStreamDescription.[DeliveryStreamStatus,DeliveryStreamType,Destinations[0].ExtendedS3DestinationDescription.BufferingHints]'
[
    "ACTIVE",
    "DirectPut",
    {
        "SizeInMBs": 64,
        "IntervalInSeconds": 300
    }
]
```

## Three calls, three objects

`put-record` sends one record and `put-record-batch` sends up to 500 in one request. Two more files
of records, the second with a newline at the end of each one, saved beside the first:

`batch.json`:

```json
[
  {"Data": "{\"order_id\": \"o-201\", \"customer_id\": \"c-17\", \"total_cents\": 4590}"},
  {"Data": "{\"order_id\": \"o-202\", \"customer_id\": \"c-02\", \"total_cents\": 12800}"}
]
```

`batch-nl.json`:

```json
[
  {"Data": "{\"order_id\": \"o-203\", \"customer_id\": \"c-05\", \"total_cents\": 990}\n"},
  {"Data": "{\"order_id\": \"o-204\", \"customer_id\": \"c-03\", \"total_cents\": 2350}\n"}
]
```

```
ana@laptop:~/aws$ aws firehose put-record --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --record '{"Data": "{\"order_id\": \"o-200\", \"customer_id\": \"c-17\", \"total_cents\": 1500}\n"}'
{
    "RecordId": "c3977c46-4b6a-41ad-bc33-7699a7628e6c",
    "Encrypted": false
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --records file://batch.json --query FailedPutCount
0
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod --recursive
2026-10-16 13:10:44         66 raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-44-34791ed3-64ca-4c6f-ada0-553848f853bd
2026-10-16 13:10:45        131 raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-4d0ced18-b2a1-4b8f-b677-79d2ca19ce5c
2026-10-16 13:10:45        131 raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-87813042-af20-40bb-a2f0-bcc3e2856c47
ana@laptop:~/aws$ for k in $(aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/orders/ --query 'Contents[].Key' --output text); do echo "$k"; aws s3 cp s3://quitanda-raw-prod/$k - | cat -A; echo; done
raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-44-34791ed3-64ca-4c6f-ada0-553848f853bd
{"order_id": "o-200", "customer_id": "c-17", "total_cents": 1500}$

raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-4d0ced18-b2a1-4b8f-b677-79d2ca19ce5c
{"order_id": "o-201", "customer_id": "c-17", "total_cents": 4590}{"order_id": "o-202", "customer_id": "c-02", "total_cents": 12800}
raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-87813042-af20-40bb-a2f0-bcc3e2856c47
{"order_id": "o-203", "customer_id": "c-05", "total_cents": 990}$
{"order_id": "o-204", "customer_id": "c-03", "total_cents": 2350}$
```

**Every key starts with the prefix and then `2026/10/16/16/`, which is the hour in UTC**, not in São
Paulo: `ls` printed the time as 13:10 local and the key says 16. That dated part is what Firehose
adds by default after the prefix, and the object's name after it is the stream's name, a version
number, the time again to the second, and a random suffix, so that two objects never collide. The
next section but one changes that layout.

**moto wrote an object per call, the moment each call arrived.** AWS would not: with the hints in
`orders-to-s3.json`, all four records would have waited in one buffer for up to 300 seconds and
then been written as one object. So the number of objects above is moto's, and nothing about it
predicts the number on AWS; the next section is about that number.

**What the objects contain is faithful, and it is the thing people get wrong.** `cat -A` marks the
end of each line with `$`. The object written from `batch.json` is one line holding two JSON
documents glued together, `}{`, because **by default Firehose adds no delimiter between records**:
it concatenates the bytes it was given. Athena, Glue and DuckDB all read JSON as one document per line,
and they cannot read that object as two orders. The records of `batch-nl.json` end with `\n`, and
their object is two lines, which every one of those readers can read. A processor called
`AppendDelimiterToRecord` can make Firehose add the newline itself; without it, the newline is the
producer's job, and the first record of this section, the one sent with `put-record`, carried its own.
