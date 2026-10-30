---
title: Jobs, executions and tasks
version: 1
---

A Cloud Run service waits for requests. **A Cloud Run job does not wait for anything: it runs
until its work is finished and then stops.** Same containers, same contract about logs and
signals, but no port, no address and no request. It is the platform's answer to the nightly
script that used to live in a cron table on a machine nobody dared to turn off.

## Three words

A **job** is the definition: an image, its settings, and how many pieces the work is cut into. It
does nothing on its own. An **execution** is one run of the job, started by hand, by a schedule or
by an API call; a job run every night has one execution a night. And a **task** is one of the
pieces: an execution of a job with `--tasks=3` starts three containers, each told which piece it
is. The execution succeeds when every task has succeeded.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A job named invoices is a definition. One execution of it, started at two in the morning, runs three tasks with indexes 0, 1 and 2, each a container. Task 0 and task 2 succeed on their first attempt. Task 1 fails on attempt 0 and succeeds on attempt 1. The execution succeeds when all three tasks have succeeded.\"><defs><marker id=\"l10-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"130\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">job</text><text x=\"85.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">invoices</text><path d=\"M150 140 L190 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><rect x=\"190\" y=\"110\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">execution</text><text x=\"265.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">02:00, tonight</text><path d=\"M340 128 L400 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><path d=\"M340 140 L400 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><path d=\"M340 152 L400 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><rect x=\"400\" y=\"36\" width=\"120\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">task 0</text><text x=\"460.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">attempt 0</text><rect x=\"400\" y=\"116\" width=\"120\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">task 1</text><text x=\"460.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">attempt 0</text><rect x=\"400\" y=\"198\" width=\"120\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">task 2</text><text x=\"460.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">attempt 0</text><path d=\"M520 140 L560 140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-ah)\"></path><text x=\"540\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">exit 1</text><rect x=\"560\" y=\"116\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">task 1</text><text x=\"630.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">attempt 1</text><text x=\"535\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">exit 0</text><text x=\"535\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">exit 0</text><text x=\"630\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">exit 0</text><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the execution succeeds when every task has</text></svg>", "caption": "A job is a definition, an execution is one run of it, and a task is one piece of that run. A retry is a new attempt of the same task, with the same index."}
```

## The shop's invoice job

Every night the shop writes an invoice for each of yesterday's orders. **Create a folder `job` in
`~/gcp` and save this as `job.py` in it:**

```python
# job/job.py
"""The shop's nightly invoice job: each task invoices its share of the orders."""
import json
import os
import sys

ORDERS = list(range(1001, 1011))  # yesterday's ten orders

index = int(os.environ.get('CLOUD_RUN_TASK_INDEX', '0'))
count = int(os.environ.get('CLOUD_RUN_TASK_COUNT', '1'))
attempt = int(os.environ.get('CLOUD_RUN_TASK_ATTEMPT', '0'))


def log(severity, message):
    print(json.dumps({'severity': severity, 'message': message}), flush=True)


mine = ORDERS[index::count]
log('INFO', f'task {index} of {count}, attempt {attempt}: orders {mine}')

if os.environ.get('FAIL_TASK') == str(index) and attempt == 0:
    log('ERROR', f'task {index}: the invoice service timed out')
    sys.exit(1)

for order in mine:
    log('INFO', f'invoice for order {order} written')
```

And this as its `Dockerfile`, in the same folder:

```dockerfile
# job/Dockerfile
FROM python:3.12.13-slim
WORKDIR /app
COPY job.py .
USER nobody
CMD ["python3", "job.py"]
```

There is no web server in it. The program reads three variables Cloud Run sets on every task,
takes **every `count`-th order starting at its own index**, writes their invoices, and exits.
`FAIL_TASK` is there for section 04, to make one task fail on its first attempt; it does nothing
unless set. Build it and run it once, as a job of one task would:

```
ana@laptop:~/gcp$ docker build -q -t invoices:1 job
sha256:57cabdcaa663070f9a42bf71fb523a25974a81107574b775d5aea29c0b03781f
ana@laptop:~/gcp$ docker run --rm invoices:1
{"severity": "INFO", "message": "task 0 of 1, attempt 0: orders [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010]"}
{"severity": "INFO", "message": "invoice for order 1001 written"}
{"severity": "INFO", "message": "invoice for order 1002 written"}
{"severity": "INFO", "message": "invoice for order 1003 written"}
{"severity": "INFO", "message": "invoice for order 1004 written"}
{"severity": "INFO", "message": "invoice for order 1005 written"}
{"severity": "INFO", "message": "invoice for order 1006 written"}
{"severity": "INFO", "message": "invoice for order 1007 written"}
{"severity": "INFO", "message": "invoice for order 1008 written"}
{"severity": "INFO", "message": "invoice for order 1009 written"}
{"severity": "INFO", "message": "invoice for order 1010 written"}
```

With no variables set, the program is task 0 of 1 and takes all ten orders. **Exit status 0 is the
whole of what Cloud Run reads**: a task that exits 0 has succeeded, and any other status has
failed, whatever the logs say. So a job's program must exit non-zero when it fails, which is the
opposite of a service, where a failure is an HTTP status and the process keeps running.

## What a job is for

| the work | a service | a job |
|---|---|---|
| answers a request while somebody waits | yes | no |
| runs until a piece of work is done, then stops | no | yes |
| started by | a request | a schedule, a command or an API call |
| longest run | the request timeout, 60 minutes at most | the task timeout, 10 minutes unless set, and hours at most |
| billed | per request or per instance, lesson 11 | for the time each task runs, at the sheet's instance rates |

The table's last column is the useful one when choosing. A database migration, a nightly export,
a batch of image resizing, a report: anything that has an end and nobody is waiting on is a job.
A service that receives a request and then keeps working after answering it, so as not to make
the caller wait, is usually a job pretending to be a service, and section 03 of lesson 11 shows
why that goes wrong.
