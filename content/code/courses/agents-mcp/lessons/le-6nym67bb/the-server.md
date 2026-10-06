---
title: The server
version: 1
---

`ai-dev` lesson 7 section 06 built a first server: functions become tools through a decorator, type hints become the input schema, docstrings become descriptions, `readOnlyHint` marks a tool that changes nothing, and `ToolError` carries a message the model may see. This lesson starts from there and builds the server the rest of this course uses, with all three primitives and the decisions that make it safe to connect.

```schooling-example
{
  "language": "python",
  "file": "marginalia_mcp.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's MCP server: two tools, the help centre as resources, and one prompt.\"\"\"\nimport json\nfrom typing import Annotated\n\nfrom mcp.server.mcpserver import MCPServer\nfrom mcp.server.mcpserver.exceptions import ResourceNotFoundError, ToolError\nfrom mcp.types import ToolAnnotations\nfrom pydantic import BaseModel, Field\n\nimport shop\n\n"
    },
    {
      "code": "server = MCPServer(\"marginalia\", version=\"1.0.0\",\n                   instructions=\"Tools and documents for answering Marginalia's customers about orders and the help centre.\")\n",
      "note": "**A name, a version and instructions.** The instructions are returned by `server/discover`, for a host to show or to give the model as a description of the whole server."
    },
    {
      "code": "HELP = {a[\"id\"]: a for a in map(json.loads, open(\"data/help.jsonl\"))}\n\n",
      "note": "**The help centre's forty articles**, the same `help.jsonl` the course's lab copies from `embeddings-vectors`."
    },
    {
      "code": "OrderId = Annotated[str, Field(pattern=r\"^M-[0-9]{4}$\", description=\"M- and four digits, such as M-1043\")]\n\n\nclass Line(BaseModel):\n    book_id: str\n    quantity: int\n    cents: int\n\n\n",
      "note": "**The id's rule, written once**: a pattern and a description. Section 03."
    },
    {
      "code": "class Order(BaseModel):\n    id: str\n    status: str\n    placed_on: str\n    delivered_on: str | None\n    tracking: str | None\n    lines: list[Line]\n    total: int\n    refunded: int\n\n\n@server.tool(annotations=ToolAnnotations(readOnlyHint=True))\n",
      "note": "**What the tool returns, as a type.** Its fields are the output schema, and the only fields that leave the server. Section 04."
    },
    {
      "code": "def get_order(order_id: OrderId) -> Order:\n    \"\"\"Look up one Marginalia order: status, dates, tracking, lines and amounts in cents.\"\"\"\n    try:\n        found = shop.get_order(order_id)\n    except LookupError as e:\n",
      "note": "**Read-only, checked on the way in, typed on the way out.**"
    },
    {
      "code": "        raise ToolError(f\"{e}; check the number on the confirmation email\") from e\n    return Order.model_validate(found)\n\n\nclass Hit(BaseModel):\n    title: str\n    uri: str\n\n\n@server.tool(annotations=ToolAnnotations(readOnlyHint=True))\n",
      "note": "**An expected failure, with a message the model can act on.** Section 05."
    },
    {
      "code": "def search_help(query: str) -> list[Hit]:\n    \"\"\"Search Marginalia's help centre by meaning. Returns titles and the URI of each article to read.\"\"\"\n    return [Hit(title=a[\"title\"], uri=f\"help://{a['id']}\") for a in shop.search_help(query)]\n\n\n",
      "note": "**Search returns where to read, not the articles themselves**: a title and a URI each."
    },
    {
      "code": "@server.resource(\"help://{article_id}\", mime_type=\"text/markdown\")\ndef help_article(article_id: str) -> str:\n    \"\"\"One article of Marginalia's help centre.\"\"\"\n    if article_id not in HELP:\n",
      "note": "**A resource template**: every article is addressable as `help://h01` to `help://h40`. Section 06."
    },
    {
      "code": "        raise ResourceNotFoundError(f\"no help article {article_id}\")\n    a = HELP[article_id]\n    return f\"# {a['title']}\\n\\n{a['body']}\\n\\n(updated {a['updated']})\"\n\n\n",
      "note": "**An unknown article is an error with its reason**, not an empty page."
    },
    {
      "code": "@server.prompt()\ndef reply_to_customer(order_id: str, question: str) -> str:\n    \"\"\"Draft a reply to a customer's question about one order.\"\"\"\n    return (f\"A customer asks about order {order_id}: {question}\\n\"\n            \"Look the order up with get_order, check the help centre if a policy applies, \"\n            \"and draft a short reply. Quote dates and amounts exactly as the tools return them.\")\n\n\nif __name__ == \"__main__\":\n    server.run()",
      "note": "**A prompt**: a template a person picks, with two arguments. Section 07."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The three primitives in Marginalia&#x27;s server, and who uses each. The model asks for the tools get_order and search_help, and the host allows or refuses. The host reads the resources help://h01 to help://h40 and decides what to put in the model&#x27;s context. A person picks the prompt reply_to_customer and fills in its arguments.\"><defs><marker id=\"l14prim-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools</text><text x=\"30\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order, search_help</text><rect x=\"20\" y=\"85\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resources</text><text x=\"30\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">help://{article_id}</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">prompts</text><text x=\"30\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reply_to_customer</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the model asks</text><text x=\"490\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the host allows or refuses</text><rect x=\"480\" y=\"85\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the host reads</text><text x=\"490\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and chooses what the model sees</text><rect x=\"480\" y=\"150\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a person picks</text><text x=\"490\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and fills in the arguments</text><path d=\"M480 45 L220 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14prim-ah-amber)\"></path><path d=\"M480 110 L220 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14prim-ah-amber)\"></path><path d=\"M480 175 L220 175\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14prim-ah-amber)\"></path></svg>", "caption": "Three primitives, three different people deciding."}
```

It runs like any other: started as a program it speaks stdio, and the first thing a client can ask is what it is.

```
ana@lab:~/agents$ printf '%s\n' '{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}' | python marginalia_mcp.py 2> /dev/null
{"jsonrpc":"2.0","id":1,"result":{"cacheScope":"private","capabilities":{"prompts":{"listChanged":true},"resources":{"listChanged":true,"subscribe":true},"tools":{"listChanged":true}},"instructions":"Tools and documents for answering Marginalia's customers about orders and the help centre.","resultType":"complete","supportedVersions":["2026-07-28"],"ttlMs":0,"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia","version":"1.0.0"}}}}
```

The `instructions` are in the reply, after the capabilities. Everything else in this lesson talks to the server through `try_server.py`, which uses the `mcp` SDK's client **in the same process**: `Client(server)` given the server object itself connects without starting a subprocess, which is also how section 08 tests it.

```python
"""Talk to marginalia_mcp's server in-process, the way a test would, and print what comes back."""
import asyncio
import json
import sys

