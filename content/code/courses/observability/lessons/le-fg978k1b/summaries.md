---
title: Summaries, and why histograms won
version: 1
---

The fourth type, the **summary**, was meant to solve the bucket problem by computing the percentiles
inside the service, exactly, from every observation, and publishing them ready-made. Python's client
library implements the type in its minimal form, and `summary.py` shows what that is:

```python
from prometheus_client import CollectorRegistry, Summary, generate_latest

registry = CollectorRegistry()
took = Summary("demo_request_seconds", "A summary, observed three times.", registry=registry)
for seconds in (0.2, 0.4, 1.9):
    took.observe(seconds)
print(generate_latest(registry).decode(), end="")
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python summary.py 2>/dev/null
# HELP demo_request_seconds A summary, observed three times.
# TYPE demo_request_seconds summary
demo_request_seconds_count 3.0
demo_request_seconds_sum 2.5
# HELP demo_request_seconds_created A summary, observed three times.
# TYPE demo_request_seconds_created gauge
demo_request_seconds_created 1.790936343199444e+09
```

**A count and a sum, and no percentiles at all**: the Python client does not compute them. Clients
in other languages do, and their output carries lines like `{quantile="0.99"}`. Even there, a
summary has a flaw no client can fix: **percentiles cannot be added**. If three copies of a service
each report a 99th percentile, no arithmetic on the three numbers gives the 99th percentile of all
their requests together; you would need the observations, which were thrown away. Buckets *can* be
added: summing three histograms' buckets gives the histogram of all three, and its percentile is
right up to the bucket's resolution.

That is why the storefront uses a histogram, and why the advice is the same almost everywhere: **a
histogram, with buckets chosen on purpose**. Prometheus 3 also supports **native histograms**, whose
buckets are chosen automatically at a fixed relative resolution and stored far more compactly; they
need the client library and the server to agree on the format, and the lab's classic buckets are
what this course measures with.
