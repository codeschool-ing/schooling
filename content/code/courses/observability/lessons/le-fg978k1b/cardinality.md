---
title: Cardinality: the same logins, by user
version: 1
---

The same twenty thousand logins, now labelled by `user_id`:

```
ana@obs:~/shop$ docker compose run -d --rm --name logins sandbox python logins.py user_id
 Container shop-otel-collector-1 Running 
 Container logins Creating 
 Container logins Created 
3f0addda312ad842af41899934b362433ce339a2b9272ebd0eb14d8ac4bada86
ana@obs:~/shop$ ./promq 'count(demo_logins_total)'
  20000
ana@obs:~/shop$ ./promq 'prometheus_tsdb_head_series'
__name__=prometheus_tsdb_head_series instance=localhost:9090 job=prometheus  43805
```

**20000 series for one counter, and the head went from 3782 to 43805.** The counter's twenty
thousand were joined by twenty thousand `_created` gauges, one per series. A single label added
forty thousand series, ten times everything the rest of the lab holds. The number of distinct values
a label takes is called its **cardinality**, and this is what *high cardinality* costs:

```
ana@obs:~/shop$ ./promq 'scrape_samples_scraped{job="logins"}'
__name__=scrape_samples_scraped instance=logins:8000 job=logins  40016
ana@obs:~/shop$ curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job == "logins") | [.health, .lastScrapeDuration] | @tsv'
up	0.456697839
```

40016 samples on every scrape, and the scrape now takes **457 milliseconds**, against 3.5 for the
same counter by plan. And Prometheus itself:

```
ana@obs:~/shop$ ./promq 'process_resident_memory_bytes{job="prometheus"}'
__name__=process_resident_memory_bytes instance=localhost:9090 job=prometheus  158539776
```

**158 MB, up from 96**, for one counter of one experiment, before a single dashboard has asked for
anything. Every one of those series lives in memory while it is active, is written to disk, and is
indexed so a query can find it. Each costs little, and there are forty thousand of them. Real
systems make the same mistake with a request id, an e-mail address, a full URL with its query string
or a timestamp in a label. The series then multiply with traffic until Prometheus runs out of
memory.

**The rule is lesson 2's, turned around.** On a span, a user id is the right place for detail,
because a span is stored once whatever its attributes say. On a metric, it is the wrong place: a
label value is a new series that lives on. Labels should take a small, known set of values, and
anything that identifies one request, one user or one order belongs in a trace or a log line.
