---
title: Versioning, and the delete that keeps the bytes
version: 1
---

**A versioned bucket never overwrites and never deletes unless you name a generation.** Every
object in Cloud Storage has a generation, a number the service gives it when it is written, and in a
versioned bucket a write to a name that exists keeps the old generation as a noncurrent version
instead of throwing it away. A delete with no generation does the same to the live one: the name
disappears from listings and every byte it held stays in the bucket and on the bill. People switch
versioning on to protect data and are surprised twice: first that a deleted file can come back, and
then by what keeping every version costs.

This lesson starts from an empty fake-gcs-server, as every lesson does, running in its own terminal,
with the lines of lesson 1's "Every time you open a terminal" typed in this one. The curated bucket
gets versioning before its first object:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-curated-prod --format='value(versioning_enabled)'
False
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-curated-prod --versioning
  
Updating gs://quitanda-curated-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-curated-prod --format='value(versioning_enabled)'
True
```

A new bucket has versioning off. `--versioning` turns it on and `--no-versioning` turns it off again,
and those are the only two states: Cloud Storage has no third, "suspended" one.

## Two writes, two generations

Quitanda's curated customer table is rewritten whole every night. Write it twice, and look at the
bucket in two ways: with the command line, and with a short program that asks the emulator for every
generation directly. The program is the reason for the second way, and the section on where the
emulator is weaker says why the command line cannot be trusted here.

`versions.py`:

```python
"""Every generation of every object in a bucket of the local emulator."""
import json
import os
import sys
import urllib.request

host = os.environ['STORAGE_EMULATOR_HOST']
url = f'{host}/storage/v1/b/{sys.argv[1]}/o?versions=true'
for o in json.load(urllib.request.urlopen(url)).get('items', []):
    state = 'noncurrent since ' + o['timeDeleted'] if 'timeDeleted' in o else 'live'
    print(o['generation'], f"{o['size']:>3}", o['name'], state)
```

It reads the address of the emulator from `STORAGE_EMULATOR_HOST`, which lesson 1's lines set, and
prints one line per generation: the generation number, the size, the name, and whether it is live.

```
ana@laptop:~/gcp$ printf 'customer_id,city\nc-17,Santos\n' > customers.csv && gcloud storage cp customers.csv gs://quitanda-curated-prod/customers/customers.csv
Copying file://customers.csv to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ printf 'customer_id,city\nc-17,Campinas\n' > customers.csv && gcloud storage cp customers.csv gs://quitanda-curated-prod/customers/customers.csv
Copying file://customers.csv to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ gcloud storage ls -a gs://quitanda-curated-prod/customers/
gs://quitanda-curated-prod/customers/customers.csv#1793385436988405
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385436988405  31 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-curated-prod/o/customers%2Fcustomers.csv?alt=media&generation=1793385435809152'
customer_id,city
c-17,Santos
```

**Both generations are there**, and the program shows them: 31 bytes live, Campinas, and 29 bytes
noncurrent since the moment the second write replaced it, Santos. A read with no generation returns
the live one; a read that names a generation returns that one, and the last command fetched Santos
back by its number. `gcloud storage ls -a`, which on Cloud Storage lists every generation with its
number after a `#`, printed only the live one here. On Cloud Storage it would have printed both.

The noncurrent generation is billed exactly like the live one: same class, same price per GiB, for as
long as it exists.

## A delete, and the way back

```
ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-curated-prod/customers/customers.csv
Removing objects:
  
Removing gs://quitanda-curated-prod/customers/customers.csv...
ERROR: 'NoneType' object has no attribute 'items'

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/customers/
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**The name has gone from the listing, and nothing was removed.** `gcloud storage rm` with no
generation made the live version noncurrent, so now both generations are noncurrent and the name
answers as absent. The `ERROR` line after the removal is the command line failing to read the
emulator's reply, and it prints after every `rm` in this lab; the delete itself happened, as the
listing shows. On Cloud Storage the same command prints the removal and no error.

There is no delete marker in Cloud Storage, which is worth saying because other object stores have
one. A deleted name in a versioned bucket is simply a name with no live generation. Bringing it back
is a copy of the generation you want onto the name:

```
ana@laptop:~/gcp$ gcloud storage cp gs://quitanda-curated-prod/customers/customers.csv#1793385435809152 gs://quitanda-curated-prod/customers/customers.csv
Copying gs://quitanda-curated-prod/customers/customers.csv#1793385435809152 to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-curated-prod/customers/customers.csv
customer_id,city
c-17,Santos
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385441037210  29 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**The copy made a third generation, live, with Santos's 29 bytes**, and the two older ones are still
noncurrent behind it. Only a delete that names a generation, `gcloud storage rm gs://…#GENERATION`,
removes anything for good, and it removes that one generation and nothing else. **IAM does not tell
the two deletes apart**: the permission `storage.objects.delete` allows both, and replacing an object
needs it too. A pipeline that only ever adds new names can run with `roles/storage.objectCreator`,
which has no delete at all; anything that rewrites names can also destroy generations, and the
protection against it is the retention policy three sections on, not a role.

## Turning it off keeps what was kept

```
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-curated-prod --no-versioning
  
Updating gs://quitanda-curated-prod/...

ana@laptop:~/gcp$ printf 'customer_id,city\nc-17,Sorocaba\n' > customers.csv && gcloud storage cp customers.csv gs://quitanda-curated-prod/customers/customers.csv
Copying file://customers.csv to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385444118716  31 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**Turning versioning off keeps every noncurrent version it had**, here the two from before. What
changes is the next write: Sorocaba replaced the live generation without keeping it, which is what an
unversioned bucket does, and the restored copy of Santos is gone. Turning versioning off stops the
growth; it does not shrink what is stored. Removing old generations takes a delete per generation, or
the life-cycle rule of the section after next.

## Soft delete, which is on whether you asked or not

Versioning is a setting you choose. **Soft delete is a second, separate protection, and Google turns
it on for new buckets**, with a retention of seven days. Google's documentation for it,
cloud.google.com/storage/docs/soft-delete, describes it like this: an object that is deleted or
replaced is kept, unreadable and unlisted by ordinary commands, for the soft-delete duration, and can
be brought back with `gcloud storage restore` during that time. `gcloud storage ls --soft-deleted`
lists them. The duration can be set between 7 and 90 days with `--soft-delete-duration`, or soft
delete turned off with `--clear-soft-delete`.

The two protections stack. In a versioned bucket, a version deleted for good, by you or by a rule,
becomes soft-deleted next. In an unversioned bucket, every overwrite and every delete leaves the old
bytes soft-deleted. **Soft-deleted objects are billed at the price of their class** for the days they
are kept, which the next section puts a number on. fake-gcs-server keeps nothing of the kind, and the
section on where it is weaker shows it.
