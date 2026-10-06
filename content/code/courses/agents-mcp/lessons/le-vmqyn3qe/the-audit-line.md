---
title: The audit line
version: 1
---

Every call that reached `run()` wrote a line to `host-audit.jsonl`, whatever happened to it:

```
ana@lab:~/agents$ cat host-audit.jsonl
{"server": "shop", "tool": "get_order", "arguments": {"order_id": "M-1043"}, "approved": true, "is_error": false}
{"server": "shop", "tool": "search_help", "arguments": {"query": "send a book back"}, "approved": true, "is_error": true}
{"server": "shop", "resource": "help://h14", "approved": true}
{"server": "shop", "tool": "search_help", "arguments": {"query": "send a book back"}, "approved": true, "is_error": false}
{"server": "shop", "resource": "help://h14", "approved": true}
{"server": "shop", "resource": "file:///home/ana/agents/data/shop.db", "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": true, "is_error": false}
```

Eight lines for the runs of this lesson: the lookup, the failed search and the good one, three reads of resources (one refused), the declined refund and the approved one. Each says which server, which tool or resource, the arguments, whether it was approved and whether the result was an error.

Three properties make it worth having. **It is written by the host**, the one component that sees every call, from every server. **It records refusals**, which a log written by the servers could not: the declined refund never reached `refunds`, and the `file://` URI never reached anybody. And **it records arguments**, because "a refund was approved" is less use than "3890 cents on M-1047, approved".

It is also personal data, as lesson 8 said of traces: the arguments include order ids, and could include anything a customer typed. Keep it where the rest of that data is kept, and delete it on the same schedule. This repository's own rule for its administrative writes, that every one records who did it (`internal/audit`), is the model lesson 17 builds on.
