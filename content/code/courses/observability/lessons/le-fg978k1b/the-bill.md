---
title: The bill, and dropping what you cannot afford
version: 1
---

On your own Prometheus, cardinality costs memory and disk. **On a managed service it costs money
directly.** Most hosted metrics products charge by the number of active series, or by the number of
samples ingested, which is series times scrapes. The arithmetic needs no vendor's price list. One
label turned 3782 series into 43805: whatever a series costs on a given bill, that label multiplied
the metrics part of it by more than eleven. If the experiment had been a real service running in
fifty copies, every copy would have added its own forty thousand.

When a metric like that is already in production, the first remedy is at the scrape. A **metric
relabelling** rule in the job's configuration runs on every scraped sample before it is stored, and
can drop a metric by name:

```
ana@obs:~/shop$ tail -8 prometheus/prometheus.yml
      - targets: [localhost:9090]
  - job_name: logins
    static_configs:
      - targets: [logins:8000]
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: demo_logins_total
        action: drop
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && echo reloaded
reloaded
```

```
ana@obs:~/shop$ ./promq 'scrape_samples_scraped{job="logins"}'
__name__=scrape_samples_scraped instance=logins:8000 job=logins  40016
ana@obs:~/shop$ ./promq 'scrape_samples_post_metric_relabeling{job="logins"}'
__name__=scrape_samples_post_metric_relabeling instance=logins:8000 job=logins  20016
ana@obs:~/shop$ ./promq 'count(demo_logins_total)'
```

**The scrape still brought 40016 samples, and 20016 survived.** The rule dropped
`demo_logins_total`, so the query for it now returns nothing. But it named only that metric, and the
twenty thousand `_created` series came through untouched. That is the honest state of a quick fix.
It stops the part somebody wrote down, at the cost of scraping and parsing everything first, and it
is only as complete as its regular expression.

**The fix belongs in the code**: count by `plan`, or by nothing, and put the user id on the span of
the login, where lesson 2 says it costs nothing. A relabel rule is how a team stops the bleeding on
a Friday night. A change to the instrumentation is how it stops it from happening again. The
experiment was stopped after this capture and `prometheus.yml` restored.
