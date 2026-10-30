---
title: From spans to the tables of lesson 11
version: 1
---

**The Azure Monitor exporter turns each span into a row of the table its kind belongs to.** The mapping
is Microsoft's, documented with the distro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Mapping from OpenTelemetry to Application Insights. A SERVER span becomes a row in AppRequests. A CLIENT span becomes a row in AppDependencies. An exception event on a span becomes a row in AppExceptions. The trace id becomes OperationId on all of them, the span id becomes Id, and the parent span id becomes ParentId.\"><defs><marker id=\"ah-map\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">OpenTelemetry</text><text x=\"560\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Application Insights</text><rect x=\"40\" y=\"45\" width=\"220\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SERVER span</text><rect x=\"40\" y=\"100\" width=\"220\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CLIENT span</text><rect x=\"40\" y=\"155\" width=\"220\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">exception event</text><rect x=\"460\" y=\"45\" width=\"220\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">AppRequests</text><rect x=\"460\" y=\"100\" width=\"220\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">AppDependencies</text><rect x=\"460\" y=\"155\" width=\"220\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">AppExceptions</text><path d=\"M260 65 L458 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-map)\"></path><path d=\"M260 120 L458 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-map)\"></path><path d=\"M260 175 L458 175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-map)\"></path><text x=\"360\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">trace id → OperationId   span id → Id   parent → ParentId</text></svg>", "caption": "The exporter translates; the shape of the trace is kept."}
```

So the five lines you printed would have been, in a workspace, two `AppRequests` rows, three
`AppDependencies` rows and one `AppExceptions` row, all carrying the trace id as `OperationId`. That is
the join lesson 11 relied on: **`OperationId` is not an Application Insights invention, it is the
OpenTelemetry trace id**, and it is the same across every service the request touches, provided each one
passes the trace context along. Over HTTP that is the W3C `traceparent` header, which OpenTelemetry's HTTP
instrumentation sends and reads by itself.

The status maps as you would expect: a span with status `ERROR` becomes a row with `Success` false, and
an HTTP server span's result code comes from `http.response.status_code`. Attributes that are not part of
the mapping are kept as **custom dimensions**, queryable in the `Properties` column. Sampling, lesson 11's
subject, is done by the SDK before export, and the exporter writes the sampling rate into `ItemCount`.

The resource's `service.name`, `shop-api` here, becomes the **cloud role name**, `AppRoleName`, which is
how a workspace with ten services tells their rows apart and how Application Insights draws its map of
which service calls which.
