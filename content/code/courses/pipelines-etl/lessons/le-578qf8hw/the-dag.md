---
title: A DAG that expects to fail
version: 1
---

Ana's nightly price fetch is lesson 3's `prices.py`, moved inside a task, with every decision about
failure written next to the code it is about:

```schooling-example
{
  "language": "python",
  "file": "dags/prices_daily.py",
  "parts": [
    {
      "code": "\"\"\"The publishers' prices, every night at 03:00, and what to do when the API is down.\"\"\"\nimport datetime as dt\nimport json\nimport os\nimport time\n\n",
      "note": "The standard library's parts: `timedelta` for every duration in the file, `json` to write the prices out, `os` to read the key from the environment, and `time` to wait when the API asks."
    },
    {
      "code": "import pendulum\nimport requests\nfrom airflow.sdk import AsyncCallback, DeadlineAlert, DeadlineReference, dag, task\nfrom airflow.sdk.exceptions import AirflowFailException\nfrom oncall import failed, late\n\n",
      "note": "Airflow's pieces for a deadline, the exception that refuses a retry, and the two callbacks from Ana's `oncall` module, which is in the plugins folder, not here. **This import is the line that failed first.**"
    },
    {
      "code": "URL = \"http://127.0.0.1:8081/v1/prices\"\n\n\n",
      "note": "The API of lesson 3, which the lab serves on the same machine."
    },
    {
      "code": "@dag(\n    schedule=\"0 3 * * *\",\n    start_date=pendulum.datetime(2026, 3, 2, tz=\"America/Sao_Paulo\"),\n    catchup=False,\n",
      "note": "Every night at 03:00, São Paulo time, and no runs invented for the nights before today."
    },
    {
      "code": "    default_args={\n        \"retries\": 4,\n        \"retry_delay\": dt.timedelta(seconds=15),\n        \"retry_exponential_backoff\": 2.0,              # 15 s, then 30, 60, 120\n        \"execution_timeout\": dt.timedelta(minutes=2),\n        \"on_failure_callback\": failed,\n    },\n",
      "note": "**`default_args` apply to every task in the DAG.** Four retries after the first try, so five tries in all; the first wait 15 seconds, each next one twice as long; no try may last more than two minutes; and when a task has failed for good, `failed` is called."
    },
    {
      "code": "    deadline=DeadlineAlert(\n        reference=DeadlineReference.DAGRUN_QUEUED_AT,\n        interval=dt.timedelta(minutes=2),\n        callback=AsyncCallback(late),\n    ),\n)\n",
      "note": "**A deadline belongs to the run, not to a task.** Two minutes after the run was queued, if it has not finished, `late` is called, in the triggerer. In production this would be hours; two minutes is the lab's."
    },
    {
      "code": "def prices_daily():\n    @task\n    def fetch() -> int:\n        headers = {\"X-Api-Key\": os.environ[\"PRICES_API_KEY\"]}\n        params, rows = {\"page_size\": 200}, []\n",
      "note": "One task, written as a function. The key comes from the environment, never from the file."
    },
    {
      "code": "        while True:\n            r = requests.get(URL, headers=headers, params=params, timeout=10)\n",
      "note": "Each page is one request with its own ten-second timeout, which is the network's limit; the two minutes above are the whole task's."
    },
    {
      "code": "            if r.status_code == 429:                  # too fast: wait as told, ask again\n                time.sleep(float(r.headers.get(\"Retry-After\", \"1\")))\n                continue\n",
      "note": "A `429` is handled inside the try, as lesson 3 did: the API says how long to wait, and the same page is asked again. No retry is spent on it."
    },
    {
      "code": "            if r.status_code in (400, 401, 403):      # asking again will not change the answer\n                raise AirflowFailException(f\"the API refused the request: {r.status_code} {r.text}\")\n",
      "note": "**A refusal fails the task at once.** `AirflowFailException` tells Airflow not to retry, whatever `retries` says."
    },
    {
      "code": "            r.raise_for_status()                      # 5xx: worth another try, later\n",
      "note": "Anything else that is not a success — a `503` above all — raises an ordinary exception, and an ordinary exception is retried."
    },
    {
      "code": "            body = r.json()\n            rows += body[\"data\"]\n            if body[\"next_cursor\"] is None:\n                break\n            params[\"cursor\"] = body[\"next_cursor\"]\n",
      "note": "The pages, joined, as in lesson 3."
    },
    {
      "code": "        with open(\"/home/ana/etl/landing/prices.jsonl\", \"w\") as out:\n            out.writelines(json.dumps(row) + \"\\n\" for row in rows)\n        return len(rows)\n\n",
      "note": "**The whole file is rewritten, never appended to**, so a try that runs again after one that got halfway leaves the same file. That is what makes a retry safe here."
    },
    {
      "code": "    fetch()\n\n\nprices_daily()"
    }
  ]
}
```

