---
title: Adding what only the code knows
version: 2
---

The fix for the first gap is not to replace the automatic instrumentation. **It is to add to the
span it already opened.** Flask's instrumentation makes its `SERVER` span the current span for the
whole request. Code inside the handler can therefore reach it with `trace.get_current_span()` and set an
attribute on it, with no new span and no setup. One line in `create()` does it, and the import
grows by one name. Keep a copy of the file first, as in the previous section:

```sh
cp services/orders/app.py /tmp/orders.app.py
```


```
ana@obs:~/shop$ sed -i 's/^    traceparent = request.headers.get("traceparent")/&\n    trace.get_current_span().set_attribute("shop.sku", body["sku"])/; s/^from opentelemetry import propagate/from opentelemetry import propagate, trace/' services/orders/app.py
ana@obs:~/shop$ grep -n 'trace' services/orders/app.py | head -4
5:publish() that carry the trace into the message, because nothing instruments
15:from opentelemetry import propagate, trace
54:    traceparent = request.headers.get("traceparent")
55:    trace.get_current_span().set_attribute("shop.sku", body["sku"])
```

Restart `orders` so it reads the edited file, and send a checkout:

```sh
docker compose restart orders
checkout
```

The automatic span now carries the attribute the code added:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/e5978340492b8d7ed0b69c7ed6adcab4 | jq -c '.data[0].spans[] | select(.operationName == "POST /orders") | [.tags[] | select(.key | test("^(shop|http.route)")) | {(.key): .value}] | add'
{"http.route":"/orders","shop.sku":"kettle"}
```

**`shop.sku` now sits beside `http.route`** on a span that Flask opened. The same function works for
everything this lesson found missing. Call `set_attribute` for what the request was about, open a
`start_as_current_span` of your own around a slow piece of internal work, and make the propagation calls
of lesson 4 at the client nobody instrumented. The line is cheap: with no SDK, `get_current_span()`
returns the same do-nothing span `no_sdk.py` printed in lesson 2, so it costs nothing where tracing
is off.

That is the arrangement most services end up with, and the reason this course teaches both halves:
**automatic instrumentation for the edges, a few hand-written lines for what the edges cannot
know.** Put the file back the
same way as before, so the rest of the course runs the shop's own `orders`:

```sh
cp /tmp/orders.app.py services/orders/app.py && docker compose restart orders
```
