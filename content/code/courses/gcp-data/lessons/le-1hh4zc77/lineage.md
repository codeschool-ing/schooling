---
title: Lineage, and the event a job sends
version: 1
---

**Lineage is the record of which job made which data from which other data.** It answers the two
questions that come after every incident. Upstream: the finance export for 1 October is wrong, so
where did its numbers come from? Downstream: the raw orders file of 1 October was loaded twice, so
which tables and exports inherited the double? Without lineage both are answered by reading the code
of every job, which is slow on a good day and impossible on the day it matters.

**A lineage graph has two kinds of node and one kind of edge.** Datasets are the nouns, a table or a
file; jobs are the verbs, the process that read some datasets and wrote others; and an edge says that
one run of a job read this and wrote that. Google's Data Lineage API keeps three resources that map
onto it: a **process** is the job, a **run** is one execution of it, and a **lineage event** records
the links from sources to targets that one run made.

## Where the events come from

**Some of Google Cloud reports lineage on its own.** With the Data Lineage API enabled in a project,
BigQuery records a lineage event for every query job that writes a table, a `CREATE TABLE … AS
SELECT` or an `INSERT … SELECT`. The documentation lists other services that do the same for
their jobs, among them Dataproc, Cloud Composer and Dataflow. Nothing in the job's code changes. The
pricing page calls this **automatic lineage parsing** and bills it as premium processing, because
Google spends compute reading the jobs to find the links.

**Everything else reports its own, in OpenLineage.** OpenLineage is an open standard, a project of the
Linux Foundation, for exactly this: a JSON event that a job sends when it starts, completes or fails,
naming the job, the run, and its input and output datasets. The Data Lineage API accepts these events
through a method called `ProcessOpenLineageRunEvent`, and the pricing page says that lineage reported
this way, which it calls custom, is free, as is reading lineage back.

## The events of Quitanda's nightly pipeline

Three jobs run every night. `load_orders` reads the raw CSV from `quitanda-raw-prod` into the BigQuery
table `curated.orders`; `daily_revenue` joins `curated.orders` with `curated.customers` into
`curated.daily_revenue`; `export_finance` writes that table out as a CSV in `quitanda-curated-prod`
for the finance team. This program writes the event each job would send on completing, as files,
because there is nowhere here to send them. Save it as `~/gcp/emit.py`:

```schooling-example
{"language": "python", "file": "emit.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Write the OpenLineage run events of Quitanda's nightly pipeline into ./events, one file each.\n\n    python3 emit.py 2026-10-01\n\nNothing is sent anywhere: these are the events a job would send to a lineage service.\n\"\"\"\nimport json\nimport pathlib\nimport sys\nimport uuid\n\n", "note": "It writes events and sends nothing. A real job would send each one at the moment it finished, to a lineage service."}, {"code": "day = sys.argv[1]\nRAW = ('gs://quitanda-raw-prod', f'raw/orders/dt={day}/orders.csv')\nORDERS = ('bigquery', 'planner-dev.curated.orders')\nCUSTOMERS = ('bigquery', 'planner-dev.curated.customers')\nREVENUE = ('bigquery', 'planner-dev.curated.daily_revenue')\nEXPORT = ('gs://quitanda-curated-prod', f'finance/revenue/dt={day}/revenue.csv')\n", "note": "**Every dataset is a pair, a namespace and a name**, in OpenLineage's convention: `bigquery` and the table's full name, or a bucket and an object path. The day is part of the file names, so each night's files are different datasets."}, {"code": "JOBS = [\n    ('load_orders', [RAW], [ORDERS]),\n    ('daily_revenue', [ORDERS, CUSTOMERS], [REVENUE]),\n    ('export_finance', [REVENUE], [EXPORT]),\n]\n\n", "note": "The three jobs, with what each one reads and writes. `daily_revenue` reads two tables."}, {"code": "out = pathlib.Path('events')\nout.mkdir(exist_ok=True)\nfor n, (job, inputs, outputs) in enumerate(JOBS, start=1):\n", "note": "One file per event, numbered in the order the jobs run."}, {"code": "    event = {\n        'eventType': 'COMPLETE',\n        'eventTime': f'{day}T03:{10 * n:02d}:00-03:00',\n        'run': {'runId': str(uuid.uuid5(uuid.NAMESPACE_URL, f'{job}/{day}'))},\n        'job': {'namespace': 'quitanda-nightly', 'name': job},\n        'inputs': [{'namespace': ns, 'name': name} for ns, name in inputs],\n        'outputs': [{'namespace': ns, 'name': name} for ns, name in outputs],\n        'producer': 'https://example.com/quitanda/emit.py',\n        'schemaURL': 'https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent',\n    }\n", "note": "**The event.** `COMPLETE` is sent when a run succeeds; a job also sends `START` before and `FAIL` if it fails. The run id is derived from the job and the day, so the same night always has the same id, and `schemaURL` names the version of the standard the event follows."}, {"code": "    path = out / f'{day}-{n}-{job}.json'\n    path.write_text(json.dumps(event, indent=2) + '\\n')\n    print(path)\n", "note": "Each event is written to its own file, and the program prints the name."}]}
```

