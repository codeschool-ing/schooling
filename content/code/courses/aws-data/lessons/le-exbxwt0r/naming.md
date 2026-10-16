---
title: A naming scheme that survives
version: 1
---

**A bucket's name is global and a key's name is forever**, and those two facts are what a naming
scheme is for. A bucket name is shared by every account in AWS's commercial partition, so
`quitanda-raw-prod` belongs to whoever created it first, anywhere in the world. And a key is the only
handle a program has on an object: rename one and every program, report and table that pointed at
the old key now points at nothing, because S3 has no rename. Moving an object is a copy and a delete.

## The rules for a bucket's name

AWS's rules for a general-purpose bucket are short. Three to 63 characters. Lowercase letters,
digits, hyphens and dots, starting and ending with a letter or a digit. Not shaped like an IP
address, not starting with `xn--` or `sthree-`, and not ending in `-s3alias` or `--ol-s3`. And **no
dots, in practice**: a dot is allowed, and it breaks the TLS certificate of the address
`bucket.s3.sa-east-1.amazonaws.com`, whose wildcard covers one label and not two.

moto checks less of that than AWS does, which is the previous section's point made with a name:

```
ana@laptop:~/aws$ aws s3 mb s3://qr
make_bucket failed: s3://qr An error occurred (InvalidBucketName) when calling the CreateBucket operation: The specified bucket is not valid.
ana@laptop:~/aws$ aws s3 mb s3://Quitanda_Raw
make_bucket: Quitanda_Raw
ana@laptop:~/aws$ aws s3 mb s3://192.168.5.4
make_bucket: 192.168.5.4
ana@laptop:~/aws$ aws s3 mb s3://quitanda.raw.prod
make_bucket: quitanda.raw.prod
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket failed: s3://quitanda-raw-prod An error occurred (BucketAlreadyOwnedByYou) when calling the CreateBucket operation: Your previous request to create the named bucket succeeded and you already own it.
```

**moto refused the two-letter name and accepted the next three.** AWS refuses `Quitanda_Raw`, with
its capital letter and its underscore, and refuses `192.168.5.4`. The dotted name would be accepted
there too, and would then fail the first time a program reached it over HTTPS with the usual
address. So the rules are checked here by you, not by the server. And the second `mb` of the same
name met `BucketAlreadyOwnedByYou`, which is the gentle version of a collision. Against the real S3,
a name someone else already has fails with `BucketAlreadyExists`, and that answer was not produced
here: moto imitates one account, so there is nobody else to own a name.

## A scheme for bucket names

A scheme is worth having before the second bucket exists. The one this course uses puts the most
stable word first and the most variable last:

```
quitanda-raw-prod
quitanda-curated-prod
quitanda-logs-prod
quitanda-raw-dev
```

**Company, layer, environment.** The company makes the name unlikely to be taken. The layer says what
kind of data lives there, which is also what decides its storage class, its life cycle and who may
read it, the subjects of lessons 2 to 4. The environment keeps development data out of production
buckets, where a test that deletes everything is a test that deletes everything.

Two things do not go in a bucket name. **A person's or a team's name**, because people move and the
bucket stays. **Anything secret or personal**, because a bucket's name travels in DNS lookups, in
logs and in error messages that strangers can see. Some teams add the account number and the region,
`quitanda-raw-prod-123456789012-sa-east-1`, and that settles the collision problem for good at the
price of 40 characters of the 63.

## A scheme for keys

Inside a bucket the keys are where data lakes succeed or fail, and the rule is to **lay keys out
by the question that will be asked most**. For data that arrives every day and is read by date, that
means the date goes into the path, written so that alphabetical order is time order:

```
raw/orders/dt=2026-10-01/orders.csv
raw/orders/dt=2026-10-02/orders.csv
raw/payments/dt=2026-10-01/payments.csv
```

**`dt=2026-10-01` and not `01-10-2026`.** S3 returns keys in UTF-8 byte order, so a year-month-day
date lists in time order and a day-month-year one lists every first of the month together. The
`name=value` form is the convention Athena, Glue and Spark read as a partition, which lesson 15 uses
to read one day instead of all of them. A source name before the date, `orders` and `payments`, keeps
one feed's files out of another's listing.

**Write keys as if they could never be renamed**, because in practice they cannot. Lowercase, no
spaces, no accents, no characters a URL has to escape. A key may legally hold almost anything, and
`relatório final (2).csv` is a valid one; it is also a key that every tool quotes differently.