from mcp import Client

from marginalia_mcp import server


async def main(what):
    async with Client(server) as client:  # an MCPServer object: connected in-process, no subprocess
        if what == "schema":
            for tool in (await client.list_tools()).tools:
                print(tool.name)
                print("  input: ", json.dumps(tool.input_schema["properties"]))
                print("  output:", json.dumps(sorted(tool.output_schema["properties"]))
                      if "properties" in tool.output_schema else json.dumps(tool.output_schema)[:110])
                print("  hints: ", tool.annotations.model_dump(exclude_none=True))
        if what == "calls":
            for order_id in ("M-1043", "M-9999", "1043"):
                result = await client.call_tool("get_order", {"order_id": order_id})
                print(f"{order_id}: isError={result.is_error}")
                if result.structured_content:
                    print("  structured:", json.dumps(result.structured_content)[:150])
                else:
                    print("  text:", result.content[0].text.replace("\n", " ")[:150])
        if what == "resources":
            for t in (await client.list_resource_templates()).resource_templates:
                print("template:", t.uri_template, t.mime_type)
            hits = await client.call_tool("search_help", {"query": "send a book back"})
            print("search_help:", json.dumps(hits.structured_content)[:160])
            for uri in ("help://h14", "help://h99"):
                try:
                    print(uri, "->", (await client.read_resource(uri)).contents[0].text.replace("\n", " ")[:120])
                except Exception as e:
                    print(uri, "->", type(e).__name__, e)
        if what == "prompt":
            for p in (await client.list_prompts()).prompts:
                print("prompt:", p.name, [(a.name, a.required) for a in p.arguments])
            got = await client.get_prompt("reply_to_customer", {"order_id": "M-1042", "question": "Can I still return it?"})
            for m in got.messages:
                print(f"{m.role}: {m.content.text}")


asyncio.run(main(sys.argv[1]))
```
