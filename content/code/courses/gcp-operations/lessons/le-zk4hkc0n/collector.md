---
title: The Collector, between the code and the destination
version: 1
---

**The OpenTelemetry Collector is a program that receives telemetry, processes it and exports it, configured
as pipelines.** A pipeline has receivers (where data comes in), processors (what happens to it) and exporters
(where it goes). The shop's code sends to the Collector and never to a vendor; the Collector holds the
credentials, the batching and the choice of destination. Changing the destination is a change to the
Collector's file, not to every service.

The first configuration prints what it receives, so you can see the spans. Write it into
`~/gcp/collector.yaml`:

```yaml
# collector.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 2s

exporters:
  debug:
    verbosity: normal

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
```

`debug` is an exporter that writes the data to the Collector's own log. Start the Collector with that file,
then run the checkout:

```
ana@laptop:~/gcp$ docker run -d --rm --name otel -p 4318:4318 -v "$PWD/collector.yaml":/etc/otelcol-contrib/config.yaml otel/opentelemetry-collector-contrib:0.137.0
1721c394743fa582cc23943bd5a973870832e787439d574d2ecb4162f65350c5
ana@laptop:~/gcp$ python3 checkout.py
trace id 05ff145145343c86f543a2515ba5c99f
```

And read what the Collector received:

```
ana@laptop:~/gcp$ docker logs otel 2>&1 | grep -A5 '^ScopeTraces'
ScopeTraces #0 shop.checkout
load basket 05ff145145343c86f543a2515ba5c99f 2a625d4a41f3f63e
charge payment 05ff145145343c86f543a2515ba5c99f 39c4173bc0c9bed9 payment.provider=pix
insert order 05ff145145343c86f543a2515ba5c99f e5df3da9c89b932d
POST /orders 05ff145145343c86f543a2515ba5c99f 6b91678415ea4966 order.id=o-1001
	{"resource": {"service.instance.id": "97f0242e-2c00-442e-8bc4-3db34d94b5c0", "service.name": "otelcol-contrib", "service.version": "0.137.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces"}
```

Four spans, all with the same trace id, the one the program printed. Each line is a span's name, the trace
id, its own span id, and its attributes. The order in the log is the order the spans **ended**, inner ones
first, which is why `POST /orders`, the parent, comes last: it ends when the last child has ended.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A Collector pipeline as three boxes from left to right: the receiver otlp takes spans from the program, the processor batch groups them, and the exporter debug writes them out. Changing the destination means changing only the exporter.\"><defs><marker id=\"ah5\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">program</text><rect x=\"190\" y=\"40\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">otlp</text><text x=\"255\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">receiver</text><rect x=\"380\" y=\"40\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">batch</text><text x=\"445\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">processor</text><rect x=\"570\" y=\"40\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">debug</text><text x=\"635\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exporter</text><line x1=\"142\" y1=\"75\" x2=\"188\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><line x1=\"322\" y1=\"75\" x2=\"378\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><line x1=\"512\" y1=\"75\" x2=\"568\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">swap the exporter to send elsewhere; the program does not change</text></svg>", "caption": "Receivers, processors, exporters: the program only knows the first."}
```

## What the processors are for

`batch` groups spans and sends them every two seconds or when enough have gathered, instead of one request
per span. Other processors are the reason a Collector is worth running even with one destination:

| processor | what it does |
|---|---|
| `batch` | fewer, larger exports |
| `memory_limiter` | refuses data before the Collector runs out of memory |
| `resourcedetection` | adds where the Collector runs: project, region, Cloud Run service, GKE cluster |
| `attributes` | adds, renames or removes attributes, such as deleting one that carries personal data |
| `tail_sampling` | keeps whole traces by rule (errors, slow ones), after seeing them |

**Removing personal data in the Collector** is the one to remember: a span attribute holding an e-mail
address is personal data stored in Cloud Trace, and an `attributes` processor that deletes it covers every
service at once.
