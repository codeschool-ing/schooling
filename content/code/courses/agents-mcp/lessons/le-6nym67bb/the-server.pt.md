---
title: O servidor
version: 2
---

A seção 06 da aula 7 de `ai-dev` construiu um primeiro servidor: funções viram ferramentas por um decorador, anotações de tipo viram o esquema de entrada, docstrings viram descrições, o `readOnlyHint` marca uma ferramenta que não muda nada, e o `ToolError` leva uma mensagem que o modelo pode ver. Esta aula parte daí e constrói o servidor que o resto do curso usa, com as três primitivas e as decisões que tornam seguro conectá-lo.

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
      "note": "**Um nome, uma versão e instruções.** As instruções voltam no `server/discover`, para um hospedeiro mostrar ou dar ao modelo como descrição do servidor inteiro."
    },
    {
      "code": "HELP = {a[\"id\"]: a for a in map(json.loads, open(\"data/help.jsonl\"))}\n\n",
      "note": "**Os catorze artigos da central de ajuda**, o `help.jsonl` que o `make_shop.py` da aula 1 escreve."
    },
    {
      "code": "OrderId = Annotated[str, Field(pattern=r\"^M-[0-9]{4}$\", description=\"M- and four digits, such as M-1043\")]\n\n\nclass Line(BaseModel):\n    book_id: str\n    quantity: int\n    cents: int\n\n\n",
      "note": "**A regra do id, escrita uma vez**: um padrão e uma descrição. Seção 03."
    },
    {
      "code": "class Order(BaseModel):\n    id: str\n    status: str\n    placed_on: str\n    delivered_on: str | None\n    tracking: str | None\n    lines: list[Line]\n    total: int\n    refunded: int\n\n\n@server.tool(annotations=ToolAnnotations(readOnlyHint=True))\n",
      "note": "**O que a ferramenta devolve, como tipo.** Os campos dele são o esquema de saída, e os únicos campos que saem do servidor. Seção 04."
    },
    {
      "code": "def get_order(order_id: OrderId) -> Order:\n    \"\"\"Look up one Marginalia order: status, dates, tracking, lines and amounts in cents.\"\"\"\n    try:\n        found = shop.get_order(order_id)\n    except LookupError as e:\n",
      "note": "**Só leitura, conferido na entrada, tipado na saída.**"
    },
    {
      "code": "        raise ToolError(f\"{e}; check the number on the confirmation email\") from e\n    return Order.model_validate(found)\n\n\nclass Hit(BaseModel):\n    title: str\n    uri: str\n\n\n@server.tool(annotations=ToolAnnotations(readOnlyHint=True))\n",
      "note": "**Uma falha esperada, com uma mensagem com que o modelo consegue agir.** Seção 05."
    },
    {
      "code": "def search_help(query: str) -> list[Hit]:\n    \"\"\"Search Marginalia's help centre by meaning. Returns titles and the URI of each article to read.\"\"\"\n    return [Hit(title=a[\"title\"], uri=f\"help://{a['id']}\") for a in shop.search_help(query)]\n\n\n",
      "note": "**A busca devolve onde ler, não os próprios artigos**: um título e uma URI cada."
    },
    {
      "code": "@server.resource(\"help://{article_id}\", mime_type=\"text/markdown\")\ndef help_article(article_id: str) -> str:\n    \"\"\"One article of Marginalia's help centre.\"\"\"\n    if article_id not in HELP:\n",
      "note": "**Um modelo de recurso**: todo artigo é endereçável como `help://h01` a `help://h40`. Seção 06."
    },
    {
      "code": "        raise ResourceNotFoundError(f\"no help article {article_id}\")\n    a = HELP[article_id]\n    return f\"# {a['title']}\\n\\n{a['body']}\"\n\n\n",
      "note": "**Um artigo desconhecido é um erro com o motivo**, não uma página vazia."
    },
    {
      "code": "@server.prompt()\ndef reply_to_customer(order_id: str, question: str) -> str:\n    \"\"\"Draft a reply to a customer's question about one order.\"\"\"\n    return (f\"A customer asks about order {order_id}: {question}\\n\"\n            \"Look the order up with get_order, check the help centre if a policy applies, \"\n            \"and draft a short reply. Quote dates and amounts exactly as the tools return them.\")\n\n\nif __name__ == \"__main__\":\n    server.run()",
      "note": "**Um prompt**: um modelo que uma pessoa escolhe, com dois argumentos. Seção 07."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"As três primitivas no servidor da Marginalia, e quem usa cada uma. O modelo pede as ferramentas get_order e search_help, e o hospedeiro permite ou recusa. O hospedeiro lê os recursos help://h01 a help://h40 e decide o que pôr no contexto do modelo. Uma pessoa escolhe o prompt reply_to_customer e preenche os argumentos dele.\"><defs><marker id=\"l14prim-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas</text><text x=\"30\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order, search_help</text><rect x=\"20\" y=\"85\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recursos</text><text x=\"30\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">help://{article_id}</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">prompts</text><text x=\"30\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reply_to_customer</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o modelo pede</text><text x=\"490\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o hospedeiro permite ou recusa</text><rect x=\"480\" y=\"85\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o hospedeiro lê</text><text x=\"490\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e escolhe o que o modelo vê</text><rect x=\"480\" y=\"150\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma pessoa escolhe</text><text x=\"490\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e preenche os argumentos</text><path d=\"M480 45 L220 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14prim-ah-amber)\"></path><path d=\"M480 110 L220 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14prim-ah-amber)\"></path><path d=\"M480 175 L220 175\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14prim-ah-amber)\"></path></svg>", "caption": "Três primitivas, e em cada uma decide alguém diferente.", "same": ["get_order, search_help", "help://{article_id}", "prompts", "reply_to_customer"]}
```

Ele roda como qualquer outro: iniciado como programa fala stdio, e a primeira coisa que um cliente pode perguntar é o que ele é.

```
ana@lab:~/agents$ printf '%s\n' '{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}' | python marginalia_mcp.py 2> /dev/null
{"jsonrpc":"2.0","id":1,"result":{"cacheScope":"private","capabilities":{"prompts":{"listChanged":true},"resources":{"listChanged":true,"subscribe":true},"tools":{"listChanged":true}},"instructions":"Tools and documents for answering Marginalia's customers about orders and the help centre.","resultType":"complete","supportedVersions":["2026-07-28"],"ttlMs":0,"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia","version":"1.0.0"}}}}
```

As `instructions` estão na resposta, depois das capacidades. Todo o resto desta aula fala com o servidor pelo `try_server.py`, que usa o cliente do SDK `mcp` **no mesmo processo**: o `Client(server)`, recebendo o próprio objeto do servidor, conecta sem iniciar subprocesso, que é também como a seção 08 o testa.

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
