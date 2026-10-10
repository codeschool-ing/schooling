---
title: Prometheus collects, by asking
version: 1
---

Prometheus **pulls**. It does not wait for programs to send it numbers; every few seconds it asks
each program for its `/metrics` page, a request called a **scrape**, and stores what it reads with
the time. A program only has to answer that page, and Prometheus decides how often and from whom.

Its configuration, saved as `prometheus.yml`, says what to scrape:

```yaml
# prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: tickets
    dns_sd_configs:
      - names: [app]
        type: A
        port: 8000
        refresh_interval: 5s
```

`scrape_interval: 5s` is how often. The scrape job is called `tickets`, and its targets come from
**DNS**: every address Docker's name server gives for the name `app`, on port 8000, looked up again
every five seconds. That matters because the box office runs as several copies, and Prometheus has
to ask **each copy** for its own numbers.

## Starting it

The image is rebuilt with the new library, and the stack starts with one copy of the box office:

```
ana@lab:~/tickets$ docker compose build -q
 Image tickets-app Building 
 Image tickets-app Built 
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_replication Creating 
 Network tickets_replication Creating 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-prometheus-1 Creating 
 Network tickets_replication Created 
 Network tickets_replication Created 
 Container tickets-db-1 Creating 
 Container tickets-prometheus-1 Created 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-prometheus-1 Starting 
 Container tickets-db-1 Starting 
 Container tickets-prometheus-1 Started 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
```

One read and one sale, then the metrics page, filtered to the box office's own lines:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1 >/dev/null; curl -s -X POST localhost:8080/events/1/tickets >/dev/null
ana@lab:~/tickets$ curl -s localhost:8080/metrics | grep '^tickets_'
tickets_requests_total{method="GET",route="/events/{id}",status="200"} 1.0
tickets_requests_total{method="POST",route="/events/{id}/tickets",status="201"} 1.0
tickets_request_seconds_bucket{le="0.005",method="GET",route="/events/{id}"} 0.0
tickets_request_seconds_bucket{le="0.01",method="GET",route="/events/{id}"} 0.0
tickets_request_seconds_bucket{le="0.025",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.05",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.1",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.25",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.5",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="1.0",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="2.5",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="5.0",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="+Inf",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_count{method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_sum{method="GET",route="/events/{id}"} 0.016301100000418955
tickets_request_seconds_bucket{le="0.005",method="POST",route="/events/{id}/tickets"} 0.0
tickets_request_seconds_bucket{le="0.01",method="POST",route="/events/{id}/tickets"} 0.0
tickets_request_seconds_bucket{le="0.025",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.05",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.1",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.25",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.5",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="1.0",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="2.5",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="5.0",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="+Inf",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_count{method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_sum{method="POST",route="/events/{id}/tickets"} 0.02141379299973778
tickets_in_flight 1.0
```

The counter says one `GET` answered 200 and one `POST` answered 201. The histogram has a line per
bucket, each counting the requests that took **up to** that many seconds, so the counts only grow
from top to bottom: the read took more than 10 ms and less than 25, and so did the sale. `_count` and
`_sum` are the number of observations and their total, 16 ms for the read and 24 ms for the sale.
`tickets_in_flight` is 1: the request asking for the page was itself in progress.

## Three copies, three targets

Now three copies, and nginx restarted to see them, as in lesson 1:

```
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-replica-1 Running 
 Container tickets-app-1 Running 
 Container tickets-prometheus-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-2 Creating 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Created 
 Container tickets-app-3 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
```

A few seconds later, Prometheus has found them. `up` is a series Prometheus writes for every target,
1 if the last scrape worked and 0 if it did not. `promtool`, inside the Prometheus image, sends a
query and prints the answer:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'up'
up{instance="172.18.0.5:8000", job="tickets"} => 1 @[1791612577.701]
up{instance="172.18.0.7:8000", job="tickets"} => 1 @[1791612577.701]
up{instance="172.18.0.8:8000", job="tickets"} => 1 @[1791612577.701]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Prometheus on the left asks Docker's DNS for the addresses of app, gets three, and every five seconds sends GET /metrics to each copy directly. nginx, which spreads the users' requests, is not on the path of the scrapes.\"><rect x=\"20\" y=\"85\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Prometheus</text><text x=\"90\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every 5 s</text><rect x=\"20\" y=\"175\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">DNS: app → 3 addresses</text><path d=\"M90 145 L90 175\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"330\" y=\"30\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"405\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">tickets-app-1</text><text x=\"405\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/metrics</text><path d=\"M160 115 L328 52\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M328 52 L323.2 57.1 L321.0 51.4 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"330\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"405\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">tickets-app-2</text><text x=\"405\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/metrics</text><path d=\"M160 115 L328 122\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M328 122 L321.6 124.8 L321.8 118.7 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"330\" y=\"170\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"405\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">tickets-app-3</text><text x=\"405\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/metrics</text><path d=\"M160 115 L328 192\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M328 192 L321.0 192.1 L323.5 186.6 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"600\" y=\"92\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"650\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb (nginx)</text><path d=\"M600 114 L482 52\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M600 114 L482 122\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M600 114 L482 192\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"650\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">users' requests</text></svg>", "caption": "Prometheus finds every copy by name and scrapes each one; users go through nginx."}
```

Three targets, one per copy, each scraped directly at its own address and not through nginx. **Asking
through the load balancer would have answered with one copy's numbers**, a different one each time,
which is useless for a counter. That is the reason a pull system needs **service discovery**, a way
to learn the address of every copy, and the reason `up` is the first thing to alert on: a copy that
stops answering scrapes is a copy whose numbers have silently left every graph.
