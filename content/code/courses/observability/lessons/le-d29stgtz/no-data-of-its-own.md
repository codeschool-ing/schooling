---
title: A front end with no data of its own
version: 2
---

The common picture of Grafana is *the monitoring system*. **It stores none of the data it draws.**
Every panel is a query sent, when the panel is drawn, to a **data source**: a backend Grafana knows
how to ask. Prometheus holds the metrics, Loki the logs, Jaeger the traces, and Grafana holds the
dashboards, the users and the list of where to ask. Losing Grafana loses the drawings, not a single
data point.

This lesson draws a shop under load, so start from a lab started again from nothing and set the
simulated customers going for half an hour:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 1800
```

Grafana answers on port 3000:

```
ana@obs:~/shop$ curl -s localhost:3000/api/health | jq -c .
{"database":"ok","version":"13.0.10","commit":"885f00ce25d95a9bedc723c89dfb2e4cb7c876eb"}
```

Its data sources are not clicked together in the interface; they are **provisioned** from a file
read at start-up, which lives in `~/shop` beside everything else:

```
ana@obs:~/shop$ cat grafana/provisioning/datasources/shop.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    uid: loki
    type: loki
    url: http://loki:3100
  - name: Jaeger
    uid: jaeger
    type: jaeger
    url: http://jaeger:16686
```

And Grafana confirms it holds those three, each with the `uid` the file gave it:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) localhost:3000/api/datasources | jq -r '.[] | [.name, .type, .uid, .url] | @tsv'
Jaeger	jaeger	jaeger	http://jaeger:16686
Loki	loki	loki	http://loki:3100
Prometheus	prometheus	prometheus	http://prometheus:9090
```

**The `uid` is what everything else refers to**, and the file chose it on purpose. A dashboard that
names its data source by a `uid` written in the file works the same on every Grafana that loaded the
same file. One that names it by an id Grafana generated works only on the Grafana that generated it.
The admin password comes from the file you wrote in lesson 1, `.grafana-password`, read by `$(cat ...)` so it
never appears on the screen. The next section stops needing it at all.
