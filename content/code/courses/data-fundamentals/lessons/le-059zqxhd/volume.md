---
title: How much: rows a day times bytes a row
version: 1
---

**Volume is an estimate you can make before collecting a single row: rows a day, times bytes a row,
times the days you keep it.** The rows come from the business and are easy to get right. The bytes
are where estimates go wrong, because people count them in their head instead of measuring them.

## Rows a day

The rows are arithmetic on facts somebody at Roda Livre already knows. The twelve stations have 150
docks between them, from ten at the smallest to eighteen at Rodoferroviária, and every dock reports
once a minute whether it holds a bicycle. That is 150 readings a minute, and a day has 1,440 minutes.

## Bytes a row, measured

**The bytes are measured on a sample, written in the format you will actually store.** A reading
carries five values: a station, a dock, a time, whether the dock is occupied and the battery voltage.
Counting the characters of the values gives about forty bytes, and that guess is the one to distrust.

Every program in this lesson lives in the lesson's own directory, `~/roda/collect`. Make it and move
into it:

```sh
mkdir -p ~/roda/collect && cd ~/roda/collect
```

This program writes one hour of readings as JSON Lines, one reading a line, which is how the sensors'
server sends them. Then it measures the file, divides, and multiplies by the business's numbers: the
150 docks of today, and the 246 there will be once the eight new stations of twelve docks each,
planned for next year, are open. Save it as `collect/volume.py`:

```python
# collect/volume.py
import json
import os
import random

random.seed(7)
DOCKS = {"ST01": 15, "ST02": 12, "ST03": 10, "ST04": 12, "ST05": 18, "ST06": 12,
         "ST07": 15, "ST08": 10, "ST09": 12, "ST10": 12, "ST11": 12, "ST12": 10}

# a sample: one hour of readings, every dock reporting once a minute
with open("sample.jsonl", "w") as f:
    for minute in range(60):
        for station, n in DOCKS.items():
            for dock in range(1, n + 1):
                f.write(json.dumps({
                    "station": station,
                    "dock": dock,
                    "at": f"2025-09-15T08:{minute:02d}:00-03:00",
                    "occupied": random.random() < 0.6,
                    "voltage": round(random.uniform(11.8, 12.6), 2),
                }) + "\n")

rows = 60 * sum(DOCKS.values())
size = os.path.getsize("sample.jsonl")
per_row = size / rows
print(f"sample: {rows} rows, {size} bytes, {per_row:.1f} bytes a row")

# the estimate: rows a day times bytes a row, today and with the new stations
for docks in (sum(DOCKS.values()), sum(DOCKS.values()) + 8 * 12):
    a_day = docks * 24 * 60
    print(f"{docks} docks: {a_day} rows a day, {a_day * per_row / 1e6:.1f} MB a day, "
          f"{a_day * per_row * 365 / 1e9:.1f} GB a year")
```

```
ana@lab:~/roda/collect$ python volume.py
sample: 9000 rows, 923206 bytes, 102.6 bytes a row
150 docks: 216000 rows a day, 22.2 MB a day, 8.1 GB a year
246 docks: 354240 rows a day, 36.3 MB a day, 13.3 GB a year
```

The measured row is more than twice the guess. The first line of the sample says why:

```
ana@lab:~/roda/collect$ head -1 sample.jsonl
{"station": "ST01", "dock": 1, "at": "2025-09-15T08:00:00-03:00", "occupied": true, "voltage": 11.92}
```

The five values are 39 characters. The rest is the names of the keys, the quotes, the colons and the
spaces, **written again on every line**, because each line of JSON Lines carries its own field names.
A format that stores the names once per file, and the values of one column together, writes far
fewer bytes for the same readings; lesson 6 measures exactly that. The estimate is only as good as the
sample, which is why the sample is written in the format that will be stored, not in the one that is
easiest to imagine.

## Growth, and the peak

**An estimate made for today is wrong by next year, so it is made for the growth the business has
already planned.** The eight new stations raise the daily volume by 64% without a single extra
customer. Ask the people who plan the business, not the data: nothing in today's readings predicts a
station that has not been built.

A day's volume is also an average. The sensors report at the same rate at four in the morning and at
six in the evening, so their peak is their average. Rides are the opposite: most of them happen in
two rush hours, and a system sized for the daily average of rides is too small twice a day. When the
data is processed as it arrives, which is lesson 8, the peak is the number that matters.

## What the number decides

At 8.1 GB a year, the dock sensors fit on a laptop. That is worth knowing early, because volume is the
answer that chooses tools: a few gigabytes a year needs one machine and the standard library, and
lesson 9 is about what changes when it needs more than one. Write the estimate down with its
assumptions — 150 docks, one reading a minute, 102.6 bytes a row in JSON Lines — so that the day it
turns out wrong, everybody can see which assumption moved.
