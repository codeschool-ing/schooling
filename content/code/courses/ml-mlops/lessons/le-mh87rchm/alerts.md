---
title: Alerts, and who is woken by them
version: 1
---

A check that nobody hears is a log line. **An alert is a check with a person at the end of it**, and
the hard part is not raising it but deciding which checks deserve one.

**A service level objective, an SLO, is the promise an alert defends.** It is written in the terms
of the four questions, with a number and a period:

| question | an objective for the lapse service | measured from |
| --- | --- | --- |
| is it answering? | 99.9% of requests not answered with a 5xx, over 30 days | `requests.log` |
| how fast? | 99% of requests under 50 ms, at the load of a normal afternoon | `requests.log` |
| what is it saying? | every night's `watch.py` exits 0, or somebody looked before 9 a.m. | the nightly run |
| was it right? | average precision on the latest night with outcomes within 0.05 of the test | `report_card.py` |

The numbers are decisions, made with the people who use the scores, and they are the same kind of
judgment as the bounds inside `watch.py`. **Too tight, and the alerts fire on ordinary noise until
everybody learns to ignore them; too loose, and the night spend arrived a hundred times too
large passes quietly.** Start loose enough that every alert in the first month was worth reading, and tighten from
what those alerts taught.

**Two kinds of alert, by how soon somebody must act.** A page wakes a person: the service answering
errors, or p99 far past its objective, because members feel it now. A ticket waits for the morning:
a watch alarm before the voucher list goes out, a report card drifting down. The lapse model's
decisions are monthly, so almost nothing about it deserves a page; a fraud model's are per payment,
and almost everything does.

**The nightly checks are steps of the pipeline.** The scheduler that runs the batch runs the watch
after it, and a non-zero exit status stops the chain before anything is published and tells
whoever the scheduler tells. On a single machine, cron is enough to show the shape, one line in
`crontab -e`:

```conf
# every night at 02:30: tonight's snapshot, the scores, then the watch; the chain stops at a failure
30 2 * * * cd ~/ml && . ~/mlenv/bin/activate && night=$(date +\%F) && { python featurestore.py snapshot $night && python score_batch.py $night && python watch.py $night; } >> nightly.log 2>&1
```

`\%F` is escaped because cron treats a bare `%` as a line break. On Ponto Final's platform the same
three steps would be tasks in an Airflow DAG like the pipelines course's, with its retries and its
notifications; the course does not ask you to install the cron line, which only shows where the
checks sit. **What matters is the order: the watch runs between the scores being written and anybody
reading them**, and a night it does not like is a night nobody acts on until a person has looked.
