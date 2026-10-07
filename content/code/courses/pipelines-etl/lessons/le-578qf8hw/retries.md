---
title: Retries, and the wait between them
version: 1
---

`retries` is the number of tries Airflow may make **after** the first one, so `retries: 4` is five
tries in all. `retry_delay` is how long it waits before the first retry, and
`retry_exponential_backoff` multiplies the wait every time it is used again.

**In Airflow 3.3 the backoff is a number, not a switch.** Its documentation calls it a multiplier,
with `0` meaning a constant delay and `2.0` meaning *double each time*. Older DAGs wrote `True`
there, and Python counts `True` as `1`, so they get a wait multiplied by one — the same fifteen
seconds before every try, with nothing in any log to say the backoff is not happening. Ana writes
`2.0` and a comment with the waits it should produce. Airflow also adds up to that much again, an
amount drawn from a hash of the task, the run's logical date and the try number, so that a hundred
tasks that failed together do not all come back in the same second.

Why wait longer each time? Because the reason for a passing failure is usually something that needs
a while to pass — a deploy, a restart, an overloaded server — and a client that asks again every
fifteen seconds is one more client keeping that server overloaded. **The growing wait is politeness
and arithmetic at once**: the first retry catches a blip, and the last one still has a chance
against an outage of several minutes.

The lab's API can be switched off. Ana switches it off, unpauses the DAG — which creates a run at
once, for the most recent 03:00 that has passed, as lesson 9 showed — and switches it back on after
the second try has failed:

```
#!/bin/sh
# Every try of one task in one run, from Airflow's API: when it ran and how it ended.
curl -s "http://127.0.0.1:8080/api/v2/dags/$1/dagRuns/$2/taskInstances/$3/tries" |
  python -c 'import json, sys
for t in json.load(sys.stdin)["task_instances"]:
    print("try", t["try_number"], t["state"], (t["start_date"] or "")[11:19], "to", (t["end_date"] or "")[11:19])'
```

```
ana@vm:~/etl$ airflow dags unpause prices_daily
dag_id       | is_paused
=============+==========
prices_daily | True     
                        
ana@vm:~/etl$ airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
prices_daily  scheduled__2026-10-07T06:00:00+00:00  success  2026-10-07T06:00:00+00:00  2026-10-07T06:00:00+00:00  202
ana@vm:~/etl$ sh tries.sh prices_daily $(airflow dags list-runs prices_daily -o plain | grep -o "scheduled__[^ ]*") fetch
try 1 failed 06:08:39 to 06:08:43
try 2 failed 06:09:01 to 06:09:01
try 3 success 06:09:36 to 06:09:36
ana@vm:~/etl$ cat alerts.log
cat: alerts.log: No such file or directory
```

The run succeeded. **Two tries failed, the third found the API back, and nobody was told**,
because nothing had to be done: `alerts.log` does not even exist yet. The gaps between the tries
show the backoff working, each wait about twice the last.

**A retry turns a passing failure into a slower success**, and
a slower success is not news. What is news is the failure the retries could not absorb, which is
the next section.

Retries have one condition, and it is easy to forget because it is not about Airflow at all: **a
task must be safe to run twice**. A try that loaded half its rows and then failed will be followed
by a try that loads all of them; if the first half is still there, it is loaded twice. `fetch`
rewrites its whole file on every try, so a second try leaves the same file as one try would.
Lesson 15 makes that property the subject.
