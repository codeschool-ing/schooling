---
title: Small objects, counted
version: 1
---

**Many small objects make every operation-priced thing expensive and every byte-priced thing cheap**,
and a design that writes one object per event picks the expensive side without noticing. The
storage of two million 4 KiB objects is the storage of 7.6 GiB. Their operations are the operations
of two million objects, every time anybody writes them, lists them, reads them or moves them to
another class.

That is easier to believe once you have counted the requests a command makes, and the emulator is
the one place in this course where you can. **fake-gcs-server logs one line per request it
answers**: the method, the path and the status. In its terminal, stop it with `Ctrl+C` and start it
again with its output copied into a file as well as onto the screen:

```sh
cd ~/gcp && export PATH="$HOME/gcp/bin:$PATH"
fake-gcs-server -scheme http -port 4443 -backend memory -location southamerica-east1 2>&1 | tee -a requests.log
```

The emulator writes its log to standard error, which the `2>&1` joins to the output, and `tee -a`
appends each line to `requests.log` in `~/gcp`. **The `-a` matters**: it is what lets you empty the
file between two experiments with `: > requests.log` and have the next line land at the start of it.
Restarting the emulator forgets every bucket, as lesson 1 said, so the buckets of this lesson are
created again below.

## A program that reads the log

Save this as `~/gcp/count.py`. It puts each logged request in the class the pricing page gives its
method, and prices the ones that were answered:

```schooling-example
{"language": "python", "file": "count.py", "parts": [{"code": "\"\"\"Count the requests in fake-gcs-server's log, and price them.\"\"\"\nimport re\nimport sys\nfrom collections import Counter\n\n# USD per operation, Standard class, a bucket in one region\nPRICE = {'A': 0.005 / 1000, 'B': 0.0004 / 1000, 'free': 0.0}\nREQUEST = re.compile(r'\\\\\"([A-Z]+) (/[^ ?]*)\\S* HTTP/1\\.1\\\\\" (\\d{3})')\n\n\n", "note": "**The prices are the Standard class's, for a bucket in one region**, from the operations table of the pricing page, divided by 1,000 because the page prints them per thousand. `REQUEST` picks the method, the path and the status out of each line the emulator logs."}, {"code": "def operation(method, path):\n    \"\"\"The JSON API method a request is, and its class.\"\"\"\n    parts = path.strip('/').split('/')\n    if parts[0] == 'upload':\n        return 'objects.insert', 'A'\n    if parts[0] == 'download':\n        return 'objects.get, data', 'B'\n    tail = parts[3:]\n    if method == 'DELETE':\n        return 'delete', 'free'\n    if not tail:\n        return ('buckets.insert' if method == 'POST' else 'buckets.list'), 'A'\n    if len(tail) == 1:\n        return ('buckets.patch', 'A') if method == 'PATCH' else ('buckets.get', 'B')\n    if tail[1] == 'storageLayout':\n        return 'buckets.getStorageLayout', 'B'\n    if tail[1] == 'o' and len(tail) == 2:\n        return 'objects.list', 'A'\n    if tail[1] == 'o' and len(tail) == 3:\n        return 'objects.get, metadata', 'B'\n    return path, '?'\n\n\n", "note": "Each path of the JSON API is one method, and the pricing page puts each method in a class. **Writing and listing are Class A; reading data or metadata is Class B; deleting is free.** A path this table does not know comes out with a `?` rather than a guess."}, {"code": "seen = Counter()\nfor line in open(sys.argv[1]):\n    m = REQUEST.search(line)\n    if m:\n        method, path, status = m.groups()\n        name, cls = operation(method, path)\n        answer = 'ok' if status.startswith('2') else status\n        seen[cls, name, answer] += 1\n\n\n", "note": "One count per class, method and answer. A request that was refused is kept apart, because the pricing page says that a request answered with a 4xx or a 5xx is generally not charged."}, {"code": "usd = 0.0\nfor (cls, name, answer), n in sorted(seen.items()):\n    if answer == 'ok':\n        usd += n * PRICE.get(cls, 0.0)\n    print(f'{n:>5}  class {cls:<4}  {name:<26} {answer}')\nprint(f'USD {usd:.6f}, for the requests answered ok')\n", "note": "A line per kind of request, and the price of the ones that were answered. The sum is in millionths of a dollar for a run this small, which is the point: the count is what scales, and the next program scales it."}]}
```

