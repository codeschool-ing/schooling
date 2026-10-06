---
title: A request, by hand
version: 1
---

Three requests in the 2026-07-28 revision: discover the server, list its tools, call one.

```json
{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

Every request carries the same `_meta`: `io.modelcontextprotocol/protocolVersion` says which revision the client speaks, and `io.modelcontextprotocol/clientCapabilities` what it can do, here nothing. That is what replaced the handshake: there is no connection-wide agreement to remember, so each request says it again.

```
ana@lab:~/agents$ python raw.py shop_mcp.py 400 < modern.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":1,"result":{"cacheScope":"private","capabilities":{"prompts":{"listChanged":true},"resources":{"listChanged":true,"subscribe":true},"tools":{"listChanged":true}},"resultType":"complete","supportedVersions":["2026-07-28"],"ttlMs":0,"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia-shop","version":""}}}}
> {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":2,"result":{"cacheScope":"private","resultType":"complete","tools":[{"description":"Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.","inputSchema":{"type":"object","properties":{"order_id":{"title":"Order Id","type":"string"}},"required":["order_id"],"title":"get_orderArguments"},"name":"get_order","outputSchema":
> {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"2026-09-28\", \"status\": \"shipped\", \"delivered_on\": null, \"shipping\": 0, \"tracking\": \"BR5512340003\", \"lines\": [{\"book_id\": \"b13\", \"quantity\": 1, \"cents\": 2490}, {\"book_id\": \"b14\", \"quantity\": 1, \"cents\": 2590}, {\"book_id\": \"b26\", \"quantity\": 1, 
```

Read the replies field by field.

- **`server/discover`** returned the server's `capabilities` (tools, resources and prompts, each able to announce changes to its list), `supportedVersions`, and the server's name in the result's `_meta` as `serverInfo`. A client that calls it first learns, before anything else, whether the two can talk.
- **Every result has `resultType: "complete"`**. Section 06 shows the other value.
- **The list results carry `ttlMs` and `cacheScope`**: how long the answer may be reused, here `0`, and whether a shared cache may keep it, here `private`. Lesson 11 noticed a client asking for the tool list before every model request; these two fields are the server's way of saying how often that is needed.
- **The tool list includes an `outputSchema`** as well as the `inputSchema`, because `get_order` is declared to return a string; lesson 14 makes it return structured data.
- **The call's result is `content`**, a list of blocks, here one text block holding the order. The same value appears again as `structuredContent` further along the line, beyond what the page shows.
