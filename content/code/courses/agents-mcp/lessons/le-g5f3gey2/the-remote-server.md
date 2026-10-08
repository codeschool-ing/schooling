---
title: The remote server
version: 1
---

The server ana deployed is lesson 14's idea with three additions: TLS, a token check, and a scope per tool.

```schooling-example
{
  "language": "python",
  "file": "remote_mcp.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's MCP server as a remote service: TLS, bearer tokens, and a scope per tool.\"\"\"\nimport hashlib\nimport json\nimport time\n\nimport uvicorn\nfrom mcp.server.auth.middleware.auth_context import get_access_token\nfrom mcp.server.auth.provider import AccessToken\nfrom mcp.server.auth.settings import AuthSettings\nfrom mcp.server.mcpserver import MCPServer\nfrom mcp.server.mcpserver.exceptions import ToolError\nfrom mcp.server.transport_security import TransportSecuritySettings\n\nimport shop\n\n"
    },
    {
      "code": "URL = \"https://mcp.marginalia.test:8443/mcp\"\n\n\n",
      "note": "**The server's canonical URL**, which is also the resource every token must name."
    },
    {
      "code": "class TokenTable:\n    \"\"\"Checks a bearer token against the table the authorization server keeps (second_machine.sh writes it).\"\"\"\n\n    async def verify_token(self, token: str) -> AccessToken | None:\n        entry = json.load(open(\"tokens.json\")).get(hashlib.sha256(token.encode()).hexdigest())\n",
      "note": "**How a token is checked.** A real deployment verifies a signed token or asks the authorization server about it; here the lab plays the authorization server and keeps a table of what each token grants, keyed by the token's SHA-256 so the table holds no token itself."
    },
    {
      "code": "        if entry is None or entry[\"expires_at\"] < time.time():\n            return None\n",
      "note": "**Unknown or expired: no access.** Returning `None` makes the SDK answer 401."
    },
    {
      "code": "        return AccessToken(token=token, client_id=entry[\"client_id\"], scopes=entry[\"scopes\"],\n                           expires_at=entry[\"expires_at\"], resource=entry[\"resource\"])\n\n\n",
      "note": "**What the token grants**: the client it was issued to, its scopes, its expiry, and the resource it was issued for."
    },
    {
      "code": "server = MCPServer(\n    \"marginalia-remote\", version=\"1.0.0\", token_verifier=TokenTable(),\n",
      "note": "**The SDK's resource-server mode**: a token verifier and `AuthSettings`."
    },
    {
      "code": "    auth=AuthSettings(issuer_url=\"https://auth.marginalia.test:9443\", resource_server_url=URL,\n                      required_scopes=[\"orders:read\"], validate_token_resource=True))\n\n\n@server.tool()\ndef get_order(order_id: str) -> str:\n    \"\"\"Look up one Marginalia order by its id, M- and four digits.\"\"\"\n    try:\n        found = shop.get_order(order_id)\n    except LookupError as e:\n        raise ToolError(str(e)) from e\n",
      "note": "**Who issues tokens, which URL this server is, the scope every request needs**, and `validate_token_resource=True`: refuse a token issued for any other resource. That last flag is the specification's audience rule, section 06."
    },
    {
      "code": "    return json.dumps({k: found[k] for k in (\"id\", \"status\", \"placed_on\", \"delivered_on\", \"tracking\", \"total\")})\n\n\n@server.tool()\ndef refund(order_id: str, cents: int, reason: str) -> str:\n    \"\"\"Refund part or all of an order, in cents. Needs the orders:refund scope.\"\"\"\n",
      "note": "**Lesson 14's allow list**, written inline: no `customer_id` leaves this server either."
    },
    {
      "code": "    token = get_access_token()\n    if \"orders:refund\" not in token.scopes:\n        raise ToolError(f\"the token of {token.client_id} does not carry orders:refund\")\n    return json.dumps(shop.refund(order_id, cents, reason, approved_by=token.client_id))\n\n\n",
      "note": "**A second scope, checked in the tool**: reading needs `orders:read`, refunding also needs `orders:refund`."
    },
    {
      "code": "app = server.streamable_http_app(transport_security=TransportSecuritySettings(\n    allowed_hosts=[\"mcp.marginalia.test:8443\"], allowed_origins=[]))\n\nif __name__ == \"__main__\":\n",
      "note": "**The HTTP application, with lesson 13's protections**: only requests addressed to `mcp.marginalia.test:8443` are served, and no browser origin is allowed."
    },
    {
      "code": "    uvicorn.run(app, host=\"203.0.113.10\", port=8443, ssl_certfile=\"tls/server.crt\", ssl_keyfile=\"tls/server.key\",\n                log_level=\"warning\")",
      "note": "**TLS, on the second machine's address only.**"
    }
  ]
}
```

Two things are worth noticing in what is not there. The server never asks who the person is: the token says which **client** it was issued to (`support-agent`, `refunds-desk`), and that is the identity the refund records as `approved_by`. And the server holds no secret that would let it call anything else on the client's behalf: it checks tokens, it does not forward them.
