---
title: A naming scheme that survives
version: 1
---

**A bucket's name is global and an object's name is forever**, and those two facts are what a naming
scheme is for. A bucket name is shared by every project in Cloud Storage, so `quitanda-raw-prod`
belongs to whoever created it first, anywhere in the world. And a name is the only handle a program
has on an object: rename one and every program, report and table that pointed at the old name now
points at nothing, because in a flat-namespace bucket a rename is a copy and a delete.

## The rules for a bucket's name

Google's rules for a bucket's name are short. Three to 63 characters, or up to 222 when the name
contains dots. Lowercase letters, digits, hyphens, underscores and dots, starting and ending with a
letter or a digit. Not shaped like an IP address, not starting with `goog`, and not containing
`google` or a close misspelling of it. And **no dots, in practice**: a dotted name is reserved for
somebody who can prove they own the domain it spells, through Search Console, and it breaks the TLS
certificate of the address `bucket.storage.googleapis.com`, whose wildcard covers one label and not
two.

fake-gcs-server checks less of that than Cloud Storage does, which is the previous section's point
made with a name:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://qr
Creating gs://qr/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://Quitanda_Raw
Creating gs://Quitanda_Raw/...
ERROR: (gcloud.storage.buckets.create) HTTPError 400: invalid bucket name
ana@laptop:~/gcp$ gcloud storage buckets create gs://192.168.5.4
Creating gs://192.168.5.4/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda.raw.prod
Creating gs://quitanda.raw.prod/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://goog-quitanda
Creating gs://goog-quitanda/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod
Creating gs://quitanda-raw-prod/...
ERROR: (gcloud.storage.buckets.create) HTTPError 409: A Cloud Storage bucket named 'quitanda-raw-prod' already exists. Try another name. Bucket names must be globally unique across all Google Cloud projects, including those outside of your organization.
```

**The emulator refused one name of the five that Cloud Storage would refuse or hold back**, and it
refused it for the capital letter. Cloud Storage refuses `qr`, two characters, and `192.168.5.4`,
and `goog-quitanda` for its first four letters. It would accept `quitanda.raw.prod` only from
somebody verified as the owner of `raw.prod`, which is nobody here. So the rules are checked by you,
not by this server. The second create of `quitanda-raw-prod` met the 409, and its sentence is the
real service's own: names are unique across every project, including other people's. Against Cloud
Storage that answer also comes when the name is taken by somebody you have never heard of, and
fake-gcs-server can only produce it for a name of yours, because it imitates nobody else.

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
logs and in error messages that strangers can see. Some teams add the project id,
`quitanda-raw-prod-planner-dev`, which settles the collision problem for good at the price of a
longer name in every path.

## A scheme for object names

Inside a bucket the object names are where data lakes succeed or fail, and the rule is to **lay
names out by the question that will be asked most**. For data that arrives every day and is read by
date, that means the date goes into the path, written so that alphabetical order is time order:

```
raw/orders/dt=2026-10-01/orders.csv
raw/orders/dt=2026-10-02/orders.csv
raw/payments/dt=2026-10-01/payments.csv
```

**`dt=2026-10-01` and not `01-10-2026`.** Cloud Storage lists names in lexicographic order of their
bytes, so a year-month-day date lists in time order and a day-month-year one lists every first of
the month together. The `name=value` form is the *hive partitioning* convention that BigQuery's
external tables, Spark and DuckDB read as a partition, which lessons 15 and 17 use to read one day
instead of all of them. A source name before the date, `orders` and `payments`, keeps one feed's
files out of another's listing.

**Write names as if they could never be renamed**, because in practice they cannot. Lowercase, no
spaces, no accents, no characters a URL has to escape. An object name may legally hold almost any
UTF-8 up to 1,024 bytes, and `relatório final (2).csv` is a valid one; it is also a name that every
tool quotes differently, as the `%2F` in the last section's error already showed for a plain slash.
