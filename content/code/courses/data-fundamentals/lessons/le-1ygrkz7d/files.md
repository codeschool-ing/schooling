---
title: Files, and knowing when one has finished arriving
version: 1
---

**A file is the oldest way two companies hand each other data, and its one hard question is whether it
has finished arriving.** Roda Livre's bicycles are repaired by a contractor, whose system exports the
day's repairs as a CSV every night and drops it where Roda Livre can read it. Two places are common: a
directory on a server, reached over SFTP, or a bucket in object storage, which `cloud` covers. Davi's
side checks the place on a schedule and loads whatever it finds.

The wrong picture is that a file which exists is a file which is complete. A file appears the moment
its writer opens it, and grows while the writer works. **A file still being written and a file whose
writer died halfway look exactly the same from outside**: same name, same place, some rows. A reader
that loads whatever it finds will one day load half a night.

## The marker goes last

The usual answer is an agreement between writer and reader: the writer writes the data first and
something else **last**, and the reader touches nothing until that last thing exists. Spark and Hadoop
write an empty file called `_SUCCESS` beside their output when a job finishes. A **manifest** says more:
which files belong to the delivery, how many rows they hold, and a checksum of their bytes, so the
reader can check that what it read is what was written.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"A timeline of two exports. The first writes rides.csv and then manifest.json. The second writes part of rides.csv and stops. A reader checks twice: the first time both show some rows and no manifest; the second time only the first has a manifest.\" data-fig=\"drop\"><defs><marker id=\"drop-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the export that finishes</text><rect x=\"130\" y=\"44\" width=\"330\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rides.csv, growing</text><rect x=\"480\" y=\"44\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">manifest.json</text><text x=\"130\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the export that dies</text><rect x=\"130\" y=\"110\" width=\"200\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rides.csv, growing</text><rect x=\"340\" y=\"110\" width=\"120\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the writer stops</text><line x1=\"290\" y1=\"24\" x2=\"290\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><line x1=\"650\" y1=\"24\" x2=\"650\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"290\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">first check</text><text x=\"290\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">both: some rows, no manifest</text><text x=\"706\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">second check</text><text x=\"706\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one has a manifest, one never will</text><line x1=\"130\" y1=\"224\" x2=\"700\" y2=\"224\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#drop-ah)\"></line><text x=\"122\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">time</text></svg>", "caption": "At the first check the two exports cannot be told apart: each has left part of a file and no manifest. Only the export that finishes ever writes the marker."}
```

There is a second convention for a single file: write it under a temporary name and rename it when it
is complete, because on one filesystem a rename happens all at once. Object storage has no rename, which
is one reason the marker is the convention there.

## Half a night, loaded

This program stands in for the contractor's export. It writes a thousand rows, then a manifest with the
row count and a SHA-256 checksum of the data. Given a number, it stops after that many bytes, which is
how the lab stages a writer that dies:

```schooling-example
{"language": "python", "file": "sources/export.py", "parts": [
{"code": "# sources/export.py\nimport hashlib\nimport json\nimport os\nimport sys\n\n"},
{"code": "DAY = \"drop/2025-09-15\"\ncrash_at = int(sys.argv[1]) if len(sys.argv) > 1 else None   # a byte count, to stage a crash\nos.makedirs(DAY, exist_ok=True)\nif os.path.exists(f\"{DAY}/manifest.json\"):\n    os.remove(f\"{DAY}/manifest.json\")          # the old marker goes first\n\n", "note": "One day's directory. A manifest left by an earlier run is removed first, so a crash this time cannot be mistaken for the success of last time."},
{"code": "lines = [\"ride_id,bike_id,station,minutes\\n\"]\nfor n in range(1, 1001):\n    lines.append(f\"R{n:06d},B{n % 90 + 1:03d},ST{n % 12 + 1:02d},{n % 50 + 3}\\n\")\ndata = \"\".join(lines).encode()\n\n", "note": "A thousand generated rows, held in memory as bytes."},
{"code": "with open(f\"{DAY}/rides.csv\", \"wb\") as f:\n    f.write(data[:crash_at])\nif crash_at is not None:\n    sys.exit(f\"export stopped after {crash_at} bytes\")\n\n", "note": "The data goes first. `data[:None]` is all of it; a number cuts it short, partway through a row, and the program stops there, as a crashed writer would."},
{"code": "manifest = {\"file\": \"rides.csv\", \"rows\": 1000, \"sha256\": hashlib.sha256(data).hexdigest()}\nwith open(f\"{DAY}/manifest.json\", \"w\") as f:\n    json.dump(manifest, f)\nprint(\"wrote rides.csv, then manifest.json\")\n", "note": "The manifest goes last, and only if everything before it worked: the file it describes, its row count and the SHA-256 of its bytes."}
]}
```

The loader reads the file. With `--careful` it first insists on the manifest and on the checksum:

```python
# sources/load.py
import csv
import hashlib
import json
import os
import sys

DAY = "drop/2025-09-15"
data = open(f"{DAY}/rides.csv", "rb").read()
if "--careful" in sys.argv:
    if not os.path.exists(f"{DAY}/manifest.json"):
        sys.exit("no manifest.json yet: the export is not finished, loading nothing")
    manifest = json.load(open(f"{DAY}/manifest.json"))
    if hashlib.sha256(data).hexdigest() != manifest["sha256"]:
        sys.exit("rides.csv does not match its manifest, loading nothing")
rows = list(csv.DictReader(data.decode().splitlines()))
print(len(rows), "rows loaded, the last one:", rows[-1])
```

Stage the crash, load the way a hurried reader does, then load carefully:

```
ana@lab:~/roda/sources$ python export.py 15000
export stopped after 15000 bytes
ana@lab:~/roda/sources$ python load.py
718 rows loaded, the last one: {'ride_id': 'R000718', 'bike_id': 'B089', 'station': 'ST', 'minutes': None}
ana@lab:~/roda/sources$ python load.py --careful
no manifest.json yet: the export is not finished, loading nothing
```

The plain load took 718 rows of a thousand and printed no error. Its last row is the one the writer
was in the middle of: the station is `ST`, which is no station, and `minutes` is `None`, because
`csv.DictReader` fills a short line's missing columns with `None` rather than complaining. The careful load looked for the marker first, did not
find it, and loaded nothing.

Now the export that finishes:

```
ana@lab:~/roda/sources$ python export.py
wrote rides.csv, then manifest.json
ana@lab:~/roda/sources$ python load.py --careful
1000 rows loaded, the last one: {'ride_id': 'R001000', 'bike_id': 'B011', 'station': 'ST05', 'minutes': '3'}
ana@lab:~/roda/sources$ ls drop/2025-09-15
manifest.json
rides.csv
```

A thousand rows, and the last one complete. Loading nothing on the first morning is a late report,
which somebody notices and asks about. Loading 718 rows is a report that is quietly wrong, which nobody
asks about. **The careful loader chooses the failure that somebody will notice.**

The checksum earns its line on a different day: a file copied with its end cut off, or rewritten after
its manifest was made. Neither happened here, and the manifest also says how many rows to expect,
which lesson 7 uses to count a delivery against what was promised.
