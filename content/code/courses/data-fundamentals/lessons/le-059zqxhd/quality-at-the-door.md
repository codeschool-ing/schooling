---
title: Checks at the door
version: 1
---

**The cheapest moment to catch a bad row is the moment it arrives, before anything downstream has
read it.** The common plan is to load everything and clean it later. By later, a report has counted
the bad row, a model has trained on it, and somebody has made a decision with it; cleaning then means
finding everybody who already used it.

Checks on arrival come in two kinds, and they fail in different ways:

- **checks on the file**: does it have the columns it should, and as many rows as the source says it
  sent? A file that fails one is **refused whole**. Loading part of a day makes the day look quiet,
  which is a wrong number, not a missing one.
- **checks on each row**: is a required value present, inside its range, unique where it must be,
  and pointing at something that exists? A row that fails one is **quarantined**: set aside in a
  file of its own, with the reason, where somebody can look at it. It is never dropped in silence.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A delivery, a CSV file with the count of rows the source sent, goes first through checks on the file: the columns and the row count. If they fail, the file is refused whole and nothing is loaded. If they pass, each row goes through checks for a missing value, a range, uniqueness and a reference, and is either accepted or put in quarantine with its reason.\" data-fig=\"door\"><defs><marker id=\"door-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"72\" width=\"124\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"86.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the delivery</text><text x=\"76.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a CSV file</text><text x=\"76.0\" y=\"117.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and its count</text><line x1=\"138\" y1=\"102\" x2=\"176\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><rect x=\"178\" y=\"57\" width=\"170\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"263.0\" y=\"86.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">checks on the file</text><text x=\"263.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the columns</text><text x=\"263.0\" y=\"117.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the row count</text><line x1=\"263\" y1=\"147\" x2=\"263\" y2=\"177\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><text x=\"271\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fails</text><rect x=\"178\" y=\"179\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"263.0\" y=\"194.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">refused whole</text><text x=\"263.0\" y=\"209.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing is loaded</text><line x1=\"348\" y1=\"102\" x2=\"386\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><text x=\"367\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passes</text><rect x=\"388\" y=\"32\" width=\"180\" height=\"140\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"478.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">checks on each row</text><text x=\"478.0\" y=\"86.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a missing value</text><text x=\"478.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a range</text><text x=\"478.0\" y=\"117.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uniqueness</text><text x=\"478.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a reference</text><line x1=\"568\" y1=\"78\" x2=\"594\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><rect x=\"596\" y=\"30\" width=\"112\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"652.0\" y=\"48.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">accepted</text><text x=\"652.0\" y=\"63.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loaded</text><line x1=\"568\" y1=\"126\" x2=\"594\" y2=\"142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><rect x=\"596\" y=\"116\" width=\"112\" height=\"68\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"652.0\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">quarantine</text><text x=\"652.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the row,</text><text x=\"652.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and its reason</text></svg>", "caption": "Two kinds of check on arrival. A file that fails is refused whole; a row that fails is set aside with its reason, and never dropped."}
```

## A delivery with problems in it

The app's nightly export of rides arrives as a CSV file, with a second, tiny file beside it in which
the source writes how many rows it sent. This program makes two days of them. The 15th has four
problems planted in its 200 rows, and the 16th was cut off after 137 rows of 200, as a copy
interrupted halfway would be. Save it as `collect/deliver.py`:

```python
# collect/deliver.py
import csv
import random
from datetime import datetime, timedelta

random.seed(15)


