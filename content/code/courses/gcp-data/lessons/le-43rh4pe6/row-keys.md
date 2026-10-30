---
title: A row key for the click stream
version: 1
---

**In Bigtable the row key is the only index, so it is designed from the questions, not from the
data.** Lesson 10 met the same inversion in Firestore's indexes, and the twin of it in every
store read by key: write down what will be asked, with its inputs and its size, and build the key
so that each question is one contiguous run of rows. A question the key cannot turn into a run is
a read of the whole table.

**Quitanda's app sends a click stream**: every screen a customer opens, with the product on it,
some forty million events on a busy day. The support team and the recommendation service ask
three questions of it:

| | the question | given | returns |
|---|---|---|---|
| C1 | a customer's latest events, newest first | the customer id | a few dozen rows |
| C2 | a customer's events in a time window | the id and two times | up to a few hundred |
| C3 | every event of the last minute, across customers | a time | tens of thousands |

C1 and C2 start from a customer. C3 does not, and it is the one this section leaves unanswered on
purpose: a question about everybody at once is an aggregation, and lessons 13 and 21 put it in
BigQuery and Dataflow, fed from the same stream. The section after this one shows what happens to
a table that tries to answer C3 with its key.

## customer#reversed-timestamp

**The key is the customer, a separator, and the time subtracted from a large constant.**
`c-17#8207812731000` is customer c-17 at 18:47:49 on 16 October: the event's time in milliseconds
since 1970 is 1792187269000, and `10**13` minus that is the number after the `#`, padded to 13
digits. Each piece earns its place:

- **The customer first**, so all of one customer's rows are adjacent and C1 and C2 name a
  contiguous run. Google's schema documentation calls this **field promotion**: a field that would
  have been a column is moved into the key, ahead of the timestamp, because the reads start from it.
- **The `#` after it**, so that the prefix of c-17 is not also the prefix of c-170. The block below
  measures what forgetting it costs.
- **The time reversed**, so that the newest event has the smallest number and sorts first. Rows are
  read in key order, and C1 wants the newest first.
- **A fixed width**, 13 digits, because the order is the order of bytes, and `999` sorts after
  `1000` as text.

**One row per event is the tall design**, and it is the one Google recommends for time series. The
wide alternative is one row per customer with a qualifier per event, and it fails slowly. The row
grows for as long as the customer uses the app, and a single row is limited to 256 MB, with Google
advising under 100 MB. And a write to one row is a write to one place, however many cells it adds.

## Loading it

The table has one family, `ev`, keeping one version per column, because an event is written once
and never changed:

```
ana@laptop:~/gcp$ cbt createtable clicks families=ev:maxversions=1
ana@laptop:~/gcp$ cbt ls clicks
Family Name	GC Policy		Value Type
-----------	---------		----------
ev		versions() > 1		{}
```

**The data comes from a short program** written with `google-cloud-bigtable`, the Python library of
lesson 1. Save it as `~/gcp/clicks.py`: the copy button on the block, then `nano clicks.py`, paste,
Ctrl+O, Enter and Ctrl+X.

