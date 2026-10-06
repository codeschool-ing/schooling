---
title: One call
version: 1
---

The host started both servers, listed their tools and asked the model. The course's rule had the model call `shop__get_order`:

```
ana@lab:~/agents$ python mcp_host.py "Where is my order M-1043?" 2> host.err
step 1: shop__get_order {"order_id": "M-1043"}
  result: {"id": "M-1043", "status": "shipped", "placed_on": "2026-09-28", "delivered_on": null, "tracking": "BR55123400
answer: Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
```

**The model's call and answer were written by the course**; the host, its two clients and the server are real. No person was asked: `get_order` is read-only and `shop` is a server whose hints the host believes. What reached the model was the structured result from lesson 14, as JSON, without `customer_id`.

What the model was offered, read from labllm's log:

```
ana@lab:~/agents$ python -c 'import json; [print(t["name"].ljust(20), t["description"][:70]) for t in json.loads(open("/var/log/labllm/requests.jsonl").readline())["request"]["tools"]]'
shop__get_order      (server shop) Look up one Marginalia order: status, dates, tracking, l
shop__search_help    (server shop) Search Marginalia's help centre by meaning. Returns titl
refunds__refund      (server refunds) Refund part or all of an order, in cents, after a mem
read_help            Read one help centre article by its help:// URI.
```

Four tools. Three came from the servers, each renamed `server__tool` and described as coming from its server, and one, `read_help`, is the host's own. The renaming is lesson 12's lesson put into practice: when two servers offer the same name, this host offers two different names, and the model can see which server it is choosing. A host that adds servers its users install should do no less.
