---
title: Luigi, when a step fails
version: 1
---

The 15th arrives, and Ana asks for its report:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-15
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-15 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 3 tasks of which:
* 1 ran successfully:
    - 1 LoadRaw(day=2026-03-15)
* 1 failed:
    - 1 BuildModels(day=2026-03-15)
* 1 were left pending, among these:
    * 1 had failed dependencies:
        - 1 DailyReport(day=2026-03-15)

This progress looks :( because there were failed tasks

===== Luigi Execution Summary =====
ana@vm:~/etl$ ls marks
models_2026-03-14.done
raw_2026-03-14.done
raw_2026-03-15.done
```

The raw load ran and left its marker. `BuildModels` failed, so it left none, and `DailyReport` was
never tried: its dependency had failed. Luigi's summary names all three, which is the first place to
look. The reason is in dbt's own output:

```
ana@vm:~/etl$ dbt build --project-dir shop 2>&1 | grep -E "FAIL|Done"
06:41:33  14 of 14 FAIL 2 fact_sales_has_not_drifted ..................................... [FAIL 2 in 0.05s]
06:41:33  Done. PASS=11 WARN=1 ERROR=1 SKIP=0 NO-OP=1 REUSED=0 TOTAL=14
ana@vm:~/etl$ dbt build --project-dir shop -s fact_sales+ --full-refresh 2>&1 | grep -E "Done"
06:41:36  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

Lesson 12's drift test, doing its job: two older days of `fact_sales` no longer match the shop.
Ana does what that lesson did, a full refresh of the fact table and what comes after it, and asks
Luigi again:

```
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-15 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 3 tasks of which:
* 1 complete ones were encountered:
    - 1 LoadRaw(day=2026-03-15)
* 2 ran successfully:
    - 1 BuildModels(day=2026-03-15)
    - 1 DailyReport(day=2026-03-15)

This progress looks :) because there were no failed tasks or missing dependencies

===== Luigi Execution Summary =====
```

`LoadRaw` was **complete** — its marker was there — so it was not run a second time, and the two
steps that had not finished ran. This is the useful half of completeness by existence: **a pipeline
resumes from the step that failed, without anybody telling it where that was.** Airflow does the
same with *clear* (lesson 10), but a person has to choose what to clear; Luigi works it out from the
files.

One caution comes with it. The raw marker for the 15th means *the raw load ran once on the day the
15th was asked for*. If the shop had kept trading between the failure and the retry, raw would now
be older than the shop, and Luigi would not reload it. Here nothing moved in between, so nothing
was lost; in a live system, a marker is a promise about the past.
