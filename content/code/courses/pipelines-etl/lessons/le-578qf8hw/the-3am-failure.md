---
title: The night it did not recover
version: 1
---

The lab cannot wait for three in the morning, so the night is staged: the price API goes down with `sudo shop outage on`, and
Ana triggers the run for 03:00 on 10 March by hand, with that logical date, and leaves it alone.

```
ana@vm:~/etl$ airflow dags trigger prices_daily --logical-date 2026-03-10T03:00:00-03:00 -o plain >/dev/null; airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                    state    run_after                         logical_date       
prices_daily  manual__2026-10-07T06:09:51.640565+00:00  running  2026-10-07T06:09:51.640565+00:00  2026-03-10T06:00:00
prices_daily  scheduled__2026-10-07T06:00:00+00:00      success  2026-10-07T06:00:00+00:00         2026-10-07T06:00:00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-night\" aria-label=\"The run for 03:00 on 10 March on a time line of a few minutes. Five tries, each a failure, with the waits between them growing: about fifteen seconds, then thirty, sixty and a hundred and twenty. Two minutes after the run was queued the deadline passes and a LATE line is written while the run is still trying. After the fifth try the task has failed for good and a FAILED line is written.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 200.0 L690.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M90.0 196.0 L90.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 min</text><path d=\"M197.3 196.0 L197.3 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"197.3\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 min</text><path d=\"M304.5 196.0 L304.5 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"304.5\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 min</text><path d=\"M411.8 196.0 L411.8 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"411.8\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 min</text><path d=\"M519.1 196.0 L519.1 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"519.1\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 min</text><path d=\"M626.4 196.0 L626.4 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"626.4\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 min</text><text x=\"80.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tries</text><text x=\"80.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waits</text><circle cx=\"97.2\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"97.2\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M105.2 150.0 L133.8 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"119.5\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15 s</text><circle cx=\"141.8\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"141.8\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M149.8 150.0 L219.7 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"184.8\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text><circle cx=\"227.7\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"227.7\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M235.7 150.0 L385.9 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"348.4\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 s</text><circle cx=\"393.9\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"393.9\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><path d=\"M401.9 150.0 L659.5 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.7\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120 s</text><circle cx=\"667.5\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"667.5\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5</text><path d=\"M304.5 40.0 L304.5 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"310.5\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deadline: 2 min after queued</text><text x=\"310.5\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">LATE</text><text x=\"667.5\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">FAILED</text></svg>", "caption": "The deadline speaks while the run is still trying; the failure callback only when the trying is over."}
```

In the morning there are two lines in `alerts.log`:

```
ana@vm:~/etl$ cat alerts.log
2026-10-07 03:11:53 LATE prices_daily run=manual__2026-10-07T06:09:51.640565+00:00 state=running
2026-10-07 03:15:37 FAILED prices_daily.fetch run=manual__2026-10-07T06:09:51.640565+00:00 try=5 error=HTTPError('503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200')
```

**The deadline spoke first, while the run was still trying**: two minutes after the run was queued
it had not finished, and `state=running` says so. **The failure callback spoke last, once there
was nothing left to try**: the fifth try, the exception that ended it, and the run it belonged to.
On a real night the first line is the one that wakes somebody before the morning report goes out;
the second is the one that tells them where to look.

## Reading it in the morning

Ana's order is the same every time: what Airflow saw, then what the source says now.

```
ana@vm:~/etl$ airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                    state    run_after                         logical_date       
prices_daily  manual__2026-10-07T06:09:51.640565+00:00  failed   2026-10-07T06:09:51.640565+00:00  2026-03-10T06:00:00
prices_daily  scheduled__2026-10-07T06:00:00+00:00      success  2026-10-07T06:00:00+00:00         2026-10-07T06:00:00
ana@vm:~/etl$ RUN=$(airflow dags list-runs prices_daily -o plain | grep -o "manual__[^ ]*"); sh tries.sh prices_daily $RUN fetch
try 1 failed 06:09:52 to 06:09:52
try 2 failed 06:10:15 to 06:10:15
try 3 failed 06:11:06 to 06:11:06
try 4 failed 06:12:41 to 06:12:41
try 5 failed 06:15:37 to 06:15:37
ana@vm:~/etl$ grep -ho "\"exc_type\":\"[A-Za-z]*\",\"exc_value\":\"[^\"]*\"" ~/airflow/logs/dag_id=prices_daily/run_id=manual__*/task_id=fetch/attempt=*.log | sort | uniq -c
      5 "exc_type":"HTTPError","exc_value":"503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200"
ana@vm:~/etl$ curl -s -o /dev/null -w "%{http_code}\n" -H "X-Api-Key: $PRICES_API_KEY" http://127.0.0.1:8081/v1/prices
503
```

Five tries, all failed, the gaps between them growing as the backoff said they would. Every try's
log names the same exception, so this is one cause and not five. And the API, asked by hand, still
answers `503`: **the problem is not in Ana's code and not in Airflow, and nothing she reruns now
can succeed.** The right move is to wait for the source — or, in production, to tell whoever runs
it — rather than to start clearing tasks into the same wall.

Later in the morning the API answers again:

```
ana@vm:~/etl$ curl -s -o /dev/null -w "%{http_code}\n" -H "X-Api-Key: $PRICES_API_KEY" http://127.0.0.1:8081/v1/prices
200
```

Now a rerun can work, and the next section does it.

Two things this transcript is worth remembering for. **A failure alert is the start of an
investigation, not the end of one**: the line said `503`, but whether the API was still down was
a question only a fresh request could answer. And **the order matters**: the run's tries first, then
the logs, then the source — and, when a DAG seems to have done nothing at all, the import errors
before any of them. Each step rules out a whole kind of failure before
the next one is looked at.
