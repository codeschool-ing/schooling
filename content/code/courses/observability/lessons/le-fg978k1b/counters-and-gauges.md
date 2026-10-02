---
title: Counters and gauges
version: 1
---

Every metric declares a **type** in its `# TYPE` line, and the type decides which questions the
metric can answer. The storefront's page lists them all, its own and the ones the Python client
library adds for free:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep '^# TYPE'
# TYPE python_gc_objects_collected_total counter
# TYPE python_gc_objects_uncollectable_total counter
# TYPE python_gc_collections_total counter
# TYPE python_info gauge
# TYPE process_virtual_memory_bytes gauge
# TYPE process_resident_memory_bytes gauge
# TYPE process_start_time_seconds gauge
# TYPE process_cpu_seconds_total counter
# TYPE process_open_fds gauge
# TYPE process_max_fds gauge
# TYPE http_server_requests_total counter
# TYPE http_server_requests_created gauge
# TYPE http_server_request_duration_seconds histogram
# TYPE http_server_request_duration_seconds_created gauge
```

Two types cover most of the list. A **counter** only goes up, or back to zero when the process
restarts: requests answered, garbage collections, seconds of processor used. Its name ends in
`_total` by convention, and lesson 5 showed that its value means little and its `rate()` means a lot.
A **gauge** goes up and down and its current value is the answer: memory in use, open file
descriptors, messages waiting in a queue. Two gauges and a counter of the storefront:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep -E '^process_(resident_memory_bytes|open_fds) '
process_resident_memory_bytes 4.8697344e+07
process_open_fds 11.0
ana@obs:~/shop$ ./promq 'rate(process_cpu_seconds_total{job="storefront"}[1m])'
instance=storefront:8080 job=storefront  0.01933333333333333
```

48.7 MB of memory and eleven open files, read as they are. The processor time is a counter of
seconds, so its rate is *seconds of processor per second*: 0.019, about two per cent of one core.

**The wrong type breaks the math silently.** `rate()` of a gauge treats every drop as a restart and
produces nonsense. A gauge reporting *requests so far* loses everything at a restart and cannot be
added up across instances. The rule of thumb: if the question is *how many happened*, it is a
counter; if it is *how many are there right now*, it is a gauge.

The `_created` lines are a third thing: gauges the client library adds beside each counter and
histogram. Each holds the time the series was created, which lets a backend tell a restart from a
counter that was always zero. They are worth noticing now, because this lesson's experiment trips
over them.
