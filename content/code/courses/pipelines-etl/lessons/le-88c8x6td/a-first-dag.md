---
title: A first DAG
version: 1
---

Ana's DAG runs the steps of `nightly.sh`, from lesson 7, as tasks:

```schooling-example
{
  "language": "python",
  "file": "dags/shop_nightly.py",
  "parts": [
    {
      "code": "\"\"\"Ponto Final's nightly load: the shop into raw, staging rebuilt, the marts loaded.\"\"\"\nimport pendulum\nfrom airflow.providers.standard.operators.bash import BashOperator\nfrom airflow.sdk import dag, task\n\n",
      "note": "Airflow 3 writes DAGs with `airflow.sdk`; operators come from providers, packages installed beside Airflow. `BashOperator` is in the standard provider."
    },
    {
      "code": "ETL = \"/home/ana/etl\"\nPSQL = \"psql -q -v ON_ERROR_STOP=1 -d wh\"\n\n\n",
      "note": "Constants for the commands. Nothing here touches a database: this whole file is run every time Airflow parses it, which the last section of this lesson is about."
    },
    {
      "code": "@dag(\n    schedule=\"0 2 * * *\",\n    start_date=pendulum.datetime(2026, 3, 2, tz=\"America/Sao_Paulo\"),\n    catchup=False,\n    tags=[\"shop\"],\n)\ndef shop_nightly():\n",
      "note": "**The DAG's own settings.** Run at 02:00 every day, São Paulo time; the first run that may exist is 2 March; `catchup=False` means do not invent runs for the days before today — lesson 9 is about what `True` would do."
    },
    {
      "code": "    @task\n    def day_to_load(logical_date=None) -> str:\n        \"\"\"The run at 02:00 loads the day that has just ended, in São Paulo.\"\"\"\n        return logical_date.in_timezone(\"America/Sao_Paulo\").subtract(days=1).to_date_string()\n\n",
      "note": "A task written as a Python function. It asks for `logical_date` by name, and Airflow passes it in. **It works out the day to load from the run, not from the clock** — the section on the logical date says why."
    },
    {
      "code": "    day = day_to_load()\n",
      "note": "Calling the function inside the DAG does not run it; it adds the task to the DAG and returns a handle to what it will return."
    },
    {
      "code": "    extract = BashOperator(task_id=\"extract\", bash_command=\"python load_raw.py\", cwd=ETL)\n    # as the name of a template file to load, and fails before it runs.\n    transform = BashOperator(task_id=\"transform\", bash_command=\"sh run_sql.sh\", cwd=ETL)\n    dim_customer = BashOperator(task_id=\"dim_customer\",\n                                bash_command=f\"{PSQL} -f load/dim_customer.sql\", cwd=ETL)\n    dim_book = BashOperator(task_id=\"dim_book\",\n                            bash_command=f\"{PSQL} -f load/dim_book.sql\", cwd=ETL)\n    fact_sales = BashOperator(task_id=\"fact_sales\",\n                              bash_command=f\"{PSQL} -v day={day} -f load/fact_sales.sql\",\n                              cwd=ETL)\n\n",
      "note": "Ana's scripts from lessons 6 and 7, one task each, run in `~/etl`. In `fact_sales`, `{day}` inside an f-string becomes a template that fetches `day_to_load`'s answer when the task runs, so the fact load is told which day."
    },
    {
      "code": "    extract >> transform >> [dim_customer, dim_book]\n    [day, dim_customer] >> fact_sales\n\n\n",
      "note": "**The order.** `>>` means *runs before*. A list on one side means every task in it. Nothing runs in the order it was written; everything runs in the order these two lines say."
    },
    {
      "code": "shop_nightly()"
    }
  ]
}
```

Six tasks, and between them five arrows. `extract` must finish before `transform`, which must
finish before both dimension loads; the fact load waits for the customer dimension and for the day
to be worked out. **`dim_book` and `dim_customer` have no arrow between them**, so Airflow is free to
run them at the same time, and with `LocalExecutor` it does.

The file goes in the DAG folder, `~/etl/dags`. The DAG processor finds it within seconds, and
`airflow dags test` runs one complete run of it in the terminal, without the scheduler — which is
how a DAG is tried before it is trusted. A test run prints every line of every task's log, so Ana
first writes a filter that keeps what ran, how each task ended and any error:

```
#!/bin/sh
# airflow dags test prints every line of every task's log. Keep the lines that
# say what ran, how it ended, and any error.
grep -oE "\[DAG TEST\] end task task_id=[a-z_]+|Running command: \[[^]]*\]|Command exited with return code [0-9]+|[A-Za-z0-9.]*(Error|NotFound): .*|DagRun Finished: dag_id=[a-z_]+, logical_date=[^,]+|state=[a-z]+, run_type=[a-z]+"
```

Then she asks Airflow to read the folder now rather than at its next pass, lists the DAGs, counts
the lines a test run prints, and runs it through the filter:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags list
dag_id       | fileloc                            | owners  | is_paused | bundle_name | bundle_version
=============+====================================+=========+===========+=============+===============
shop_nightly | /home/ana/etl/dags/shop_nightly.py | airflow | True      | dags-folder | None          
                                                                                                      
ana@vm:~/etl$ airflow dags test shop_nightly 2026-03-03 2>&1 | wc -l
134
ana@vm:~/etl$ airflow dags test shop_nightly 2026-03-03 2>&1 | sh trace.sh
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
[DAG TEST] end task task_id=day_to_load
Running command: ['/usr/bin/bash', '-c', 'python load_raw.py']
Command exited with return code 0
[DAG TEST] end task task_id=extract
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
[DAG TEST] end task task_id=transform
DagRun Finished: dag_id=shop_nightly, logical_date=2026-03-03 03:00:00+00:00
state=failed, run_type=manual
```

Airflow knows the DAG, and it is paused — every new DAG is, until somebody unpauses it, so that a
file copied into the folder by mistake does not start running on its own. `dags test` runs it
anyway.

**It failed**, in the middle of 134 lines, which is why the filter exists. The error is in the
`transform` task, and its command never ran: `TemplateNotFound: 'sh run_sql.sh'`. `extract` and
`day_to_load` succeeded, and nothing after `transform` was attempted, because everything after it
waits for it. The next section says why it failed, and how one space fixes it.
