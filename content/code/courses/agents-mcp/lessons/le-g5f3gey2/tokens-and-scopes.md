---
title: Tokens and scopes
version: 1
---

`call.sh` sends one `tools/call` with a named token, the headers of lesson 13 and the lab's CA:

```bash
# call.sh TOKEN-NAME TOOL ARGUMENTS: one tools/call to the remote server, by hand, with curl.
curl -s --cacert /opt/agents/share/marginalia-ca.crt https://mcp.marginalia.test:8443/mcp \
  -H "Authorization: Bearer $(cat tokens/$1)" \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: tools/call" -H "Mcp-Name: $2" \
  -d "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/call\", \"params\": {\"name\": \"$2\", \"arguments\": $3,
       \"_meta\": {\"io.modelcontextprotocol/protocolVersion\": \"2026-07-28\", \"io.modelcontextprotocol/clientCapabilities\": {}}}}" \
  -w "  [HTTP %{http_code}]\n"
```

Four tokens, five calls:

```
ana@lab:~/agents$ bash call.sh support get_order '{"order_id": "M-1043"}' | cut -c1-170
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"status\": \"shipped\", \"placed_on\": \"2026-09-28\", \"delivered_on\": null, \"tracking\": \
ana@lab:~/agents$ bash call.sh support refund '{"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}' | cut -c1-170
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"Error executing tool refund: the token of support-agent does not carry orders:refund","type":"text"}],"isError":true
ana@lab:~/agents$ bash call.sh refunds refund '{"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}' | cut -c1-170
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}","type":"text"}],"isError":false,"resultType":"comple
ana@lab:~/agents$ bash call.sh billing get_order '{"order_id": "M-1043"}'
{"error": "invalid_token", "error_description": "Authentication required"}  [HTTP 401]
ana@lab:~/agents$ bash call.sh expired get_order '{"order_id": "M-1043"}'
{"error": "invalid_token", "error_description": "Authentication required"}  [HTTP 401]
```

- **`support`**, scope `orders:read`, read the order. Only the fields of the allow list came back.
- **`support` again, asking for a refund**, got a tool error: *"the token of support-agent does not carry orders:refund"*. The token was valid; the tool refused because its scope was too narrow.
- **`refunds`**, with `orders:read` and `orders:refund`, refunded 3890 cents, on the second machine's own copy of the shop.
- **`billing`**, valid and unexpired but **issued for `https://billing.marginalia.test/mcp`**, got `401`. This is the specification's **audience rule**: an MCP server must accept only tokens issued for it. Without it, a token ana's client obtained for one service would work at any other service that trusted the same authorization server, and a malicious server that received a token could replay it somewhere else.
- **`expired`** got `401` too, with the same body. A client cannot tell from the answer which check failed, and that is deliberate: the server gives nobody a way to probe which tokens exist.

One point where this server and the specification part ways. For a valid token with **too narrow a scope**, the specification recommends `403 Forbidden` with a `WWW-Authenticate` header naming the scope needed, so a client can go back and ask for it. Here the refusal is a tool error inside a `200`: a model can read it, but a client cannot act on it automatically. The SDK's resource-server mode checks one set of required scopes for the whole server; a scope per tool is checked in the tool, as here, and reporting it the way the specification recommends would take more code than this lesson's server has.

The design point stands either way: **give each client the narrowest token that does its job**. The support agent reads; only the refunds desk refunds. If the support agent's token leaks, or its model is talked into trying a refund (lesson 17), the server says no.
