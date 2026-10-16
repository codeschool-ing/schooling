---
title: MapReduce with a Unix pipe
version: 1
---

**The whole model fits in one shell command**, on one machine and one day of data. Save the two
functions as files. The mapper, `~/big/mapper.py`:

```schooling-example
{
  "language": "python",
  "file": "mapper.py",
  "parts": [
    {
      "code": "\"\"\"Map: for every event, emit its kind and a 1.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "for line in sys.stdin:\n    fields = line.rstrip(\"\\n\").split(\",\")\n    print(f\"{fields[3]}\\t1\")\n",
      "note": "**A mapper reads lines on standard input and writes key-value pairs on standard output**, a tab between them. It sees one line at a time and remembers nothing, which is what lets a thousand copies of it run at once on a thousand slices of the file."
    }
  ]
}
```

The reducer, `~/big/reducer.py`:

```schooling-example
{
  "language": "python",
  "file": "reducer.py",
  "parts": [
    {
      "code": "\"\"\"Reduce: the input arrives sorted by key; add up each run of equal keys.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "current, total = None, 0\nfor line in sys.stdin:\n    key, value = line.rstrip(\"\\n\").split(\"\\t\")\n    if key != current:\n        if current is not None:\n            print(f\"{current}\\t{total}\")\n        current, total = key, 0\n    total += int(value)\n",
      "note": "**The reducer relies on one promise: its input is sorted by key.** So every `cart` arrives together, then every `purchase`, and it only has to notice where one run of equal keys ends and the next begins. It holds one running total, never a dictionary of every key."
    },
    {
      "code": "if current is not None:\n    print(f\"{current}\\t{total}\")\n",
      "note": "The last run has no next key to announce its end, so it is written when the input runs out."
    }
  ]
}
```

Then join them with a pipe, with `sort` standing in for the shuffle:

```
ana@lab:~/big$ time (zcat data/raw/clicks/day=2025-03-14/*.gz | tail -n +2 | python3 mapper.py | sort | python3 reducer.py)
cart	5203
purchase	2588
search	5370
view	52592

real	0m0.137s
user	0m0.168s
sys	0m0.026s
```

**A day's events by kind, in the blink of an eye.** Read the pipe left to right and it is the model
of the last section: `zcat` and `tail` produce the records without their header line, `mapper.py`
maps each one to a pair, `sort` brings equal keys together, and `reducer.py` adds up each run. The
reducer works only because `sort` ran first; feed it unsorted pairs and it prints `view` many times,
once for each run of views it happened to meet.

Nothing in either program knows about files, machines or HDFS. They read standard input and write
standard output, and that is the contract that lets Hadoop run them on a cluster unchanged: the next
section does.
