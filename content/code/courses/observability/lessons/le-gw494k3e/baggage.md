---
title: Baggage, and what must never travel in it
version: 1
---

The context that travels has a second part besides the trace. **Baggage** is a set of key and value
pairs that a service puts into the context and that every service downstream can read. It is carried
in its own header beside `traceparent`. `baggage.py` sets one entry and injects, as a service would
before calling the next:

```python
from opentelemetry import baggage, context, propagate, trace
from opentelemetry.sdk.trace import TracerProvider

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer("baggage")

ctx = baggage.set_baggage("shop.channel", "mobile-app")
token = context.attach(ctx)
with tracer.start_as_current_span("checkout"):
    headers = {}
    propagate.inject(headers)
    for name, value in headers.items():
        print(f"{name}: {value}")
context.detach(token)
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python baggage.py 2>/dev/null
traceparent: 00-0c531134f2a06a5c7c096165b02bd3c7-c44dc70726c00067-03
baggage: shop.channel=mobile-app
```

The second header is the baggage: `shop.channel=mobile-app`. A service three hops away can read it
with `baggage.get_baggage("shop.channel")`. It could, for instance, record it on its own spans, so
that *are checkouts from the mobile app slower?* can be asked of a service that never saw the app.

Two properties of baggage are easy to miss, and both cause trouble:

- **It is not an attribute.** Nothing records baggage on a span automatically. It travels, and a
  service that wants it on its spans has to copy it there, or configure a span processor that does.
- **It travels everywhere the context goes**, and the context goes with every outgoing call the
  instrumentation sees: to your own services, and also to a payment provider, a maps API or any
  other third party the shop calls over HTTP. Whatever is in the baggage is sent to all of them, in
  plain text, on every request.

That second property is the rule: **nothing personal or secret goes into baggage**. Not a customer's
e-mail or tax number, not a session token, not an internal hostname you would not publish. A
channel, a region, a tenant id that means nothing outside the company: those are what it is for. And
because every entry is sent on every call, it has a cost in bytes too. A few short entries are the
ceiling, not the start.
