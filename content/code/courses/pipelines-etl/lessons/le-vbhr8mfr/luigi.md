---
title: Luigi: done means the output exists
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "nightly_luigi.py",
  "parts": [
    {
      "code": "\"\"\"The nightly load as three Luigi tasks. A task is done when its output exists.\"\"\"\nimport subprocess\n\nimport luigi\n\n\n",
      "note": "Luigi is a library: a pipeline is a Python module, and each step is a class."
    },
    {
      "code": "class LoadRaw(luigi.Task):\n    day = luigi.DateParameter()\n\n",
      "note": "A **parameter** is part of the task's identity. `LoadRaw` for the 14th and `LoadRaw` for the 15th are two different tasks."
    },
    {
      "code": "    def output(self):\n        return luigi.LocalTarget(f\"marks/raw_{self.day}.done\")\n\n",
      "note": "**`output` is how Luigi decides whether a task is done**: if the target exists, the task is complete and is never run. A database load leaves no file, so Ana's tasks write a small marker file to stand for it."
    },
    {
      "code": "    def run(self):\n        subprocess.run([\"python\", \"load_raw.py\"], check=True)\n        with self.output().open(\"w\") as mark:\n            mark.write(\"loaded\\n\")\n\n\n",
      "note": "The work, and then the marker. If the work fails, no marker is written, and the next run tries again."
    },
    {
      "code": "class BuildModels(luigi.Task):\n    day = luigi.DateParameter()\n\n",
      "note": "The second step, with its own parameter."
    },
    {
      "code": "    def requires(self):\n        return LoadRaw(self.day)\n\n",
      "note": "**`requires` is the dependency**: the models for a day need the raw load for that day. Luigi builds the graph by following these calls back from the task it is asked for."
    },
    {
      "code": "    def output(self):\n        return luigi.LocalTarget(f\"marks/models_{self.day}.done\")\n\n    def run(self):\n        subprocess.run([\"dbt\", \"build\", \"--project-dir\", \"shop\", \"--quiet\"], check=True)\n        with self.output().open(\"w\") as mark:\n            mark.write(\"built\\n\")\n\n\n",
      "note": "Another marker, after `dbt build` has built and tested everything."
    },
    {
      "code": "class DailyReport(luigi.Task):\n    day = luigi.DateParameter()\n\n    def requires(self):\n        return BuildModels(self.day)\n\n",
      "note": "The last task, and the only one whose output is the real product: the CSV file for the managers."
    },
    {
      "code": "    def output(self):\n        return luigi.LocalTarget(f\"reports/daily_{self.day}.csv\")\n\n",
      "note": "The report's own output."
    },
    {
      "code": "    def run(self):\n        query = (\"COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales \"\n                 f\"WHERE order_date = '{self.day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)\")\n        csv = subprocess.run([\"psql\", \"-d\", \"wh\", \"-c\", query], check=True,\n                             capture_output=True, text=True).stdout\n        with self.output().open(\"w\") as out:      # written to a temporary file, renamed at the end\n            out.write(csv)",
      "note": "One day of `daily_sales`, copied out by `psql`. Writing through the target's `open` makes the file appear whole or not at all."
    }
  ]
}
```

Luigi is asked for the task at the end, and works backwards: `DailyReport` for the 14th requires
`BuildModels` for the 14th, which requires `LoadRaw` for the 14th. Whatever is not complete is run,
in dependency order. `--local-scheduler` runs it all in this process; Luigi also has a central
scheduler, `luigid`, which stops two people running the same task at once and draws the graph in a
browser, and which the lab does not start. `PYTHONPATH=.` is there because Luigi imports the module
by name, and the current directory is not on Python's path for an installed command.

```
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-14 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 3 tasks of which:
* 3 ran successfully:
    - 1 BuildModels(day=2026-03-14)
    - 1 DailyReport(day=2026-03-14)
    - 1 LoadRaw(day=2026-03-14)

This progress looks :) because there were no failed tasks or missing dependencies

===== Luigi Execution Summary =====
ana@vm:~/etl$ ls marks reports
marks:
models_2026-03-14.done
raw_2026-03-14.done

reports:
daily_2026-03-14.csv
ana@vm:~/etl$ head -4 reports/daily_2026-03-14.csv
shop_id,category,books,revenue_cents
1,Biography,6,58340
1,Business,7,61430
1,Cooking,9,54810
```

Three tasks, three outputs: two markers and the report. Now the same command again:

```
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-14 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 1 tasks of which:
* 1 complete ones were encountered:
    - 1 DailyReport(day=2026-03-14)

Did not run any tasks
This progress looks :) because there were no failed tasks or missing dependencies

===== Luigi Execution Summary =====
```

**Nothing ran.** Luigi asked `DailyReport` for the 14th whether it was complete, the file was there,
and that was the end of it — it did not even look at the two tasks before. This is Luigi's whole
idea, and it is a good one: **a pipeline that is asked to run twice does the work once**, and a
pipeline that fails halfway resumes where it stopped, as the next section shows.

It is also its weakness, and the markers show where. A marker says that a step finished once. It
does not say that what the step produced is still right. If the shop's 14th changes tomorrow — a
refund, as lesson 11 found — `reports/daily_2026-03-14.csv` is still there, Luigi still calls it
complete, and nothing will ever write it again unless somebody deletes the file. **Completeness by
existence is exact for files that never change, and only approximate for anything in a database.**
