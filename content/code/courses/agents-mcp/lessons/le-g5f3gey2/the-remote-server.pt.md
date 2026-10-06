---
title: O servidor remoto
version: 1
---

O servidor que a ana implantou é a ideia da aula 14 com três acréscimos: TLS, uma checagem de token, e um escopo por ferramenta.

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
      "note": "**A URL canônica do servidor**, que é também o recurso que todo token tem de nomear."
    },
    {
      "code": "class TokenTable:\n    \"\"\"Checks a bearer token against the table the authorization server keeps (the lab writes it).\"\"\"\n\n    async def verify_token(self, token: str) -> AccessToken | None:\n        entry = json.load(open(\"tokens.json\")).get(hashlib.sha256(token.encode()).hexdigest())\n",
      "note": "**Como um token é conferido.** Uma implantação de verdade verifica um token assinado ou pergunta sobre ele ao servidor de autorização; aqui o laboratório faz o papel do servidor de autorização e guarda uma tabela do que cada token concede, com o SHA-256 do token como chave, para a tabela não guardar token nenhum."
    },
    {
      "code": "        if entry is None or entry[\"expires_at\"] < time.time():\n            return None\n",
      "note": "**Desconhecido ou vencido: sem acesso.** Devolver `None` faz o SDK responder 401."
    },
    {
      "code": "        return AccessToken(token=token, client_id=entry[\"client_id\"], scopes=entry[\"scopes\"],\n                           expires_at=entry[\"expires_at\"], resource=entry[\"resource\"])\n\n\n",
      "note": "**O que o token concede**: o cliente para quem foi emitido, os escopos, o vencimento, e o recurso para o qual foi emitido."
    },
    {
      "code": "server = MCPServer(\n    \"marginalia-remote\", version=\"1.0.0\", token_verifier=TokenTable(),\n",
      "note": "**O modo de servidor de recurso do SDK**: um verificador de token e o `AuthSettings`."
    },
    {
      "code": "    auth=AuthSettings(issuer_url=\"https://auth.marginalia.test:9443\", resource_server_url=URL,\n                      required_scopes=[\"orders:read\"], validate_token_resource=True))\n\n\n@server.tool()\ndef get_order(order_id: str) -> str:\n    \"\"\"Look up one Marginalia order by its id, M- and four digits.\"\"\"\n    try:\n        found = shop.get_order(order_id)\n    except LookupError as e:\n        raise ToolError(str(e)) from e\n",
      "note": "**Quem emite tokens, que URL este servidor é, o escopo que todo pedido precisa**, e `validate_token_resource=True`: recusar um token emitido para qualquer outro recurso. Essa última flag é a regra de audiência da especificação, seção 06."
    },
    {
      "code": "    return json.dumps({k: found[k] for k in (\"id\", \"status\", \"placed_on\", \"delivered_on\", \"tracking\", \"total\")})\n\n\n@server.tool()\ndef refund(order_id: str, cents: int, reason: str) -> str:\n    \"\"\"Refund part or all of an order, in cents. Needs the orders:refund scope.\"\"\"\n",
      "note": "**A lista de permitidos da aula 14**, escrita direto: nenhum `customer_id` sai deste servidor também."
    },
    {
      "code": "    token = get_access_token()\n    if \"orders:refund\" not in token.scopes:\n        raise ToolError(f\"the token of {token.client_id} does not carry orders:refund\")\n    return json.dumps(shop.refund(order_id, cents, reason, approved_by=token.client_id))\n\n\n",
      "note": "**Um segundo escopo, conferido na ferramenta**: ler precisa de `orders:read`, reembolsar precisa também de `orders:refund`."
    },
    {
      "code": "app = server.streamable_http_app(transport_security=TransportSecuritySettings(\n    allowed_hosts=[\"mcp.marginalia.test:8443\"], allowed_origins=[]))\n\nif __name__ == \"__main__\":\n",
      "note": "**A aplicação HTTP, com as proteções da aula 13**: só pedidos endereçados a `mcp.marginalia.test:8443` são servidos, e nenhuma origem de navegador é permitida."
    },
    {
      "code": "    uvicorn.run(app, host=\"203.0.113.10\", port=8443, ssl_certfile=\"tls/server.crt\", ssl_keyfile=\"tls/server.key\",\n                log_level=\"warning\")",
      "note": "**TLS, só no endereço da segunda máquina.**"
    }
  ]
}
```

Duas coisas valem nota no que não está lá. O servidor nunca pergunta quem é a pessoa: o token diz para que **cliente** ele foi emitido (`support-agent`, `refunds-desk`), e essa é a identidade que o reembolso registra como `approved_by`. E o servidor não guarda segredo nenhum que o deixe chamar outra coisa em nome do cliente: ele confere tokens, não os repassa.
