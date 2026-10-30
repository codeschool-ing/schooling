---
title: ETags and the write that checks first
version: 1
---

**By default the last write wins, silently.** Two programs that write the same blob a second apart
both succeed, and the blob holds whatever the second one sent. Nothing records that the first write
happened. That is fine for an export written once a night by one job, and wrong for anything two
writers share: a marker that says where the nightly job stopped, a small configuration file, a
manifest listing a table's files. The fix is to make each write say which version it expects to
replace, and let the service refuse it when the blob has moved on.

## The command line asks before it overwrites

`az storage blob upload` already refuses one case on its own:

```
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --no-progress 2>&1 | grep ErrorCode
ErrorCode:BlobAlreadyExists
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-none-match "*" --no-progress 2>&1 | grep ErrorCode
ErrorCode:BlobAlreadyExists
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-match "\"0x8D0000000000000\"" --no-progress 2>&1 | grep ErrorCode
ErrorCode:ConditionNotMet
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-match "$(az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv)" --no-progress -o none && echo written
written
```

**Without `--overwrite`, the command line refuses to replace a blob that exists**, which is the same
refusal that `--if-none-match "*"` asks for explicitly: write only if nothing is there. The libraries
default the same way, and that is why every program in this lesson passes `overwrite=True` when it
means it. The second pair of commands is the other condition. `--if-match` carries an ETag, the write
succeeds only if the blob still has it, and the made-up one was refused with `ConditionNotMet`. The
command that passed read the current ETag first and handed it straight back, which is the whole
pattern in one line.

## Two copies of the same job

The story the condition exists for: Quitanda's nightly export keeps a marker blob saying which night
it exported last. One night the scheduled run is slow, somebody starts a retry by hand, and both
copies read the marker before either writes it.

```schooling-example
{"language": "python", "file": "etag.py", "parts": [{"code": "from azure.core import MatchConditions\nfrom azure.core.exceptions import ResourceModifiedError\nfrom azure.storage.blob import BlobServiceClient\n\nservice = BlobServiceClient.from_connection_string(\"UseDevelopmentStorage=true\")\nmarker = service.get_blob_client(\"orders-raw\", \"control/last-export.txt\")\nmarker.upload_blob(b\"2026-10-29\\n\", overwrite=True)\n", "note": "The marker is a one-line blob saying which night was exported last. The nightly job reads it to know where to start, and writes it when it finishes."}, {"code": "\nseen_by_a = marker.get_blob_properties().etag\nseen_by_b = marker.get_blob_properties().etag\nprint(\"both copies read\", seen_by_a)\n", "note": "Two copies of the job, the scheduled run and a retry somebody started by hand, read the marker within a second of each other. Each keeps the ETag it saw."}, {"code": "\nmarker.upload_blob(b\"2026-10-30\\n\", overwrite=True,\n                   etag=seen_by_a, match_condition=MatchConditions.IfNotModified)\nprint(\"A wrote, and the ETag is now\", marker.get_blob_properties().etag)\n", "note": "Copy A writes on condition that the blob still carries the ETag it read. It does, so the write succeeds and the blob gets a new ETag."}, {"code": "\ntry:\n    marker.upload_blob(b\"2026-10-31\\n\", overwrite=True,\n                       etag=seen_by_b, match_condition=MatchConditions.IfNotModified)\nexcept ResourceModifiedError as refusal:\n    print(\"B was refused:\", refusal.status_code, refusal.error_code)\nprint(\"the marker says\", marker.download_blob().readall().decode(), end=\"\")\n", "note": "Copy B sends the same condition with the ETag it read before A wrote. The service compares, refuses with 412, and nothing is written. Without the condition, B's write would have replaced A's in silence."}], "output": "both copies read \"0x261450520A0CB40\"\nA wrote, and the ETag is now \"0x1F27705FF331080\"\nB was refused: 412 StorageErrorCode.CONDITION_NOT_MET\nthe marker says 2026-10-30\n"}
```

Run it with `python etag.py`; the output is under the program.

**Copy B was refused with 412, the HTTP status for a failed precondition**, and `ConditionNotMet`
is Blob Storage's name for it, printed by the library as `StorageErrorCode.CONDITION_NOT_MET`. The marker says `2026-10-30`, which is what copy A wrote. Without
`etag=` and `match_condition=`, copy B's write would have succeeded and the marker would say
`2026-10-31`, a night that has not been exported. The refusal is not an error to retry blindly. It
means *somebody else changed this since you read it*, and the right response is to read it again and
decide whether your write still makes sense. This is called optimistic concurrency: nothing is
locked, and the rare collision is caught at the moment of writing.

## The lock, when you need one

**A lease is the pessimistic version: a lock on the blob, held by whoever acquired it.** While the
lease is held, a write that does not present the lease id is refused, whoever sends it:

```
ana@laptop:~/azure$ az storage blob lease acquire -c orders-raw -b control/last-export.txt --lease-duration 15 -o tsv | wc -c
37
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n control/last-export.txt -f export/orders-2026-10-28.csv --overwrite --no-progress 2>&1 | grep ErrorCode
ErrorCode:LeaseIdMissing
```

`lease acquire` returned a lease id, 36 characters plus the newline that `wc -c` counted. The upload
without it was refused with `LeaseIdMissing`. According to Microsoft's documentation a lease lasts
from 15 to 60 seconds or is infinite, and a finite one has to be renewed before it runs out. A lease
fits a job that must be the only writer for a long stretch. For a marker read and written in a
second, the ETag condition is simpler, and nothing is left locked when a program crashes holding it.
