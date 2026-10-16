---
title: The same report on one machine
version: 1
---

**Lesson 1 promised to run the question on a single-machine engine as well, and this is the right
moment**: the report has been tuned, and sixteen seconds is what a well-written Spark job takes on
this lab. DuckDB is a database that runs inside the program that uses it, reads Parquet by column and
by row group as Spark does, uses every core and spills to disk when memory runs short. It installs as
a Python package:

```sh
python3 -m venv ~/duck-env
~/duck-env/bin/pip install duckdb==1.5.6
```

The same report, as one SQL query over the same files. Save this as `~/big/report_duckdb.py`:

```schooling-example
{
  "language": "python",
  "file": "report_duckdb.py",
  "parts": [
    {
      "code": "\"\"\"The morning report again, on one machine, with DuckDB instead of a cluster.\"\"\"\nimport time\n\nimport duckdb\n\n"
    },
    {
      "code": "db = duckdb.connect()\n",
      "note": "**The same files, read by an engine that runs inside this Python process.** DuckDB reads Parquet by column and by row group like Spark, uses every core of the machine, and spills to disk when memory runs short. `hive_partitioning` turns the `day=` directories into a column, as Spark did."
    },
    {
      "code": "db.sql(\"SET TimeZone = 'America/Sao_Paulo'\")\nstart = time.time()\nrows = db.sql(\"\"\"\n    SELECT strftime(date_trunc('month', timezone('UTC', ts)), '%Y-%m') AS month, category,\n           count(*) AS purchases, sum(price_cents) AS cents\n    FROM read_parquet('data/silver/clicks/*/*.parquet', hive_partitioning = true)\n    JOIN read_parquet('data/silver/books/*.parquet') USING (book_id)\n    WHERE kind = 'purchase'\n    GROUP BY ALL\n    ORDER BY month, cents DESC\"\"\").fetchall()\nprint(f\"{len(rows)} rows in {time.time() - start:.1f} s; top of January:\",\n      [(r[1], r[3] // 100) for r in rows[:2]])\n",
      "note": "**The months in São Paulo's time**, as Spark's session counted them. Spark wrote the timestamps as UTC with no zone attached, so `timezone('UTC', ts)` says what they are, and the session's zone decides where each month begins."
    }
  ]
}
```

```
ana@lab:~/big$ ~/duck-env/bin/python report_duckdb.py
120 rows in 0.8 s; top of January: [('poetry', 997352), ('science', 877502)]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l14-fixes\" aria-label=\"Horizontal bars of the morning report's time. All four mistakes: 131.1 seconds. Parquet instead of CSV: 105.7. A built-in function instead of Python: 75.4. Adaptive execution: 18.0. Broadcast allowed: 15.9. The same report in DuckDB on one machine: 0.8.\"><path d=\"M180.0 236.0 L660.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M180.0 236.0 L180.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M248.6 236.0 L248.6 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"248.6\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M317.1 236.0 L317.1 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"317.1\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M385.7 236.0 L385.7 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"385.7\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M454.3 236.0 L454.3 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"454.3\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><path d=\"M522.9 236.0 L522.9 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"522.9\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M591.4 236.0 L591.4 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"591.4\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><path d=\"M660.0 236.0 L660.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">140</text><text x=\"420.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">seconds</text><rect x=\"180.0\" y=\"26.0\" width=\"449.5\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">all four mistakes</text><text x=\"635.5\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">131.1 s</text><rect x=\"180.0\" y=\"61.0\" width=\"362.4\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Parquet, not CSV</text><text x=\"548.4\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">105.7 s</text><rect x=\"180.0\" y=\"96.0\" width=\"258.5\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">built-in, not Python</text><text x=\"444.5\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75.4 s</text><rect x=\"180.0\" y=\"131.0\" width=\"61.7\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">adaptive execution</text><text x=\"247.7\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18.0 s</text><rect x=\"180.0\" y=\"166.0\" width=\"54.5\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">broadcast allowed</text><text x=\"240.5\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15.9 s</text><rect x=\"180.0\" y=\"201.0\" width=\"2.7\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"213.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">DuckDB, one machine</text><text x=\"188.7\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8 s</text></svg>", "caption": "Each fix measured on its own, and one machine faster than all of them."}
```

**The same 120 rows, the same January totals, in about a second**: twenty times faster than the
tuned Spark job, on the same machine and the same files. Nothing went wrong with Spark. DuckDB starts
no JVM, ships nothing to executors, shuffles nothing between processes and schedules no tasks; every
one of those costs is what makes Spark able to use a hundred machines, and on one machine they are
all overhead.

**That is lesson 1's answer, measured.** 400 MB of Parquet is not big data. A single machine with an
engine built for analysis handles tens or hundreds of gigabytes like this; a cluster earns its
overhead when the data, or the work per row, is past what one machine can get through in the time
there is. The rest of this lesson prices the cluster for when it does.