```schooling-example
{"language": "python", "file": "clicks.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Quitanda's app click stream, written to the Bigtable table `clicks`.\n\n    python3 clicks.py load            # three customers, one evening of events\n    python3 clicks.py load 2000       # two thousand customers\n    python3 clicks.py key c-17 18:30  # the row key of c-17 at 18:30\n\nThe same number always writes the same rows. The table must exist, with a family `ev`.\n\"\"\"\nimport random\nimport sys\nfrom datetime import datetime, timedelta, timezone\n\nfrom google.cloud.bigtable.data import BigtableDataClient, RowMutationEntry, SetCell\n\n", "note": "The docstring says how to run it. **`BigtableDataClient` is the library's data client**, the half that reads and writes rows; tables and families are the admin API's, which is why the table is made with `cbt` first."}, {"code": "SAO_PAULO = timezone(timedelta(hours=-3))\nEVENING = datetime(2026, 10, 16, 18, 0, tzinfo=SAO_PAULO)\nSCREENS = ['home', 'search', 'product', 'cart', 'checkout']\nSKUS = ['banana', 'tomato', 'rice-5kg', 'coffee-500g', 'eggs-12', 'milk-1l']\n\n", "note": "The material the generator draws from. Times are in São Paulo's offset, fixed at three hours behind UTC, so the keys and the timestamps `cbt` prints agree with the prose."}, {"code": "def key(customer, when):\n    millis = int(when.timestamp() * 1000)\n    return f'{customer}#{10**13 - millis:013d}'\n\n", "note": "**The whole design is in these three lines.** The customer, a `#`, and the time in milliseconds subtracted from `10**13`, padded to 13 digits so that byte order and numeric order agree."}, {"code": "if sys.argv[1] == 'key':\n    hour, minute = map(int, sys.argv[3].split(':'))\n    print(key(sys.argv[2], EVENING.replace(hour=hour, minute=minute)))\n    sys.exit()\n\n", "note": "`key` on its own prints a row key for a time of the evening of 16 October, which is how the range reads of this section compute where to start and stop."}, {"code": "customers = int(sys.argv[2]) if len(sys.argv) > 2 else 3\nrnd = random.Random(17)\nentries = []\n", "note": "Three customers by default, starting at c-17. A seeded `Random` makes every run write the same rows, which is what lets this lesson print them."}, {"code": "for n in range(customers):\n    cid = f'c-{17 + n}'\n    when = EVENING + timedelta(seconds=rnd.randint(0, 3000))\n    for _ in range(rnd.randint(3, 6)):\n        when += timedelta(seconds=rnd.randint(5, 240))\n        micros = int(when.timestamp()) * 1_000_000\n        entries.append(RowMutationEntry(key(cid, when), [\n            SetCell('ev', 'screen', rnd.choice(SCREENS), micros),\n            SetCell('ev', 'sku', rnd.choice(SKUS), micros)]))\n\n", "note": "Three to six events per customer, a few seconds to four minutes apart. **Each event is one row**, with two cells in the family `ev`, and both cells carry the event's own time as their timestamp, in microseconds and a whole number of seconds."}, {"code": "with BigtableDataClient(project='planner-dev') as client:\n    client.get_table('quitanda', 'clicks').bulk_mutate_rows(entries)\nprint(f'{customers} customers, {len(entries)} events written to clicks')\n", "note": "`bulk_mutate_rows` sends every row in one batch of mutations; each row is applied atomically and on its own, so a failure is reported per row rather than for the whole batch."}]}
```

```
ana@laptop:~/gcp$ python3 clicks.py load
/home/ana/gcp/clicks.py:43: RuntimeWarning: Connecting to Bigtable emulator at localhost:8086
  with BigtableDataClient(project='planner-dev') as client:
3 customers, 15 events written to clicks
```

**The first two lines are the library telling you where it went**: a `RuntimeWarning` that it found
`BIGTABLE_EMULATOR_HOST` and connected to the emulator. Against Google it does not appear. Fifteen
events, and their keys:

```
ana@laptop:~/gcp$ cbt read clicks columns=ev:screen | grep '^"'
"c-17#8207812731000"
"c-17#8207812843000"
"c-17#8207812911000"
"c-17#8207812987000"
"c-17#8207813172000"
"c-17#8207813251000"
"c-18#8207813469000"
"c-18#8207813637000"
"c-18#8207813780000"
"c-18#8207813990000"
"c-18#8207814220000"
"c-18#8207814260000"
"c-19#8207813418000"
"c-19#8207813630000"
"c-19#8207813788000"
```

**The rows are in key order, and so each customer's events run newest first.** c-17's first row is
`…2731000` at 18:47:49 and its last is `…3251000` at 18:39:09. The customers do not interleave by
time; c-19's events are after c-18's although some happened earlier, because `c-18#` sorts before
`c-19#` whatever follows.

## The two reads the key was built for

**C1 is a prefix with a count, and C2 is a range.** For the range, the start and the end are keys
too, so `clicks.py key` computes them; reversed time means the later moment is the start:

