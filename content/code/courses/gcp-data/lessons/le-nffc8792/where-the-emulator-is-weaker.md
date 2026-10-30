---
title: Where the emulator is weaker than Cloud Storage
version: 1
---

**fake-gcs-server keeps versions and gives several of them back wrongly.** The earlier sections
showed what it ignores outright: the life-cycle configuration, the retention policy, the holds. This
one shows the parts it implements and gets wrong, because those are worse. A setting that is ignored
fails a test the moment the test reads it back. A setting that is half kept can pass a test and
mislead it, and two of the three below err in the dangerous direction.

## The listing that hides noncurrent versions

`gcloud storage ls -a` showed one generation where the bucket had two, in the first section. The
reason is a spelling. The command line asks for every generation with `versions=True` in the query
string, and the emulator only understands `versions=true`, in lower case:

```
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-curated-prod/o?versions=True' | grep -o '"generation"' | wc -l
1
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-curated-prod/o?versions=true' | grep -o '"generation"' | wc -l
3
```

**Same bucket, same request, one letter different: one generation or three.** The Python client
library asks the same way the command line does, so a program that lists versions with it sees only
the live ones here. That is why this lesson's `versions.py` builds the request itself. A cleanup
script tested against the emulator would find no old versions to clean, and on Cloud Storage it
would meet all of them.

## The old generation that reads as the new one

Reading a noncurrent generation by its number worked with `curl` in the first section. The command
line asks for it in a different way, and gets something else:

```
ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-curated-prod/customers/customers.csv#1793385435809152
customer_id,city
c-17,SorocabERROR: (gcloud.storage.cat) Source hash qI/uqz6hnJWXM58h9wVE7w== does not match destination hash uWdDzi0lSTK1t8mLdxXZKw== for object -.
```

**The emulator served the bytes of the live object, cut to the length of the old one**: `Sorocab`,
the first 29 bytes of the 31-byte live version, where the 29-byte generation asked for holds
`Santos`. The command line noticed only because it checks the MD5 hash of what it receives against
the one the object's metadata declares, and the two disagree. The check is the command line's, not
the emulator's, and it is the reason to keep it on: a program that downloads without checking a hash
would have stored the wrong file and reported success.

## The delete that removes the wrong generation

This is the dangerous one. Delete one noncurrent generation by its number, the only kind of delete
in Cloud Storage that removes anything for good:

```
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385444118716  31 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-curated-prod/customers/customers.csv#1793385435809152
Removing objects:
  
Removing gs://quitanda-curated-prod/customers/customers.csv#1793385435809152...
ERROR: 'NoneType' object has no attribute 'items'
.
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**The live version disappeared and the generation that was named is still there.** Before the
command, the bucket held Sorocaba live and two noncurrent generations; after it, the two noncurrent
ones remain, the first of them the very number the command named. fake-gcs-server 1.54.0 ignores
the generation on a delete and removes the live version of the name instead. On Cloud Storage the
same command removes exactly the generation it names, and the live object is untouched. A script
that prunes old versions, run against this emulator, would delete the current data and keep the
history.

## Soft delete, retention, holds and life cycle

The settings of the earlier sections, side by side, from the transcripts above and this one:

```
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-archive-prod --format='value(soft_delete_policy)'

ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-archive-prod --soft-delete-duration=30d
  
Updating gs://quitanda-archive-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-archive-prod --format='value(soft_delete_policy)'

ana@laptop:~/gcp$ gcloud storage ls --soft-deleted 'gs://quitanda-archive-prod/**'
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
```

**The soft-delete duration was accepted and not kept, like everything else in this list**: the policy
reads back empty before and after `--soft-delete-duration=30d`, and the invoice deleted earlier in
this bucket is not among any soft-deleted objects, because there are none. On Cloud Storage a new
bucket would report a seven-day policy before anybody set one, and then thirty days.

| setting | the emulator | Cloud Storage |
|---|---|---|
| versioning | kept, listed only with `versions=true` | kept and listed with `ls -a` |
| reading a generation | right with `curl`, wrong bytes with `gcloud storage cat` | the generation named |
| deleting a generation | removes the live version instead | removes the generation named |
| life-cycle rules | accepted, not stored, never applied | stored, applied within about a day |
| retention policy and lock | accepted, not stored | enforced; a lock is permanent |
| holds | accepted, not stored | enforced until released |
| soft delete | accepted, not stored | on by default, seven days |

## So what does a test here prove?

That the requests are well formed: a bucket was created, a flag was spelt correctly, a JSON file
parsed. It proves nothing about whether a version survives, whether a delete deletes the right thing,
or whether a lock holds. **Test the shape of a protection against the emulator and believe Google's
documentation for its strength.** And keep the one check that caught a real error here: the hash
that the command line compares on every download, which no emulator can talk you out of.
