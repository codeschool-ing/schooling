---
title: An MCP server for the shop
version: 1
---

The `mcp` Python SDK turns ordinary functions into MCP tools. A decorator registers each one, the
function's type hints become the input schema, and its docstring becomes the description, so the
contract of lesson 7 section 04 is written once, in the code:

```schooling-example
{
  "language": "python",
  "file": "mcp_shop.py",
  "parts": [
    {
      "code": "\"\"\"An MCP server that gives a model three tools over the shop: two that read, one that pays.\"\"\"\nimport json\nfrom pathlib import Path\n\nfrom mcp.server.mcpserver import MCPServer\nfrom mcp.server.mcpserver.exceptions import ToolError\nfrom mcp.types import ToolAnnotations\n\n"
    },
    {
      "code": "HANDBOOK = Path(\"docs/handbook\").resolve()\napp = MCPServer(\"shop\")\n\n\n",
      "note": "**One server, named, holding the tools.**"
    },
    {
      "code": "@app.tool(annotations=ToolAnnotations(readOnlyHint=True))\ndef get_order(order_id: str) -> dict:\n    \"\"\"Look up an order by its number: status, dates, lines and shipping, in cents.\"\"\"\n    orders = json.loads(Path(\"data/orders.json\").read_text())\n    if order_id not in orders:\n        raise ToolError(f\"no order {order_id}\")\n    return orders[order_id]\n\n\n",
      "note": "**Read-only, and it says so.** The type hint `order_id: str` becomes the input schema; the docstring becomes the description the model reads."
    },
    {
      "code": "@app.tool(annotations=ToolAnnotations(readOnlyHint=True))\ndef read_handbook(name: str) -> str:\n    \"\"\"Read one page of the support handbook, such as 'returns' or 'shipping'.\"\"\"\n    path = (HANDBOOK / f\"{name}.md\").resolve()\n    if path.parent != HANDBOOK:\n        raise ToolError(f\"{name!r} is not a page of the handbook\")\n    return path.read_text()\n\n\n",
      "note": "**The path is checked by the tool**, after resolving it, so `..` cannot leave the handbook's folder."
    },
    {
      "code": "@app.tool(annotations=ToolAnnotations(readOnlyHint=False, destructiveHint=True))\ndef issue_refund(order_id: str, cents: int) -> str:\n    \"\"\"Refund part or all of an order to the customer's original payment method.\"\"\"\n    with open(\"data/refunds.log\", \"a\") as log:\n        log.write(f\"{order_id} {cents}\\n\")\n    return f\"refunded {cents} cents on order {order_id}\"\n\n\n",
      "note": "**The one tool that changes something**, marked not read-only and destructive. The host of lesson 7 section 03 will not call it without a person's yes."
    },
    {
      "code": "if __name__ == \"__main__\":\n    app.run()",
      "note": "**Run over stdio** when started as a program, which is how a host launches it."
    }
  ]
}
```

The orders are a JSON file written for the course, holding two orders:

```json
{
  "1042": {"status": "delivered", "delivered_on": "2026-09-28",
           "lines": [{"sku": "MUG-01", "quantity": 2, "unit_price": 3990}], "shipping": 1500},
  "1043": {"status": "shipped", "shipped_on": "2026-09-30", "tracking": "BR123456789",
           "lines": [{"sku": "LAMP-02", "quantity": 1, "unit_price": 21000}], "shipping": 0}
}
```

## What the SDK did

Compare the code with the `tools/list` reply of lesson 7 section 05: `order_id: str` became
`{"order_id": {"type": "string"}}` with `required`, the docstring became `description`, and the
annotation became `readOnlyHint`. **A change to the function is a change to the contract**, which is
the reason to generate one from the other rather than writing the schema by hand next to it.

Two details are decisions rather than defaults:

- **`ToolError` for a failure the caller can act on.** Its message reaches the model. Any other
  exception is treated as a crash: the SDK logs the traceback on the server and sends the client only a
  generic message, so a database error does not leak its connection string into a model's context.
- **The path check is in the tool.** `read_handbook` resolves the path and refuses anything outside
  `docs/handbook`, whatever the model asks for. The schema can say the argument is a string; only code
  can say which strings are allowed.