```
ana@laptop:~/gcp$ python3 emit.py 2026-10-01
events/2026-10-01-1-load_orders.json
events/2026-10-01-2-daily_revenue.json
events/2026-10-01-3-export_finance.json
ana@laptop:~/gcp$ cat events/2026-10-01-2-daily_revenue.json
{
  "eventType": "COMPLETE",
  "eventTime": "2026-10-01T03:20:00-03:00",
  "run": {
    "runId": "d33d71e8-fc3d-5c58-aaa2-cad1a5d473b0"
  },
  "job": {
    "namespace": "quitanda-nightly",
    "name": "daily_revenue"
  },
  "inputs": [
    {
      "namespace": "bigquery",
      "name": "planner-dev.curated.orders"
    },
    {
      "namespace": "bigquery",
      "name": "planner-dev.curated.customers"
    }
  ],
  "outputs": [
    {
      "namespace": "bigquery",
      "name": "planner-dev.curated.daily_revenue"
    }
  ],
  "producer": "https://example.com/quitanda/emit.py",
  "schemaURL": "https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent"
}
```

**That is an OpenLineage run event, whole.** `job` is the process, `run.runId` the run, and `inputs`
and `outputs` the datasets, each named by a `namespace` and a `name`. The namespace says what kind of
store the name lives in, and the naming is the standard's convention: `bigquery` with
`project.dataset.table`, and a bucket as `gs://bucket` with the object path as the name. **The names
are the whole join.** Two jobs agree that they touched the same table only if they spell it
identically, so a job that wrote `planner-dev:curated.orders` with a colon would start a second,
disconnected node, and the graph would have a break nobody sees.

## The graph, built from the events

**What follows is a model of the idea, not the Data Lineage API**: a program that reads the event
files, keeps the completed runs, turns each input and output pair into an edge, and walks the edges
in either direction. Save it as `~/gcp/edges.py`:

```schooling-example
{"language": "python", "file": "edges.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read OpenLineage run events and answer two questions a lineage service answers.\n\n    python3 edges.py                      # every edge: input -> output, through which job\n    python3 edges.py upstream DATASET     # everything DATASET was made from\n    python3 edges.py downstream DATASET   # everything made from DATASET\n\nA MODEL OF THE IDEA, NOT THE DATA LINEAGE API: a graph built from files in ./events.\n\"\"\"\nimport json\nimport pathlib\nimport sys\n\n", "note": "**A model of the service, and the docstring says so.** It answers the two walks an incident needs, from a file of events instead of an API."}, {"code": "def fqn(dataset):\n    return f\"{dataset['namespace']}/{dataset['name']}\"\n\n", "note": "A dataset's full name is its namespace and its name joined, `bigquery/planner-dev.curated.orders`, which is what makes two events about the same table meet."}, {"code": "edges = set()\nfor path in sorted(pathlib.Path('events').glob('*.json')):\n    event = json.loads(path.read_text())\n    if event['eventType'] != 'COMPLETE':\n        continue\n    job = f\"{event['job']['namespace']}.{event['job']['name']}\"\n    for source in event['inputs']:\n        for target in event['outputs']:\n            edges.add((fqn(source), job, fqn(target)))\n\n", "note": "**Every completed run turns each pair of an input and an output into an edge**, labelled with the job. A run that only started, or failed, draws nothing."}, {"code": "if len(sys.argv) < 3:\n    for source, job, target in sorted(edges, key=lambda e: e[1]):\n        print(f'{source}\\n    --[{job}]--> {target}')\n    sys.exit()\n\n", "note": "With no arguments it prints every edge, grouped by job."}, {"code": "direction, start = sys.argv[1], sys.argv[2]\nseen, todo = set(), [start]\nwhile todo:\n    here = todo.pop()\n    for source, job, target in sorted(edges):\n        near, far = (target, source) if direction == 'upstream' else (source, target)\n        if near == here and far not in seen:\n            seen.add(far)\n            todo.append(far)\n            print(f'{far}  (via {job})')\n", "note": "**The walk**: from one dataset, follow edges backwards for `upstream` or forwards for `downstream`, until nothing new is found. `seen` stops it going round a cycle, which a pipeline that reads its own output would have."}]}
```

