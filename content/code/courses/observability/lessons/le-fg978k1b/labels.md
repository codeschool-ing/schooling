---
title: Labels, and the experiment
version: 2
---

A label is what lets one metric answer *by route* or *by status code*, and lesson 5 leaned on it in
every query. **The price is that every distinct combination of label values is a separate series**,
stored, indexed and kept in memory by Prometheus on its own. The storefront's counter has a handful
because routes, methods and status codes are few. The danger is a label whose values are not few.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Labels multiply. The storefront's request counter has three labels it sets, route with 3 values, method with 2, code with 4 seen, and Prometheus adds job and instance. The number of series is the product of the values that actually occur together. Adding one label with 20000 values, a user id, multiplies whatever was there by 20000.\"><defs><marker id=\"mul-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">route</text><text x=\"100.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 values</text><text x=\"180\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper)\">×</text><rect x=\"200\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">method</text><text x=\"260.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 values</text><text x=\"340\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper)\">×</text><rect x=\"360\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">code</text><text x=\"420.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 values</text><text x=\"500\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper)\">×</text><rect x=\"520\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">user_id</text><text x=\"580.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20000 values</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">series = the product of the values that occur together</text><text x=\"280\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">at most 3 × 2 × 4 = 24 without the last label</text><text x=\"560\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">× 20000 with it</text></svg>", "caption": "A label is not a column in a row; it is a multiplier on the number of rows. The cost of a label is its number of distinct values, not its length."}
```

The experiment measures it. `logins.py` counts twenty thousand logins with one counter and a label
chosen on the command line: `plan`, with three possible values, or `user_id`, with one value per
user. It serves the result on port 8000 and stays up so Prometheus can scrape it:

```python
import random
import sys
import time

from prometheus_client import Counter, start_http_server

label = sys.argv[1]
LOGINS = Counter("demo_logins", "Logins, labelled the way the first argument says.", [label])
random.seed(7)
start_http_server(8000)
plans = ["free", "monthly", "yearly"]
for user_id in range(1, 20001):
    value = str(user_id) if label == "user_id" else random.choice(plans)
    LOGINS.labels(value).inc()
print(f"20000 logins counted by {label}", flush=True)
time.sleep(3600)
```

Prometheus is given two more scrape jobs, itself, so its own memory and series count become
metrics, and the experiment. Keep a copy of `prometheus.yml`, then add at its end the six lines the
`tail` below prints, and save `logins.py` in `~/shop/scratch`:

```sh
cp prometheus/prometheus.yml /tmp/prometheus.yml.orig
```


```
ana@obs:~/shop$ tail -6 prometheus/prometheus.yml
  - job_name: prometheus
    static_configs:
      - targets: [localhost:9090]
  - job_name: logins
    static_configs:
      - targets: [logins:8000]
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && echo reloaded
reloaded
```

Before anything else runs, the series Prometheus holds in memory and the memory it uses:

```
ana@obs:~/shop$ ./promq 'prometheus_tsdb_head_series'
__name__=prometheus_tsdb_head_series instance=localhost:9090 job=prometheus  3760
ana@obs:~/shop$ ./promq 'process_resident_memory_bytes{job="prometheus"}'
__name__=process_resident_memory_bytes instance=localhost:9090 job=prometheus  96370688
```

**3760 series and 96 MB**, for the whole shop and everything that watches it. Then the logins,
counted by plan:

```
ana@obs:~/shop$ docker compose run -d --rm --name logins sandbox python logins.py plan
 Container shop-otel-collector-1 Running 
 Container logins Creating 
 Container logins Created 
507e2ae26979678decc89d4d47f625ca0be16788587617ee231fbd9501d750ce
ana@obs:~/shop$ curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job == "logins") | [.health, .lastScrapeDuration] | @tsv'
up	0.003508293
ana@obs:~/shop$ ./promq 'demo_logins_total'
__name__=demo_logins_total instance=logins:8000 job=logins plan=monthly  6639
__name__=demo_logins_total instance=logins:8000 job=logins plan=free  6758
__name__=demo_logins_total instance=logins:8000 job=logins plan=yearly  6603
ana@obs:~/shop$ ./promq 'prometheus_tsdb_head_series'
__name__=prometheus_tsdb_head_series instance=localhost:9090 job=prometheus  3782
```

**Three series**, one per plan, adding up to 20000, and the head grew by 22. Six are for the logins,
because every counter brings its `_created` gauge. The rest are for the new target itself: its `up`,
its scrape statistics and the process metrics the client library publishes. Nothing to see.

Stop the experiment before the next section, which starts it again under the same name:

```sh
docker stop logins
```
