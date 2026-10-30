---
title: Reading an archived blob back
version: 1
---

**A blob in the archive tier cannot be read until it is rehydrated.** It is listed, it has a size,
its properties come back, and a download of its bytes is refused. People expect a slow read; what
they get is no read at all, and a separate step that asks Azure to bring the blob back online, which
on Azure finishes hours later. Hot, cool and cold have no such step, which is what makes archive
different in kind and not only in price.

## Archiving and asking

The cool copy of September from the previous section goes to archive, and the download is tried:

```
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/cool.csv --tier Archive
ana@laptop:~/azure$ az storage blob download -c orders-archive -n orders/2026-09/cool.csv -f back.csv --no-progress 2>&1 | grep -E "ERROR|ErrorCode"
ERROR: This operation is not permitted on an archived blob.
ErrorCode:BlobArchived
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "{tier:properties.blobTier, size:properties.contentLength}"
{
  "size": 64,
  "tier": "Archive"
}
```

**`BlobArchived` is the refusal**, and it came from Azurite, as it would from Azure. The properties
still answer: the tier says `Archive`, and the 64 bytes are counted. Everything that describes the
blob stays online; only its content is put away.

## Rehydrating in place

The first way back is to change the tier, which on an archived blob starts a rehydration:

```
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/cool.csv --tier Hot --rehydrate-priority Standard
WARNING: Argument '--rehydrate-priority' is in preview and under development. Reference and support levels: https://aka.ms/CLI_refstatus
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "properties.[blobTier, rehydrationStatus]" -o tsv
Hot
None
ana@laptop:~/azure$ az storage blob download -c orders-archive -n orders/2026-09/cool.csv -f back.csv --no-progress -o none && cat back.csv
order_id,customer_id,total_cents
09-1,c-17,4590
09-2,c-03,12800
```

**On Azurite the rehydration is finished before the next command**: the tier already says `Hot`,
`rehydrationStatus` is empty, and the download that failed a moment ago succeeds. That is the largest
gap between Azurite and Azure in this lesson. On Azure, according to Microsoft's documentation, the
tier would go on saying `Archive` while the rehydration runs, the blob's archive status would say
`rehydrate-pending-to-hot`, and every download would still fail with `BlobArchived` until it
finished. The warning about `--rehydrate-priority` being in preview is the command line describing
its own option.

The priority is the one choice a rehydration offers:

| priority | Microsoft documents it as finishing |
|---|---|
| Standard | within 15 hours |
| High | under one hour, for a blob smaller than 10 GB |

None of that was run here. High priority costs more per gigabyte than standard, and Microsoft
documents that it may take longer than an hour for large blobs or when demand is unusual. A pending
standard rehydration can be raised to high; a high one cannot be lowered.

## Copying out of the archive

The second way back leaves the archived blob where it is and copies it to a new name in an online
tier. That is the right way when the archive copy has to stay, for an auditor or because its
minimum 180 days have not run out. The command line has the options for it, `--tier` and
`--rehydrate-priority` on `az storage blob copy start`, and against Azurite it fails on a step that
has nothing to do with tiers:

```
ana@laptop:~/azure$ az storage blob copy start -c orders-archive -b restored/cool.csv --source-container orders-archive --source-blob orders/2026-09/cool.csv --tier Hot --rehydrate-priority High 2>&1 | grep ErrorCode
ErrorCode:CannotVerifyCopySource
```

`CannotVerifyCopySource` is Azurite failing to check the source address the command line built for
it, and the same command fails the same way for a blob in hot. The Python library sends the copy
correctly, so this course does it with a short program:

`rehydrate.py`:

```python
from azure.storage.blob import BlobServiceClient, RehydratePriority, StandardBlobTier

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
archive = service.get_container_client("orders-archive")
source = archive.get_blob_client("orders/2026-09/audit.csv")
source.upload_blob(open("export/orders-2026-09.csv", "rb"), overwrite=True,
                   standard_blob_tier=StandardBlobTier.ARCHIVE)

target = archive.get_blob_client("restored/orders-2026-09.csv")
copy = target.start_copy_from_url(source.url, standard_blob_tier=StandardBlobTier.HOT,
                                  rehydrate_priority=RehydratePriority.HIGH)
print("copy:", copy["copy_status"])
for blob in (source, target):
    props = blob.get_blob_properties()
    print(blob.blob_name, props.blob_tier, props.size)
```

```
ana@laptop:~/azure$ python rehydrate.py
copy: success
orders/2026-09/audit.csv Archive 64
restored/orders-2026-09.csv Hot 64
```

**Two blobs, one in each tier.** The audit copy is still in archive and the restored one is in hot,
with the same 64 bytes. Azurite reported the copy as `success` at once. On Azure the same call would
answer `pending`, and the target would become readable when the rehydration behind the copy finished,
on the same clock as the table above.

## Archive and the account's redundancy

**Microsoft's documentation, at the time of writing, does not offer the archive tier on accounts
replicated with ZRS, GZRS or RA-GZRS.** Lesson 1 chose ZRS for Quitanda's exports account, so that
account cannot archive anything. The declaration in the previous section is a second account,
`stquitandaarchiveprd`, on LRS. Azurite has no replication and accepted every tier above, which is
another success that proves only that the request was well formed.
