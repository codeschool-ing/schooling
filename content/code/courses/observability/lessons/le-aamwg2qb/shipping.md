---
title: Shipping: from standard output to a store
version: 2
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
Collector is pointed at a second configuration file beside the first.

**This lesson needs a bigger machine than the rest.** Elasticsearch, OpenSearch and Graylog are
three Java programs, and with them running the lab wants 16 GB of memory. On a machine with 8 GB,
read this lesson's transcripts rather than reproducing them; nothing later in the course depends on
it having run.

Graylog needs two secrets before it starts: a password for its `admin` user, and a key it encrypts
its own settings with. `compose.yaml` reads both from `.graylog.env`, which these lines write. The
password also stays in a file of its own, because the API calls below read it from there:

```sh
cd ~/shop
openssl rand -hex 12 > .graylog-password
printf 'GRAYLOG_PASSWORD_SECRET=%s\nGRAYLOG_ROOT_PASSWORD_SHA2=%s\n' "$(openssl rand -hex 32)" "$(tr -d '\n' < .graylog-password | sha256sum | cut -d' ' -f1)" > .graylog.env
```

Then the lab is started again from nothing with the two profiles that hold the stores, which brings
up Elasticsearch, MongoDB, OpenSearch and Graylog beside the rest. Payments fails one charge in
twenty from the start, so that there are failures to look for. Graylog takes a minute or two before
its API answers on port 9000:

```sh
docker compose --profile '*' down -v
docker compose --profile elastic --profile graylog up -d
echo '{"fail_every": 20}' > faults/payments.json
```

The Collector's second configuration is this file:

`~/shop/otel/collector-logs.yaml`

```yaml
# The same Collector, sending every log line to three stores at once:
# Loki, Elasticsearch and Graylog. Lesson 9 switches to it.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 400
  batch: {}
  # A batch from Docker mixes every container's lines under one resource, so
  # the lines are regrouped by their own "service" field, one resource each,
  # before that field becomes the resource's service.name.
  groupbyattrs/service:
    keys: [service]
  transform/service:
    error_mode: ignore
    log_statements:
      - context: resource
        statements:
          - set(attributes["service.name"], attributes["service"]) where attributes["service"] != nil
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(trace_id.string, attributes["trace_id"]) where attributes["trace_id"] != nil
          - set(span_id.string, attributes["span_id"]) where attributes["span_id"] != nil

exporters:
  debug:
    verbosity: basic
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  zipkin:
    endpoint: http://zipkin:9411/api/v2/spans
  otlp_http/loki:
    endpoint: http://loki:3100/otlp
  elasticsearch:
    endpoints: [http://elasticsearch:9200]
  otlp_grpc/graylog:
    endpoint: graylog:4317
    tls:
      insecure: true

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: 0.0.0.0
                port: 8888
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp_grpc/jaeger, zipkin]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki, elasticsearch, otlp_grpc/graylog]
```

And the override that points the Collector at it is the three lines the `cat` below prints, saved as
`~/shop/compose.override.yaml`. What changed from the first file:

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
standard port, through its API. Graylog refuses a change through its API that does not carry an
`X-Requested-By` header, against requests forged from a browser; any value will do:

```
ana@obs:~/shop$ docker compose up -d otel-collector 2>&1 | tail -1
 Container shop-otel-collector-1 Started 
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Content-Type: application/json' -X POST localhost:9000/api/system/inputs -d '{"title": "shop logs (OTLP)", "type": "org.graylog.inputs.otel.OTelGrpcInput", "global": true, "configuration": {"bind_address": "0.0.0.0", "port": 4317, "insecure": true, "max_inbound_msg_size": 4194304}}'; echo
{"id":"6abfd0605386fc4fd78ceb27"}
```

From here, every line any service writes reaches Loki, Elasticsearch and Graylog, through the same
pipeline, with the same fields. That is the point of the exercise: **the comparison that follows is
between three stores holding identical data**, not three setups that differ in what they were sent.

The simulated customers run for a quarter of an hour, and the next sections read what they left
after two and a half minutes:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 900
sleep 150
```
