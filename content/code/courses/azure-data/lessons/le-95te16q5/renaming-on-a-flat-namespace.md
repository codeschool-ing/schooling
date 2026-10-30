---
title: Renaming a folder that does not exist
version: 1
---

**On a flat namespace, renaming a folder means renaming every blob in it, one at a time.** Lesson 2
showed that a folder is the answer to a listing and not a thing; the consequence arrives the first
time somebody needs to move one. Blob Storage has no rename operation even for a single blob, so a
"move" is a copy to the new name followed by a delete of the old one, and a folder of a thousand
files is two thousand of those. This section counts them on Azurite, which has a flat namespace like
every account that does not ask for a hierarchical one.

The data is the kind a lake is full of. Quitanda's app sends click events, and the stream that
lands them (lesson 22) writes many small files a day. A thousand for 29 October, in a container
called `lake`:

`seed.py`:

```python
from concurrent.futures import ThreadPoolExecutor
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
lake = service.get_container_client("lake")
if not lake.exists():
    lake.create_container()


def put(n):
    lake.upload_blob(f"clicks/2026/10/29/part-{n:04d}.json", b'{"event": "view"}\n', overwrite=True)


with ThreadPoolExecutor(8) as pool:
    list(pool.map(put, range(1000)))
print(sum(1 for _ in lake.list_blobs(name_starts_with="clicks/")), "blobs under clicks/")
```

```
ana@laptop:~/azure$ python seed.py
1000 blobs under clicks/
```

The analysts want the day's directory called `date=2026-10-29`, the layout lesson 18 explains,
which query engines read as a column. The program that moves a prefix:

```schooling-example
{"language": "python", "file": "rename.py", "parts": [{"code": "import sys\nfrom azure.storage.blob import BlobServiceClient\n\nrequests = 0\n\n\ndef count(response):\n    global requests\n    requests += 1\n\n\nservice = BlobServiceClient.from_connection_string(\n    \"UseDevelopmentStorage=true\", raw_response_hook=count)\nlake = service.get_container_client(\"lake\")\n", "note": "`raw_response_hook` is called once for every answer the service sends back, so `requests` counts round trips to the service, which is what Azure bills operations by."}, {"code": "\nold, new = sys.argv[1], sys.argv[2]\nstop_after = int(sys.argv[3]) if len(sys.argv) > 3 else None\n", "note": "The old prefix and the new one come from the command line. The optional third argument makes the program stop after that many blobs, standing in for a crash."}, {"code": "\nmoved = 0\nfor item in lake.list_blobs(name_starts_with=old):\n    source = lake.get_blob_client(item.name)\n    target = lake.get_blob_client(new + item.name[len(old):])\n    copy = target.start_copy_from_url(source.url)\n    if copy[\"copy_status\"] != \"success\":\n        sys.exit(f\"{item.name}: copy is {copy['copy_status']}, source kept\")\n    source.delete_blob()\n    moved += 1\n    if moved == stop_after:\n        print(\"stopped after\", moved)\n        break\n", "note": "A flat namespace has no rename, so each blob is copied to its new name and then deleted. A copy inside one account usually finishes at once; when it answers `pending` instead, deleting the source would lose the data, so the program stops."}, {"code": "print(\"moved\", moved, \"blobs in\", requests, \"requests\")\n", "note": "The listing itself is requests too, one per page of up to 5,000 names."}]}
```

## A thousand files, stopped halfway

The first run stops after 400 blobs, as a crash or a lost connection would:

```
ana@laptop:~/azure$ python rename.py clicks/2026/10/29/ clicks/date=2026-10-29/ 400
stopped after 400
moved 400 blobs in 801 requests
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/2026/10/29/ --num-results 5000 --query "length(@)"
600
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/date=2026-10-29/ --num-results 5000 --query "length(@)"
400
```

**Both names are now in use at once.** 600 files are still under `clicks/2026/10/29/` and 400 are
under `clicks/date=2026-10-29/`, and the 400 moves cost 801 requests: the listing, 400 copies and
400 deletes. Any job that read the day in that moment read part of it. A job reading the old prefix
lost 400 files; a job reading the new one found less than half a day; and nothing in Blob Storage
says a move was in progress, because there is no move, only a long run of separate writes.

Run it again without the third argument and it finishes the job:

```
ana@laptop:~/azure$ python rename.py clicks/2026/10/29/ clicks/date=2026-10-29/
moved 600 blobs in 1201 requests
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/2026/10/29/ --num-results 5000 --query "length(@)"
0
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/date=2026-10-29/ --num-results 5000 --query "length(@)"
1000
```

The other 600 took 1,201 requests, the listing and two for each blob. **The whole rename was 2,002
requests**, two listings and two thousand writes, to change one word in a path. Azure bills
operations by the ten thousand, and at lake scale a day has hundreds of thousands of files rather
than a thousand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Renaming a directory of 1,000 files, two ways. On a flat namespace there is no directory: one listing, then a copy and a delete for each of the 1,000 blobs, 2,001 requests made one blob at a time, and a reader in between sees some files under each name. With a hierarchical namespace the directory 2026/10/29/ is an object of its own, and one rename moves it, with the 1,000 files under it, in a single operation.\" data-fig=\"l03-rename\"><defs><marker id=\"l03-rename-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"260\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">flat namespace</text><rect x=\"34\" y=\"62\" width=\"302\" height=\"22\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"44\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clicks/2026/10/29/part-0000.json</text><rect x=\"34\" y=\"92\" width=\"302\" height=\"22\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"44\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clicks/2026/10/29/part-0001.json</text><text x=\"185\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">…</text><rect x=\"34\" y=\"152\" width=\"302\" height=\"22\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"44\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clicks/2026/10/29/part-0999.json</text><text x=\"185\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 list</text><text x=\"185\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">+ 1,000 copies + 1,000 deletes</text><text x=\"185\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">= 2,001 requests, one blob at a time</text><text x=\"185\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a reader in between sees both names</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"260\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">hierarchical namespace</text><rect x=\"384\" y=\"62\" width=\"140\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"454\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">clicks/</text><rect x=\"404\" y=\"104\" width=\"140\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"474\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026/10/29/</text><line x1=\"424\" y1=\"88\" x2=\"424\" y2=\"103\" stroke=\"var(--wire)\" stroke-width=\"1.4\"/><rect x=\"424\" y=\"146\" width=\"180\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"514\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1,000 files</text><line x1=\"444\" y1=\"130\" x2=\"444\" y2=\"145\" stroke=\"var(--wire)\" stroke-width=\"1.4\"/><line x1=\"548\" y1=\"117\" x2=\"600\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rename-ah)\"/><rect x=\"602\" y=\"104\" width=\"90\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"647\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">date=…</text><text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">1 rename of one directory</text><text x=\"535\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the files under it move with it</text><text x=\"535\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a reader sees the old tree or the new</text></svg>", "caption": "The arithmetic on the left is what rename.py counted against Azurite, done in one run rather than two. The right is Microsoft's documented behaviour and was not run."}
```

## What it would take to do better on a flat namespace

Nothing makes this atomic. The defensive designs all avoid the rename instead: write each day into
its final name from the start, or write a new copy and switch readers to it with a small manifest
blob updated by the conditional write of lesson 2. Lake table formats such as Delta, in lesson 18,
take the second road and keep a log of which files belong to a table, so that "rename" never has to
touch a file at all.

The hierarchical namespace takes the other road. It makes the directory a real object that the
files hang from, so the same rename is one operation on one entry, atomic, whatever is under it.
The previous section described that from Microsoft's documentation; the next one shows what Azurite
says when it is asked.
