---
title: Shipping: from standard output to a store
version: 1
---

Lesson 8 left every service printing JSON to its standard output and knowing nothing about where it
goes. **Something has to collect those lines and deliver them.** The general name for it is a
log *shipper* or *agent*: Fluent Bit, Vector, Logstash, Promtail and its successor Alloy, or the
OpenTelemetry Collector, which the lab already runs for traces. Putting this job outside the service
is what lets the service stay simple, and what lets the destination change without a release.
A service that sends its logs straight to a store over HTTP has to retry, buffer and authenticate
itself, and changes every time the store does.

In the lab the path is Docker's `fluentd` logging driver, which hands each line to the Collector,
whose `transform` processor parses the JSON, and an exporter per store. Adding two stores is a change
to the Collector alone. Compose reads `compose.override.yaml` on top of `compose.yaml`, so the
Collector is pointed at a second configuration file that the lab ships beside the first:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
ana@obs:~/shop$ diff otel/collector.yaml otel/collector-logs.yaml
1,2c1,2
< # The OpenTelemetry Collector: every trace and every log line of the shop
< # passes through here on its way to where it is stored.
---
> # The same Collector, sending every log line to three stores at once:
> # Loki, Elasticsearch and Graylog. Lesson 9 switches to it.
51a52,57
>   elasticsearch:
>     endpoints: [http://elasticsearch:9200]
>   otlp_grpc/graylog:
>     endpoint: graylog:4317
>     tls:
>       insecure: true
70c76
<       exporters: [otlp_http/loki]
---
>       exporters: [otlp_http/loki, elasticsearch, otlp_grpc/graylog]
```

**Two exporters added, and one line changed**: the logs pipeline now ends in three exporters, and
every line is sent to all three. The traces pipeline is untouched. The Collector is recreated with
the new file, and Graylog is given an input to receive on, its *OpenTelemetry (gRPC)* type on the
standard port, through its API:

```
ana@obs:~/shop$ docker compose up -d otel-collector 2>&1 | tail -1
 Container shop-otel-collector-1 Started 
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Content-Type: application/json' -X POST localhost:9000/api/system/inputs -d '{"title": "shop logs (OTLP)", "type": "org.graylog.inputs.otel.OTelGrpcInput", "global": true, "configuration": {"bind_address": "0.0.0.0", "port": 4317, "insecure": true, "max_inbound_msg_size": 4194304}}'; echo
{"id":"6abfd0605386fc4fd78ceb27"}
```

From here, every line any service writes reaches Loki, Elasticsearch and Graylog, through the same
pipeline, with the same fields. That is the point of the exercise: **the comparison that follows is
between three stores holding identical data**, not three setups that differ in what they were sent.
