---
title: How a service gets spans it never asked for
version: 1
---

`orders` imports no tracer and opens no span, and lesson 1's trace still had four spans from it.
The difference is one word in front of its command:

```
ana@obs:~/shop$ grep -A3 '^  orders:' compose.yaml
  orders:
    <<: *shop
    command: opentelemetry-instrument waitress-serve --port 8081 --threads 16 orders.app:app
    environment:
```

**`opentelemetry-instrument` runs before the program and changes it.** It is a small launcher that
sets up the SDK and then starts the real command, `waitress-serve`, in the same process. Between
the two it does the step lesson 2 never had: for each library it knows how to instrument, it
replaces the library's functions with wrappers that open a span, call the original and close the
span. This is called **monkey-patching**, and Python allows it because a module's functions are
attributes anyone can reassign.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"What opentelemetry-instrument does before the program runs, in five steps left to right. One: read the OTEL_ environment variables. Two: build the SDK from them, the provider, processor and exporter. Three: find every installed instrumentation package. Four: each one wraps its library's functions: Flask, requests, psycopg. Five: start the real program, waitress-serve with orders.app, whose code calls the wrapped functions without knowing.\"><defs><marker id=\"auto-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 read</text><text x=\"80.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OTEL_ variables</text><rect x=\"160\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 build the SDK</text><text x=\"220.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provider, exporter</text><rect x=\"300\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 find</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">instrumentations</text><rect x=\"440\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 wrap</text><text x=\"500.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Flask, requests,</text><rect x=\"580\" y=\"80\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5 run</text><text x=\"640.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders.app</text><text x=\"500\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">psycopg</text><path d=\"M142 115 L158 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><path d=\"M282 115 L298 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><path d=\"M422 115 L438 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><path d=\"M562 115 L578 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#auto-ah)\"></path><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">opentelemetry-instrument waitress-serve ... orders.app:app</text><path d=\"M20 190 L280 190\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"150\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what lesson 2 did by hand</text><path d=\"M300 190 L560 190\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"430\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new: finds and changes</text><text x=\"430\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the imported libraries</text></svg>", "caption": "Everything lesson 2 wrote by hand in common/tracing.py, done from the environment, plus the step lesson 2 never had: patching libraries the code imports."}
```

Which libraries get patched is decided by what is installed. Each instrumentation is a separate
package, and the launcher loads every one it finds:

```
ana@obs:~/shop$ docker compose exec orders pip list 2>/dev/null | grep -i opentelemetry-instrumentation
opentelemetry-instrumentation            0.66b0
opentelemetry-instrumentation-dbapi      0.66b0
opentelemetry-instrumentation-flask      0.66b0
opentelemetry-instrumentation-psycopg    0.66b0
opentelemetry-instrumentation-requests   0.66b0
opentelemetry-instrumentation-wsgi       0.66b0
```

Flask for the requests that arrive, `requests` for the calls that leave, psycopg for the database.
The `wsgi` and `dbapi` packages are the generic layers the first and the last are built on. The
image installed them because its requirements named them; `opentelemetry-bootstrap`, which comes
with the launcher, can instead read what a program has installed and print the instrumentation
packages that match.

**Everything else comes from the environment**, the same SDK lesson 2 built by hand, described by
variables instead of code:

```
ana@obs:~/shop$ docker compose exec orders env | grep ^OTEL_ | sort
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_LOGS_EXPORTER=none
OTEL_METRICS_EXPORTER=none
OTEL_PYTHON_FLASK_EXCLUDED_URLS=health,metrics
OTEL_SERVICE_NAME=orders
OTEL_TRACES_EXPORTER=otlp
```

`OTEL_SERVICE_NAME` becomes the resource's `service.name`. The exporter is OTLP over HTTP to the
Collector, and metrics and logs are switched off because the shop handles those its own way. Not one
line of `orders/app.py` mentions any of it.
