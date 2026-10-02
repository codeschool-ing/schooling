---
title: Um servidor MCP para a loja
version: 1
---

O SDK Python `mcp` transforma funções comuns em ferramentas MCP. Um decorador registra cada uma, as
dicas de tipo da função viram o esquema de entrada e a docstring vira a descrição, então o contrato da
aula 7 seção 04 é escrito uma vez só, no código:

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
      "note": "**Um servidor, com nome, que guarda as ferramentas.**"
    },
    {
      "code": "@app.tool(annotations=ToolAnnotations(readOnlyHint=True))\ndef get_order(order_id: str) -> dict:\n    \"\"\"Look up an order by its number: status, dates, lines and shipping, in cents.\"\"\"\n    orders = json.loads(Path(\"data/orders.json\").read_text())\n    if order_id not in orders:\n        raise ToolError(f\"no order {order_id}\")\n    return orders[order_id]\n\n\n",
      "note": "**Só leitura, e diz isso.** A dica de tipo `order_id: str` vira o esquema de entrada; a docstring vira a descrição que o modelo lê."
    },
    {
      "code": "@app.tool(annotations=ToolAnnotations(readOnlyHint=True))\ndef read_handbook(name: str) -> str:\n    \"\"\"Read one page of the support handbook, such as 'returns' or 'shipping'.\"\"\"\n    path = (HANDBOOK / f\"{name}.md\").resolve()\n    if path.parent != HANDBOOK:\n        raise ToolError(f\"{name!r} is not a page of the handbook\")\n    return path.read_text()\n\n\n",
      "note": "**O caminho é conferido pela ferramenta**, depois de resolvido, para `..` não sair da pasta do manual."
    },
    {
      "code": "@app.tool(annotations=ToolAnnotations(readOnlyHint=False, destructiveHint=True))\ndef issue_refund(order_id: str, cents: int) -> str:\n    \"\"\"Refund part or all of an order to the customer's original payment method.\"\"\"\n    with open(\"data/refunds.log\", \"a\") as log:\n        log.write(f\"{order_id} {cents}\\n\")\n    return f\"refunded {cents} cents on order {order_id}\"\n\n\n",
      "note": "**A única ferramenta que muda algo**, marcada como não somente leitura e destrutiva. O host da aula 7 seção 03 não a chama sem o sim de uma pessoa."
    },
    {
      "code": "if __name__ == \"__main__\":\n    app.run()",
      "note": "**Roda por stdio** quando iniciado como programa, que é como um host o lança."
    }
  ]
}
```

Os pedidos são um arquivo JSON escrito para o curso, com dois pedidos:

```json
{
  "1042": {"status": "delivered", "delivered_on": "2026-09-28",
           "lines": [{"sku": "MUG-01", "quantity": 2, "unit_price": 3990}], "shipping": 1500},
  "1043": {"status": "shipped", "shipped_on": "2026-09-30", "tracking": "BR123456789",
           "lines": [{"sku": "LAMP-02", "quantity": 1, "unit_price": 21000}], "shipping": 0}
}
```

## O que o SDK fez

Compare o código com a resposta do `tools/list` da aula 7 seção 05: `order_id: str` virou
`{"order_id": {"type": "string"}}` com `required`, a docstring virou `description`, e a anotação
virou `readOnlyHint`. **Uma mudança na função é uma mudança no contrato**, e esse é o motivo de gerar
um a partir do outro em vez de escrever o esquema à mão ao lado.

Dois detalhes são decisões, não padrões:

- **`ToolError` para uma falha com que quem chama consegue agir.** A mensagem dela chega ao modelo.
  Qualquer outra exceção é tratada como pane: o SDK registra o traceback no servidor e manda ao cliente
  só uma mensagem genérica, para um erro de banco não vazar a string de conexão no contexto de um
  modelo.
- **A checagem do caminho fica na ferramenta.** O `read_handbook` resolve o caminho e recusa qualquer
  coisa fora de `docs/handbook`, peça o modelo o que pedir. O esquema pode dizer que o argumento é uma
  string; só código pode dizer que strings são permitidas.
