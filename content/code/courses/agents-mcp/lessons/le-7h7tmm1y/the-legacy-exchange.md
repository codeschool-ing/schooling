---
title: The legacy exchange
version: 1
---

The same server, spoken to the way lesson 11's Claude and Google clients spoke to it, in the 2025-11-25 revision:

```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "by-hand", "version": "0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
```

```
ana@lab:~/agents$ python raw.py shop_mcp.py 300 < legacy.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "by-hand", "version": "0"}}}
< {"jsonrpc":"2.0","id":1,"result":{"capabilities":{"prompts":{"listChanged":false},"resources":{"listChanged":false,"subscribe":false},"tools":{"listChanged":false}},"protocolVersion":"2025-11-25","serverInfo":{"name":"marginalia-shop","version":""}}}
> {"jsonrpc": "2.0", "method": "notifications/initialized"}
> {"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
< {"jsonrpc":"2.0","id":2,"result":{"tools":[{"description":"Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.","inputSchema":{"properties":{"order_id":{"title":"Order Id","type":"string"}},"required":["order_id"],"type":"object","title":"ge
```

`initialize` agrees the version for the whole connection, and the reply says which version the server accepted and what it supports. `notifications/initialized` has no `id`, so `raw.py` waited for no answer and none came. After that, `tools/list` carries no `_meta` at all: the connection remembers.

Set against section 03's exchange, the differences are the 2026-07-28 changes in miniature:

| | legacy (2025-11-25) | modern (2026-07-28) |
|---|---|---|
| agreeing a version | `initialize`, once per connection | `_meta` on every request |
| learning capabilities | the `initialize` result | `server/discover`, when the client wants |
| `resultType` on results | absent | always present |
| `ttlMs`, `cacheScope` on lists | absent | present |
| the server's name | `serverInfo` in the `initialize` result | `serverInfo` in each result's `_meta` |

One detail in the capabilities: the legacy reply says `listChanged: false` for tools, prompts and resources, and the modern `server/discover` said `true`. **The same server declared different abilities in the two eras.** Over a legacy connection, a server tells the client about a changed list with a notification on the open connection; in the modern revision clients opt in to those through `subscriptions/listen`. Which abilities a server offers can depend on the revision, so a client should read them on the connection it has, not assume them from another.
