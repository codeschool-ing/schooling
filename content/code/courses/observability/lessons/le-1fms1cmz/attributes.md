---
title: Attributes: what a span knows
version: 1
---

A span with only a name and a duration says that something took time. **Attributes say what it was
taking time on**: key and value pairs, set while the span is open, that a backend can search and
group by. This is the start of the storefront's checkout, the span lesson 1's trace began with:

```schooling-example
{
  "language": "python",
  "file": "storefront/app.py",
  "parts": [
    {
      "code": "@app.post(\"/checkout\")\ndef checkout():\n    with tracer.start_as_current_span(\"POST /checkout\", kind=SpanKind.SERVER) as span:\n        body = request.get_json()\n        sku, qty = body[\"sku\"], int(body.get(\"qty\", 1))\n",
      "note": "One span for the whole request, opened by hand. `kind=SpanKind.SERVER` says this span is the receiving end of a call, which backends use to draw the boundary between services."
    },
    {
      "code": "        span.set_attribute(\"http.request.method\", \"POST\")\n        span.set_attribute(\"http.route\", \"/checkout\")\n",
      "note": "Attributes from **OpenTelemetry's semantic conventions**: names every backend and every library agree on, so a dashboard built for one service works for the next."
    },
    {
      "code": "        span.set_attribute(\"shop.sku\", sku)\n        span.set_attribute(\"shop.quantity\", qty)\n",
      "note": "The shop's own attributes, under a prefix of its own so they can never collide with a convention added later."
    },
    {
      "code": "        if sku not in PRODUCTS:\n            span.set_attribute(\"http.response.status_code\", 404)\n            log.info(\"unknown product\", extra={\"fields\": {\"sku\": sku}})\n            return {\"error\": f\"no product {sku}\"}, 404\n        total = PRODUCTS[sku] * qty\n        span.set_attribute(\"shop.total_cents\", total)",
      "note": "A 404 is recorded and **not marked as an error**: the storefront did its job by refusing an unknown product. The card number in `body` is never set as an attribute, on purpose."
    }
  ]
}
```

And this is what that span carried for one checkout of a kettle, as Jaeger stored it:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/7649c3dfb988a9ca71e4bec16bfca43f | jq -c '.data[0].spans[] | select(.operationName == "POST /checkout") | .tags[] | {key, value}'
{"key":"otel.scope.name","value":"storefront"}
{"key":"otel.scope.version","value":"1.4.0"}
{"key":"http.request.method","value":"POST"}
{"key":"http.status_code","value":201}
{"key":"http.route","value":"/checkout"}
{"key":"shop.quantity","value":1}
{"key":"shop.sku","value":"kettle"}
{"key":"shop.total_cents","value":18990}
{"key":"span.kind","value":"server"}
```

Three families are mixed in that list, and telling them apart is most of the skill:

- **Attributes from the semantic conventions**, `http.request.method` and `http.route`. OpenTelemetry
  publishes the names for common things: HTTP, databases, messaging, cloud resources. Use them
  wherever one fits, because every backend and every automatic instrumentation uses the same ones,
  and a query for `http.route` finds the route whoever wrote the span. The status code went out as
  `http.response.status_code`, the current convention, and Jaeger lists it under the older name
  `http.status_code`.
- **The shop's own attributes**, `shop.sku`, `shop.quantity` and `shop.total_cents`. Nothing
  automatic knows what a kettle is, and these are the attributes that make *"are checkouts of one
  product slower?"* answerable. The prefix is the shop's, so a convention added next year can never
  mean something else under the same name.
- **What the backend added**: `otel.scope.name` and `otel.scope.version` are the tracer that made the
  span, and `span.kind` is the kind it was given.

**What is not in the list matters as much.** The request body carried a card number, and the code
never copies it into an attribute. A trace is stored, shipped between systems, sampled, exported to
vendors and read by anybody debugging. A card number, a password, a token or a personal document
in it leaks to every one of those places at once. Lesson 10 makes the same argument for logs, at
length.

An attribute may be as specific as the request is: an order id, a customer's country, a product.
**That is the difference from a metric label**, which lesson 6 shows multiplying into an
unaffordable number of series. A span is stored once whatever its attributes say, so high
cardinality is what attributes are for. A span's *name* is different again, and the last section
of this lesson is about it.