def deliver(day, first, rows, sent):
    start = datetime.fromisoformat(day + " 06:00")
    out = []
    for i in range(first, first + rows):
        at = start + timedelta(seconds=random.randrange(17 * 3600))
        out.append([f"R{i:06d}", f"ST{random.randint(1, 12):02d}", str(at),
                    str(random.randint(3, 60))])
    if day == "2025-09-15":
        out[40][1] = "ST13"           # a station that does not exist
        out[77][3] = "-4"             # a ride of minus four minutes
        out[120][2] = ""              # no start time
        out[150] = out[149]           # a ride written over the next one
    with open(f"delivery-{day}.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["ride_id", "start_station", "started_at", "minutes"])
        w.writerows(out[:sent])
    with open(f"delivery-{day}.count", "w") as f:
        f.write(f"{rows}\n")          # what the source says it sent
    print(f"delivery-{day}.csv: {sent} rows written, the source says {rows}")


deliver("2025-09-15", 1, 200, 200)
deliver("2025-09-16", 201, 200, 137)   # the copy was cut off halfway
```

The checks are the program below. The two at the top look at the whole file and stop it with
`sys.exit`, which prints the reason and ends the program with an error. `problem` looks at one row
and returns the reason it fails, or an empty string. The loop at the bottom files every row as
accepted or quarantined and writes both files. Save it as `collect/door.py`:

```python
# collect/door.py
import csv
import sys

COLUMNS = ["ride_id", "start_station", "started_at", "minutes"]
STATIONS = {f"ST{n:02d}" for n in range(1, 13)}
day = sys.argv[1]

with open(f"delivery-{day}.csv", newline="") as f:
    header, *rows = list(csv.reader(f))
promised = int(open(f"delivery-{day}.count").read())

# checks on the whole file: if one fails, nothing is loaded
if header != COLUMNS:
    sys.exit(f"refused: the columns are {header}")
if len(rows) != promised:
    sys.exit(f"refused: {len(rows)} rows arrived, the source says {promised}")


def problem(row, seen):
    ride_id, station, started_at, minutes = row
    if ride_id in seen:
        return "ride_id seen before"
    if station not in STATIONS:
        return "unknown station"
    if not started_at.startswith(day):
        return "started_at empty or not on " + day
    if not minutes.isdigit() or not 1 <= int(minutes) <= 720:
        return "minutes outside 1-720"
    return ""


def save(path, rows):
    with open(path, "w", newline="") as f:
        csv.writer(f).writerows(rows)


# checks on each row: a bad row is set aside with its reason, never dropped
seen, accepted, quarantined = set(), [], []
for row in rows:
    reason = problem(row, seen)
    seen.add(row[0])
    if reason:
        quarantined.append(row + [reason])
    else:
        accepted.append(row)
save(f"accepted-{day}.csv", [COLUMNS] + accepted)
save(f"quarantine-{day}.csv", [COLUMNS + ["reason"]] + quarantined)
print(f"{day}: {len(rows)} rows, {len(accepted)} accepted, {len(quarantined)} quarantined")
```

Make the deliveries, and put the 15th through the door:

```
ana@lab:~/roda/collect$ python deliver.py
delivery-2025-09-15.csv: 200 rows written, the source says 200
delivery-2025-09-16.csv: 137 rows written, the source says 200
ana@lab:~/roda/collect$ python door.py 2025-09-15
2025-09-15: 200 rows, 196 accepted, 4 quarantined
```

Four of the 200 were set aside, and the quarantine file says which and why:

```
ana@lab:~/roda/collect$ cat quarantine-2025-09-15.csv
ride_id,start_station,started_at,minutes,reason
R000041,ST13,2025-09-15 06:45:11,60,unknown station
R000078,ST03,2025-09-15 07:49:29,-4,minutes outside 1-720
R000121,ST11,,35,started_at empty or not on 2025-09-15
R000150,ST06,2025-09-15 12:53:05,45,ride_id seen before
```

Each row is a different kind of check. `ST13` names a station that does not exist, a **reference**
check. A ride of minus four minutes is outside its **range**. A ride with no start time fails the
check for a **missing value**. And `R000150` arrived twice: the export wrote it again over the ride that
should have come next, `R000151`. Only a **uniqueness** check sees the double, because on its own the
row is perfect. Nothing at the door sees the ride that is missing, since the file still has the 200
rows it promised; that takes the source's own list, which is section 07.

The 16th never gets that far:

```
ana@lab:~/roda/collect$ python door.py 2025-09-16; echo $?
refused: 137 rows arrived, the source says 200
1
```

**The file is refused before a single row is judged**, because 137 good rows are worse than none when
the reader believes they are the whole day. The program ended with an error, which is what a scheduler
watches for: the morning report waits, and somebody asks the source for the rest of the file.

## The rules are decisions, and somebody owns them

Every number in a check was chosen. 720 minutes is twelve hours, longer than any honest ride, and
somebody decided that a longer one is an error rather than a customer who forgot to dock. Write each
rule down with the reason for it, and agree it with the source's owner, because a rule the source
does not know about is broken the first time the source changes. That agreement is the data contract
lesson 4 described.

A quarantine also needs an owner. **A quarantine file nobody reads is a silent drop with an extra
step**: the rows are gone from every report, and the file holding them grows quietly. Decide who
looks at it and how often, and count it: four rows a day is noise, four hundred is a source that
changed.

This section is the door and nothing more. Measuring quality across a whole table, profiling it and
repairing what is wrong is `data-cleaning`; checks written as tests that run inside every pipeline
are `pipelines-etl`.