```
ana@laptop:~/gcp$ cbt read clicks prefix=c-17# count=2
----------------------------------------
"c-17#8207812731000"
  "ev:screen"                              @ 2026/10/16-18:47:49.000000
    "product"
  "ev:sku"                                 @ 2026/10/16-18:47:49.000000
    "eggs-12"

----------------------------------------
"c-17#8207812843000"
  "ev:screen"                              @ 2026/10/16-18:45:57.000000
    "cart"
  "ev:sku"                                 @ 2026/10/16-18:45:57.000000
    "milk-1l"

ana@laptop:~/gcp$ python3 clicks.py key c-17 18:46
c-17#8207812840000
ana@laptop:~/gcp$ cbt read clicks start=$(python3 clicks.py key c-17 18:46) end=$(python3 clicks.py key c-17 18:40) columns=ev:screen
----------------------------------------
"c-17#8207812843000"
  "ev:screen"                              @ 2026/10/16-18:45:57.000000
    "cart"

----------------------------------------
"c-17#8207812911000"
  "ev:screen"                              @ 2026/10/16-18:44:49.000000
    "home"

----------------------------------------
"c-17#8207812987000"
  "ev:screen"                              @ 2026/10/16-18:43:33.000000
    "checkout"

----------------------------------------
"c-17#8207813172000"
  "ev:screen"                              @ 2026/10/16-18:40:28.000000
    "search"
```

**`prefix=c-17# count=2` is C1**: the two latest events, in the order they are stored, with nothing
else read. **The range is C2**: from the key of 18:46 up to, but not including, the key of 18:40,
which is the four events between 18:40 and 18:46, newest first. `end` is exclusive, the way an
interval of keys usually is in Bigtable, which is why a window that must include 18:40 itself ends
one millisecond earlier in the key, at the key of 18:39:59.999.

## The separator, measured

**With two thousand customers, the prefix without its `#` reads a hundred and eleven customers.**
The same program, the same seed, a larger number:

```
ana@laptop:~/gcp$ python3 clicks.py load 2000
/home/ana/gcp/clicks.py:43: RuntimeWarning: Connecting to Bigtable emulator at localhost:8086
  with BigtableDataClient(project='planner-dev') as client:
2000 customers, 8999 events written to clicks
ana@laptop:~/gcp$ cbt count clicks
8999
ana@laptop:~/gcp$ cbt read clicks prefix=c-17 columns=ev:screen | grep -c '^"'
497
ana@laptop:~/gcp$ cbt read clicks prefix=c-17# columns=ev:screen | grep -c '^"'
6
```

**8,999 rows.** `prefix=c-17` matched c-17, c-170 to c-179 and c-1700 to c-1799, 497 rows that would
have reached a support agent's screen as c-17's history. `prefix=c-17#` matched the six that are.
Nothing failed, and the wrong answer looks like a busy customer. Fixed-width ids, `c-00017`, are
the other repair, and the separator costs one byte.

## What a filter does not save

**`include-stats=full` asks the server what a read cost**, and it is how to tell a run of keys from
a scan with a filter on top:

```
ana@laptop:~/gcp$ cbt read clicks prefix=c-17# include-stats=full | tail -7
====================
rows_seen_count: 6
rows_returned_count: 6
cells_seen_count: 12
cells_returned_count: 12
frontend_server_latency: 0ms

ana@laptop:~/gcp$ cbt read clicks regex='c-17#.*' include-stats=full | tail -7
====================
rows_seen_count: 8999
rows_returned_count: 6
cells_seen_count: 17998
cells_returned_count: 12
frontend_server_latency: 96ms

ana@laptop:~/gcp$ cbt read clicks prefix=c-17# reversed=true count=1
----------------------------------------
"c-17#8207813251000"
  "ev:screen"                              @ 2026/10/16-18:39:09.000000
    "product"
  "ev:sku"                                 @ 2026/10/16-18:39:09.000000
    "rice-5kg"
```

**The same six rows, and the second read looked at all 8,999 to find them.** A `regex` on the row
key is a filter: the server walks every row in the range it was given, here the whole table, and
returns the ones that match. The `prefix` told it where to start and where to stop. On the emulator
the difference is 96 milliseconds; on a table of forty million rows a day it is the whole table on
every call, on nodes the next section prices.

**And the direction is a choice of the read.** `reversed=true` reads a range from its end, so the
oldest of c-17's events comes first. Bigtable gained reverse scans in 2024, and the emulator serves
them. Before that, a reversed timestamp was the only way to read newest first; now it is still the
cheaper way for a read that always wants newest first, and plain time with `reversed=true` fits a
table that is read both ways.
