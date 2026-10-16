---
title: One fix at a time
version: 1
---

**Change one thing, measure, keep it or put it back.** Changing four things at once and finding the
job faster says nothing about which of them mattered, and the next job will have a different mix.
The same report, with one mistake removed per run:

```
ana@lab:~/big$ spark-submit report.py --udf --partitions 2000 --no-broadcast 2>/dev/null
120 rows in 105.7 s; top of January: [('poetry', 997352), ('science', 877502)]
ana@lab:~/big$ spark-submit report.py --partitions 2000 --no-broadcast 2>/dev/null
120 rows in 75.4 s; top of January: [('poetry', 997352), ('science', 877502)]
ana@lab:~/big$ spark-submit report.py --no-broadcast 2>/dev/null
120 rows in 18.0 s; top of January: [('poetry', 997352), ('science', 877502)]
ana@lab:~/big$ spark-submit report.py 2>/dev/null
120 rows in 15.9 s; top of January: [('poetry', 997352), ('science', 877502)]
```

| run | change | time | saved |
|---|---|---|---|
| 1 | all four mistakes | 131.1 s | |
| 2 | silver Parquet instead of CSV | 105.7 s | 25.4 s |
| 3 | `date_trunc` instead of a Python function | 75.4 s | 30.3 s |
| 4 | adaptive execution and its own partition count | 18.0 s | 57.4 s |
| 5 | broadcast allowed | 15.9 s | 2.1 s |

**Eight times faster, and no change to the answer.** Each fix is one lesson's lesson. The CSV cost
parsing every line of text and reading every column; Parquet read three. The Python function cost a
trip to a Python worker for each of 960,000 purchases. The 2,000 partitions cost 2,000 tasks reading
almost nothing each, the overhead lesson 7 measured, where adaptive execution merged them to a handful.

**The last fix saved two seconds**, and that is a finding too. With adaptive execution on, the
join's shuffle was small, the purchases only, and a sort-merge join of small partitions costs little
more than a broadcast. A fix that matters in one job is noise in another, which is why each one is
measured on its own.

And the history server, for the fast version:

```
ana@lab:~/big$ python3 history.py report
app-20261016062256-0017 40.6 s
stage  tasks  wall s  task s  input MiB  shuffle MiB  spill MiB  name
    4     15    10.4    26.5       26.3          0.0        0.0  collect at /home/ana/big/rep
    0    365    10.2     3.4        0.0          0.0        0.0  parquet at NativeMethodAcces
    3      1     1.2     1.0        0.0          0.0        0.0  collect at /home/ana/big/rep
    1      1     0.8     0.7        0.0          0.0        0.0  parquet at NativeMethodAcces
    2      1     0.8     0.6        0.0          0.0        0.0  parquet at NativeMethodAcces
    8      1     0.4     0.3        0.0          0.1        0.0  collect at /home/ana/big/rep
```

**The slowest stage now reads Parquet and does nothing slow per row.** What is left is mostly reading
24 million rows' worth of three columns from 365 files, and lesson 10's choices are what would cut it
further.
