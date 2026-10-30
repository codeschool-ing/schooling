---
title: Block blobs: staged, then committed
version: 1
---

**A block blob is a list of blocks, and it changes only when a new list is committed.** People
picture an upload as bytes flowing into a file that grows until the transfer ends. Blob Storage does
not work that way. The client sends blocks, each with an id, and they sit beside the blob, staged and
invisible. Then one more request, the commit, names the blocks in order, and at that instant the blob
becomes that list. A reader sees the old blob or the new one, never half of either.

The program below writes the export for 30 October in three blocks, one line each, and asks the
service what it holds between the steps:

```schooling-example
{"language": "python", "file": "blocks.py", "parts": [{"code": "import base64\nfrom azure.storage.blob import BlobServiceClient, BlobBlock\n\nservice = BlobServiceClient.from_connection_string(\"UseDevelopmentStorage=true\")\nblob = service.get_blob_client(\"orders-raw\", \"exports/2026/10/orders-2026-10-30.csv\")\n\n\ndef block_id(n):\n    return base64.b64encode(f\"{n:06d}\".encode()).decode()\n", "note": "The connection string is the one every terminal exports, spelt out so that the program needs nothing else. A block id is any string of up to 64 bytes, base64-encoded, and every id in one blob has to be the same length, which is why the number is padded to six digits."}, {"code": "\n\nparts = [b\"order_id,customer_id,total_cents\\n\", b\"30-1,c-17,4590\\n\", b\"30-2,c-03,12800\\n\"]\nfor n, data in enumerate(parts):\n    blob.stage_block(block_id(n), data)\ncommitted, uncommitted = blob.get_block_list(\"all\")\nprint(\"staged:\", len(committed), \"committed,\", len(uncommitted), \"uncommitted\")\nprint(\"exists before the commit:\", blob.exists())\n", "note": "Three blocks are staged, one request each. A real upload stages blocks of megabytes, several at a time from several threads; these hold one line of CSV each so that the output fits on a screen."}, {"code": "\nblob.commit_block_list([BlobBlock(block_id=block_id(n)) for n in range(3)])\ncommitted, uncommitted = blob.get_block_list(\"all\")\nprint(\"after the commit:\", [b.id for b in committed], len(uncommitted), \"uncommitted\")\nprint(blob.download_blob().readall().decode(), end=\"\")\n", "note": "The commit is one request naming the blocks in the order the blob should hold them. Only now does the blob exist, and all of it at once."}, {"code": "\nblob.stage_block(block_id(2), b\"30-2,c-03,12900\\n\")\nblob.commit_block_list([BlobBlock(block_id=block_id(n)) for n in range(3)])\nprint(blob.download_blob().readall().decode(), end=\"\")\n", "note": "Staging a block under an id the blob already uses, and committing the same list again, replaces that block and keeps the other two. The first two blocks were not sent a second time."}], "output": "staged: 0 committed, 3 uncommitted\nexists before the commit: False\nafter the commit: ['MDAwMDAw', 'MDAwMDAx', 'MDAwMDAy'] 0 uncommitted\norder_id,customer_id,total_cents\n30-1,c-17,4590\n30-2,c-03,12800\norder_id,customer_id,total_cents\n30-1,c-17,4590\n30-2,c-03,12900\n"}
```

Run it with `python blocks.py`. The output is under the program: **before the commit, the blob does
not exist**, although three blocks are already stored for it. After the commit the block list names
three committed blocks and no uncommitted ones, and the CSV comes back whole. The last part changed
one total from 12800 to 12900 by sending sixteen bytes; the header and the first order stayed where
they were.

That is what makes a block blob safe for the nightly export. A job that crashes halfway through a
large upload leaves staged blocks and an untouched blob, so whoever reads `orders-2026-10-30.csv`
the next morning reads the last complete version or nothing. Microsoft's documentation says staged
blocks that are never committed are discarded after a week, so a failed upload costs storage only
for that long.

## The library cuts the file for you

Nobody writes `stage_block` for an ordinary upload. The Python library and the command line decide
for themselves: a file below a threshold goes up in a single request, and a larger one is cut into
blocks, staged several at a time and committed at the end. Both thresholds are settings of the client:

`split.py`:

```python
from azure.storage.blob import BlobServiceClient

rows = b"".join(f"{i},c-{i % 97:02d},{i * 37 % 20000}\n".encode() for i in range(40000))
print(len(rows), "bytes")

default = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
print("defaults:", default._config.max_single_put_size, default._config.max_block_size)

small = BlobServiceClient.from_connection_string(
    "UseDevelopmentStorage=true", max_single_put_size=256 * 1024, max_block_size=256 * 1024)
blob = small.get_blob_client("orders-raw", "exports/2026/10/big.csv")
blob.upload_blob(rows, overwrite=True)
committed, _ = blob.get_block_list("committed")
print(len(committed), "blocks:", [b.size for b in committed])
```

```
ana@laptop:~/azure$ python split.py
646670 bytes
defaults: 67108864 4194304
3 blocks: [262144, 262144, 122382]
```

The library's defaults, printed on the second line, are a single request up to 64 MiB and blocks of
4 MiB above that. `_config` is a private attribute, read here only to print the numbers; the
supported way to change them is the two arguments the program passes. With 256 KiB for both, the
646,670 bytes went up as two full blocks of 262,144 bytes and a last one with the remainder.

**Documented limits** for a block blob, from Microsoft's page on block, append and page blobs: up to
50,000 committed blocks, each up to 4,000 MiB, which puts the largest blob at about 190.7 TiB. None
of that is reachable in the lab or worth trying. What is worth knowing is the first number: a
program that uploads a 300 GB file in 4 MiB blocks needs 76,800 blocks, more than a blob may hold,
and fails at the commit. A program that moves files that large sets a larger block size, and a
program that sets `max_block_size` small for a test should not keep that setting in production.
