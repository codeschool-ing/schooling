---
title: Scheduled jobs: work that nobody asked for
version: 1
---

The report has no parent, and that is correct rather than a gap. **A job started by a timer has no
caller**: cron, a Kubernetes `CronJob` or a scheduler in the cloud starts it, and none of them is
a span. So a scheduled job's trace starts at the job, and three habits keep it from being an island:

- **Name the root span after the job**, `nightly report`, so every run of it is one operation in
  every backend, the rule from lesson 2's last section.
- **Link to the work it touches**, as the report does, when that work has traces of its own.
- **Record what makes this run this run** as attributes: the window it covered, how many items, how
  many failed. The report sets `report.orders` and `report.paid` on its span, which is what lets
  *the report counted nothing last Tuesday* be found by searching rather than by reading logs.

The opposite case also exists: a job **that is** started by something with a trace, a deploy pipeline
running a migration or a service launching a worker process. There the parent's context has to reach
a new process, and there is no header to carry it. OpenTelemetry has added a convention for that:
the parent sets the environment variables `TRACEPARENT` and `TRACESTATE` for the child, in the same
format as the headers, and the child extracts from its environment as a server extracts from a
request. It is recent, and few tools read it on their own yet, so a script launched that way may need
the two lines written by hand.

What a scheduled job's trace cannot do is say **that the job did not run**. A trace exists only for
work that happened; the night the scheduler failed leaves no span at all. That question belongs to a
metric, *time since the last successful run*, and an alert on it, which lessons 5 and 16 build.
