---
title: Steering it with the environment
version: 1
---

An automatic instrumentation is configured the way it was installed: from outside the code. Every
setting is an environment variable, and most of them start with `OTEL_`. The ones that matter
first:

| variable | what it decides |
|---|---|
| `OTEL_SERVICE_NAME` | the `service.name` every span carries |
| `OTEL_RESOURCE_ATTRIBUTES` | more resource attributes, as `key=value,key=value` |
| `OTEL_TRACES_EXPORTER` | `otlp`, `console` or `none` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | where the exporter sends |
| `OTEL_TRACES_SAMPLER` | which traces are kept; lesson 12 |
| `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` | instrumentations to skip, by name |
| `OTEL_PYTHON_FLASK_EXCLUDED_URLS` | Flask routes that get no span |

**The last one is already in use.** Prometheus asks every service for `/metrics` every fifteen
seconds, and a health check asks `/health` on its own schedule. Traced, each of those would be a
trace nobody wants, at a steady rate, crowding out the checkouts. `orders` excludes both, and three
calls to its health check leave no trace behind:

```
ana@obs:~/shop$ docker compose exec orders python -c 'import urllib.request as u; print([u.urlopen("http://localhost:8081/health").status for i in range(3)])'
[200, 200, 200]
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=orders' | jq -r '.operations[].name' | sort
INSERT
POST
POST /orders
UPDATE
```

Four operations, and no `GET /health` among them. **Turning a whole instrumentation off** is the
same kind of change. Here the database layer is disabled, `orders` is recreated with the new
variable, and a checkout is sent:

```
ana@obs:~/shop$ cp compose.yaml compose.yaml.orig
ana@obs:~/shop$ sed -i 's/      OTEL_PYTHON_FLASK_EXCLUDED_URLS: health,metrics/&\n      OTEL_PYTHON_DISABLED_INSTRUMENTATIONS: psycopg/' compose.yaml
ana@obs:~/shop$ docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
ana@obs:~/shop$ curl -s localhost:16686/api/traces/09839a6961d8e8d4b0f0c10ba65e358c | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[] | select($t.processes[.processID].serviceName == "orders") | .operationName'
POST /orders
POST
ana@obs:~/shop$ mv compose.yaml.orig compose.yaml && docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
```

`INSERT` and `UPDATE` are gone, and nothing else changed: the database was still called, it just
was not watched. That is how a noisy or misbehaving instrumentation is silenced in production while
somebody decides what to do about it, without a release of the service. `mv` put the original
`compose.yaml` back, and `orders` was recreated again with its database spans.