## Twenty taps, one at a time and packed

Quitanda's app sends an event for every tap a customer makes, a few dozen bytes of JSON. Twenty of
them, as twenty files, uploaded with one command:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ mkdir -p taps && for i in $(seq -w 1 20); do printf "{\"tap\":%d,\"screen\":\"cart\"}\n" $((10#$i)) > taps/tap-$i.json; done && ls taps | head -3
tap-01.json
tap-02.json
tap-03.json
ana@laptop:~/gcp$ : > requests.log
ana@laptop:~/gcp$ gcloud storage cp --no-user-output-enabled taps/*.json gs://quitanda-raw-prod/raw/taps/dt=2026-10-01/
ana@laptop:~/gcp$ python3 count.py requests.log
   20  class A     objects.insert             ok
    1  class A     objects.list               ok
   40  class B     buckets.getStorageLayout   404
    1  class B     objects.get, metadata      404
USD 0.000105, for the requests answered ok
```

**Twenty files are twenty `objects.insert`, one per object**, and `gcloud` added a listing of its own
to check what was already under the destination. Those 21 are Class A, and they are the bill:
21 × 0.005 / 1,000 = 0.000105. The 41 refused requests are the client asking questions the emulator
cannot answer. `buckets.getStorageLayout` is how `gcloud storage` asks whether a bucket has a
hierarchical namespace before it writes, twice per file here, and **fake-gcs-server does not implement
it, so it answers 404**. Cloud Storage implements it and answers 200, and the pricing page lists it
in Class B, so on a real bucket those 40 would be billed at the cheap rate. A count taken against an
emulator is a floor, not a measurement.

The same twenty lines, packed into one file first:

```
ana@laptop:~/gcp$ : > requests.log && cat taps/*.json > taps.jsonl && gcloud storage cp --no-user-output-enabled taps.jsonl gs://quitanda-raw-prod/raw/taps-packed/dt=2026-10-01/
ana@laptop:~/gcp$ python3 count.py requests.log
    1  class A     objects.insert             ok
    1  class A     objects.list               ok
    2  class B     buckets.getStorageLayout   404
    1  class B     objects.get, metadata      404
USD 0.000010, for the requests answered ok
```

**Two Class A instead of twenty-one**, for the same bytes. The difference is a tenth of a cent at
twenty taps, and the same ratio at two million.

## Reading them back, and listing them

A dashboard that wants yesterday's taps has to find them and then read them:

```
ana@laptop:~/gcp$ : > requests.log && gcloud storage cat 'gs://quitanda-raw-prod/raw/taps/dt=2026-10-01/*.json' | wc -l
20
ana@laptop:~/gcp$ python3 count.py requests.log
    1  class A     objects.list               ok
   21  class B     buckets.getStorageLayout   404
   20  class B     objects.get, data          ok
USD 0.000013, for the requests answered ok
ana@laptop:~/gcp$ : > requests.log && gcloud storage cat gs://quitanda-raw-prod/raw/taps-packed/dt=2026-10-01/taps.jsonl | wc -l
20
ana@laptop:~/gcp$ python3 count.py requests.log
    2  class B     buckets.getStorageLayout   404
    1  class B     objects.get, data          ok
    1  class B     objects.get, metadata      ok
USD 0.000001, for the requests answered ok
```

**The wildcard is a listing**: Cloud Storage has no "read everything under this prefix" request, so
`gcloud` lists the prefix, one Class A, and then reads each object it found, twenty Class B. The
packed file is two Class B, its metadata and then its data. The pricing page warns about exactly
this, that a tool may use two or more operations to do what looks like one, and the log is how you
find out how many.

```
ana@laptop:~/gcp$ : > requests.log && gcloud storage ls gs://quitanda-raw-prod/raw/taps/dt=2026-10-01/ | wc -l
20
ana@laptop:~/gcp$ python3 count.py requests.log
    2  class A     objects.list               ok
    1  class B     objects.get, metadata      404
USD 0.000010, for the requests answered ok
```

**Two listings to print twenty names.** `gcloud storage ls` lists the prefix as written and again
with the trailing slash, and a listing is Class A whatever it returns. A prefix of two million names
is two thousand pages of a thousand, two thousand Class A per pass.

## The same arithmetic at Quitanda's size

Quitanda's app sends 2 million taps a month, about 4 KiB each once they carry the device, the session
and the screen. The first design writes each one as its own object, and a dashboard reads all of
them every morning to draw the last month. Save this as `~/gcp/reads.py`; it prices that design and
three others, from the pages:

```schooling-example
{"language": "python", "file": "reads.py", "parts": [{"code": "\"\"\"What reading costs against what storing costs, Cloud Storage in southamerica-east1.\"\"\"\nimport math\n\n# USD, from cloud.google.com/storage/pricing and /cdn/pricing, read 2026-10-30\nSTORE = 0.035            # Standard, per GiB-month, southamerica-east1\nA = 0.005 / 1000         # Class A: insert, list, copy, rewrite, compose\nB = 0.0004 / 1000        # Class B: get, data or metadata\nOUT = [(10_240, 0.12), (143_360, 0.11), (None, 0.08)]   # to the internet\nCDN_OUT = [(10_240, 0.09), (143_360, 0.06), (870_400, 0.05), (None, 0.04)]\nCDN_FILL = 0.02          # per GiB, from a bucket in South America\nCDN_LOOKUP = 0.0075 / 10_000\nDAYS = 30\n\n\n", "note": "**Every price is a line of a pricing page**, with the region where the page has one. `OUT` is the internet tiers of Cloud Storage, each a number of GiB and its price: the first 10 TiB, the next 140, then the rest. `CDN_OUT` is Cloud CDN's own staircase for viewers in South America."}, {"code": "def tiers(gib, table):\n    \"\"\"USD for gib in one month, tier by tier.\"\"\"\n    usd, left = 0.0, gib\n    for size, price in table:\n        step = left if size is None else min(left, size)\n        usd += step * price\n        left -= step\n        if left <= 0:\n            break\n    return usd\n\n\n", "note": "A tiered price is a staircase and not one rate: the first 10,240 GiB of the month at 0.12, the next 143,360 at 0.11. Each step takes as much of what is left as its tier holds."}, {"code": "def gib(objects, kib):\n    return objects * kib / 1024 / 1024\n\n\ndef show(name, stored, requests, out):\n    store = stored * STORE\n    print(f'{name:<34}{store:>9,.2f}{requests:>10,.2f}{out:>11,.2f}'\n          f'{store + requests + out:>11,.2f}')\n\n\n", "note": "A count of objects of a size in KiB, as GiB. And one line of the table: a month of storage, the month's requests in dollars, the month's transfer, and their sum."}, {"code": "taps = gib(2_000_000, 4)\nfiles = math.ceil(taps * 1024 / 64)\npages = math.ceil(2_000_000 / 1000)\nprint(f'{\"a month\":<34}{\"storage\":>9}{\"requests\":>10}{\"transfer\":>11}{\"total\":>11}')\nshow('2M taps of 4 KiB, read daily', taps,\n     (2_000_000 + pages * DAYS) * A + 2_000_000 * DAYS * B, 0)\nshow(f'the same, in {files} files of 64 MiB', taps,\n     (files + DAYS) * A + files * DAYS * B, 0)\n\n\n", "note": "**The taps are written once in the month and read once a day.** Reading them means listing the prefix first, a thousand names a page, which is Class A, and then one `GET` per object, which is Class B. Packed into 64 MiB files, the same bytes are 123 objects."}, {"code": "downloads = 20 * 1024 * 1024 * 1024 // 400\nmisses = downloads // 20\nshow('500 GiB of images, 20 TiB out', 500, downloads * B, tiers(20_480, OUT))\nshow('the same behind Cloud CDN', 500,\n     misses * B + downloads * CDN_LOOKUP,\n     tiers(20_480, CDN_OUT) + 1_024 * CDN_FILL)\n", "note": "Quitanda's product images: a library of 500 GiB from which 20 TiB a month is downloaded, in files of 400 KiB. Behind Cloud CDN, 19 downloads in 20 are answered from its cache, and every download is a cache lookup."}]}
```

```
ana@laptop:~/gcp$ python3 reads.py
a month                             storage  requests   transfer      total
2M taps of 4 KiB, read daily           0.27     34.30       0.00      34.57
the same, in 123 files of 64 MiB       0.27      0.00       0.00       0.27
500 GiB of images, 20 TiB out         17.50     21.47   2,355.20   2,394.17
the same behind Cloud CDN             17.50     41.34   1,556.48   1,615.32
```

**The dashboard's month is 34.57, of which 0.27 is storage.** The rest is requests: 2,000,000
inserts at 0.005 a thousand is 10.00; the morning listing, 2,000 pages for 30 days, is 0.30; and
2,000,000 reads a day for 30 days is 60 million at 0.0004 a thousand, 24.00. Reading and writing cost
128 times what keeping does, and nothing about the data changed except how it was cut up.

**Packing the taps into 64 MiB files takes the requests to 0.00**: 123 files, written once and read
123 times a day, cost fractions of a cent, for the same 7.63 GiB. This is one reason data lakes keep
their files large, and lesson 17 meets the same pressure from BigQuery's side, when a query reads
files straight out of a bucket and every small file is one more to open.

## Where small objects come from

Nobody designs two million tiny files on purpose. They arrive:

- **from streams**, where something writes whatever arrived in the last few seconds, which lessons 21
  and 22 meet with Dataflow and its windows;
- **from partitions too fine for the data**, a prefix per hour per customer, each holding a file of a
  few rows;
- **from one-object-per-record designs**, the tap above, convenient to write and ruinous to read.

The cure is the same each time: write fewer, larger objects, or join the small ones into large ones
on a schedule. Cloud Storage has a request for the second, `objects.compose`, which joins up to 32
objects into one without downloading them, at one Class A per call. And the colder classes of lesson
2 punish small objects twice: every read of a 4 KiB tap kept in Coldline is a Class B at 0.01 a
thousand, twenty-five times Standard's, before its retrieval fee.

## Moving them to a colder class is an operation too

**Changing an object's class is a Class A operation, billed at the rate of the class it moves to.**
The pricing page says so in a footnote, and adds that it applies when a life-cycle rule of lesson 3
does the moving, with a warning that this has a large effect on a bill where most objects are under
1 MB. For the taps, the arithmetic is short:

```
ana@laptop:~/gcp$ python3 -c 'print(2_000_000 * 0.02 / 1000, round(7.63 * (0.035 - 0.007), 4))'
40.0 0.2136
```

**Moving two million taps to Coldline costs 40.00 once, to save 0.2136 a month.** It pays for itself
after fifteen years, and that is before the first read at Coldline's prices. A life-cycle rule that
was right for 500 GiB of order exports in a few hundred files is wrong for the same rule pointed at a
prefix of taps, and nothing about the rule says which one it is looking at. Count the objects under a
prefix before a rule moves them.

The last two lines of the table are the next section's.
