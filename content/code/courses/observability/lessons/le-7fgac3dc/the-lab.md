---
title: The lab this course runs on
version: 1
---

Every command in this course was run, and every line of output is what it printed. **The lab is
one Linux computer running Docker**: a small online shop, written for the course, and the
open-source software that watches it, each in its own container. The user is `ana` and the work
happens in `~/shop`:

```
ana@obs:~/shop$ docker compose ps --format 'table {{.Service}}\t{{.Image}}' | sort
SERVICE             IMAGE
alertmanager        prom/alertmanager:v0.34.1
blackbox-exporter   prom/blackbox-exporter:v0.28.0
grafana             grafana/grafana:13.0.10
jaeger              jaegertracing/jaeger:2.21.0
loki                grafana/loki:3.7.8
mailer              shop:1.4.0
node-exporter       prom/node-exporter:v1.12.1
orders              shop:1.4.0
otel-collector      otel/opentelemetry-collector-contrib:0.161.0
pager               shop:1.4.0
payments            shop:1.4.0
postgres            postgres:16.15
postgres-exporter   prometheuscommunity/postgres-exporter:v0.20.1
prometheus          prom/prometheus:v3.15.0
rabbitmq            rabbitmq:4.2-management
storefront          shop:1.4.0
zipkin              openzipkin/zipkin:3.6.1
```

**The shop is the part written for the course**, every container whose image is `shop:1.4.0`. A
checkout arrives at `storefront`, which asks `orders` to store it; `orders` asks `payments` to
charge the card and, once it is paid, puts a message on a RabbitMQ queue that `mailer` takes off to
send the confirmation. `pager` is where alerts land in lesson 16, and two more programs from the same
image run only when asked: `report`, the nightly job of lesson 4, and `loadgen`, which plays
customers. The shop is small on purpose, and **it has the shapes production systems have**: HTTP
between services, a database, a queue and a scheduled job, which are exactly the places where
signals get lost.

::: track networks-infra
The services are written in Python, which this track has already taught you. Reading them is
reading code you know, and lessons 2 to 4 change them.
:::

::: track data-platform
The services are written in Python, which the data track this one continues has already taught
you. Reading them is reading code you know, and lessons 2 to 4 change them.
:::

::: track software-architecture
The services are written in Python, which this track has not taught, and you will not need to
write it. Every piece of code this course shows carries a note saying what it does, and what you
change in it is a line or two that the lesson gives you whole.
:::

::: track *
The services are written in Python. You need to be able to read it, not to write it: every piece
of code this course shows carries a note saying what it does, and what you change in it is a line
or two that the lesson gives you whole.
:::

Everything else is real, unmodified software in its official image. The OpenTelemetry Collector
receives traces and logs and forwards them. Prometheus stores metrics and Alertmanager routes the
alerts it raises. Loki stores logs, Jaeger and Zipkin store traces, and Grafana draws all of them.
The exporters turn the machine, the database and an outside probe into metrics. Lessons 9, 14 and
19 add Elasticsearch, Graylog, a Kubernetes cluster and Envoy, and say so when they do.

**Every port is published on `127.0.0.1` only**, so `localhost:8080` is the shop and
`localhost:9090` is Prometheus, from `ana`'s shell and from nowhere else.

To build the same lab you need a Linux machine, a virtual machine being the easiest, with Docker
Engine and the Compose plugin, four processors and 8 GB of memory. The script that builds it is
`lab.sh`, published with this course's source; `sudo bash lab.sh up` writes `~/shop`, builds the
shop's image and starts everything, and `sudo bash lab.sh reset` throws it all away and starts
again from nothing. Every lesson's transcripts begin from a reset, so **what you see on your
machine after a reset is what the lesson shows**, except for the parts that are different on every
run: dates, durations to the millisecond, and the random ids every trace gets.

**When something does not answer**, ask Docker before asking the program: `docker compose ps`
says whether the container is running, and `docker compose logs <service>` says what it printed
on the way up.
