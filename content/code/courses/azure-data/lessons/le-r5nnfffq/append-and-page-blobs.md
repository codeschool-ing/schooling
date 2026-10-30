---
title: Append blobs for logs, page blobs for disks
version: 1
---

**An append blob accepts one kind of write: a block added at its end.** No block can be replaced,
reordered or removed afterwards, and every append is readable the moment it is acknowledged, with no
commit step. That is the shape of a log, and it is what append blobs are for. Quitanda's checkout
service writes a line for each thing that happens to a cart, and the program below keeps those lines
in one blob per day:

`applog.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
log = service.get_blob_client("app-logs", "checkout/2026-10-30.log")
if not service.get_container_client("app-logs").exists():
    service.create_container("app-logs")
if not log.exists():
    log.create_append_blob()

for event in ["cart c-17 opened", "cart c-17 paid 4590", "cart c-03 opened"]:
    answer = log.append_block(f"{event}\n".encode())
    print("appended at offset", answer["blob_append_offset"],
          "- blocks so far:", answer["blob_committed_block_count"])
print(log.download_blob().readall().decode(), end="")
```

Run it twice:

```
ana@laptop:~/azure$ python applog.py
appended at offset 0 - blocks so far: 1
appended at offset 17 - blocks so far: 2
appended at offset 37 - blocks so far: 3
cart c-17 opened
cart c-17 paid 4590
cart c-03 opened
ana@laptop:~/azure$ python applog.py
appended at offset 54 - blocks so far: 4
appended at offset 71 - blocks so far: 5
appended at offset 91 - blocks so far: 6
cart c-17 opened
cart c-17 paid 4590
cart c-03 opened
cart c-17 opened
cart c-17 paid 4590
cart c-03 opened
```

**The second run did not start a new file.** The blob existed, so the program skipped
`create_append_blob` and its three appends went after the first three: offsets 54, 71 and 91,
block counts 4 to 6. Each append is one request, and the answer says where in the blob it landed.
Two programs appending to the same blob at once interleave their lines without overwriting each
other, which is the property a shared log needs.

Microsoft's documentation limits an append blob to 50,000 appended blocks. A program that appends
one line per request reaches that in a busy afternoon, so real loggers gather lines and append them
in batches.

## Append-only is not protection

The type fixes which operations the blob accepts; it says nothing about who may delete it or
replace it. An upload with `--overwrite` does not append. It replaces the whole blob with a new one,
of whatever type the upload creates:

```
ana@laptop:~/azure$ az storage blob upload -c app-logs -n checkout/2026-10-30.log -f export/orders-2026-10-27.csv --overwrite --no-progress -o none
ana@laptop:~/azure$ az storage blob show -c app-logs -n checkout/2026-10-30.log --query "[properties.blobType, properties.contentLength]" -o tsv
BlockBlob
64
ana@laptop:~/azure$ python applog.py 2>&1 | grep ErrorCode
ErrorCode:InvalidBlobType
```

The six log lines are gone, the blob is now a block blob holding a CSV, and the next run of the
logger fails on its first append with `InvalidBlobType`, because a block blob does not accept
appends. A log that must not be rewritten needs the immutability policies of lesson 5, which refuse
the overwrite itself.

## Page blobs

**A page blob is a fixed-size array of 512-byte pages, and any page can be written at any time.**
That is how a disk behaves, and it is what page blobs exist for: the disks of Azure's virtual
machines are stored as page blobs. A data platform seldom creates one, and meets them mostly as a
line on a storage bill it did not expect. Their size is declared up front and must be a multiple of
512 bytes:

`pages.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
if not service.get_container_client("disks").exists():
    service.create_container("disks")
disk = service.get_blob_client("disks", "vm-01.vhd")

for size in (1000, 1024):
    try:
        disk.create_page_blob(size)
        print("created with", size, "bytes")
    except Exception as refusal:
        print(size, "bytes refused:", refusal.error_code)

try:
    disk.upload_page(b"x" * 100, offset=0, length=100)
except ValueError as refusal:
    print("100 bytes refused before sending:", refusal)

disk.upload_page(b"\x01" * 512, offset=512, length=512)
written, cleared = disk.get_page_ranges()
print("written ranges:", written)
data = disk.download_blob().readall()
print(len(data), "bytes; first page", data[:4], "second page", data[512:516])
```

```
ana@laptop:~/azure$ python pages.py
1000 bytes refused: StorageErrorCode.INVALID_OPERATION
created with 1024 bytes
100 bytes refused before sending: length must be an integer that aligns with 512 page size
written ranges: [{'start': 512, 'end': 1023}]
1024 bytes; first page b'\x00\x00\x00\x00' second page b'\x01\x01\x01\x01'
```

Two refusals, then the write that works. **Azurite refused a size of 1,000 bytes** with the code
`InvalidOperation`, which the library prints as its own constant, `StorageErrorCode.INVALID_OPERATION`,
because 1,000 is not a multiple of 512. The 100-byte write never left the computer:
the library checked the alignment itself and raised a `ValueError`, which is why that line has a
Python message rather than an error code. The aligned write landed on the second page. The blob is
1,024 bytes long, the service reports one written range, bytes 512 to 1023, and the page nobody wrote
reads back as zeros. **Only written pages are billed on a standard account**, according to
Microsoft's documentation, which is why a 1 TB disk that is mostly empty does not cost a terabyte.
The documented maximum size of a page blob is 8 TiB.
