---
title: A span's name is a category, not a record
version: 1
---

The storefront's span is called `POST /checkout`, not `POST /checkout for kettle`. That looks like a
detail, and it is the most common instrumentation mistake there is. `names.py` makes fifty spans
for fifty orders, once naming each with its order id and once with the route's template and the id
as an attribute:

```python
    if style == "bad":
        name = f"GET /orders/{order_id}"
        attributes = {}
    else:
        name = "GET /orders/{id}"
        attributes = {"shop.order_id": order_id}
    with tracer.start_as_current_span(name, attributes=attributes):
        pass
```

Jaeger keeps a list of each service's **operations**, the distinct span names it has seen, and
offers it as the first thing to filter by:

```
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=names-bad' | jq '.operations | length'
50
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=names-bad' | jq -r '.operations[:3][].name'
GET /orders/1011
GET /orders/1047
GET /orders/1026
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=names-good' | jq -r '.operations[].name'
GET /orders/{id}
```

**Fifty operations against one**, for the same fifty requests. The list in the first service grows
by one with every order the shop ever takes; its first three are `1011`, `1047` and `1026`, in no
order anybody chose. A filter by operation is now a search for one order. A latency
aggregated per operation is fifty averages of one request each. Backends that compute metrics from
spans, which lesson 12 does with the Collector, make one series per operation, and the name has
become the label that blows up the bill in lesson 6.

The rule follows from what a name is for: **a span's name says what kind of work this is**, and the
attributes say which instance of it. `GET /orders/{id}` with `shop.order_id = 1011` keeps both: the
operation is one row in every list, and order 1011 is still one search away. The semantic
conventions write this down for HTTP, where the name is the method and the route template, and for
databases, where it is the operation and the table, never the full query with its values.
