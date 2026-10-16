---
title: Reading an archived object back
version: 1
---

**An object in Glacier Flexible Retrieval or Deep Archive cannot be read until it is restored.** It
is listed, it has a size and an ETag, `head-object` describes it, and a `GET` of its bytes is
refused. People expect a slow read; what they get is no read at all, and a separate request that
asks S3 to make a temporary readable copy, which arrives hours later. Glacier Instant Retrieval is
the one archive class without that step, which is what its name says.

The bucket from the previous section still holds the four copies. Ask for two of them:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-archive-prod/orders/2026-09/deep.csv back.csv
warning: Skipping file s3://quitanda-archive-prod/orders/2026-09/deep.csv. Object is of storage class GLACIER. Unable to perform download operations on GLACIER objects. You must restore the object to be able to perform the operation. See aws s3 download help for additional parameter options to ignore or force these transfers.
                                                              
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv back.csv

aws: [ERROR]: An error occurred (InvalidObjectState) when calling the GetObject operation: The operation is not valid for the object's storage class

Additional error details:
StorageClass: DEEP_ARCHIVE
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/instant.csv back.csv --query "[ContentLength,StorageClass]" --output text
10295	GLACIER_IR
```

**Two refusals and one answer.** `aws s3 cp` refused before downloading anything: it asked for the
object's metadata, saw an archive class, and skipped the file with a warning that calls Deep Archive
`GLACIER` too, the command line's word for both. `get-object` sent the request
anyway, and moto answered as S3 does, with `InvalidObjectState`. The Glacier Instant Retrieval copy
came back at once, all 10,295 bytes.

## The restore

A restore names how many days the readable copy should live and how fast to make it, the tier:

```
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv --restore-request "Days=2,GlacierJobParameters={Tier=Bulk}"
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv --query "[StorageClass,Restore]"
[
    "DEEP_ARCHIVE",
    "ongoing-request=\"false\", expiry-date=\"Sun, 18 Oct 2026 15:54:18 GMT\""
]
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv back.csv --query "[ContentLength,StorageClass]" --output text
10295	DEEP_ARCHIVE
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/deep2.csv --storage-class DEEP_ARCHIVE
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/deep2.csv
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/deep2.csv --restore-request "Days=1,GlacierJobParameters={Tier=Expedited}"
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --restore-request Days=1

aws: [ERROR]: An error occurred (InvalidObjectState) when calling the RestoreObject operation: The operation is not valid for the object's storage class

Additional error details:
StorageClass: STANDARD
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/instant.csv --restore-request Days=1

aws: [ERROR]: An error occurred (InvalidObjectState) when calling the RestoreObject operation: The operation is not valid for the object's storage class

Additional error details:
StorageClass: GLACIER_IR
```

**In moto the restore is finished before the next command**: `ongoing-request="false"` already, and
the `GET` that failed a moment ago succeeds. That is the largest gap between moto and S3 in this
lesson. On AWS the same `head-object` would print `ongoing-request="true"` for as long as the restore
takes, and every `GET` would still fail with `InvalidObjectState` until it finished. AWS documents
the speeds as:

| class | tier | the copy is ready in |
|---|---|---|
| Glacier Flexible Retrieval | Expedited | 1 to 5 minutes |
| Glacier Flexible Retrieval | Standard | 3 to 5 hours |
| Glacier Flexible Retrieval | Bulk | 5 to 12 hours |
| Deep Archive | Standard | within 12 hours |
| Deep Archive | Bulk | within 48 hours |

None of that was run here; it is the documented behaviour. **Deep Archive has no Expedited tier**, and
moto took the Expedited request above without complaint. S3 refuses it. A program that restores from
Deep Archive and is tested only against moto can ship with a tier S3 will never accept.

The restored copy is temporary. When its days run out the object is unreadable again, and for the
days it lives you pay for the archived object and the restored copy both. The object never leaves its
class: the `StorageClass` above still says `DEEP_ARCHIVE` after the restore. To bring it back for
good, restore it and then copy it onto itself in another class, as the previous section did.

**Asking for a restore of something that is not archived is refused**, as the last two commands
above show: the Standard copy and the Glacier Instant Retrieval copy both have nothing to restore.

## What the hours mean for a design

A restore measured in hours decides what may go in an archive class: data nobody needs this
afternoon. Quitanda's audit exports qualify, because an auditor's request comes with weeks of notice.
Last month's orders do not, because the finance team reruns a report on them whenever a number looks
wrong, and a report that waits twelve hours for its input is a report nobody waits for.
