---
title: Prometheus, and asking it questions
version: 1
---

**Prometheus collects metrics by asking for them.** Every few seconds it sends a `GET /metrics` to
each address in its configuration, a *scrape*, stores what comes back as time series, and answers
queries over them in PromQL. The application never sends anything anywhere; it only has to answer
when asked, which is what `observed.py` now does. It is the metrics half of what Grafana draws in
most of the teams that use Grafana.

## Installing it

It comes from Ubuntu's own archive, in one command:

```sh
sudo apt-get install -y prometheus
```

The machine in these transcripts has it installed the same way. Check which version you got:

```
ana@nft:~$ prometheus --version | head -1; promtool --version | head -1
prometheus, version 2.45.3+ds (branch: debian/sid, revision: 2.45.3+ds-2ubuntu0.3)
promtool, version 2.45.3+ds (branch: debian/sid, revision: 2.45.3+ds-2ubuntu0.3)
```

**On your VM, that `apt-get` also started it**, as a background service reading
`/etc/prometheus/prometheus.yml`, and it installed and started a second program beside it, the
*node exporter*, which answers on port 9100 with the machine's own numbers: processors, memory,
disks, network. The node exporter is what USE needs, and it can keep running. The Prometheus
service would hold port 9090 and scrape a configuration that is not this lesson's, so stop it, and
stop it starting at boot:

```sh
sudo systemctl disable --now prometheus
```

Those two lines about the services were not run here: the machine in the transcripts has no
service manager, so the node exporter was started by hand, as `prometheus-node-exporter`, which is
what the service runs. Yours is already running; `curl -s localhost:9100/metrics | head` shows it
answering.

## The configuration

Everything Prometheus does comes from one YAML file. This lesson keeps its monitoring files in a
directory of their own:

```sh
mkdir -p ~/monitor && cd ~/monitor
```

Create `prometheus.yml` there:

```yaml
# monitor/prometheus.yml
# What to scrape, and how often. Prometheus reads it once at start-up.
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: boxoffice
    static_configs:
      - targets: ["127.0.0.1:8000"]
  - job_name: node
    static_configs:
      - targets: ["127.0.0.1:9100"]
```

Two jobs: boxoffice on port 8000 and the node exporter on 9100. **Five seconds is a lesson's
interval**, chosen so that a one-minute load test gives enough points to read. Production
configurations scrape every 15 to 60 seconds, because every scrape is a request the application has
to answer and every point is something to store.

Start Prometheus in the foreground, in a third terminal, from `~/monitor`:

```sh
cd ~/monitor
prometheus --config.file=prometheus.yml --storage.tsdb.path=data
```

It logs a great deal, one `key=value` line per event. The two that matter are the first and the
one saying it is ready:

```
ana@nft:~/monitor$ prometheus --config.file=prometheus.yml --storage.tsdb.path=data
ts=2026-10-10T07:34:52.129Z caller=main.go:563 level=info msg="Starting Prometheus Server" mode=server version="(version=2.45.3+ds, branch=debian/sid, revision=2.45.3+ds-2ubuntu0.3)"
ts=2026-10-10T07:34:52.146Z caller=main.go:989 level=info msg="Server is ready to receive web requests."
```

The data goes into `~/monitor/data`. Prometheus has a web interface on `localhost:9090` as well;
this lesson asks it questions through its HTTP API instead, because an answer in a terminal can be
copied, compared and scripted.

## Asking

The API takes a PromQL expression in the `query` parameter of `/api/v1/query` and answers with
JSON. A short script saves typing the `curl` and the `jq` every time. Create `promql.sh` in
`~/monitor`:

```sh
# monitor/promql.sh
# Asks Prometheus one PromQL question; prints one line per series it answers.
curl -s localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | "\(.metric | del(.__name__) | tostring)  \(.value[1])"'
```

`--data-urlencode` takes care of the braces, quotes and spaces PromQL is full of, which a bare
`?query=` in the address would need escaped by hand. The first question is whether the scrapes are
working. `up` is a series Prometheus writes itself, 1 for every target it reached at the last
scrape and 0 for every one it did not:

```
ana@nft:~/monitor$ sh promql.sh up
{"instance":"127.0.0.1:8000","job":"boxoffice"}  1
{"instance":"127.0.0.1:9100","job":"node"}  1
```

**`up` is the cheapest alert there is**, and the least informative: a process can answer `/metrics`
perfectly while failing every booking.

## Some traffic to look at

A metric with nobody using the system is a flat line. This script, for the k6 that lesson 5
installed, is a minute of ordinary traffic: ten virtual users, each listing the shows, opening one, booking a
random seat three times in ten, and pausing half a second. Create `traffic.js` in `~/monitor`:

