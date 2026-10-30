---
title: Choosing the class when the object is written
version: 1
---

**The class is a property of each object, set when the object is written**, and the request that
writes it is the same upload as always, with one more field. There is no archive service to send
files to and no separate kind of bucket. `gcloud storage cp` exposes the field as `--storage-class`.
When the request names no class, the object takes the bucket's default class, and a bucket created
with no default has `STANDARD`.

Quitanda closes each month by exporting its orders, and September's file is the first thing that
goes to the archive bucket. Make one, 500 orders long:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n' > export/orders-2026-09.csv
for i in $(seq 1 500); do
  printf 'ord-09-%d,c-%d,%d\n' "$i" $((i % 40)) $((990 + i * 7)) >> export/orders-2026-09.csv
done
```

Then put four copies of it in four classes, which nobody would do with one file and is the quickest
way to see what changes and what does not:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-archive-prod --location=southamerica-east1
Creating gs://quitanda-archive-prod/...
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/standard.csv
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/standard.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/nearline.csv --storage-class=NEARLINE
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/nearline.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/coldline.csv --storage-class=COLDLINE
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/coldline.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/archive.csv --storage-class=ARCHIVE
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/archive.csv
  

ana@laptop:~/gcp$ gcloud storage objects list 'gs://quitanda-archive-prod/orders/2026-09/*' --format='table(name,storage_class,size)'
NAME                         STORAGE_CLASS  SIZE
orders/2026-09/archive.csv   ARCHIVE        10295
orders/2026-09/coldline.csv  COLDLINE       10295
orders/2026-09/nearline.csv  NEARLINE       10295
orders/2026-09/standard.csv  STANDARD       10295
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/nearline.csv --format='yaml(storage_class,storage_class_update_time,size,generation)'
generation: '1793385009764338'
size: 10295
storage_class: NEARLINE
storage_class_update_time: 2026-10-30T15:30:09-0300
```

**Every copy has the same size and was written the same way**; the only difference is the word in
`STORAGE_CLASS`. The upload with no `--storage-class` came out `STANDARD`, the bucket's default.
`storage_class_update_time` records when the class was last set, which for a new object is the moment
it was written. The file is 10,295 bytes, and Cloud Storage would bill each copy as 10,295 bytes: there
is no minimum object size to round it up to.

## The names the command line knows, and the ones it does not check

The four names are `STANDARD`, `NEARLINE`, `COLDLINE` and `ARCHIVE`. The command line turns a
lower-case name into the upper-case one before it sends anything. What it does not do is check the
name against the list:

```
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/lower.csv --storage-class=nearline
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/lower.csv
  
.
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/glacier.csv --storage-class=GLACIER
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/glacier.csv
  

ana@laptop:~/gcp$ gcloud storage objects list gs://quitanda-archive-prod/orders/2026-09/lower.csv gs://quitanda-archive-prod/orders/2026-09/glacier.csv --format='table(name,storage_class)'
NAME                        STORAGE_CLASS
orders/2026-09/lower.csv    NEARLINE
orders/2026-09/glacier.csv  GLACIER
```

**`GLACIER` is not a Cloud Storage class**, and the emulator stored it anyway. Cloud Storage refuses
an upload naming a class it does not have, with an error and no object; fake-gcs-server keeps whatever
string it is given. A script whose class is misspelt, or carried over from another cloud's
vocabulary, passes every test against this emulator and fails on its first run against Google. Keep
the four names in one constant of the program and test that constant, not the emulator's answer.

## The bucket's default class

A bucket's default class is set when the bucket is created, with `--default-storage-class`, and
changed later with `gcloud storage buckets update`. Changing it affects the objects written after
the change and none of those already there. Quitanda's development bucket holds data nobody reads
twice, so Nearline would be its default:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-dev --location=southamerica-east1 --default-storage-class=NEARLINE
Creating gs://quitanda-raw-dev/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-raw-dev --format='value(default_storage_class)'
STANDARD
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-raw-dev/orders/2026-09/orders.csv
Copying file://export/orders-2026-09.csv to gs://quitanda-raw-dev/orders/2026-09/orders.csv
  

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-dev/orders/2026-09/orders.csv --format='value(storage_class)'
STANDARD
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-raw-dev --default-storage-class=COLDLINE
  
Updating gs://quitanda-raw-dev/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-raw-dev --format='value(default_storage_class)'
STANDARD
```

**The emulator ignores the default class**, on creation and on update: the bucket reports `STANDARD`
both times, and so does the object written into it with no class of its own. On Cloud Storage the
first `describe` would print `NEARLINE`, the object would be `NEARLINE`, and after the update the
bucket would report `COLDLINE` while that object stayed `NEARLINE`. In this lab, set the class on
every upload that needs one, which is the habit worth having anyway: an upload that names its class
does not depend on a setting somebody may change.

**The default class also prices the bucket's own requests.** The pricing page says that an operation
on a bucket, such as listing its objects, is charged at the rate of the bucket's default class, and
an operation on an object at the rate of the object's class. A bucket whose default is Archive pays
0.05 USD for every thousand listings, against 0.005 for a bucket whose default is Standard, whatever
the objects inside are. A job that lists a prefix every minute to see whether a file has arrived makes
43,200 listings in a 30-day month: 43,200 / 1,000 × 0.005 = 0.22 USD in a Standard bucket, and
× 0.05 = 2.16 in an Archive one, ten times as much for the same question. Quitanda keeps its archive bucket's default at Standard and names the class on every upload,
which is cheaper to ask questions of and does not move a file to Archive by accident.

## Changing an object's class

An object's class changes only when the object is written again, and `gcloud storage objects update
--storage-class` is the command that does it. Its help says so in one line: using the flag "triggers
a rewrite of underlying object data".

```
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/standard.csv --format='value(storage_class,generation,creation_time)'
STANDARD	1793385008602532	2026-10-30T15:30:08-0300
ana@laptop:~/gcp$ gcloud storage objects update gs://quitanda-archive-prod/orders/2026-09/standard.csv --storage-class=COLDLINE
  
Rewriting gs://quitanda-archive-prod/orders/2026-09/standard.csv...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/standard.csv --format='value(storage_class,generation,creation_time)'
STANDARD	1793385028551218	2026-10-30T15:30:28-0300
ana@laptop:~/gcp$ gcloud storage objects update gs://quitanda-archive-prod/orders/2026-09/nearline.csv --storage-class=ARCHIVE
  
Rewriting gs://quitanda-archive-prod/orders/2026-09/nearline.csv...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/nearline.csv --format='value(storage_class,generation)'
STANDARD	1793385030548817
```

**The rewrite happened, and the class did not change.** `Rewriting` is printed, and the object came
back with a new generation number and a new creation time, both signs of a new object written over
the old one. Its class came back `STANDARD`, after a rewrite to `COLDLINE` and after another to
`ARCHIVE`. fake-gcs-server 1.54.0 writes every rewritten object as Standard, whatever the request
asked for. On Cloud Storage the two `describe` lines would say `COLDLINE` and `ARCHIVE`.

What the emulator does show correctly is the part that costs money. **A rewrite is a new object**,
so on Cloud Storage it is one Class A operation, billed at the rate of the class it goes to, and the
old object ends its life on that day. The Nearline copy above was rewritten seconds after it was
written: on Cloud Storage that copy would be billed its 30 days of Nearline at once, as an early
deletion. Doing this by hand for a few files is fine. For a whole prefix, every month, a life-cycle
rule is the tool: it changes the class without a rewrite and without the early-deletion charge, and
lesson 3 writes one.
