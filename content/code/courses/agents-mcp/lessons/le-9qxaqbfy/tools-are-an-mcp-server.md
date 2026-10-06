---
title: Tools are an MCP server
version: 1
---

The Claude Agent SDK has no tool decorator of its own in the sense of lessons 7 and 8. A tool is declared with `@tool` and placed in an **MCP server** that runs inside your process:

```schooling-example
{
  "language": "python",
  "file": "cs_tools.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's tools for the Claude Agent SDK: an MCP server that runs inside this process.\"\"\"\nimport json\n\nfrom claude_agent_sdk import create_sdk_mcp_server, tool\n\nimport shop\n\n\n"
    },
    {
      "code": "def text(value):\n    return {\"content\": [{\"type\": \"text\", \"text\": json.dumps(value, ensure_ascii=False)}]}\n\n\n",
      "note": "**A tool returns MCP content**: a list of blocks, here one text block holding JSON. Lesson 8's `str()` problem does not arise, because the tool writes the text itself."
    },
    {
      "code": "@tool(\"get_order\", \"Look up one Marginalia order by its id, M- and four digits. \"\n      \"Returns status, dates, lines and amounts in cents.\", {\"order_id\": str})\n",
      "note": "**Name, description and a schema.** `{\"order_id\": str}` is the short form: one required string property. A full JSON Schema dictionary is also accepted, which is where a `pattern` would go."
    },
    {
      "code": "async def get_order(args):\n    return text(shop.get_order(args[\"order_id\"]))\n\n\n@tool(\"search_help\", \"Search Marginalia's help centre by meaning and return the three closest articles.\",\n      {\"query\": str})\nasync def search_help(args):\n    return text([{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])])\n\n\n@tool(\"refund\", \"Refund part or all of an order to the customer's original payment, in cents.\",\n      {\"order_id\": str, \"cents\": int, \"reason\": str})\nasync def refund(args):\n    return text(shop.refund(args[\"order_id\"], args[\"cents\"], args[\"reason\"], approved_by=\"ana\"))\n\n\n",
      "note": "**The handler receives the arguments as a dictionary** and is async, because the call arrives over the pipe from the subprocess."
    },
    {
      "code": "shop_server = create_sdk_mcp_server(\"shop\", version=\"1.0.0\", tools=[get_order, search_help, refund])",
      "note": "**The three tools become one server**, named `shop`, version 1.0.0."
    }
  ]
}
```

**MCP** is the Model Context Protocol, the subject of lessons 11 to 16: a standard way for an agent to discover and call tools that somebody else provides. Here the server is in-process, so nothing crosses a network; the CLI asks the SDK for the tool list and sends each call back over the same pipe, and the SDK runs the handler.

The name the model sees is built from both: `mcp__shop__get_order`, the prefix `mcp`, the server's name and the tool's name, joined by double underscores. That full name is what appears in the stream, in the permission lists of section 06 and in the hooks of section 08. A server from somewhere else, a process on this machine or a service across the network, is added to `mcp_servers` the same way, and its tools get the same kind of name. The agent does not care where a tool runs; the person deciding which tools it may call should.