```javascript
// monitor/traffic.js
// A minute of ordinary traffic: mostly reading, now and then a booking.
import http from 'k6/http';
import { sleep } from 'k6';

export const options = { vus: 10, duration: '60s' };
const BASE = 'http://127.0.0.1:8000';

export default function () {
  const show = 981 + Math.floor(Math.random() * 20);
  http.get(`${BASE}/shows`);
  http.get(`${BASE}/shows/${show}`);
  if (Math.random() < 0.3) {
    const seat = 1 + Math.floor(Math.random() * 300);
    http.post(`${BASE}/bookings`, JSON.stringify({ show_id: show, seat, customer: `k6-${__VU}` }),
      { headers: { 'Content-Type': 'application/json' } });
  }
  sleep(0.5);
}
```

Run it in the second terminal with `k6 run traffic.js`, and while it runs, ask Prometheus RED's
three questions in a fourth, or in the second once k6 has finished. These were asked about 45
seconds into the run:

```
ana@nft:~/monitor$ sh promql.sh 'sum by (route) (rate(boxoffice_requests_total[1m]))'
{"route":"/shows"}  12.089420833333334
{"route":"/shows/{id}"}  12.079215151515154
{"route":"other"}  0
{"route":"/bookings"}  3.7210931818181816
ana@nft:~/monitor$ sh promql.sh 'sum by (status) (rate(boxoffice_requests_total[1m]))'
{"status":"200"}  24.24826916666667
{"status":"404"}  0
{"status":"201"}  3.053846666666667
{"status":"409"}  0.6788383333333333
ana@nft:~/monitor$ sh promql.sh 'sum(rate(boxoffice_requests_total{status=~"5.."}[1m])) / sum(rate(boxoffice_requests_total[1m]))'
ana@nft:~/monitor$ sh promql.sh '(sum(rate(boxoffice_requests_total{status=~"5.."}[1m])) or vector(0)) / sum(rate(boxoffice_requests_total[1m]))'
{}  0
ana@nft:~/monitor$ sh promql.sh 'histogram_quantile(0.95, sum by (le, route) (rate(boxoffice_request_duration_seconds_bucket{route!="other"}[1m])))'
{"route":"/bookings"}  0.24216133272600035
{"route":"/shows"}  0.006216002317520896
{"route":"/shows/{id}"}  0.058429510856609614
ana@nft:~/monitor$ sh promql.sh '1 - avg(rate(node_cpu_seconds_total{mode="idle"}[1m]))'
{}  0.47410176750000166
```

Read them in order.

- **Rate.** `rate()` turns a counter, which only ever grows, into how fast it grew: requests per
  second, averaged over the last minute. `sum by (route)` adds the series of each route together.
  Listing and opening a show ran at about 12 a second each, because every iteration does both;
  bookings at 3.7, close to the three in ten of the script.
- **Errors.** By status, every answer was a 200, a 201 or a 409. The 409s are seats that somebody
  else already had, and they are the box office working: refusing to sell a seat twice is a
  feature. So the error ratio counts only `5..`, the server's own failures. **The first answer is
  no answer at all**: there has never been a 5xx, so there is no series to divide, and PromQL
  returns an empty result rather than a zero. `or vector(0)` writes the zero in. An alert built on
  the first form simply never fires while the series does not exist, which is correct here and
  surprising the first time.
- **Duration.** `histogram_quantile(0.95, …)` reads the 95th percentile out of the buckets, per
  route: 6 ms to list the shows, 58 ms to open one, 242 ms to book. Bookings are the slow route
  because each one waits its turn for `booking_lock`, which is the saturation USE asks about. The
  figure further down shows how a percentile comes out of buckets.
- **Utilisation.** The last query is USE's, from the node exporter: the share of time the
  processors were not idle, 0.47, nearly half. This machine is shared with the load generator,
  which accounts for a good part of it.

Here is the end of what k6 printed when the minute was up:

```
ana@nft:~/monitor$ k6 run traffic.js
…
  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=52.91ms  min=799.32µs med=60.67ms  max=895.7ms p(90)=112.69ms p(95)=139.94ms
      { expected_response:true }...: avg=51.76ms  min=799.32µs med=59.69ms  max=895.7ms p(90)=111.73ms p(95)=139.55ms
    http_req_failed................: 3.00%  67 out of 2233
    http_reqs......................: 2233   36.835368/s

    EXECUTION
    iteration_duration.............: avg=627.35ms min=559.08ms med=579.15ms max=1.66s   p(90)=722.6ms  p(95)=767.75ms
    iterations.....................: 962    15.869066/s
    vus............................: 10     min=10         max=10
    vus_max........................: 10     min=10         max=10

    NETWORK
    data_received..................: 2.1 MB 35 kB/s
    data_sent......................: 202 kB 3.3 kB/s
```

