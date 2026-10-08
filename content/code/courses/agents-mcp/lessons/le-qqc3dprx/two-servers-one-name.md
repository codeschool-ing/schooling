---
title: Two servers, one name
version: 1
---

Tool names are chosen by whoever writes a server, and nothing stops two servers from choosing the same one. `orders` offers `get_order` for live orders; `archive`, another team's server, also offers `get_order`, for last year's:

```python
"""Another team's server, "archive", which happens to name its tool get_order too."""
import json

from mcp.server.mcpserver import MCPServer

server = MCPServer("archive")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up an order in last year's archive."""
    return json.dumps({"id": order_id, "status": "archived", "source": "archive server"})


if __name__ == "__main__":
    server.run()
```

Each host was given both servers and asked about M-1043. `names.py` prints the tool names the host offered the model in its first request:

```python
"""The tool names the host offered its model, in the first request that offered any."""
import json
import os

lines = open("requests.jsonl").readlines() if os.path.exists("requests.jsonl") else []
offered = [r["request"]["tools"] for r in map(json.loads, lines) if r["request"].get("tools")]
if not offered:
    print("offered: no tools were sent" if lines else "offered: no request was sent")
else:
    print("offered:", ", ".join(t.get("name") or t["function"]["name"] for t in offered[0]))
```

```
ana@lab:~/agents$ python hosts.py OpenAI 'Where is my order M-1043?' orders archive 2> /dev/null; python names.py
raised UserError: Duplicate tool names found across MCP servers: 'get_order'. Pass `include_server_in_tool_names=True` to `MCPUtil.get_all_function_tools()` or set `mcp_config={'include_server_in_tool_names': True}` on the agent to prefix tool names with their server name and avoid collisions.
offered: no request was sent
ana@lab:~/agents$ python hosts.py Claude 'Where is my order M-1043?' orders archive 2> /dev/null; python names.py
Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
offered: mcp__archive__get_order, mcp__orders__get_order
ana@lab:~/agents$ python hosts.py Google 'Where is my order M-1043?' orders archive 2> /dev/null; python names.py
WARNING:root:Duplicate tool name 'get_order': the previously registered tool is shadowed and can no longer be called.
WARNING:root:Duplicate tool name 'get_order': the previously registered tool is shadowed and can no longer be called.
Order M-1043 is archived, so I cannot see where it is now.
offered: get_order, get_order
```

Three hosts, three behaviours:

- **The OpenAI host refused** to run at all: `UserError: Duplicate tool names found across MCP servers`, with the option that fixes it, `include_server_in_tool_names`. No request reached the model.
- **The Claude host renamed** both, `mcp__orders__get_order` and `mcp__archive__get_order`, so the model could tell them apart, and the course's rule chose the live one.
- **The Google host offered the model two tools with the same name**, and every call went to `archive`, the one registered last. The answer said the order was archived. The only sign was a warning in the log, *"the previously registered tool is shadowed and can no longer be called"*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two servers, orders and archive, each offer a tool named get_order. The OpenAI host refused to start the run. The Claude host renamed them mcp__orders__get_order and mcp__archive__get_order, and the model chose the live one. The Google host offered two tools both named get_order, and every call went to the archive server, with only a warning in the log.\"><defs><marker id=\"l12same-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">two servers</text><text x=\"30\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both offer get_order</text><rect x=\"250\" y=\"20\" width=\"450\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">OpenAI host: refuses</text><text x=\"260\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">UserError: Duplicate tool names</text><rect x=\"250\" y=\"85\" width=\"450\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Claude host: renames</text><text x=\"260\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mcp__orders__get_order, mcp__archive__get_order</text><rect x=\"250\" y=\"150\" width=\"450\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Google host: shadows, quietly</text><text x=\"260\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order twice; calls go to archive</text><path d=\"M170 100 L250 45\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l12same-ah-wire)\"></path><path d=\"M170 110 L250 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l12same-ah-wire)\"></path><path d=\"M170 120 L250 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l12same-ah-wire)\"></path></svg>", "caption": "One name, two servers: refuse, rename, or route to whichever came last."}
```

The third is the one to remember. The run succeeded, the customer got a confident answer, and it came from the wrong system. Nothing in MCP prevents it, because a name collision is not a protocol error: each server is correct on its own. **It is the host's job to keep tools from different servers apart**, by prefixing, by refusing, or by choosing on purpose which servers a host connects at once, and a test that connects every server a deployment uses and checks the tool list for duplicates is cheap.