```
ana@laptop:~/gcp$ python3 edges.py
bigquery/planner-dev.curated.customers
    --[quitanda-nightly.daily_revenue]--> bigquery/planner-dev.curated.daily_revenue
bigquery/planner-dev.curated.orders
    --[quitanda-nightly.daily_revenue]--> bigquery/planner-dev.curated.daily_revenue
bigquery/planner-dev.curated.daily_revenue
    --[quitanda-nightly.export_finance]--> gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv
gs://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv
    --[quitanda-nightly.load_orders]--> bigquery/planner-dev.curated.orders
ana@laptop:~/gcp$ python3 edges.py upstream gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv
bigquery/planner-dev.curated.daily_revenue  (via quitanda-nightly.export_finance)
bigquery/planner-dev.curated.customers  (via quitanda-nightly.daily_revenue)
bigquery/planner-dev.curated.orders  (via quitanda-nightly.daily_revenue)
gs://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv  (via quitanda-nightly.load_orders)
ana@laptop:~/gcp$ python3 edges.py downstream bigquery/planner-dev.curated.customers
bigquery/planner-dev.curated.daily_revenue  (via quitanda-nightly.daily_revenue)
gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv  (via quitanda-nightly.export_finance)
```

**Four edges from three events**, because `daily_revenue` read two tables and so drew two. The
upstream walk from the finance export went back through every job to the raw CSV and to the customers
table, which is the incident's first question answered in one line. The downstream walk from
`curated.customers` found the two things a bad customer table would spoil. The real service draws the
same graph in the console, for tables and, from BigQuery, for some columns as well, and its API
answers the same two walks with a search for the links into or out of a dataset.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"Lineage of the nightly pipeline. The raw orders CSV in quitanda-raw-prod feeds the job load_orders, which writes curated.orders. curated.orders and curated.customers feed the job daily_revenue, which writes curated.daily_revenue. That feeds the job export_finance, which writes the finance CSV in quitanda-curated-prod.\" data-fig=\"g26-graph\"><defs><marker id=\"g26-graph-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"16\" y=\"40\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"26\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">gs://quitanda-raw-prod</text><text x=\"26\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">raw/orders/…/orders.csv</text><rect x=\"16\" y=\"110\" width=\"120\" height=\"26\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"76\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">load_orders</text><line x1=\"76\" y1=\"80\" x2=\"76\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"16\" y=\"160\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"26\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bigquery</text><text x=\"26\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curated.orders</text><line x1=\"76\" y1=\"136\" x2=\"76\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"16\" y=\"230\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"26\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bigquery</text><text x=\"26\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curated.customers</text><rect x=\"290\" y=\"190\" width=\"120\" height=\"26\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"350\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">daily_revenue</text><line x1=\"216\" y1=\"180\" x2=\"288\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><line x1=\"216\" y1=\"250\" x2=\"288\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"260\" y=\"260\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"270\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bigquery</text><text x=\"270\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curated.daily_revenue</text><line x1=\"350\" y1=\"216\" x2=\"350\" y2=\"258\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"500\" y=\"190\" width=\"120\" height=\"26\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"560\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">export_finance</text><line x1=\"440\" y1=\"280\" x2=\"498\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"484\" y=\"110\" width=\"220\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"494\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">gs://quitanda-curated-prod</text><text x=\"494\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">finance/revenue/…/revenue.csv</text><line x1=\"560\" y1=\"188\" x2=\"560\" y2=\"152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><text x=\"16\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the nightly pipeline's lineage, from three events</text><rect x=\"484\" y=\"260\" width=\"10\" height=\"10\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"500\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dataset</text><rect x=\"484\" y=\"282\" width=\"10\" height=\"10\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"500\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">job</text></svg>", "caption": "The graph edges.py builds, drawn: datasets as boxes, jobs between them. The real service draws the same shape from the same events."}
```

**Sending an event to Google is one request**, shown and not run; it would need a real project, the
API enabled and credentials this course never has:

```sh
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @events/2026-10-01-2-daily_revenue.json \
  "https://datalineage.googleapis.com/v1/projects/planner-dev/locations/southamerica-east1:processOpenLineageRunEvent"
```

**Lineage is only as complete as the jobs that report it.** A script somebody runs by hand on a
laptop, or a job written before anybody thought of lineage, draws no edge, and the graph shows a
table appearing from nowhere. The upstream walk then stops early and looks finished. The rule that
keeps the graph honest is the one this course keeps for everything else: every job that writes data
says what it read.
