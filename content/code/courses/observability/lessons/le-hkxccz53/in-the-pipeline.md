---
title: Removing it in the pipeline, and what that misses
version: 1
---

The second defence is in the Collector, where every service's lines pass whether or not their code
was careful. The filter was taken back out of `logs.py` to show it working alone, and a third
Collector file adds two statements to the `transform` processor, before the JSON is parsed, so the
parsed fields are made from the cleaned text:

```
ana@obs:~/shop$ diff otel/collector-logs.yaml otel/collector-redact.yaml
35a36,37
>           - replace_pattern(body, "\\b(?:\\d[ -]?){12,15}(\\d{4})\\b", "**** $$1")
>           - replace_pattern(body, "Bearer [A-Za-z0-9._-]+", "Bearer [removed]")
```

`replace_pattern` rewrites the line's body with a regular expression: card-shaped numbers keep their
last four digits, and anything after `Bearer` is replaced. `$$1` is the first captured group, with
the dollar sign doubled because the Collector expands `$` in its configuration files. The Collector is
recreated with this file, the storefront restarted, and a checkout sent:

```
ana@obs:~/shop$ sed -i 's#collector-logs.yaml#collector-redact.yaml#' compose.override.yaml && docker compose up -d otel-collector 2>&1 | tail -1
 Container shop-otel-collector-1 Started 
ana@obs:~/shop$ docker compose restart storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d @checkout.json
{"id":2703,"qty":1,"sku":"kettle","status":"paid"}
```

What Loki received:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="storefront"} | json | message="request"' --data-urlencode since=5m --data-urlencode limit=1 | jq -r '.data.result[].values[][1]' | jq -c '{card: .body.card, auth: .headers.Authorization}'
{"card":"**** 1111","auth":"Bearer [removed]"}
```

**Masked.** And what the container itself wrote, read on the machine with `docker compose logs`:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep '"request"' | tail -1 | jq -c '{card: .body.card, auth: .headers.Authorization}'
{"card":"4111 1111 1111 1111","auth":"Bearer sk_live_9f8e7d6c5b4a"}
```

**Not masked.** The pipeline only cleans what passes through it. The container's own log on the
machine, a crash dump, a developer running the service by hand, anything that reads the process's
output before the Collector does, still has the secret.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Where a secret written by the storefront ends up, and which defence covers which place. The storefront's line goes first to the container's own log on the machine, then through the Collector, then to Loki and Elasticsearch. A filter in the code removes the secret before the line exists anywhere. Redaction in the Collector removes it only from what the Collector forwards: the container's own log on the machine still holds it.\"><defs><marker id=\"lk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"80.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">writes the line</text><rect x=\"180\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">container log</text><text x=\"255.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the machine</text><rect x=\"180\" y=\"120\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Collector</text><text x=\"255.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replace_pattern</text><rect x=\"380\" y=\"100\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loki</text><rect x=\"380\" y=\"160\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Elasticsearch</text><path d=\"M142 120 L178 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M142 140 L178 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M332 150 L378 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M332 155 L378 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah)\"></path><path d=\"M20 225 L510 225\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"265\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a filter in the code: every copy is clean</text><path d=\"M180 262 L510 262\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"345\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">redaction in the Collector: only what it forwards</text><text x=\"600\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">still has the secret</text><text x=\"600\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">if only the Collector redacts</text><path d=\"M520 60 L334 55\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#lk-ah)\"></path></svg>", "caption": "Two defences, two coverages. The one in the code covers every copy; the one in the pipeline covers every copy after the pipeline, which is why it is the second line and not the first."}
```

That is why the order matters: **the code is the first defence and the pipeline is the second**. The
pipeline catches the service somebody forgot to update and the library that logs on its own; the code
catches everything, everywhere the line goes. The Collector also ships a dedicated `redaction`
processor, built around an allow-list of attribute names, which is stricter still: what is not
listed is dropped.
