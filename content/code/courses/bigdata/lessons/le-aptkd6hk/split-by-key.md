---
title: Split the data by key, and the wall moves
version: 1
---

**The way past the wall is to make sure no step ever needs all the data at once.** Counting the
different visitors of a book needs every event of that book's visitors together, but it does not
need every visitor together. So Ana splits the work by visitor, and counts each part on its own.
Save it as `~/big/buckets.py`:

```schooling-example
{
  "language": "python",
  "file": "buckets.py",
  "parts": [
    {
      "code": "\"\"\"The same question, in two passes, without holding every visitor at once.\"\"\"\nimport csv\nimport glob\nimport gzip\nimport os\nimport resource\nimport zlib\n\n"
    },
    {
      "code": "N = 16\nos.makedirs(\"buckets\", exist_ok=True)\nout = [open(f\"buckets/{i:02}.csv\", \"w\") for i in range(N)]\nfor path in sorted(glob.glob(\"data/raw/clicks/day=*/*.csv.gz\")):\n    with gzip.open(path, \"rt\") as f:\n        for row in csv.DictReader(f):\n            if row[\"book_id\"]:\n                i = zlib.crc32(row[\"visitor_id\"].encode()) % N\n                out[i].write(f'{row[\"book_id\"]},{row[\"visitor_id\"]}\\n')\nfor f in out:\n    f.close()\n\n",
      "note": "**Pass one sends every pair to one of sixteen files**, chosen by the visitor. `crc32` is a checksum used here as a hash: the same visitor always lands in the same file. Python's own `hash()` would not do, because it changes from one run to the next."
    },
    {
      "code": "counts = {}\nfor i in range(N):\n    seen = {}\n    with open(f\"buckets/{i:02}.csv\") as f:\n        for line in f:\n            book, visitor = line.rstrip(\"\\n\").split(\",\")\n            seen.setdefault(book, set()).add(visitor)\n    for book, visitors in seen.items():\n        counts[book] = counts.get(book, 0) + len(visitors)\n\nfor book, n in sorted(counts.items(), key=lambda kv: kv[1], reverse=True)[:3]:\n    print(f\"book {book}: {n:,} visitors\")\npeak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss\nprint(f\"peak memory: {peak / 1024:,.0f} MB\")\n",
      "note": "**Pass two reads one file at a time**, builds the sets for that file alone and throws them away. A visitor is in exactly one file, so the counts from the sixteen files simply add up."
    }
  ]
}
```

The same limit of 1 GB:

```
ana@lab:~/big$ (ulimit -v 1000000; time python3 buckets.py)
book 1: 936,076 visitors
book 2: 335,986 visitors
book 3: 244,287 visitors
peak memory: 163 MB

real	1m10.381s
user	1m8.465s
sys	0m0.976s
```

**The same three numbers, in the same time, at 163 MB instead of 2.3 GB.** Pass one costs a second
copy of the pairs on disk, 271 MB of it, and that is the trade: disk is cheap and plentiful, and
memory is neither.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-buckets\" aria-label=\"Two passes over the clicks. On the left, 365 daily files of events. Pass one reads them once and sends each book and visitor pair to one of sixteen bucket files, chosen by a hash of the visitor. Fifteen buckets are about 17 MB; bucket 09, which holds the crawler, is 28 MB. Pass two reads one bucket at a time, counts the different visitors of each book in it, and adds the counts into one total per book.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16.0\" y=\"115.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">365 daily files</text><text x=\"91.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24 million events</text><rect x=\"290.0\" y=\"30.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">00.csv</text><path d=\"M166.0 145.0 L288.0 43.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 43.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"64.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">01.csv</text><path d=\"M166.0 145.0 L288.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 77.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"98.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">02.csv</text><path d=\"M166.0 145.0 L288.0 111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 111.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"330.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">· · ·</text><rect x=\"290.0\" y=\"158.0\" width=\"80.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">09.csv</text><path d=\"M166.0 145.0 L288.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 180.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"380.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the crawler</text><text x=\"330.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">· · ·</text><rect x=\"290.0\" y=\"236.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">15.csv</text><path d=\"M166.0 145.0 L288.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 249.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"228.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pass 1: by visitor</text><text x=\"420.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pass 2: one at a time</text><rect x=\"472.0\" y=\"115.0\" width=\"220.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"582.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">visitors per book</text><text x=\"582.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the counts add up</text></svg>", "caption": "Pass one decides where every pair goes; pass two never holds more than one bucket. The same visitor always lands in the same bucket, which is what lets the counts add up."}
```

**Look at the sizes of the sixteen files**, because one of them is not like the others:

```
ana@lab:~/big$ ls -lS buckets | head -4
total 276932
-rw-r--r-- 1 ana ana 28342444 Oct 10 04:23 09.csv
-rw-r--r-- 1 ana ana 17091101 Oct 10 04:23 03.csv
-rw-r--r-- 1 ana ana 17042747 Oct 10 04:23 01.csv
ana@lab:~/big$ ls -lS buckets | tail -2
-rw-r--r-- 1 ana ana 16969934 Oct 10 04:23 14.csv
-rw-r--r-- 1 ana ana 16961778 Oct 10 04:23 08.csv
ana@lab:~/big$ du -sh buckets
271M	buckets
```

Fifteen files of about 17 MB and one of 28 MB. The visitors were spread evenly by the hash, but
the events were not: file 09 holds `v0000000`, the crawler, and with it four events in every
hundred. Pass two's memory, its time and its chance of failing are set by the largest file and not
by the average. Lesson 8 is entirely about that one file.

## What this has to do with a cluster

Read the program again with a cluster in mind, because **you have just written, by hand, the three
steps every distributed job is made of**:

1. **Split by key.** Every record goes to the part its key decides, and the same key always goes to
   the same part. Spark calls this a *shuffle*.
2. **Work on each part alone.** Nothing in pass two for file 03 needs file 07. The sixteen parts
   could be counted on sixteen machines at the same time, and on a cluster they are.
3. **Combine.** The partial counts add up to the answer.

Here the sixteen parts were done one after another, on one machine, so the program got past the
memory wall and gained no time at all. A cluster does the same split and then works on the parts
at the same time, on different machines: that is how it gets past the time wall too.
