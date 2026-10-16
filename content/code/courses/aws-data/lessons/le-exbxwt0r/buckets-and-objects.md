---
title: Buckets, objects and the folders that are not there
version: 1
---

**A bucket is a container with a name, and an object is a key and the bytes stored under it.** That
is the whole data model of S3. There are no directories inside a bucket, no files in the operating
system's sense, and no way to change part of an object: you write it whole, read it whole or in a
range, and delete it. The slashes people put in keys look like a filesystem, and the console draws
folders out of them, and both are a convenience laid over a flat list of names.

The running example of this course is Quitanda, a grocery delivery company in São Paulo, and its
first bucket holds the files its shop exports every night. Make three small ones, one per day:

```sh
mkdir -p export
for d in 01 02 03; do
  printf 'order_id,customer_id,total_cents\n%s-1,c-17,4590\n%s-2,c-03,12800\n' "$d" "$d" \
    > export/orders-2026-10-$d.csv
done
```

Then create a bucket and put them in it, each under a key that starts with `raw/orders/`:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws s3 cp export/orders-2026-10-01.csv s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
upload: export/orders-2026-10-01.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
ana@laptop:~/aws$ aws s3 cp export/ s3://quitanda-raw-prod/raw/orders/ --recursive --exclude "*" --include "*-0[23].csv"
upload: export/orders-2026-10-03.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-03.csv
upload: export/orders-2026-10-02.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-02.csv
```

`aws s3 mb` is "make bucket", and it created the bucket in the region the terminal points at,
São Paulo. Each `cp` was one `PutObject` request, and the key is the whole string after the bucket's
name, slashes included.

## Listing is asking for a prefix

```
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod
                           PRE raw/
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod --recursive
2026-10-16 12:31:13         64 raw/orders/orders-2026-10-01.csv
2026-10-16 12:31:14         64 raw/orders/orders-2026-10-02.csv
2026-10-16 12:31:14         64 raw/orders/orders-2026-10-03.csv
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/ --delimiter / --query CommonPrefixes
[
    {
        "Prefix": "raw/orders/"
    }
]
```

**The first listing shows a `PRE raw/` that nobody created.** `aws s3 ls` asked S3 for the keys of
the bucket grouped at the first slash, and S3 answered with one group, `raw/`, because every key
starts with those four characters. `--recursive` asks for the keys themselves, and there they are:
three objects, each with its full name. The `s3api` call underneath shows what the grouping is: a
`Prefix` to filter by and a `Delimiter` to group at, and the answer is a list of `CommonPrefixes`.
**A folder is the answer to a question, and it exists only while some key starts with it.**

That has a consequence people trip over. Asking for the "folder" as an object fails, because there
is no such object:

```
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/

aws: [ERROR]: An error occurred (404) when calling the HeadObject operation: Not Found
```

The console's "Create folder" button gets round it by writing an empty object whose key ends in a
slash, `raw/orders/` with zero bytes. That object is real, it is listed, and it is the reason an
"empty folder" can be seen in the console and not in a program that lists only objects with content.

## An object is replaced, never edited

```
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/orders-2026-10-01.csv --query "[ContentLength,ETag]" --output text
64	"4740c82dd2e0ef8604f2ef39abeed681"
ana@laptop:~/aws$ printf "ord-01-3,c-22,990\n" >> export/orders-2026-10-01.csv && aws s3 cp export/orders-2026-10-01.csv s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
upload: export/orders-2026-10-01.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/orders-2026-10-01.csv --query "[ContentLength,ETag]" --output text
82	"3c43e2ba2e34e273de8eb7f5abb2bd32"
ana@laptop:~/aws$ md5sum export/orders-2026-10-01.csv
3c43e2ba2e34e273de8eb7f5abb2bd32  export/orders-2026-10-01.csv
```

**The ETag changed and so did the size, because the second `cp` wrote a new object under the same
key**; nothing was edited in place. The ETag of an object uploaded in one request is the MD5 of its
bytes, which is why the third command, `md5sum`, prints the same 32 characters. The metadata came
back from `head-object`, which reads everything about an object except its body, and costs one
request rather than a download.

**Overwriting is silent and final**, unless the bucket keeps versions. On the bucket above, the first
version of `orders-2026-10-01.csv` is gone, and there is no undo. Lesson 3 turns on versioning, which
makes an overwrite keep the old bytes as a previous version, and shows what that costs.
