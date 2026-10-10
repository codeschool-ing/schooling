---
title: The pieces and where they run
version: 1
---

Four kinds of thing take part, and each runs in its own place:

1. **The SDK, inside each service.** The box office and payments each create spans as they work, and
   hand the finished ones to a span processor, which collects them in batches.
2. **The exporter, also inside each service**, which sends each batch over OTLP to an address, in
   the background. A request never waits for its spans to be sent.
3. **The Collector, a separate container**, which receives OTLP from every service, can drop,
   sample, enrich and batch it, and forwards it to one or more back ends.
4. **The back end**, here **Jaeger**, which stores traces and answers queries about them, on a web
   page and through an API.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two services on the left, the box office and payments, each with the OpenTelemetry SDK inside it, a batch processor and an OTLP exporter. Both send their spans over OTLP to one Collector in the middle, which batches them and forwards them to Jaeger on the right, where traces are stored and queried.\"><rect x=\"20\" y=\"30\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets</text><rect x=\"36\" y=\"62\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"81\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SDK spans</text><rect x=\"136\" y=\"62\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"181\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">batch + OTLP</text><path d=\"M126 79 L134 79\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M134 79 L127.7 82.0 L127.7 76.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M240 70 L318 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M318 125 L311.1 123.9 L314.6 118.9 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"20\" y=\"140\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">payments</text><rect x=\"36\" y=\"172\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"81\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SDK spans</text><rect x=\"136\" y=\"172\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"181\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">batch + OTLP</text><path d=\"M126 189 L134 189\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M134 189 L127.7 192.0 L127.7 186.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M240 180 L318 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M318 125 L314.6 131.1 L311.1 126.1 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"279\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">OTLP</text><rect x=\"320\" y=\"95\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">collector</text><text x=\"395\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">receive · batch · send</text><path d=\"M470 125 L548 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M548 125 L541.7 128.0 L541.7 122.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"550\" y=\"95\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">jaeger</text><text x=\"625\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">store · query</text><text x=\"625\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:16686</text></svg>", "caption": "Spans leave each service in batches, meet in the Collector and are stored in Jaeger."}
```

Every service could send straight to Jaeger, and in a lab it would work. The Collector is there for
the same reason a load balancer is: it is **the one place that changes when the back end changes**.
It is also where sampling across services, sensitive-attribute removal and retries are configured
once rather than in every program. In production it usually runs twice: a small Collector beside
each service, or on each machine, and a pool of Collectors behind them.

## A span, precisely

A **trace** is the whole path of one request. It is made of **spans**, each one a unit of work with:

- a **trace id**, shared by every span of the trace, and a **span id** of its own;
- the **id of its parent span**, empty for the root, which is what turns the spans into a tree;
- a **name**, a **kind** (`SERVER` for work done answering a request, `CLIENT` for a call to another
  service, `INTERNAL` for anything else), a start and an end;
- **attributes**: key-value pairs describing it, like the route and the status;
- **events** with timestamps, such as a recorded exception, and a **status**.

Lesson 7's metrics told you that sales took 120 ms at the 95th percentile. A trace of one sale tells
you how those milliseconds were spent, and in which service.
