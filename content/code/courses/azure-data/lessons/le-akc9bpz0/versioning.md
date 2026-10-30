---
title: Versioning, and its manual cousin the snapshot
version: 1
---

**With versioning switched on, every write to a blob keeps the previous content as a version.**
Nothing written is ever lost to an overwrite. Each version has an id, a timestamp to the
ten-millionth of a second in the shape of the snapshot's `2026-10-30T19:00:35.1940000Z` below, and the
blob's ordinary name always reads the current one. A delete does not destroy anything either: the current content becomes a
previous version, and the name stops answering until somebody restores it. Restoring is a copy: the
version you want is copied over the blob's name, and that copy is itself a new current version.

The versioning half of this section is taught from Microsoft's documentation, because Azurite gives no
version ids, as the last section of the lesson shows; the snapshots at its end ran on Azurite. The declaration that
switches it on is the `versioning_enabled = true` line of the previous section.

## What it costs

**Every version is billed while it is kept**, and that is the line that grows without anybody looking.
Microsoft's billing rules count the data that differs between a blob and its versions, so a large log
that gains a few lines a day adds little. A file rewritten whole every night shares nothing with the
night before, and each version is a full copy: a 50 GB table rewritten nightly for a year in a
versioned account is about 18 TB of versions behind 50 GB of current data. That is why versioning
comes with the life-cycle rule of the next section, whose `version` block deletes versions after a
number of days.

Versioning is not on by default, and it can only be switched on through the control plane, which is
why, in the last section, `az storage account blob-service-properties update --enable-versioning`
stops and asks for a login. Soft delete and versioning work together: with both on, Microsoft documents
that deleting a version soft-deletes it, so even a version removed by mistake has the retention days
of the previous section.

## Snapshots, which Azurite has

Before versioning there were **snapshots**: a read-only copy of a blob at one moment, made on request
rather than on every write. They still exist, a program still makes them, and Azurite implements
them, so they show on a laptop the mechanics that versioning automates. Quitanda's finance team keeps
a small file of exchange rates that one person edits by hand; a program snapshots it before each edit:

`snapshot.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
container = service.get_container_client("finance")
if not container.exists():
    container.create_container()
rates = container.get_blob_client("rates/usd-brl.csv")

rates.upload_blob(b"date,rate\n2026-10-29,5.41\n", overwrite=True)
before = rates.create_snapshot()["snapshot"]
print("snapshot taken:", before)

rates.upload_blob(b"date,rate\n2026-10-29,54.1\n", overwrite=True)
print("now:", rates.download_blob().readall().decode().splitlines()[1])

old = container.get_blob_client("rates/usd-brl.csv", snapshot=before)
print("snapshot:", old.download_blob().readall().decode().splitlines()[1])
print("listed:", [(b.name, b.snapshot) for b in container.list_blobs(include=["snapshots"])])

rates.start_copy_from_url(old.url)
print("restored:", rates.download_blob().readall().decode().splitlines()[1])
```

```
ana@laptop:~/azure$ python snapshot.py
snapshot taken: 2026-10-30T19:00:35.1940000Z
now: 2026-10-29,54.1
snapshot: 2026-10-29,5.41
listed: [('rates/usd-brl.csv', None), ('rates/usd-brl.csv', '2026-10-30T19:00:35.1940000Z')]
restored: 2026-10-29,5.41
```

**The snapshot kept 5.41 while the blob was overwritten with a slipped decimal point, 54.1.** The
listing shows two entries under one name: the snapshot, with its timestamp, and the current blob, with
none. The restore copied the snapshot's URL over the blob's own name, which is exactly how a version
is restored, and the rate is right again. With versioning on, the `create_snapshot` call would
not be needed: every upload would have left a version behind without being asked.
