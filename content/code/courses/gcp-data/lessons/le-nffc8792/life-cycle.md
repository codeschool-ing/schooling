---
title: Life-cycle rules, and the clock the emulator does not have
version: 1
---

**A life-cycle configuration is a list of rules that Cloud Storage applies to a bucket's objects as
they age**: move them to a colder class after so many days, delete them after so many more, delete
noncurrent versions, clear away uploads that were started and never finished. It is the one place
where Cloud Storage does work on its own, with no request from you, and that is exactly the part an
emulator cannot imitate.

Each rule is an action and a condition, and the action happens to an object when every part of the
condition is true of it. Google's documentation, cloud.google.com/storage/docs/lifecycle, lists
three actions:

| action | what it does |
|---|---|
| `SetStorageClass` | moves the object to a colder class, without rewriting it |
| `Delete` | deletes the object; a live one in a versioned bucket becomes noncurrent, a noncurrent one goes for good |
| `AbortIncompleteMultipartUpload` | removes the parts of an upload that was started and never completed |

And the conditions most rules are built from:

| condition | true of an object when |
|---|---|
| `age` | it was created at least that many days ago |
| `matchesPrefix`, `matchesSuffix` | its name starts or ends with one of the strings given |
| `matchesStorageClass` | its class is one of those given |
| `isLive` | it is the live version (`true`) or a noncurrent one (`false`) |
| `daysSinceNoncurrentTime` | it has been noncurrent for at least that many days |
| `numNewerVersions` | at least that many newer versions of the same name exist |

There are no tags in Cloud Storage to filter on, unlike some other object stores, so **the name is
the filter**. That is one more reason lesson 1's naming scheme puts the kind of data first in the
key: `raw/orders/` and `raw/scratch/` can be told apart by a rule, and a file that hid its kind at
the end of a long name could only be caught with `matchesSuffix`.

## Quitanda's rules

The raw bucket holds the nightly exports under `raw/orders/`. Analysts read the last month often, the
last year rarely, and nothing older except for an audit. Scratch files under `raw/scratch/` are
worthless after a week. Write that down as rules, in a file:

`lifecycle.json`:

```json
{
  "rule": [
    {
      "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
      "condition": {"age": 30, "matchesPrefix": ["raw/orders/"], "matchesStorageClass": ["STANDARD"]}
    },
    {
      "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
      "condition": {"age": 365, "matchesPrefix": ["raw/orders/"], "matchesStorageClass": ["NEARLINE"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 2555, "matchesPrefix": ["raw/orders/"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 7, "matchesPrefix": ["raw/scratch/"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"isLive": false, "daysSinceNoncurrentTime": 7}
    },
    {
      "action": {"type": "AbortIncompleteMultipartUpload"},
      "condition": {"age": 3}
    }
  ]
}
```

**An export is Standard for its first month, Nearline until it is a year old, Archive for six more
years, and then gone**, 2,555 days being seven years. A scratch file lives a week. Anywhere in the
bucket, a version lives seven days after it is replaced, and an upload left unfinished is cleared
after three. The `matchesStorageClass` conditions keep each move to the objects it was written for. A
life-cycle rule only ever moves an object to a colder class, so nothing but a rewrite brings one
back.

**Over its seven years a GiB under these rules costs about 0.48 USD**, against 2.98 if it had stayed
in Standard. The prices are São Paulo's, from lesson 2, and a month is 30 days:

```
ana@laptop:~/gcp$ python3 -c 'print(round(30 / 30 * 0.035 + 335 / 30 * 0.020 + 2190 / 30 * 0.003, 4), round(2555 / 30 * 0.035, 4))'
0.4773 2.9808
```

The first number is 30 days of Standard at 0.035, 335 of Nearline at 0.020 and 2,190 of Archive at
0.003; the second is all 2,555 days in Standard. The minimum stays are all met, so no early deletion
is charged; and the class changes a rule makes are free of the early-deletion charge anyway, according
to the pricing page. **Each move is one Class A operation at the price of the class it goes to.**
For an export of a few hundred megabytes that is nothing. For a million 10 KB files moved to Archive
it is 50 USD, which is why a rule for a bucket of small files deserves a second look.

## What the emulator does with the rules

Apply the file and read the bucket back:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=lifecycle.json
  
Updating gs://quitanda-raw-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-raw-prod --format=json
{
  "creation_time": "2026-10-30T15:37:25-0300",
  "default_storage_class": "STANDARD",
  "location": "southamerica-east1",
  "location_type": "region",
  "metageneration": 1,
  "name": "quitanda-raw-prod",
  "storage_url": "gs://quitanda-raw-prod/",
  "update_time": "2026-10-30T15:37:25-0300",
  "versioning_enabled": false
}
```

**The emulator answered with success and kept nothing.** On Cloud Storage the `describe` would carry a
`lifecycle_config` with the six rules; here there is no such field. fake-gcs-server 1.54.0 does not
store a life-cycle configuration, and it has no clock that ages an object, so it could not apply one
if it did: nothing in it happens between two requests.

What does check something is the command line, before the request leaves:

```
ana@laptop:~/gcp$ printf '{"rule": [{"action": {"type": "Teleport"}, "condition": {"age": 1}}]}' > odd.json && gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=odd.json
  
Updating gs://quitanda-raw-prod/...

ana@laptop:~/gcp$ printf '{"rule": [{"action": {"type": "Delete"}, "condition": {"agee": 1}}]}' > typo.json && gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=typo.json
  
Updating gs://quitanda-raw-prod/...
ERROR: Found invalid JSON/YAML for the lifecycle rule
```

**A misspelt condition is refused by `gcloud` itself**, which knows the names of the conditions.
An action called `Teleport` is not, because the command line passes the action's type through, and
the emulator accepted it as it accepts everything. Cloud Storage refuses a rule whose action it does
not know. So in this lab a life-cycle file is checked for its condition names and its JSON, and for
nothing else: whether it parses as rules, and what they would do over months, is taught here from
Google's documentation and checked by you.

Two documented details complete the picture. **Cloud Storage applies the rules asynchronously**: the
documentation says an action can take up to 24 hours after the object qualifies, so an object reaches
its new class some time after the day it qualifies, not at the minute. And a change to the rules can
take up to 24 hours to take effect, which is worth knowing before writing a `Delete` rule with a
short `age` into a bucket that holds anything of value: test it first in `quitanda-raw-dev`.
