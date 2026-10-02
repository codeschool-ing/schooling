---
title: The Model Context Protocol
version: 1
---

Every assistant and every agent needs tools, and every company has systems to offer as tools. Without
a standard, each pair needs its own glue: the editor's way of describing a tool, the chat app's way,
the agent framework's way. **The Model Context Protocol (MCP) is that standard**: a server offers
tools (and documents, and prompt templates) in one format, and any host that speaks MCP can use them.
It was published by Anthropic in 2024 and is now implemented by assistants and SDKs from many
vendors.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"MCP&#x27;s three roles. A host, such as an editor or this lesson&#x27;s agent, holds the model connection and one client per server. Each client talks JSON-RPC to one server, over stdio for a local program or Streamable HTTP for a remote one. The servers offer tools, and know nothing about the model.\"><defs><marker id=\"mc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"150\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">host · editor, chat app, agent</text><rect x=\"40\" y=\"56\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">model connection</text><rect x=\"40\" y=\"120\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><rect x=\"40\" y=\"176\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><rect x=\"430\" y=\"112\" width=\"270\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">MCP server: shop</text><text x=\"565.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get_order, read_handbook, issue_refund</text><rect x=\"430\" y=\"176\" width=\"270\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">MCP server: tickets</text><text x=\"565.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(another team&#x27;s)</text><path d=\"M262 140 L426 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah)\"></path><text x=\"344\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON-RPC over stdio</text><path d=\"M262 196 L426 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah)\"></path><text x=\"344\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON-RPC over HTTP</text></svg>", "caption": "One host, one client per server. A server is a program that answers requests, and the host decides what the model may ask of it."}
```

## The three roles

- **The host** is the application the person uses: an editor, a chat app, the agent of lesson 7
  section 03. It holds the model connection and decides what runs.
- **The client** is the part of the host that talks to one server. A host with three servers has
  three clients.
- **The server** offers the tools. It knows nothing about models; it answers requests.

## On the wire

MCP messages are **JSON-RPC 2.0**: each request has an `id`, a `method` and `params`, and each reply
carries the same `id`. Over the **stdio** transport, the host starts the server as a child process
and they exchange one JSON message per line on its standard input and output. The other transport is
**Streamable HTTP**, for a server running somewhere else.

Nothing hides it, so here is a session typed by hand: initialise, a notification that the client is
ready, list the tools, call one. The replies are cut to the width of the page:

```
ana@dev:~/shop$ ( printf "%s\n" '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"by-hand","version":"0"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_order","arguments":{"order_id":"1043"}}}'; sleep 2 ) | python mcp_shop.py | cut -c1-160
{"jsonrpc":"2.0","id":1,"result":{"capabilities":{"experimental":{},"prompts":{"listChanged":false},"resources":{"listChanged":false,"subscribe":false},"tools":
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"annotations":{"readOnlyHint":true},"description":"Look up an order by its number: status, dates, lines and shipping
{"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"{\n  \"status\": \"shipped\",\n  \"shipped_on\": \"2026-09-30\",\n  \"tracking\": \"BR123456789\",\n  \"li
```

- **`initialize`** agrees a protocol version and says what each side supports. The server answers
  that it has tools, prompts and resources.
- **`tools/list`** returns every tool with its description and its input schema, the contract of
  lesson 7 section 04.
- **`tools/call`** runs one, by name, with arguments. The result is a list of content blocks, here one
  block of text holding order 1043.

That is the whole mechanism an assistant uses when you install an MCP server in it. **The server runs
on your machine with your permissions**, which is why lesson 7 section 08 matters: installing an MCP
server is installing a program, and everything it can reach, the model can ask it for.
