---
title: Prefixes, dates and dynamic partitioning
version: 1
---

**The default layout, `2026/10/16/16/`, is a date that no query engine recognises as one.** This
course's lake keys are Hive-style, `dt=2026-10-16/`, because that is the form Athena (lesson 15) and
the Glue Data Catalog read as a partition, so that a query for one day reads one day. A delivery stream can write that layout itself. Its `Prefix` may contain **expressions** that Firehose fills in for each object. The two that matter are `!{timestamp:…}`, a date pattern evaluated at the record's arrival time in UTC, and
`!{partitionKeyFromQuery:…}`, a value taken out of the record itself.

## A dated prefix

The configuration of the first section with a Hive-style date in its prefix, and an error prefix
that sorts failures by their kind:

```
ana@laptop:~/aws$ jq '.Prefix = "raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/" | .ErrorOutputPrefix = "errors/orders-dt/!{firehose:error-output-type}/"' orders-to-s3.json > orders-dt.json
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-dt --extended-s3-destination-configuration file://orders-dt.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-dt"
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-dt --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-dt/ --recursive
2026-10-16 13:10:50        131 raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/2026/10/16/16/orders-dt-1-2026-10-16-16-10-50-423b2c94-da7d-4041-8d81-df2aba15ae71
```

**moto wrote the expression into the key as text, and then added its own dated part after it.**
`dt=!{timestamp:yyyy-MM-dd}/` is a folder name in moto's bucket, which is what the lab can show and
nothing more: moto evaluates no expression. On AWS the expression is evaluated. The documented rule for the default part is the one moto broke: **when the prefix uses `!{timestamp:…}`, Firehose
adds nothing after it; when it uses none, Firehose adds the `YYYY/MM/dd/HH/` part itself.** So on AWS
this object would sit directly under `raw/orders-dt/dt=2026-10-16/`, with the same kind of name as
before. That key was not produced here, because moto cannot produce it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Three S3 keys for the same object, cut into their parts. With the default prefix, raw/orders/ is followed by the UTC hour 2026/10/16/16/ that Firehose adds, then the object name. With a timestamp expression on AWS, the prefix becomes raw/orders-dt/dt=2026-10-16/ and nothing is added before the object name. In moto, the expression stays as text, dt=!{timestamp:yyyy-MM-dd}/, and moto adds the UTC hour after it anyway.\" data-fig=\"l21-keys\"><text x=\"20.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">default prefix</text><rect x=\"150.0\" y=\"30.0\" width=\"76.9\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"188.4\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">raw/orders/</text><rect x=\"230.9\" y=\"30.0\" width=\"94.6\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"278.2\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2026/10/16/16/</text><rect x=\"329.5\" y=\"30.0\" width=\"177.2\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418.1\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders-to-s3-1-&lt;time&gt;-&lt;uuid&gt;</text><text x=\"20.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">expression, on AWS</text><rect x=\"150.0\" y=\"90.0\" width=\"177.2\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238.6\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">raw/orders-dt/dt=2026-10-16/</text><rect x=\"331.2\" y=\"90.0\" width=\"159.5\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"411.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders-dt-1-&lt;time&gt;-&lt;uuid&gt;</text><text x=\"20.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">expression, in moto</text><rect x=\"150.0\" y=\"150.0\" width=\"253.9\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.9\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/</text><rect x=\"407.9\" y=\"150.0\" width=\"94.6\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455.2\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2026/10/16/16/</text><rect x=\"506.5\" y=\"150.0\" width=\"159.5\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586.2\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders-dt-1-&lt;time&gt;-&lt;uuid&gt;</text><rect x=\"150.0\" y=\"192.0\" width=\"12.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"168.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">your Prefix</text><rect x=\"340.0\" y=\"192.0\" width=\"12.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the UTC hour Firehose adds</text><rect x=\"530.0\" y=\"192.0\" width=\"12.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the object name</text></svg>", "caption": "The same object's key three ways: the default layout, an expression evaluated on AWS, and the same expression kept as text by moto."}
```

**A prefix with an expression needs an `ErrorOutputPrefix` as well**, AWS's documentation says.
That is where Firehose writes records it could not deliver as configured, and
`!{firehose:error-output-type}` names the reason in the key, such as `processing-failed` or
`format-conversion-failed`, so that a failure is a folder somebody can look at instead of a silence.

## Dynamic partitioning

**A date comes from the clock; a store comes from the record.** Dynamic partitioning reads a field
out of each JSON record with a `jq` query and uses its value in the prefix, so that Quitanda's
orders land under one folder per store without a program in the middle. It is switched on in the
destination, and the query is a processor of type `MetadataExtraction`. Save this beside the others:

`orders-by-store.json`:

```json
{
  "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
  "BucketARN": "arn:aws:s3:::quitanda-raw-prod",
  "Prefix": "raw/orders-by-store/store=!{partitionKeyFromQuery:store}/dt=!{timestamp:yyyy-MM-dd}/",
  "ErrorOutputPrefix": "errors/orders-by-store/!{firehose:error-output-type}/",
  "BufferingHints": {"SizeInMBs": 64, "IntervalInSeconds": 300},
  "DynamicPartitioningConfiguration": {"Enabled": true},
  "ProcessingConfiguration": {
    "Enabled": true,
    "Processors": [{
      "Type": "MetadataExtraction",
      "Parameters": [
        {"ParameterName": "MetadataExtractionQuery", "ParameterValue": "{store: .store}"},
        {"ParameterName": "JsonParsingEngine", "ParameterValue": "JQ-1.6"}
      ]
    }]
  }
}
```

```
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-by-store --extended-s3-destination-configuration file://orders-by-store.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-by-store"
}
ana@laptop:~/aws$ aws firehose put-record --delivery-stream-name orders-by-store --cli-binary-format raw-in-base64-out --record '{"Data": "{\"order_id\": \"o-205\", \"store\": \"pinheiros\"}\n"}'
{
    "RecordId": "efb638c8-7fb5-4c2b-a766-aa1478249a9a",
    "Encrypted": false
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-by-store/ --recursive
2026-10-16 13:10:52         44 raw/orders-by-store/store=!{partitionKeyFromQuery:store}/dt=!{timestamp:yyyy-MM-dd}/2026/10/16/16/orders-by-store-1-2026-10-16-16-10-52-93acbbcb-daa8-427e-afa2-adf5570573f7
```

**Again the key carries the expressions as text**: moto ran no `jq` and read no field, and the
`pinheiros` in the record appears nowhere in the key. On AWS this record would land under
`raw/orders-by-store/store=pinheiros/dt=2026-10-16/`. The `{store: .store}` query names the key
`store`, which is the name the prefix asks for, and a record with no `store` field, or with
something that is not JSON, would go to the error prefix instead.

**Dynamic partitioning is billed by the gigabyte on top of ingestion**, at the price in the last
section, and it multiplies buffers, as the section before this one said: one per distinct
combination of keys. A partition key is a column a query will filter on and that has tens of values,
not one that has thousands. Partitioned by customer, Quitanda's stream would hold one buffer per
customer and write each one half empty every interval, and the lake would gain tens of thousands of
tiny objects a day.
