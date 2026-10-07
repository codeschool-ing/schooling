---
title: Dagster: the pipeline is the data it makes
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "nightly_dagster.py",
  "parts": [
    {
      "code": "\"\"\"The nightly load as three Dagster assets: what should exist, and what it is made from.\"\"\"\nimport subprocess\n\nimport dagster as dg\n\n\n",
      "note": "Dagster is also a library, and its unit is not a task."
    },
    {
      "code": "class Day(dg.Config):\n    day: str\n\n\n",
      "note": "Configuration for a run, declared as a class: the day of the report, given on the command line."
    },
    {
      "code": "@dg.asset\ndef raw_tables():\n    \"\"\"The shop's tables, copied into raw by load_raw.py.\"\"\"\n    subprocess.run([\"python\", \"load_raw.py\"], check=True)\n\n\n",
      "note": "**An asset is something that should exist** — here, the raw tables — and the function is how to make it. Running the function is *materializing* the asset."
    },
    {
      "code": "@dg.asset(deps=[raw_tables])\ndef dbt_models():\n    \"\"\"Every model of the dbt project, built and tested.\"\"\"\n    subprocess.run([\"dbt\", \"build\", \"--project-dir\", \"shop\", \"--quiet\"], check=True)\n\n\n",
      "note": "`deps` names the assets this one is made from. Same idea as dbt's `ref` and Airflow's assets: the dependency is between things, not between steps."
    },
    {
      "code": "@dg.asset(deps=[dbt_models])\ndef daily_report(config: Day) -> dg.MaterializeResult:\n    \"\"\"One day of daily_sales as a CSV file, for the managers.\"\"\"\n",
      "note": "The report takes the day from its configuration."
    },
    {
      "code": "    query = (\"COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales \"\n             f\"WHERE order_date = '{config.day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)\")\n    csv = subprocess.run([\"psql\", \"-d\", \"wh\", \"-c\", query], check=True,\n                         capture_output=True, text=True).stdout\n    path = f\"reports/daily_{config.day}.csv\"\n    with open(path, \"w\") as out:\n        out.write(csv)\n",
      "note": "The same copy as in the other two tools."
    },
    {
      "code": "    return dg.MaterializeResult(metadata={\"path\": path, \"rows\": csv.count(\"\\n\") - 1})\n\n\n",
      "note": "**Metadata goes with the materialization** and is stored by Dagster: where the file is, and how many rows it has. The next section reads it back."
    },
    {
      "code": "defs = dg.Definitions(assets=[raw_tables, dbt_models, daily_report])",
      "note": "The definitions Dagster loads from the module: the three assets."
    }
  ]
}
```

Luigi and Prefect describe **steps**. Dagster describes **assets**: the raw tables, the dbt models,
the report — things that should exist — each with the function that makes it and the assets it is
made from. Running the functions is *materializing* the assets, and the order comes from `deps`.
It is the idea Airflow added in lesson 9 and dbt was built on in lesson 11, taken as the starting
point rather than added later.

Dagster keeps its records in a directory named by `DAGSTER_HOME`, and Ana turns off its usage
statistics there before the first run, for the same reason as with Prefect. Then she materializes
everything, giving the report its day:

```
ana@vm:~/etl$ mkdir -p ~/dagster && printf "telemetry:\n  enabled: false\n" > ~/dagster/dagster.yaml
ana@vm:~/etl$ export DAGSTER_HOME=~/dagster; dagster asset materialize -m nightly_dagster --select "*" --config-json "{\"ops\": {\"daily_report\": {\"config\": {\"day\": \"2026-03-15\"}}}}" 2>&1 | grep -oE "(STEP_SUCCESS|STEP_FAILURE|RUN_SUCCESS|RUN_FAILURE) - .*"
STEP_SUCCESS - Finished execution of step "raw_tables" in 559ms.
STEP_SUCCESS - Finished execution of step "dbt_models" in 3.43s.
STEP_SUCCESS - Finished execution of step "daily_report" in 70ms.
RUN_SUCCESS - Finished execution of run for "__ASSET_JOB".
```

One line per asset and one for the run, filtered from a good deal more: Dagster logs every event of
every step, each in its own process. What Dagster then **keeps** is the interesting part. It
records every materialization of every asset, with its time and its metadata, and a short script
can ask:

```
"""What Dagster remembers: the last time each asset was materialized, and what it said."""
import datetime as dt

import dagster as dg

instance = dg.DagsterInstance.get()
for name in ["raw_tables", "dbt_models", "daily_report"]:
    event = instance.get_latest_materialization_event(dg.AssetKey(name))
    when = dt.datetime.fromtimestamp(event.timestamp).strftime("%H:%M:%S")
    meta = event.asset_materialization.metadata
    print(f"{name:<13}{when}  " + "  ".join(f"{k}={v.value}" for k, v in meta.items()))
ana@vm:~/etl$ DAGSTER_HOME=~/dagster /opt/etl/dagster/bin/python latest.py
raw_tables   03:42:15  
dbt_models   03:42:20  
daily_report 03:42:22  path=reports/daily_2026-03-15.csv  rows=86
done
```

The answer is the state of the data, not of a run: when each thing was last made, and what it said
about itself. The report's metadata — the path and the 86 rows — was returned by the function and
stored with the event. In Dagster's web interface, `dagster dev`, the same records drive the asset
graph, and an asset whose upstream has been materialized more recently than it is marked as stale.
The lab does not run the interface; the records are the same ones the script read.

Scheduling is a **schedule** or a **sensor** attached to a selection of assets, run by
`dagster-daemon`, which the lab does not start either.
