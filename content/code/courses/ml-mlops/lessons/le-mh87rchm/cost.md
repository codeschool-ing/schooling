---
title: What each kind of serving costs to keep
version: 1
---

Money for a model in production is mostly money for the machine it runs on, and the machine is
paid for by the hour whether it is busy or not. **So the useful measure is what a deployment holds
and for how long**, and the two kinds built in lesson 8 differ by orders of magnitude in the second.

The service, while it is running, holds this much memory, in kilobytes:

```
ana@dev:~/ml$ ps -o rss=,comm= -C uvicorn
340640 uvicorn
```

About 330 MB, for one process with one copy of the model, the online store's connection and the
libraries behind them. It holds that every hour of every day, because a service that is not running
cannot answer, and it holds it at three in the morning when nobody asks. Four workers, the remedy of
the previous section, hold four times as much.

The batch, timed with the shell's own `time`:

```
ana@dev:~/ml$ time python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 3355 rows in lapse_scores

real	0m4.122s
user	0m4.482s
sys	0m0.353s
```

**Four seconds of one processor, once a night**, for every active member. `real` is the time on the
clock; `user` and `sys` are the processor's time, in the program and in the system on its behalf,
which can add to more than `real` when the libraries use several cores at once. A month of nights is
about two minutes of computation, and the memory it needs is given back the moment it ends.

| | batch | service |
| --- | --- | --- |
| held | for four seconds a night | all day, every day |
| a month of it | about 2 minutes of one processor | 720 hours of 330 MB, per worker |
| grows with | the number of members | the busiest minute of the day |
| cost per score | falls as members grow | high when idle, low when busy |

**A service is sized for its busiest minute and paid for in its quietest.** That is the real price
of real time, and it is why lesson 8 said to start with batch. Compute the price in money with your
provider's rates for a processor-hour and a gigabyte-hour; the ratio between the two columns will not
change much, and the ratio is the argument.

**The same accounting applies to the model's own cost.** A bigger model that buys a point of average
precision also buys more memory per worker and slower predictions, which means more workers for the
same p99. Whether that point is worth it is a question for the people who use the scores, asked with
both numbers on the table.
