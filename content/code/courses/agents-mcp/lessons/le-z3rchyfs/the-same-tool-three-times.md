---
title: The same tool, three times
version: 2
---

Lessons 8, 9 and 10 gave three agents the same `get_order`. Each time it was written again for the library: a decorated function, an `@tool` returning MCP content, a plain function. And each library described it to its model in that provider's own format. Here is the first request each host sent in this lesson, cut down to the tool:

`wire.py` reads the recorder's log from lesson 1 and prints the first request's tools, as the host wrote them:

```python
"""For the first request in the recorder's log: which API it went to, and get_order as the host described it."""
import json
import textwrap

for line in open("requests.jsonl"):
    r = json.loads(line)
    tools = r["request"].get("tools", [])
    for t in tools:
        print(r["path"])
        print(textwrap.fill(json.dumps(t, ensure_ascii=False), 100, initial_indent="  ", subsequent_indent="  "))
    break
```

```
ana@lab:~/agents$ python hosts.py openai > /dev/null 2>&1; python wire.py
/v1/chat/completions
  {"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia
  order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.",
  "parameters": {"type": "object", "properties": {"order_id": {"title": "Order Id", "type":
  "string"}}, "required": ["order_id"], "title": "get_orderArguments"}, "strict": false}}
ana@lab:~/agents$ python hosts.py claude > /dev/null 2>&1; python wire.py
/v1/messages
  {"name": "mcp__shop__get_order", "description": "Look up one Marginalia order by its id, M- and
  four digits. Returns status, dates, lines and amounts in cents.", "input_schema": {"type":
  "object", "properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required":
  ["order_id"], "title": "get_orderArguments"}}
ana@lab:~/agents$ python hosts.py google > /dev/null 2>&1; python wire.py
/v1beta/models/scripted-1:generateContent
  {"description": "<<<BEGIN_UNTRUSTED_TOOL_DESCRIPTION>>>\nLook up one Marginalia order by its id,
  M- and four digits. Returns status, dates, lines and amounts in
  cents.\n<<<END_UNTRUSTED_TOOL_DESCRIPTION>>>", "name": "get_order", "parameters_json_schema":
  {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"],
  "type": "object", "title": "get_orderArguments"}, "response_json_schema": {"properties":
  {"result": {"title": "Result", "type": "string"}}, "required": ["result"], "type": "object",
  "title": "get_orderOutput"}}
```

Three formats for one tool. OpenAI's Chat Completions wraps it as `{"type": "function", "function": {...}}` with `parameters`; Anthropic's Messages API calls the schema `input_schema`; the Gemini API's declaration has `parameters_json_schema` and, here, a `response_json_schema` as well. The names differ (`mcp__shop__get_order` in one), and so do details such as `"strict": false`.

None of that is a problem while one team writes one agent with one library. It becomes one when a company has several assistants (an editor's, a chat app's, a support agent's) and several systems to offer them as tools (orders, the help centre, the ticket queue). Without a shared format, **every pair needs its own adapter**: three hosts and two tool providers is six pieces of glue, each maintained by somebody, each a place where a change to the tool is forgotten.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two ways to connect three hosts to two tool providers. On the left, without a shared protocol, every host needs its own adapter for every provider: six adapters. On the right, each host has one MCP client and each provider one MCP server: five pieces, and a new host or a new provider adds one.\"><defs><marker id=\"l11pairs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11pairs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each pair its own adapter</text><rect x=\"20\" y=\"40\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host A</text><rect x=\"20\" y=\"100\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host B</text><rect x=\"20\" y=\"160\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host C</text><rect x=\"250\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools X</text><rect x=\"250\" y=\"140\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools Y</text><path d=\"M120 58 L250 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 58 L250 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 118 L250 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 118 L250 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 178 L250 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 178 L250 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"390\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one protocol</text><rect x=\"390\" y=\"40\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host A</text><rect x=\"390\" y=\"100\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host B</text><rect x=\"390\" y=\"160\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host C</text><rect x=\"530\" y=\"40\" width=\"20\" height=\"156\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MCP</text><rect x=\"590\" y=\"60\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">server X</text><rect x=\"590\" y=\"140\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">server Y</text><path d=\"M490 58 L530 58\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M490 118 L530 118\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M490 178 L530 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M550 78 L590 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M550 158 L590 158\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path></svg>", "caption": "Without a protocol the work grows as hosts times tools. With one, it grows as hosts plus tools."}
```

The **Model Context Protocol** (MCP) is the shared format. A tool provider writes one **MCP server**; a host includes one **MCP client** per server it uses; the host translates whatever the server offers into its own provider's format. `ai-dev` lesson 7 introduced the three roles and typed a session by hand. This lesson and the five after it go further: what the protocol is now, how it is built, and where the trust boundaries fall.
