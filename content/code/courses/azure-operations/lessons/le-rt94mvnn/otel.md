---
title: OpenTelemetry, and what Azure Monitor's distro adds
version: 1
---

**OpenTelemetry is a specification and a set of libraries for producing traces, metrics and logs in one
vendor-neutral shape.** It is a project of the Cloud Native Computing Foundation, and every major
monitoring vendor, Microsoft included, accepts its data. It has four parts worth naming:

- **the API**, what application code calls: start a span, set an attribute, record an exception;
- **the SDK**, which implements the API: decides which spans to keep (sampling), batches them, and hands
  them to exporters;
- **exporters**, which send the data somewhere: the console, an OTLP endpoint, Azure Monitor;
- **semantic conventions**, agreed attribute names, such as `http.route`, `db.system` and
  `server.address`, so that every backend knows what a span means without being told.

A **span** is one unit of work with a start, an end, a kind, attributes and a status. Spans form a
**trace**: they share a trace id, and each but the first names its parent. A span's **kind** says what
role it played: `SERVER` for handling an incoming request, `CLIENT` for a call out, `INTERNAL` for work in
between.

**Microsoft's recommended way to send telemetry to Application Insights is now OpenTelemetry.** For
Python, .NET, Java and Node.js it publishes an **Azure Monitor OpenTelemetry distro**: the OpenTelemetry
SDK with the Azure Monitor exporter and a set of automatic instrumentations already wired together, so
one call configures everything. The older Application Insights SDKs still exist and still work, and
Microsoft directs new work to OpenTelemetry.

What the distro adds is convenience, not a different model. It reads a **connection string** that names
the Application Insights resource, instruments common libraries automatically (web frameworks, HTTP
clients, database drivers), and maps OpenTelemetry's spans to Application Insights' tables. The next two
sections write the instrumentation by hand, run it, and then look at that mapping.
