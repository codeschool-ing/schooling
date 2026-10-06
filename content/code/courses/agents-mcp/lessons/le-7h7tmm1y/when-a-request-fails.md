---
title: When a request fails
version: 1
---

MCP has two ways to report a failure, and they mean different things. A **protocol error** is a JSON-RPC `error`: the request itself could not be handled. A **tool execution error** is an ordinary result with `isError: true`: the request was fine, and the tool failed. The second kind is meant for the model to read and act on.

Three calls that fail:

```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": 1043}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-9999"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_ordr", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

```
ana@lab:~/agents$ python raw.py shop_mcp.py 330 < errors.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": 1043}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"Error executing tool get_order: 1 validation error for get_orderArguments\norder_id\n  Input should be a valid string [type=string_type, input_value=1043, input_type=int]\n    For further information visit https://errors.pydantic.dev/2.13/v/string_type","type":"text"}],"isErr
> {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-9999"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":2,"result":{"content":[{"text":"Error executing tool get_order","type":"text"}],"isError":true,"resultType":"complete","_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia-shop","version":""}}}}
> {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_ordr", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"Unknown tool: get_ordr","type":"text"}],"isError":true,"resultType":"complete","_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia-shop","version":""}}}}
```

- **A wrong argument type** (`1043`, a number, where the schema says string) came back as a tool execution error whose text is the validation message: field, expected type, value given. A model can correct that.
- **A tool that raised** (`M-9999` does not exist) came back as `"Error executing tool get_order"` and nothing more. The `LookupError` and its message went to the server's log; the client got none of it. This is lesson 8's default sentence in another library, and lesson 14 fixes it on the server side.
- **A tool that does not exist** (`get_ordr`) came back as a tool execution error too. The specification lists an unknown tool among the protocol errors, answered with a JSON-RPC error of code `-32602`; this SDK version answered with `isError` instead. A client that only checks for one of the two kinds will miss the other, which is a reason to check both.

Now the envelope itself. A version the server does not support:

```
ana@lab:~/agents$ python raw.py shop_mcp.py < old-version.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "1999-01-01", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":1,"error":{"code":-32022,"message":"Unsupported protocol version","data":{"supported":["2026-07-28"],"requested":"1999-01-01"}}}
```

`-32022`, **Unsupported protocol version**, with the versions the server does support. The specification says a client should pick one of those and retry. And a request with no `_meta` at all, followed by a correct one on the same connection:

```
ana@lab:~/agents$ python raw.py shop_mcp.py 260 < no-meta.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}
< {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid request parameters","data":""}}
> {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":2,"error":{"code":-32600,"message":"this connection serves the handshake protocol era; requests carrying the 2026-07-28 envelope are not accepted on it"}}
```

The first got `-32602`, *Invalid request parameters*, with no explanation. The second, correct this time, was refused with `-32600` because **the first message had already decided what this stdio connection is**: a request with no modern envelope made it a legacy connection, and from then on the server refused modern requests on it. That is this SDK's way of being dual-era over one pipe, and the practical lesson is that the first message on a stdio connection matters more than the rest.
