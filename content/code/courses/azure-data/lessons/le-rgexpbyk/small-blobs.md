---
title: The small-blobs problem
version: 1
---

**Many small blobs make everything priced per operation expensive and everything priced per byte
cheap**, and a design that writes one blob per event chooses the expensive side without noticing. Two
million taps of 4 KB are 7.63 GB of storage. They are also two million blobs, every time anybody
reads them, lists them, copies them or moves them to another tier.

Quitanda's app sends about 2 million taps a month. The first design writes each tap as its own blob,
the way `count.py` did, and a dashboard reads all of them every morning to draw the last month. The
program below prices that and four other designs at this lesson's illustrative prices. It needs no
emulator. Save it as `~/azure/costs.py`:

```schooling-example
{"language": "python", "file": "costs.py", "parts": [{"code": "\"\"\"A month of Blob Storage, meter by meter, at ILLUSTRATIVE prices.\"\"\"\nimport math\n\n# Round numbers to do the sums with, NOT Azure's prices: prices.py prints those.\nTIERS = {  # USD: per GB-month, per 10,000 writes, per 10,000 reads, per GB retrieved\n    \"hot\": (0.020, 0.05, 0.004, 0.00),\n    \"cool\": (0.010, 0.10, 0.010, 0.01),\n}\nLIST = 0.05            # per 10,000 list operations\nEGRESS = 0.10          # per GB to the internet, past the free allowance\nFREE = 100             # GB a month to the internet at no charge\nDAYS = 30\n", "note": "**Every price here is invented, and the comment says so in capitals.** They are round numbers with the shape Microsoft's sheet has: the cool tier charges less to store and more to touch, writes cost more than reads, and reading from cool has a charge per gigabyte that hot does not. Replace them with what `prices.py` prints for your region and the program does the same sums with real money."}, {"code": "\n\ndef money(x):\n    return '-' if x is None else f'{x:,.2f}'\n\n\ndef show(name, tier, stored_gb, writes, reads, lists, read_gb, out_gb):\n    store_p, write_p, read_p, retrieve_p = TIERS[tier]\n    store = stored_gb * store_p\n    ops = (writes * write_p + reads * read_p + lists * LIST) / 10_000\n    retrieval = read_gb * retrieve_p\n    out = None if out_gb is None else max(0, out_gb - FREE) * EGRESS\n    total = None if out is None else store + ops + retrieval + out\n    print(f'{name:<34}{money(store):>8}{money(ops):>10}{money(retrieval):>11}'\n          f'{money(out):>10}{money(total):>10}')\n", "note": "One line of the table: a month of storage, of operations, of retrieval and of transfer to the internet, and their sum. **Operations are divided by 10,000 because that is the unit Azure prices them in**, the mistake lesson 1 warned about. A transfer the program cannot price prints a dash, and so does the total."}, {"code": "\n\ntaps_gb = 2_000_000 * 4 / 1024 / 1024\npages = math.ceil(2_000_000 / 5_000)\nfiles = math.ceil(taps_gb * 1024 / 64)\ndownloads = 20_480 * 1024 * 1024 // 400\n", "note": "**Quitanda's month, in counts.** Two million taps of 4 KB each, which is 7.63 GB. Listing them takes one request per 5,000 names. Packed into files of 64 MiB they are 123 files. And the product images: 20 TB served to the internet in pictures of 400 KB is 53,687,091 downloads."}, {"code": "\nprint(f'{\"a month\":<34}{\"storage\":>8}{\"ops\":>10}{\"retrieval\":>11}'\n      f'{\"transfer\":>10}{\"total\":>10}')\nshow('2M taps, a blob each, hot', 'hot', taps_gb,\n     2_000_000, 2_000_000 * DAYS, pages * DAYS, taps_gb * DAYS, 0)\nshow('the same, in cool', 'cool', taps_gb,\n     2_000_000, 2_000_000 * DAYS, pages * DAYS, taps_gb * DAYS, 0)\nshow(f'the same, {files} files of 64 MiB, hot', 'hot', taps_gb,\n     files, files * 9 * DAYS, DAYS, taps_gb * DAYS, 0)\nshow('500 GB of images, 20 TB out', 'hot', 500, 0, downloads, 0, 0, 20_480)\nshow('the same behind a CDN', 'hot', 500, 0, downloads // 20, 0, 0, None)\n", "note": "**Five designs, one line each.** The taps are written once in the month and every one is read every morning, after listing them. The same taps in 64 MiB files are read in nine requests each, because that is how the library fetches a blob that size, as `count.py` showed for 80 MiB in thirteen. Behind a content delivery network, one download in twenty reaches the account and the rest are served from the network's copies; the network's own price is not in this program."}]}
```

```
ana@laptop:~/azure$ python costs.py
a month                            storage       ops  retrieval  transfer     total
2M taps, a blob each, hot             0.15     34.06       0.00      0.00     34.21
the same, in cool                     0.08     80.06       2.29      0.00     82.43
the same, 123 files of 64 MiB, hot    0.15      0.01       0.00      0.00      0.17
500 GB of images, 20 TB out          10.00     21.47       0.00  2,038.00  2,069.47
the same behind a CDN                10.00      1.07       0.00         -         -
```

**The dashboard's month is 34.21, of which 0.15 is storage.** The rest is operations: 2,000,000
writes at 0.05 per 10,000 is 10.00, 2,000,000 reads a day for 30 days is 60 million at 0.004 per
10,000, which is 24.00, and the 400 listings a day are 0.06. The reads alone cost 160 times the
storage.

**Moving the same blobs to cool makes it worse**: 82.43 against 34.21. Storage halves, from 0.15 to
0.08, and everything else grows, because cool charges more for every operation and adds 0.01 for each
of the 228.88 GB read back in the month, 2.29. Cool is for data that is kept and rarely touched, the
rule lesson 4 drew from the minimum days. The source of a dashboard read every morning is the
opposite.

**Packing the taps into 64 MiB files takes the operations to 0.01**: 123 files, written once and read
in nine requests each every morning. The bytes stored are the same 7.63 GB, and the month falls from
34.21 to 0.17. This is one reason data lakes keep their files large, and lesson 18 comes back to it
with the small files a streaming job leaves behind and the compaction that merges them.

## Where small blobs come from

Nobody designs two million tiny files on purpose. They arrive:

- **from streams**, where something writes whatever arrived in the last few seconds, which lesson 22
  meets with Event Hubs and its capture into storage;
- **from partitions too fine for the data**, a folder per hour per customer, each holding a file of a
  few rows;
- **from one-blob-per-record designs**, the tap above, convenient to write and ruinous to read.

The cure is the same each time: write fewer, larger blobs, or compact the small ones into large ones
on a schedule. The cooler tiers punish small blobs further, since every blob read from them is an
operation at that tier's higher price, however few bytes it holds.

The last two lines of the table are the next section's.
