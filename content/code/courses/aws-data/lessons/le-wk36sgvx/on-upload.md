---
title: Choosing the class when the object is written
version: 1
---

**The class is a property of each object, set when the object is written**, and the request that
writes it is the same `PutObject` as always, with one more header. There is no "Glacier bucket" and
no separate service to send archives to. The command line exposes the header as `--storage-class`.

Quitanda closes each month by exporting its orders, and September's file is the first thing that
goes to the archive bucket. Make one, 500 orders long:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n' > export/orders-2026-09.csv
for i in $(seq 1 500); do
  printf 'ord-09-%d,c-%d,%d\n' "$i" $((i % 40)) $((990 + i * 7)) >> export/orders-2026-09.csv
done
```

Then put four copies of it in four classes, which is not what anybody would do with one file and is
the quickest way to see what changes and what does not:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-archive-prod
make_bucket: quitanda-archive-prod
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/standard.csv
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/standard.csv
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/ia.csv --storage-class STANDARD_IA
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/ia.csv
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/instant.csv --storage-class GLACIER_IR
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/instant.csv
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/deep.csv --storage-class DEEP_ARCHIVE
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/deep.csv
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-archive-prod --query "Contents[].[Key,StorageClass,Size]" --output text
orders/2026-09/deep.csv	DEEP_ARCHIVE	10295
orders/2026-09/ia.csv	STANDARD_IA	10295
orders/2026-09/instant.csv	GLACIER_IR	10295
orders/2026-09/standard.csv	STANDARD	10295
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/ia.csv
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-10-16T15:54:11+00:00",
    "ContentLength": 10295,
    "ETag": "\"bdb98a48e0b7c1ba562cd7d624f65c55\"",
    "ContentType": "text/csv",
    "Metadata": {},
    "StorageClass": "STANDARD_IA"
}
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-10-16T15:54:10+00:00",
    "ContentLength": 10295,
    "ETag": "\"bdb98a48e0b7c1ba562cd7d624f65c55\"",
    "ContentType": "text/csv",
    "Metadata": {}
}
```

**Every copy has the same size and lands the same way**; the only difference is the word in
`StorageClass`. Notice what `head-object` does with it. For the Standard-IA copy it prints
`"StorageClass": "STANDARD_IA"`, and for the copy written with no class it prints no `StorageClass`
field at all. **An absent class means Standard**, in moto and in S3 alike, and a program that reads
the field has to treat its absence as `STANDARD` instead of as an error. `list-objects-v2` is the
exception, and fills it in for every key.

The file is 10,295 bytes, about 10 KB. On AWS, the Standard-IA and Glacier Instant Retrieval copies
would each be billed as 128 KB, and the Deep Archive copy as its own bytes plus the 40 KB the
previous section described. moto bills nothing, so the listing says nothing about any of that.

## The names the command line knows

The class names are a closed list, and the command line checks it before anything is sent:

```
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/x.csv --storage-class INFREQUENT_ACCESS 2>&1 | head -2

aws: [ERROR]: An error occurred (ParamValidation): argument --storage-class: Found invalid choice 'INFREQUENT_ACCESS'
```

`ParamValidation` is the command line's own refusal: no request reached moto. The valid names are
`STANDARD`, `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`,
`DEEP_ARCHIVE` and the old `REDUCED_REDUNDANCY`, among a few for other kinds of bucket. **`GLACIER` is
Glacier Flexible Retrieval**: the class kept its name when the product was renamed, which is the
reason the API and the price list disagree about what to call it.

## Changing an object's class

An object's class changes only when the object is written again. Copying it onto itself with a new
class does that:

```
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --query "[StorageClass,LastModified,ETag]"
[
    null,
    "2026-10-16T15:54:10+00:00",
    "\"bdb98a48e0b7c1ba562cd7d624f65c55\""
]
ana@laptop:~/aws$ aws s3 cp s3://quitanda-archive-prod/orders/2026-09/standard.csv s3://quitanda-archive-prod/orders/2026-09/standard.csv --storage-class GLACIER_IR
copy: s3://quitanda-archive-prod/orders/2026-09/standard.csv to s3://quitanda-archive-prod/orders/2026-09/standard.csv
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --query "[StorageClass,LastModified,ETag]"
[
    "GLACIER_IR",
    "2026-10-16T15:54:23+00:00",
    "\"bdb98a48e0b7c1ba562cd7d624f65c55\""
]
```

**The ETag stayed and the `LastModified` moved**, because the copy wrote a new object with the same
bytes over the old one. On AWS that is one `COPY` request, priced like a `PUT`, and it ends the old
object's life early: a copy out of Standard-IA in its first 30 days pays the rest of the 30. Doing
this by hand for a few files is fine. For a whole prefix, every month, it is what a life-cycle rule
is for, and lesson 3 writes one.
