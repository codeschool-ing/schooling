---
title: Structured results
version: 1
---

`get_order` returns an `Order`, not a string. Three calls, a good one and two that fail:

```
ana@lab:~/agents$ python try_server.py calls 2> server.log
M-1043: isError=False
  structured: {"id": "M-1043", "status": "shipped", "placed_on": "2026-09-28", "delivered_on": null, "tracking": "BR5512340003", "lines": [{"book_id": "b13", "quant
M-9999: isError=True
  text: Error executing tool get_order: no order M-9999; check the number on the confirmation email
1043: isError=True
  text: Error executing tool get_order: 1 validation error for get_orderArguments order_id   String should match pattern '^M-[0-9]{4}$' [type=string_pattern_m
```

The good call came back with **`structuredContent`**: a JSON object that matches the output schema, which a host can use without parsing text. The SDK also sends the same data as text in `content`, for clients and models that read only that.

Now compare the fields with what `shop.get_order` returns. The database row has `customer_id` and `shipping`; the structured result does not. `Order.model_validate(found)` kept the fields `Order` declares and dropped the rest. **The output type is an allow list**: a field reaches the client only if somebody wrote it into the type. A server that returned the database row as it came would send every column it ever gained to every model that called it, including the ones nobody thought about when the tool was written. Here a customer's id is in the database and never leaves the server, and section 08 has a test that says so.

That is the same habit as lesson 3's observations and lesson 12's question of what a server receives, turned around: decide what a server **sends**, field by field.
