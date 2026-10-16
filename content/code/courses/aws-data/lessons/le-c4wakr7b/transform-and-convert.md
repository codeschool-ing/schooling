---
title: Compression, Parquet, and a Lambda in the middle
version: 1
---

**Firehose can change records on the way to S3, in three ways of increasing ambition**: compress
each object, convert the records from JSON to Parquet, or hand every batch to a Lambda function that
rewrites it. All three are configured and none is run by moto, which stores the bytes it was given
exactly as it was given them. This section shows that, and then says what AWS does instead.

## Compression

`CompressionFormat` takes `GZIP`, `ZIP`, `Snappy` or `HADOOP_SNAPPY`, and compresses each object as a
whole. A copy of the first file with `GZIP`, and the first bytes of what moto wrote:

```
ana@laptop:~/aws$ jq '.CompressionFormat = "GZIP" | .Prefix = "raw/orders-gz/"' orders-to-s3.json > orders-gz.json
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-gz --extended-s3-destination-configuration file://orders-gz.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-gz"
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-gz --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ K=$(aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/orders-gz/ --query 'Contents[0].Key' --output text) && echo "$K" && aws s3 cp s3://quitanda-raw-prod/$K - | head -c 16 | od -c
raw/orders-gz/2026/10/16/16/orders-gz-1-2026-10-16-16-10-54-030752a7-a4e4-45cf-a9aa-cc5f43c9ada9
0000000   {   "   o   r   d   e   r   _   i   d   "   :       "   o   -
0000020
```

**A gzip file starts with the two bytes `037 213`, and this one starts with `{"order_id"`.** moto
stored plain JSON under a configuration that asked for gzip. On AWS the object would be compressed,
JSON lines typically shrink to a fraction of their size, and Athena and DuckDB read gzip as it is.
Nothing was run that shows the ratio, so no ratio is quoted here.

## Record format conversion

**Converting to Parquet is where Firehose saves the lake a job.** Lesson 19 made the case for
Parquet: a query reads only the columns it names, and the bill is the bytes scanned. Firehose can
write Parquet or ORC directly, if it is told the schema, and the schema comes from a table in the
Glue Data Catalog of lesson 16. Save this in `~/aws` too:

`orders-parquet.json`:

```json
{
  "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
  "BucketARN": "arn:aws:s3:::quitanda-curated-prod",
  "Prefix": "curated/orders/dt=!{timestamp:yyyy-MM-dd}/",
  "ErrorOutputPrefix": "errors/orders/!{firehose:error-output-type}/",
  "BufferingHints": {"SizeInMBs": 128, "IntervalInSeconds": 900},
  "CompressionFormat": "UNCOMPRESSED",
  "DataFormatConversionConfiguration": {
    "Enabled": true,
    "InputFormatConfiguration": {"Deserializer": {"OpenXJsonSerDe": {}}},
    "OutputFormatConfiguration": {"Serializer": {"ParquetSerDe": {"Compression": "SNAPPY"}}},
    "SchemaConfiguration": {
      "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
      "DatabaseName": "quitanda", "TableName": "orders", "Region": "sa-east-1"
    }
  }
}
```

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name orders

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetTable operation: Database quitanda not found.
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-parquet --extended-s3-destination-configuration file://orders-parquet.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-parquet"
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-parquet --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ for k in $(aws s3api list-objects-v2 --bucket quitanda-curated-prod --prefix curated/ --query 'Contents[].Key' --output text); do echo "$k"; aws s3 cp s3://quitanda-curated-prod/$k - | cat -A; echo; done
curated/orders/dt=!{timestamp:yyyy-MM-dd}/2026/10/16/16/orders-parquet-1-2026-10-16-16-10-57-eb178df6-4e22-454d-94d6-1e0378cd1df6
{"order_id": "o-203", "customer_id": "c-05", "total_cents": 990}$
{"order_id": "o-204", "customer_id": "c-03", "total_cents": 2350}$
```

**Three things went unchecked, one after the other.** The Glue database `quitanda` does not exist,
and `get-table` said so; moto created the delivery stream anyway, without looking for it. Then it
accepted the records, and wrote them as the JSON lines they were, under a key with the expression in
it as text.

What AWS does instead was not run and comes from its documentation. The stream reads the columns
and their types from the Glue table, parses each record with the JSON deserializer named in
`InputFormatConfiguration`, and writes Parquet files, compressed inside by `SNAPPY`; that is why the
whole object's `CompressionFormat` stays `UNCOMPRESSED`. The input has to be JSON. A record that does
not match the schema goes to the error prefix under `format-conversion-failed`, and a stream whose
table is missing fails every record that way. The buffer is larger on purpose, 128 MB and 900
seconds, because a Parquet file earns its column statistics by being big; AWS sets 64 MB as the
minimum size when conversion is on.

## A Lambda in the middle

**When a record needs more than a format change, Firehose can call a Lambda function on every
batch.** That is how a delivery stream drops test orders, masks a customer's address, or turns a
log line into JSON before conversion. The function receives a list of records, each with a
`recordId` and its `data` in base64, and must return the same list with every `recordId` back,
each carrying a `result`, which is `Ok`, `Dropped` or `ProcessingFailed`, and the new `data`. A
record returned as `ProcessingFailed`, or one the function failed to return at all, goes to the error
prefix under `processing-failed`.

This course does not run a transformation. moto's Lambda needs a container engine to execute
functions, and the delivery stream in moto does not call one; the contract above is AWS's, from its
documentation. **The transformation is also where duplicates enter quietly**: Firehose retries a
batch whose call failed or timed out, so a function with a side effect, such as writing to a
database, can perform it twice for one record. Lesson 23 is about exactly that.
