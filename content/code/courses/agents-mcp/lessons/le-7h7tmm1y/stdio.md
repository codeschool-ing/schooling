---
title: stdio, where standard output belongs to the protocol
version: 2
---

Over **stdio** the framing is one message per line: `raw.py` writes `json.dumps(message) + "\n"` and reads one line back for each request. Nothing else marks where a message ends. That makes standard output a channel with exactly one use: **everything the server writes there must be a protocol message**, and anything meant for a person (logs, warnings, a traceback) goes to standard error. `raw.py` keeps the server's standard error apart in `server.err`.

The usual way to break that rule is a debugging line left in a tool:

```python
"""The order server with one debugging line left in, written to standard output."""
import json

from mcp.server.mcpserver import MCPServer

import shop

server = MCPServer("noisy")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up one Marginalia order by its id."""
    print("looking up", order_id, flush=True)  # meant for the developer, not for the client
    return json.dumps(shop.get_order(order_id))


if __name__ == "__main__":
    server.run()
```

The two messages, `noisy.jsonl`:

```json
{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

```
ana@lab:~/agents$ python raw.py noisy_mcp.py 120 < noisy.jsonl; cat server.err
> {"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion":
< {"jsonrpc":"2.0","id":1,"result":{"cacheScope":"private","capabilities":{"prompts":{"listChanged":true},"resources":{"li
> {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"},
< {"jsonrpc":"2.0","id":2,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"
looking up M-1043
```

Both replies arrived intact, and `looking up M-1043` is in `server.err`, not in the stream. The `mcp` SDK's stdio transport takes the real standard output for itself when it starts and points the process's `print()` at standard error, so a stray line cannot reach the client. A server written without that protection, by hand or with a library that does not do it, would have sent `looking up M-1043` down the pipe as the reply's first line, and the client would have read a line that is not JSON where it expected an answer.

Two more consequences of the transport show in the earlier captures. The host owns the server's lifetime: `raw.py` closed the server's standard input and the server exited. And the server's standard error goes wherever the host sends it: `raw.py` writes it to a file, and lessons 11 and 12 dropped the hosts' standard error, and the servers' with it, with `2> /dev/null`. **A local server's logs are only as visible as its host makes them**, which matters on the day a tool fails with `"Error executing tool get_order"` and the reason is in that log.