Two numbers disagree with Prometheus, and both disagreements are worth knowing. **k6 says
`http_req_failed` was 3.00%**, 67 requests out of 2233, because k6 counts every 4xx as a failure;
the log below has exactly 67 answers of 409, and k6 cannot know that a 409 is the system doing its
job. Which statuses count as errors is a decision you write into the query, and lesson 24's
alert depends on it. And **k6's durations are longer than the server's**:
about 40 ms of each response k6 timed is spent outside the application, and lesson 9 finds where.
Monitoring from inside the server measures the server; what the customer waited is measured
from outside, which is the next lesson's subject.

## Reading a percentile out of buckets

When the run was over, the buckets of `/shows/{id}` looked like this:

```
ana@nft:~/monitor$ curl -s localhost:8000/metrics | grep 'shows/{id}'
boxoffice_requests_total{method="GET",route="/shows/{id}",status="200"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.005"} 0
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.01"} 0
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.025"} 586
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.05"} 887
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.1"} 952
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.25"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.5"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="1.0"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="2.5"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="+Inf"} 963
boxoffice_request_duration_seconds_sum{route="/shows/{id}"} 26.788998
boxoffice_request_duration_seconds_count{route="/shows/{id}"} 963
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l22-buckets\" aria-label=\"Six bars, one per bucket of GET /shows/{id} after the run, each as tall as the number of requests that took at most that long: 0 under 5 ms, 0 under 10 ms, 586 under 25 ms, 887 under 50 ms, 952 under 100 ms and all 963 under 250 ms. A dashed line at 915, which is 95% of 963, first passes under a bar at the 100 ms bucket, so the 95th percentile lies between 50 and 100 ms. Assuming the requests in that bucket are spread evenly, the estimate is about 71 ms; the bucket only knows it is somewhere in those 50 ms.\"><path d=\"M70.0 250.0 L666.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"128.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><text x=\"128.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 5 ms</text><text x=\"224.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><text x=\"224.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 10 ms</text><rect x=\"286.0\" y=\"128.3\" width=\"68.0\" height=\"121.7\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"320.0\" y=\"118.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">586</text><text x=\"320.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 25 ms</text><rect x=\"382.0\" y=\"65.8\" width=\"68.0\" height=\"184.2\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"416.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">887</text><text x=\"416.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 50 ms</text><rect x=\"478.0\" y=\"52.3\" width=\"68.0\" height=\"197.7\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"512.0\" y=\"42.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">952</text><text x=\"512.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 100 ms</text><rect x=\"574.0\" y=\"50.0\" width=\"68.0\" height=\"200.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"608.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">963</text><text x=\"608.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 250 ms</text><path d=\"M70.0 60.0 L666.0 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"66.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">915</text><text x=\"76.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">95% of 963</text><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">requests that took at most this long</text><text x=\"360.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the 95th percentile is between 50 and 100 ms; evenly spread, about 71 ms</text></svg>", "caption": "A histogram keeps counts under bounds, never durations. The percentile can only be placed inside a bucket."}
```

The figure reads the 95th percentile of the whole run from those counts. 95% of 963 requests is
the 915th, and the 915th falls between the 887 under 50 ms and the 952 under 100 ms, which puts it
at about 71 ms. The query during the run said 58 ms because it looked only at the last minute.

**A histogram never stores a single duration.** It stores how many requests fell under each
bound, so the 95th percentile can only be located between two bounds, and `histogram_quantile`
assumes the requests inside that bucket are spread evenly across it. The answer is an estimate
whose precision is the width of the bucket. If the requirement is 200 ms, put a bucket boundary at
200 ms: then the question "how many requests answered within the requirement" has an exact answer,
whatever the estimate in between says.

## Searching the log

The JSON log collected one line per request through the whole run, and `jq` searches it the way
Kibana searches an index:

```
ana@nft:~/boxoffice$ wc -l requests.log
2236 requests.log
ana@nft:~/boxoffice$ jq -s -c 'group_by(.status) | map({status: .[0].status, requests: length})' requests.log
[{"status":200,"requests":1925},{"status":201,"requests":243},{"status":404,"requests":1},{"status":409,"requests":67}]
ana@nft:~/boxoffice$ jq -c 'select(.request_id == "ana-test-1")' requests.log
{"ts":"2026-10-10T07:34:51.901+00:00","level":"info","request_id":"ana-test-1","method":"POST","route":"/bookings","path":"/bookings","status":201,"ms":67.6}
```

The first command counts the lines. The second groups them by status, which is the same answer the
metrics gave, recomputed from the raw events: metrics are what you keep for months, and the log is
what you go back to when a number needs explaining. The third finds one request by its id, which is
how a complaint becomes a line.
