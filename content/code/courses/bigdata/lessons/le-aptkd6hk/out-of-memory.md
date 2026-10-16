---
title: A program that runs out of memory
version: 1
---

**The question is simple: how many different visitors looked at each book in 2025?** The marketing
team wants the top three. Ana's first answer is the program anybody would write, and it is a good
program. Save it as `~/big/visitors.py`:

```schooling-example
{
  "language": "python",
  "file": "visitors.py",
  "parts": [
    {
      "code": "\"\"\"How many different visitors looked at each book in 2025? The top three.\"\"\"\nimport csv\nimport glob\nimport gzip\nimport resource\n\n"
    },
    {
      "code": "seen = {}\nfor path in sorted(glob.glob(\"data/raw/clicks/day=*/*.csv.gz\")):\n    with gzip.open(path, \"rt\") as f:\n        for row in csv.DictReader(f):\n            if row[\"book_id\"]:\n                seen.setdefault(row[\"book_id\"], set()).add(row[\"visitor_id\"])\n\n",
      "note": "**The whole method is this dictionary**: for every book, the set of visitors who looked at it. A set keeps each visitor once, which is what *different* means."
    },
    {
      "code": "top = sorted(seen.items(), key=lambda kv: len(kv[1]), reverse=True)[:3]\nfor book, visitors in top:\n    print(f\"book {book}: {len(visitors):,} visitors\")\n",
      "note": "Only when every file has been read can the sets be counted. Until then, everything stays in memory."
    },
    {
      "code": "peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss\nprint(f\"peak memory: {peak / 1024:,.0f} MB\")\n",
      "note": "`ru_maxrss` is the most memory the process held at any moment, in kilobytes on Linux."
    }
  ]
}
```

On the lab machine it works:

```
ana@lab:~/big$ time python3 visitors.py
book 1: 936,076 visitors
book 2: 335,986 visitors
book 3: 244,287 visitors
peak memory: 2,338 MB

real	1m8.529s
user	1m6.386s
sys	0m1.485s
```

**A little over a minute, and 2.3 GB of memory at the peak.** The data is 243 MB compressed and the
program needed ten times that, because a Python string and a set entry cost dozens of bytes each,
and there are millions of them. That ratio is normal, and it is the first thing to measure before
deciding a machine is big enough.

Now give the program a machine with 1 GB to spare. `ulimit -v` limits how much memory a process may
ask for, and inside parentheses the limit applies to that one command and not to your shell:

```
ana@lab:~/big$ (ulimit -v 1000000; time python3 visitors.py)
Traceback (most recent call last):
  File "/home/ana/big/visitors.py", line 12, in <module>
    seen.setdefault(row["book_id"], set()).add(row["visitor_id"])
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^
MemoryError

real	0m26.030s
user	0m25.123s
sys	0m0.696s
```

**Twenty-six seconds of work, then nothing.** No result for the books already counted, no partial
answer, no warning a minute before. That is how running out of memory looks every time: the
program's footprint grows with the data, and the day the data is larger than the machine, the
program stops at whatever line asked for one more byte.

Two things are worth seeing in it. **The failure is not a bug** — the program is correct, and given
a larger machine it gives the right answer. And **the fix is not a better dictionary.** Any program
that must hold every visitor at once has the same wall somewhere; a cleverer data structure moves
the wall and does not remove it. The next section removes it.
