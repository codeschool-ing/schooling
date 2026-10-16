---
title: The small-objects problem
version: 1
---

**Many small objects make every request-priced operation expensive and every byte-priced one cheap**,
and a design that writes one object per event chooses the expensive side without noticing. The
storage of a million 4 KB objects is the storage of 4 GB. Their requests are the requests of a
million objects, every time anybody reads them, lists them, copies them or moves them to another
class.

Quitanda's app sends a small JSON event for every tap: 2 million of them a month, about 4 KB each.
The first design writes each event as its own object, and a dashboard reads all of them every
morning to draw the last month. The program below prices that, and three other designs, from the
sheet. Save it as `~/aws/reads.py`:

```schooling-example
{"language": "python", "file": "reads.py", "parts": [{"code": "\"\"\"What reading costs against what storing costs, for S3 in sa-east-1.\"\"\"\nimport math\n\n# USD, from `python3 prices.py s3 transfer`\nSTORE = 0.04050          # Standard, per GB-month\nPUT = 0.00700 / 1000     # PUT, COPY, POST, LIST, per request\nGET = 0.00056 / 1000     # GET and the rest, per request\nOUT = [(10_240, 0.15000), (40_960, 0.13800), (102_400, 0.12600), (None, 0.11400)]\nDAYS = 30\n\n\n", "note": "**The four prices are lines of the sheet**, and the request prices are divided by 1,000 because the sheet prints them per thousand. `OUT` is the four tiers of transfer to the internet, each a number of GB and its price: 10 TB, then 40, then 100, then the rest."}, {"code": "def egress(gb):\n    \"\"\"USD for gb sent to the internet in one month, tier by tier.\"\"\"\n    usd, left = 0.0, gb\n    for size, price in OUT:\n        step = left if size is None else min(left, size)\n        usd += step * price\n        left -= step\n        if left <= 0:\n            break\n    return usd\n\n\n", "note": "A tiered price is a staircase, not a single rate: the first 10,240 GB of the month at 0.15, the next 40,960 at 0.138, and so on. Each step takes as much of what is left as its tier holds."}, {"code": "def gb(objects, kb):\n    return objects * kb / 1024 / 1024\n\n\ndef money(x):\n    return '-' if x is None else f'{x:,.2f}'\n\n\n", "note": "A count of objects of a size in KB, as GB. And a money column that prints a dash for a price the sheet does not have."}, {"code": "def show(name, stored_gb, puts, gets, out):\n    store = stored_gb * STORE\n    requests = puts * PUT + gets * GET\n    total = None if out is None else store + requests + out\n    print(f'{name:<32}{money(store):>9}{money(requests):>10}{money(out):>11}{money(total):>11}')\n\n\n", "note": "One line of the table: a month of storage, a month of requests, a month of transfer out, and their sum."}, {"code": "events = gb(2_000_000, 4)\nfiles = math.ceil(events * 1024 / 64)\nprint(f'{\"a month\":<32}{\"storage\":>9}{\"requests\":>10}{\"transfer\":>11}{\"total\":>11}')\nshow('2M events of 4 KB, read daily', events, 2_000_000, 2_000_000 * DAYS, 0)\nshow(f'the same, in {files} files of 64 MB', events, files, files * DAYS, 0)\nshow('500 GB of images, 20 TB out', 500, 0, 52_000_000, egress(20_480))\nshow('the same behind CloudFront', 500, 0, 2_600_000, None)\n", "note": "**Four designs, one line each.** The events are written once in the month and every one is read once a day. The same bytes packed into 64 MB files are written and read as files. The images are a library of 500 GB from which 20 TB a month is served, about 52 million downloads of 400 KB. Behind CloudFront, 95 in every 100 downloads are served from its cache, and its own price for delivering them is not in the sheet."}]}
```

```
ana@laptop:~/aws$ python3 reads.py
a month                           storage  requests   transfer      total
2M events of 4 KB, read daily        0.31     47.60       0.00      47.91
the same, in 123 files of 64 MB      0.31      0.00       0.00       0.31
500 GB of images, 20 TB out         20.25     29.12   2,949.12   2,998.49
the same behind CloudFront          20.25      1.46          -          -
```

**The dashboard's month is 47.91, of which 0.31 is storage.** The rest is requests: 2,000,000 `PUT`s
at 0.00700 a thousand is 14.00, and 2,000,000 `GET`s a day for 30 days is 60 million at 0.00056 a
thousand, 33.60. Reading costs over a hundred times what storing does, and nothing about the data
changed except how it was cut up.

**Packing the events into 64 MB files takes the requests to 0.00**: 123 files, written once and read
123 times a day, cost fractions of a cent. The bytes stored are the same 7.63 GB. This is one reason
data lakes keep their files large, and lesson 19 comes back to it: a query engine reading a lake pays
for every file it opens as well as for the bytes, and the request bill is the part of that a price
sheet shows.

## Where small objects come from

Nobody designs a million tiny files on purpose. They arrive:

- **from streams**, where something writes whatever arrived in the last few seconds, which lesson 21
  meets with Firehose and its buffer;
- **from partitions too fine for the data**, a prefix per hour per customer, each holding a file of
  a few rows;
- **from one-object-per-record designs**, the event above, convenient to write and ruinous to read.

The cure is the same each time: write fewer, larger objects, or compact the small ones into large
ones on a schedule. And the archive classes of lesson 2 punish small objects twice, since a 4 KB
event in Glacier Instant Retrieval is billed as 128 KB and every one of its reads is a request at
0.01000 a thousand, almost eighteen times Standard's `GET`.

The last two lines of the table are the next section's.