Two things in it are not in the DAG file at all. `failed` and `late`, the functions that tell a
person, live in a module of their own, because more than one DAG will want them:

```schooling-example
{
  "language": "python",
  "file": "~/airflow/plugins/oncall.py",
  "parts": [
    {
      "code": "\"\"\"Ponto Final's on-call helpers, imported by the DAGs.\n\nIn Airflow's plugins folder rather than in dags/, because a deadline's callback\nruns in the triggerer, and the triggerer can import from here and not from dags/.\"\"\"\n",
      "note": "A module of Ana's own, in Airflow's plugins folder, `~/airflow/plugins`. The docstring says why it is there, and the section below shows what happened before it was."
    },
    {
      "code": "import pendulum\n\nALERTS = \"/home/ana/etl/alerts.log\"\n\n\n",
      "note": "Every alert is one line appended to a file. In production this function would post to a chat channel or page whoever is on call; the line is the same either way."
    },
    {
      "code": "def note(text):\n    now = pendulum.now(\"America/Sao_Paulo\").strftime(\"%Y-%m-%d %H:%M:%S\")\n    with open(ALERTS, \"a\") as f:\n        f.write(f\"{now} {text}\\n\")\n\n\n",
      "note": "**A failure callback receives the task's context**: which DAG, which task, which run, which try, and the exception that ended it."
    },
    {
      "code": "def failed(context):\n    \"\"\"A task has failed for good: no tries left, or none allowed.\"\"\"\n    ti = context[\"ti\"]\n    note(f\"FAILED {ti.dag_id}.{ti.task_id} run={ti.run_id} try={ti.try_number} \"\n         f\"error={context.get('exception')!r}\")\n\n\n",
      "note": "**A deadline callback must be `async`**, because the triggerer runs it, and receives the run rather than a task: the deadline is about the run."
    }
  ]
}
```

## The first failure: a DAG Airflow cannot see

She saved both files with Airflow already running, and asked whether the DAG had loaded:

```
ana@vm:~/etl$ airflow dags list-import-errors -o plain | grep -oE "Error: .*"
Error: No module named 'oncall'
ana@vm:~/etl$ sudo shop airflow-down
ana@vm:~/etl$ sudo shop airflow
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags list-import-errors
No data found
```

**`No module named 'oncall'`.** The DAG file imports a module that the running Airflow cannot find,
so the file does not load, and a DAG whose file does not load does not exist as far as the
scheduler knows: no runs, no tries and no alert. `airflow dags list-import-errors` is the only place
it shows, which makes it **the first command to type when a DAG seems to have done nothing**.

The plugins folder is put on Python's path when each Airflow process starts, and the folder did not
exist when this Airflow started. Restarting it was the fix, and the empty list after the restart is
the DAG loading. The same is true of any later change to `oncall.py`: **a process that has already
imported a module keeps the copy it imported**, so an edit to a plugin needs a restart where an edit
to a DAG file does not.

Why not keep `oncall.py` in `dags/`, where a DAG would have found it straight away? Because one of
its two functions is not run by a task. A deadline's callback runs in the **triggerer**, the process
of lesson 8 that waits on behalf of tasks, and the triggerer does not import from the DAG folder.
Ana's first version of the module did sit beside the DAG; the deadline fired on time, and the
triggerer's log said `No module named 'oncall'` where the alert should have been.
