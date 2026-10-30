---
title: Retention policies, Bucket Lock and holds
version: 1
---

**A retention policy makes every object in a bucket impossible to delete or replace until it is old
enough, for everybody, including the project's owner.** Versioning and soft delete protect against
accidents, because whoever made the mistake can undo it; they protect nothing against somebody who
means it, because whoever may delete a live object may also delete its generations, and may turn
soft delete off. A retention policy is for the second case: ransomware run with a stolen key, an
employee covering something up, a law that says invoices are kept for five years. The last one is
why Quitanda has an archive bucket at all.

Cloud Storage has four tools for it, and they work at two levels:

| tool | set on | what it does |
|---|---|---|
| retention policy | the bucket | no object may be deleted or replaced until its age reaches the period |
| Bucket Lock | the bucket's retention policy | makes the policy permanent: it can be lengthened, never shortened or removed |
| object hold | one object | a switch, temporary or event-based, that keeps the object until it is released |
| object retention | one object | a date until which that one object is kept, unlocked or locked |

None of what follows was enforced in this lab, and the last part of this section shows that plainly.
It is taught from Google's documentation: cloud.google.com/storage/docs/bucket-lock,
cloud.google.com/storage/docs/object-holds and cloud.google.com/storage/docs/object-lock.

## The retention policy, and locking it

A retention policy is a period, set with `--retention-period` when the bucket is created or later
with `gcloud storage buckets update`. An object in that bucket can be deleted or replaced only when
its age, counted from when it was written, has reached the period. Until then a delete is refused,
whatever role asks. The period can be up to 100 years.

**An unlocked policy is a strong default and nothing more**, because anybody who may change the bucket
may also remove the policy with `--clear-retention-period` and then delete what it protected.
`--lock-retention-period` is the step that changes that. Once a policy is locked:

- it cannot be removed, and its period cannot be shortened. It can only be lengthened;
- the bucket cannot be deleted while it holds any object younger than the period;
- the project cannot be deleted while it holds such a bucket, since the documentation says a lock
  places a lien on the project.

**Locking is irreversible, and that is the whole of its value.** It is also the most expensive
command in this course to get wrong: a hundred-year period locked by mistake on a bucket that
receives a terabyte a day is a bill nobody can stop. Quitanda's invoices get five years, the period
the law asks for and not one day more, and the lock is applied once the policy has been read back
and checked by a second person.

## Holds

A hold is a switch on one object, with no date. While it is on, the object cannot be deleted or
replaced, whatever the retention policy says. There are two kinds:

- **a temporary hold** keeps the object until somebody releases it, and does nothing else. It is the
  tool for "keep everything about this customer until the lawyers say otherwise", where nobody knows
  the end date;
- **an event-based hold** does the same and also resets the clock of the retention policy: the
  object's retention period counts from the moment the hold is released, not from when it was
  written. A bucket can put one on every new object by default, with
  `--default-event-based-hold`. That suits a contract kept "five years after it ends", where the end
  is an event that nobody can date in advance.

Releasing a hold needs permission to update the object, so a hold protects against accidents and
against anyone without that permission, not against an administrator. It is not a lock.

## Object retention, for one object at a time

A bucket created with `--enable-per-object-retention` lets each object carry a date of its own, set
with `gcloud storage objects update --retain-until` and `--retention-mode`. The mode is `Unlocked` or
`Locked`. Unlocked can be shortened or removed by somebody with the right permission and the
`--override-unlocked-retention` flag, which the command line's help names; Locked can only be
extended, and the object is kept until its date whoever asks. It is the per-object counterpart of
Bucket Lock, for a bucket whose objects need different periods.

## In the emulator

Create the archive bucket with a year's retention, write an invoice and delete it at once:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-archive-prod --location=southamerica-east1 --retention-period=1y
Creating gs://quitanda-archive-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-archive-prod --format='value(retention_policy)'

ana@laptop:~/gcp$ printf 'invoice,total_cents\nnf-2026-10-0001,4590\n' > nf.csv && gcloud storage cp nf.csv gs://quitanda-archive-prod/invoices/2026-10/nf.csv
Copying file://nf.csv to gs://quitanda-archive-prod/invoices/2026-10/nf.csv
  

ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-archive-prod/invoices/2026-10/nf.csv
Removing objects:
  
Removing gs://quitanda-archive-prod/invoices/2026-10/nf.csv...
ERROR: 'NoneType' object has no attribute 'items'

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-archive-prod/invoices/
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-archive-prod --retention-period=1y && gcloud storage buckets update gs://quitanda-archive-prod --lock-retention-period
  
Updating gs://quitanda-archive-prod/...

  
Updating gs://quitanda-archive-prod/...
failed.
ERROR: (gcloud.storage.buckets.update) Bucket "gs://quitanda-archive-prod/" does not have a retention policy.
```

**The invoice was deleted, a second after it was written, in a bucket with a year's retention.** The
`describe` shows why: no retention policy came back, because fake-gcs-server did not keep one. The
last command is the clearest evidence of all, and it came from the command line, not from the
emulator. `--lock-retention-period` makes `gcloud` read the bucket's policy before it locks it, and
it found none: `does not have a retention policy`, one command after setting a year of it.

Holds fare no better:

```
ana@laptop:~/gcp$ gcloud storage cp nf.csv gs://quitanda-archive-prod/disputes/c-17/order.csv && gcloud storage objects update gs://quitanda-archive-prod/disputes/c-17/order.csv --temporary-hold
Copying file://nf.csv to gs://quitanda-archive-prod/disputes/c-17/order.csv
  

  
Patching gs://quitanda-archive-prod/disputes/c-17/order.csv...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/disputes/c-17/order.csv --format='value(temporary_hold,event_based_hold)'
	
ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-archive-prod/disputes/c-17/order.csv
Removing objects:
  
Removing gs://quitanda-archive-prod/disputes/c-17/order.csv...
ERROR: 'NoneType' object has no attribute 'items'

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-archive-prod/disputes/
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
```

**The hold was accepted and not kept**: both hold fields came back empty, and the delete that it
should have refused succeeded. In this lab every retention tool is a request that parses and a
setting that does nothing, and a test of any of them proves only that the command was spelt
correctly. A real check of a locked policy needs a real project, and costs the storage of whatever
it locks for the whole of the period, since nothing can remove it sooner.
