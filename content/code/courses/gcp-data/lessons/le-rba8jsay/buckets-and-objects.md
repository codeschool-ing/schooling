---
title: Buckets, objects and the folders that are not there
version: 1
---

**A bucket is a container with a name, and an object is a name and the bytes stored under it.**
That is the whole data model of Cloud Storage. There are no directories inside a bucket, no files
in the operating system's sense, and no way to change part of an object: you write it whole, read it
whole or in a range, and delete it. The slashes people put in object names look like a filesystem,
and the console draws folders out of them, and both are a convenience laid over a flat list of
names.

The running example of this course is Quitanda, a grocery delivery company in São Paulo, and its
first bucket holds the files its shop exports every night. Make three small ones, one per day:

```sh
mkdir -p export
for d in 01 02 03; do
  printf 'order_id,customer_id,total_cents\n%s-1,c-17,4590\n%s-2,c-03,12800\n' "$d" "$d" \
    > export/orders-2026-10-$d.csv
done
```

Then create a bucket and put them in it, each under a name that starts with `raw/orders/`:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-10-01.csv gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
Copying file://export/orders-2026-10-01.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-10-0[23].csv gs://quitanda-raw-prod/raw/orders/
Copying file://export/orders-2026-10-02.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-02.csv
Copying file://export/orders-2026-10-03.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-03.csv
  


Average throughput: 88.1kiB/s
```

`gcloud storage buckets create` made the bucket, and `--location` is where its data lives: São
Paulo, a single region. Each `cp` was one upload request per file, and the object's name is the
whole string after the bucket's name, slashes included. The empty lines are what is left of a
progress meter that redraws itself in place; a terminal shows them the same way.

## Listing is asking for a prefix

```
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-raw-prod
gs://quitanda-raw-prod/raw/
ana@laptop:~/gcp$ gcloud storage ls --recursive gs://quitanda-raw-prod
gs://quitanda-raw-prod/:

gs://quitanda-raw-prod/raw/:

gs://quitanda-raw-prod/raw/orders/:
gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
gs://quitanda-raw-prod/raw/orders/orders-2026-10-02.csv
gs://quitanda-raw-prod/raw/orders/orders-2026-10-03.csv
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-raw-prod/o?prefix=raw/&delimiter=/' | python3 -m json.tool
{
    "kind": "storage#objects",
    "prefixes": [
        "raw/orders/"
    ]
}
```

**The first listing shows a `raw/` that nobody created.** `gcloud storage ls` asked for the names in
the bucket grouped at the first slash, and the answer was one group, because every name starts with
those four characters. `--recursive` asks for the objects themselves, and there they are: three of
them, each with its full name, under headings the command line prints to make the list readable.
The third command asks the JSON API directly, with `curl`, the way every client does underneath: a
`prefix` to filter by and a `delimiter` to group at, and the answer is a list of `prefixes`. **A
folder is the answer to a question, and it exists only while some object's name starts with it.**

That has a consequence people trip over. Asking for the "folder" as an object fails, because there
is no such object:

```
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/
ERROR: (gcloud.storage.objects.describe) gs://quitanda-raw-prod/raw%2Forders%2F not found: 404.
```

The `%2F` in the error is the slash, escaped, because to the API the whole name is one string. The
console's "Create folder" button gets round the missing folder by writing an empty object whose name
ends in a slash, `raw/orders/` with zero bytes. That object is real, it is listed, and it is the
reason an "empty folder" can be seen in the console and not in a program that lists only objects
with content.

**Cloud Storage also has buckets where folders are real**, with *hierarchical namespace* turned on
when the bucket is created. There a folder is a resource of its own, and renaming one is a single
operation rather than a copy of every object under it. The price list charges those buckets' Class
A operations about 30% more, and lesson 5 shows what an operation costs. Everything in this course
uses the ordinary flat namespace, which is the default and the only one fake-gcs-server imitates.

## An object is replaced, never edited

```
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv --format='value(size,md5_hash,generation)'
64	R0DILdLg74YE8u85q+7WgQ==	1793383629365701
ana@laptop:~/gcp$ printf '01-3,c-22,990\n' >> export/orders-2026-10-01.csv && gcloud storage cp export/orders-2026-10-01.csv gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
Copying file://export/orders-2026-10-01.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
  

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv --format='value(size,md5_hash,generation)'
78	Lz4TVx6/63wQznBxKPlXhg==	1793383635165064
ana@laptop:~/gcp$ gcloud storage hash export/orders-2026-10-01.csv --skip-crc32c
---
digest_format: base64
md5_hash: Lz4TVx6/63wQznBxKPlXhg==
url: export/orders-2026-10-01.csv
```

**The size changed, the MD5 changed and so did the generation, because the second `cp` wrote a new
object under the same name**; nothing was edited in place. The **generation** is the number Cloud
Storage gives every version of an object's bytes, and a new upload always gets a new one, so it is
the cheapest way to ask "is this still the file I read?". The MD5 is of the bytes, written in base64
rather than in hexadecimal, which is why `gcloud storage hash` on the local file prints the same 24
characters. The metadata came back from `objects describe`, which reads everything about an object
except its body, and costs one request rather than a download.

**Overwriting is silent and final**, unless the bucket keeps versions. On the bucket above, the first
version of `orders-2026-10-01.csv` is gone, and there is no undo. Lesson 3 turns on versioning, which
makes an overwrite keep the old bytes as a noncurrent version, and shows what that costs. A program
that must not overwrite somebody else's write sends the generation it read with its upload, as a
precondition, and the upload fails if the object has moved on: the same idea as a version column in
a database table.
