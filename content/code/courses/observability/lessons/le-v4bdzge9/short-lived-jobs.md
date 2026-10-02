---
title: The job that is gone before the scrape
version: 1
---

Pull assumes the target is still there fifteen seconds from now. **The nightly report is not**: it
starts, counts, writes and exits in about a second, and a scrape that arrives afterwards finds
nothing to ask. Lesson 4 promised a metric that says whether the report ran, and this is where it
lives.

The answer Prometheus offers is the **Pushgateway**: a small server that accepts metrics pushed to it
and keeps the last value of each, so Prometheus can scrape it like any target. The report pushes two
gauges on its way out, using the client library's `push_to_gateway`:

```python
    registry = CollectorRegistry()
    Gauge("report_orders", "Orders the last report counted.", registry=registry).set(len(orders))
    Gauge("report_last_success_timestamp_seconds", "When the report last finished.",
          registry=registry).set_to_current_time()
    push_to_gateway(os.environ.get("PUSHGATEWAY", "pushgateway:9091"), job="report", registry=registry)
```

Before the first run there is nothing to find; the query printed no line, and the `echo` after it is
what says so. Then the report runs, and a scrape later the timestamp is there:

```
ana@obs:~/shop$ ./promq 'report_last_success_timestamp_seconds' ; echo '(nothing yet)'
(nothing yet)
ana@obs:~/shop$ docker compose run --rm report 2>&1 | grep -v Container | jq -c '{message, orders}'
{"message":"report written","orders":963}
ana@obs:~/shop$ ./promq 'report_last_success_timestamp_seconds'
__name__=report_last_success_timestamp_seconds job=report  1790935620.3108528
ana@obs:~/shop$ ./promq 'time() - report_last_success_timestamp_seconds'
job=report  20.560147285461426
```

**The metric is a timestamp, not a count of runs**, and the subtraction is the point: `time() -
report_last_success_timestamp_seconds` is *seconds since the report last finished*, about 20 here.
It grows by one every second whether or not anything happens, so an alert on it fires on the night
the report does not run, which is the case lesson 4 showed a trace can never see. The push only
happens after the report finished, so a run that crashes halfway leaves the old timestamp in place,
and that is correct.

The Pushgateway is for exactly this, **a job that ends**, and it is misused for anything else. It
keeps the last value forever, so a service that pushed and then died looks alive in it; and it
erases the per-instance `up` that makes pull worth having. A long-running service is scraped, never
pushed.
