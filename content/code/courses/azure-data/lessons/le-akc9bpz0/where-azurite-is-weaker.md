---
title: Where Azurite is weaker, and how it says so
version: 1
---

**Azurite accepts the soft-delete setting and does not keep what is deleted.** That is the most
dangerous of the gaps this lesson meets, because the setting answers as if it worked. The others are
honest refusals. Every one of them is here so that a test that passed on a laptop is not mistaken for
a protection that exists.

## Soft delete: accepted, not honoured

The retention for deleted blobs is a property of the blob service that the data plane can set, so the
command line sends it to Azurite with the connection string, and Azurite stores it:

```
ana@laptop:~/azure$ az storage blob service-properties delete-policy update --enable true --days-retained 7
{
  "allowPermanentDelete": null,
  "days": 7,
  "enabled": true
}
ana@laptop:~/azure$ printf "date,rate\n2026-10-29,5.41\n" > rates.csv && az storage blob upload -c finance -n rates.csv -f rates.csv --no-progress -o none
ana@laptop:~/azure$ az storage blob delete -c finance -n rates.csv
ana@laptop:~/azure$ az storage blob list -c finance --include d --prefix rates.csv --query "[].{name:name, deleted:deleted}"
[]
ana@laptop:~/azure$ az storage blob undelete -c finance -n rates.csv 2>&1 | grep -E "ERROR|ErrorCode"
ERROR: Current API is not implemented yet. Please vote your wanted features to https://github.com/azure/azurite/issues
ErrorCode:APINotImplemented
```

**The policy says seven days and enabled, and the deleted blob is not there.** The listing with
`--include d` asks for deleted blobs as well as current ones, and the answer is an empty list. Asking
for the blob back is refused with `APINotImplemented`, Azurite's own code for an operation it has not
written, and its message says so plainly. On Azure the same listing would show `rates.csv` with
`deleted: true` for seven days, and the undelete would bring it back.

## Versioning: no version ids

Versioning can only be switched on through the control plane, so the command line stops before it
reaches Azurite at all. A short program then writes the same blob twice and asks for its versions:

`versions.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
finance = service.get_container_client("finance")
blob = finance.get_blob_client("rates/eur-brl.csv")
first = blob.upload_blob(b"date,rate\n2026-10-29,6.27\n", overwrite=True)
second = blob.upload_blob(b"date,rate\n2026-10-30,6.29\n", overwrite=True)
print("version_id:", first.get("version_id"), second.get("version_id"))
print([(b.name, b.version_id) for b in finance.list_blobs(name_starts_with="rates/eur",
                                                           include=["versions"])])
```

```
ana@laptop:~/azure$ az storage account blob-service-properties update -n devstoreaccount1 --enable-versioning true 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ python versions.py
version_id: None None
[('rates/eur-brl.csv', None)]
```

`version_id` is `None` after both uploads, and the listing that asks for versions shows one blob, the
current one. A program that reads `version_id` from the answer of an upload, and stores it to restore
from later, stores `None` here and a real id on Azure, and the code path that restores a version is
never exercised in the lab.

## Immutability: refused

Version-level immutability and legal holds are set on a blob through the data plane, so a program can
ask Azurite for them:

`protect.py`:

```python
import datetime
from azure.storage.blob import BlobServiceClient, ImmutabilityPolicy

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
record = service.get_blob_client("finance", "rates/eur-brl.csv")
until = datetime.datetime(2033, 10, 30, tzinfo=datetime.timezone.utc)

attempts = {
    "retention until 2033": lambda: record.set_immutability_policy(
        ImmutabilityPolicy(expiry_time=until, policy_mode="Unlocked")),
    "legal hold": lambda: record.set_legal_hold(True),
}
for name, attempt in attempts.items():
    try:
        attempt()
        print(name, "set")
    except Exception as refusal:
        print(name, "refused:", str(refusal).splitlines()[0])
```

```
ana@laptop:~/azure$ python protect.py
retention until 2033 refused: Operation returned an invalid status 'Current API is not implemented yet. Please vote your wanted features to https://github.com/azure/azurite/issues'
legal hold refused: Operation returned an invalid status 'Current API is not implemented yet. Please vote your wanted features to https://github.com/azure/azurite/issues'
```

**Two refusals, and they are the honest kind**: a program that tries to protect a record against
Azurite finds out at once that it cannot. The message is the one `APINotImplemented` carried above;
the library found no error code in this answer to print, so the program prints the first line of the
message instead. The container-level policy of the previous
section is control plane, so Azurite is never asked about it.

## What the lab proves, then

| feature | what Azurite does | what a passing test proves |
|---|---|---|
| soft delete | stores the setting, keeps nothing | that the request was well formed, and nothing about recovery |
| undelete | refuses, `APINotImplemented` | nothing |
| versioning | gives no version ids | nothing |
| snapshots | keeps and restores them | the snapshot and copy logic |
| immutability, legal hold | refuses, `APINotImplemented` | nothing |
| life-cycle policy | has none; control plane | nothing; Terraform checks the declaration |

**The restore path is the one that is never rehearsed**, and it is the one that matters on the bad
day. A design that relies on these features is tested on a real account, in a subscription made for
testing, by deleting something on purpose and bringing it back, after `azure-foundations` lesson 13
has set a budget with an alert on it. Nothing in this course does that, and the course says so here rather than
letting a green test say otherwise.
