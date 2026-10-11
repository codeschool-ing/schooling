---
title: Batch, a job over a window that has closed
version: 1
---

**A batch job answers a question about a window that has already closed.** Monday's rides per station
can be counted once Monday is over, and not before: until midnight more rides can start. So the job is
scheduled for after the window ends, reads everything inside it, and writes one answer.

At Roda Livre that job runs at 01:00, every night, for the day before. Something has to start it at
01:00, check that it finished and start it again when it fails; that is a scheduler or an orchestrator,
and `pipelines-etl` is where they are built. Here you start the job by hand. Save it as
`stream/daily.py`:

```python
# stream/daily.py
import csv
import json
import sys
from collections import Counter

day = sys.argv[1]                                     # the window: one whole day
asof = sys.argv[2] if len(sys.argv) > 2 else '9999'  # only what had arrived by then
rides = Counter()
with open('docks.jsonl') as f:
    for line in f:
        e = json.loads(line)
        if e['kind'] == 'undock' and e['event_time'].startswith(day) and e['arrived'] < asof:
            rides[e['station']] += 1
with open(f'daily-{day}.csv', 'w', newline='') as f:  # the day's file, replaced whole
    out = csv.writer(f)
    out.writerow(['station', 'rides'])
    out.writerows(sorted(rides.items()))
print(f'{day}: {sum(rides.values())} rides, written to daily-{day}.csv')
```

A ride starts with an undock, so the job counts undocks whose `event_time` falls on the day. The second
argument is there for this lesson only. The file already holds all three mornings, and a job that really
ran at 01:00 on Tuesday could only have seen what had arrived by then; `asof` makes the program see
exactly that and nothing later. Run Monday as the 01:00 job would have:

```
ana@lab:~/roda/stream$ python daily.py 2025-10-06 "2025-10-07 01:00"
2025-10-06: 118 rides, written to daily-2025-10-06.csv
ana@lab:~/roda/stream$ cp daily-2025-10-06.csv first-run.csv
```

The generator made 120 rides a morning, so two are missing, and nothing in the output says so. The
copy, `first-run.csv`, keeps this answer so it can be compared later.

## A backfill is the same job, run again for windows in the past

The two missing rides started at Passeio Público, whose sensors lost their link at 09:20 on Monday and
sent everything they held at 07:02 on Tuesday, six hours after the job had run. The window was closed
by the clock and still open in fact.

**Running a batch job again over windows that have already been processed is a backfill.** It happens for
three ordinary reasons: data that arrived after the job ran, a bug fixed in the job, and a new column
somebody wants for the whole history and not only from today. Here it is the first reason, and the
backfill runs the job for all three days:

```
ana@lab:~/roda/stream$ for day in 2025-10-06 2025-10-07 2025-10-08; do python daily.py $day; done
2025-10-06: 120 rides, written to daily-2025-10-06.csv
2025-10-07: 120 rides, written to daily-2025-10-07.csv
2025-10-08: 120 rides, written to daily-2025-10-08.csv
ana@lab:~/roda/stream$ diff first-run.csv daily-2025-10-06.csv
5c5
< ST04,8
---
> ST04,10
```

Monday now has its 120 rides, and the only line that changed is Passeio Público's, `ST04`, from 8 to
10.

Two things made that safe, and both are from lesson 3. The job **replaces** the day's file rather than
appending to it, so running it twice leaves one answer, not two added together. And the raw events are
**kept**: a backfill reads the past again, and it can only do that if the past was not thrown away
after the first run.

## What batch is good at

A batch job is simple to write, simple to test and simple to run again. It sees the whole window at
once, so a count, a join or a ranking is computed over all of it. When it fails, it is started again,
and nothing was lost in the meantime because the input is still there. It costs nothing between runs.

What it cannot do is answer early. A ride that started at 08:00 on Monday is in a report at 01:00 on
Tuesday, seventeen hours later, and that delay is built into the design rather than caused by a slow
machine. When an answer is worth less after seventeen hours, or after seventeen minutes, the job needs
a different shape.
