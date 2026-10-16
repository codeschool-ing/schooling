---
title: Reading a finished job
version: 1
---

**A slow job is found after it has finished, from what it left behind.** The driver that ran the
report is gone; its event log is in `~/spark-events`, and lesson 7's history server reads it. This
program asks the history server for the stages of the newest application with a given name, the
slowest first. Save it as `~/big/history.py`:

```schooling-example
{
  "language": "python",
  "file": "history.py",
  "parts": [
    {
      "code": "\"\"\"The stages of a finished application, read back from the history server.\"\"\"\nimport json\nfrom datetime import datetime\nimport sys\nimport urllib.request\n\nHISTORY = \"http://localhost:18080/api/v1\"\n\n\ndef get(path):\n    return json.load(urllib.request.urlopen(f\"{HISTORY}/{path}\"))\n\n\n"
    },
    {
      "code": "app = next(a for a in get(\"applications?status=completed&limit=50\") if a[\"name\"] == sys.argv[1])\nprint(app[\"id\"], f\"{app['attempts'][0]['duration'] / 1000:.1f} s\")\n\n",
      "note": "**The newest finished application with the name given**, from the history server of lesson 7: the driver is long gone, and its event log is all that is left."
    },
    {
      "code": "print(\"stage  tasks  wall s  task s  input MiB  shuffle MiB  spill MiB  name\")\nstages = [s for s in get(f\"applications/{app['id']}/stages\") if s[\"status\"] == \"COMPLETE\"]\nfor s in sorted(stages, key=lambda s: -s[\"executorRunTime\"])[:6]:\n    first, last = (datetime.strptime(s[k][:23], \"%Y-%m-%dT%H:%M:%S.%f\")\n                   for k in (\"firstTaskLaunchedTime\", \"completionTime\"))\n    wall = (last - first).total_seconds()\n    print(f\"{s['stageId']:5} {s['numTasks']:6} {wall:7.1f} {s['executorRunTime'] / 1000:7.1f}\"\n          f\" {s['inputBytes'] / 2**20:10.1f} {s['shuffleReadBytes'] / 2**20:12.1f}\"\n          f\" {s['diskBytesSpilled'] / 2**20:10.1f}  {s['name'][:28]}\")\n",
      "note": "**One line per stage that ran**, slowest first: its tasks, the wall-clock time from its first task's start to its last task's end, the task time added up, and the bytes it read, shuffled and spilled."
    }
  ]
}
```

It needs no Spark, so it runs with plain `python3`:

```
ana@lab:~/big$ python3 history.py report
app-20261016061511-0013 156.0 s
stage  tasks  wall s  task s  input MiB  shuffle MiB  spill MiB  name
    4   2000    73.4   172.6        0.0          9.8        0.0  collect at /home/ana/big/rep
    3     14    23.3    57.0      239.3          0.0        0.0  collect at /home/ana/big/rep
    5   2000    15.8    11.3        0.0          2.9        0.0  collect at /home/ana/big/rep
    9   2000    14.1    10.0        0.0          2.9        0.0  collect at /home/ana/big/rep
    2      1     5.3     4.0        0.0          0.0        0.0  collect at /home/ana/big/rep
    0    365     9.8     3.5        0.0          0.0        0.0  csv at NativeMethodAccessorI
```

**Read it from the top.** The slowest stage has 2,000 tasks between them reading under 10 MiB of
shuffle: it is the sort-merge join, cut into the fixed 2,000 partitions, and it is also where the
Python function ran on every purchase before the counts. 172.6 task-seconds, the most of any stage,
and the second, third and fourth fixes are all about it. The next one read the raw CSV, all 239 MiB of gzipped text in
14 tasks, for 57 task-seconds: the first fix. Two more stages of 2,000 tasks each follow, the final
grouping and the sort of the result, every task reading almost nothing.

The columns are lesson 7's, read from a different place. **Wall time against task time** says how
parallel a stage was: three executors running all the time would make task time three times wall
time. **Input** says what was read from files, **shuffle** what was moved between stages, and
**spill** what did not fit in memory. A stage with large task time and nothing remarkable in the other
columns is doing slow work per row, which is what a Python function and the parsing of text look like
from outside.
