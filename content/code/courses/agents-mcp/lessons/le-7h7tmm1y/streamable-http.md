---
title: Streamable HTTP
version: 1
---

The same `server` object can listen on HTTP instead. `shop_http.py` binds it to `127.0.0.1`, port 8700, so only this machine can reach it:

```python
"""The same server over Streamable HTTP, listening on this machine only."""
from shop_mcp import server

server.run("streamable-http", host="127.0.0.1", port=8700)
```

`post.sh` sends one request with `curl`, with the headers the 2026-07-28 revision requires on every POST:

```bash
# post.sh METHOD NAME BODY: one MCP request over HTTP, with the headers the 2026-07-28 revision requires.
curl -s -i --noproxy 127.0.0.1 http://127.0.0.1:8700/mcp \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: $1" ${2:+-H "Mcp-Name: $2"} ${ORIGIN:+-H "Origin: $ORIGIN"} \
  -d "$3" | grep -v '^date:'
```

```
ana@lab:~/agents$ bash post.sh tools/call get_order '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}' | cut -c1-200
HTTP/1.1 200 OK
server: uvicorn
content-length: 1032
content-type: application/json

{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"2026-09-28\", \"status\": \"shipped\", \"delivered_on\": null, \"shipping\": 0, 
ana@lab:~/agents$ bash post.sh tools/call '' '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'
HTTP/1.1 400 Bad Request
server: uvicorn
content-length: 127
content-type: application/json

{"jsonrpc":"2.0","id":1,"error":{"code":-32020,"message":"mcp-name header does not match the request body's 'name' parameter"}}
ana@lab:~/agents$ bash post.sh tools/list get_order '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'
HTTP/1.1 400 Bad Request
server: uvicorn
content-length: 119
content-type: application/json

{"jsonrpc":"2.0","id":1,"error":{"code":-32020,"message":"mcp-method header does not match the request body's method"}}
ana@lab:~/agents$ ORIGIN=http://elsewhere.example bash post.sh tools/call get_order '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'
HTTP/1.1 403 Forbidden
server: uvicorn
content-length: 21

Invalid Origin header
```

The first request worked: `200 OK`, `content-type: application/json`, and the same result section 03 got over stdio. The headers are where HTTP adds something.

- **`MCP-Protocol-Version`** repeats the version from the body's `_meta`.
- **`Mcp-Method`** and **`Mcp-Name`** repeat the body's `method` and the tool's `name`. The specification gives the reason: so that load balancers, gateways and monitoring can route and inspect requests **without parsing the body**. A gateway can then refuse calls to one tool, or count them, from the headers alone.
- **The server checks that the headers match the body.** With `Mcp-Name` missing, and again with `Mcp-Method: tools/list` on a `tools/call` body, the server answered `400 Bad Request` with error `-32020`, a header mismatch. If it did not, a gateway's decision based on the header could be bypassed by a body that says something else.
- **`Origin` is checked.** A request claiming to come from a web page at `http://elsewhere.example` got `403 Forbidden`. The specification requires it, against **DNS rebinding**: a web page in the person's browser that tries to reach a server listening on their own machine. The other half of that defence is in `shop_http.py`: a local server should listen on `127.0.0.1`, not on every interface.

What this server does not do yet is check **who** is asking. Anyone on this machine could have sent those requests. Lesson 16 moves the server into its own network namespace with TLS and a bearer token, and reads the authorisation metadata the specification defines for a remote server.
