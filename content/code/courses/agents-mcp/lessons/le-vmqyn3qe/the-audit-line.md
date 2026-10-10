---
title: The audit line
version: 2
---

Every call that reached `run()` wrote a line to `host-audit.jsonl`, whatever happened to it:

```
ana@lab:~/agents$ cat host-audit.jsonl
{"server": "shop", "tool": "get_order", "arguments": {"order_id": "M-1043"}, "approved": true, "is_error": false}
{"server": "shop", "tool": "search_help", "arguments": {"query": "send book back"}, "approved": true, "is_error": false}
{"server": "shop", "tool": "search_help", "arguments": {"query": "file:///home/ana/agents/data/shop.db"}, "approved": true, "is_error": false}
{"server": "shop", "resource": "file:///home/ana/agents/data/shop.db", "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"reason": "damaged", "order_id": "M-1047", "cents": "0"}, "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"cents": 0, "order_id": "M-1047", "reason": "damaged"}, "approved": true, "is_error": true}
{"server": "refunds", "tool": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": true, "is_error": false}
```

Seven lines for the runs of this lesson: the lookup, the two searches, the refused read of a `file://` URI, the declined refund, the approved refund of 0 cents that the server rejected, and the approved one of 3890. Each says which server, which tool or resource, the arguments, whether it was approved and whether the result was an error. The stand-in's runs are there beside the real model's, because the host writes a line for every call whoever asked for it.

Three properties make it worth having. **It is written by the host**, the one component that sees every call, from every server. **It records refusals**, which a log written by the servers could not: the declined refund never reached `refunds`, and the `file://` URI never reached anybody. And **it records arguments**, because "a refund was approved" is less use than "0 cents on M-1047, approved, and rejected by the server", which is the line that shows a person said yes without reading.

It is also personal data, as lesson 8 said of traces: the arguments include order ids, and could include anything a customer typed. Keep it where the rest of that data is kept, and delete it on the same schedule. This repository's own rule for its administrative writes, that every one records who did it (`internal/audit`), is the model lesson 17 builds on.
