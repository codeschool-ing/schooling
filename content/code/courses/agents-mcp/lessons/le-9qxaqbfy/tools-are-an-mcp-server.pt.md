---
title: Ferramentas são um servidor MCP
version: 1
---

O Claude Agent SDK não tem um decorador de ferramenta próprio no sentido das aulas 7 e 8. Uma ferramenta é declarada com `@tool` e posta num **servidor MCP** que roda dentro do seu processo:

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
      "note": "**Uma ferramenta devolve conteúdo MCP**: uma lista de blocos, aqui um bloco de texto com JSON. O problema do `str()` da aula 8 não aparece, porque a própria ferramenta escreve o texto."
    },
    {
      "code": "@tool(\"get_order\", \"Look up one Marginalia order by its id, M- and four digits. \"\n      \"Returns status, dates, lines and amounts in cents.\", {\"order_id\": str})\n",
      "note": "**Nome, descrição e um esquema.** `{\"order_id\": str}` é a forma curta: uma propriedade string obrigatória. Um dicionário de JSON Schema completo também é aceito, e é ali que um `pattern` entraria."
    },
    {
      "code": "async def get_order(args):\n    return text(shop.get_order(args[\"order_id\"]))\n\n\n@tool(\"search_help\", \"Search Marginalia's help centre by meaning and return the three closest articles.\",\n      {\"query\": str})\nasync def search_help(args):\n    return text([{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])])\n\n\n@tool(\"refund\", \"Refund part or all of an order to the customer's original payment, in cents.\",\n      {\"order_id\": str, \"cents\": int, \"reason\": str})\nasync def refund(args):\n    return text(shop.refund(args[\"order_id\"], args[\"cents\"], args[\"reason\"], approved_by=\"ana\"))\n\n\n",
      "note": "**O handler recebe os argumentos como dicionário** e é assíncrono, porque a chamada chega pelo cano vinda do subprocesso."
    },
    {
      "code": "shop_server = create_sdk_mcp_server(\"shop\", version=\"1.0.0\", tools=[get_order, search_help, refund])",
      "note": "**As três ferramentas viram um servidor**, chamado `shop`, versão 1.0.0."
    }
  ]
}
```

**MCP** é o Model Context Protocol, assunto das aulas 11 a 16: um jeito padrão de um agente descobrir e chamar ferramentas que outra pessoa oferece. Aqui o servidor está no processo, então nada atravessa uma rede; o CLI pede ao SDK a lista de ferramentas e manda cada chamada de volta pelo mesmo cano, e o SDK roda o handler.

O nome que o modelo vê é montado a partir dos dois: `mcp__shop__get_order`, o prefixo `mcp`, o nome do servidor e o da ferramenta, unidos por sublinhados duplos. Esse nome completo é o que aparece no fluxo, nas listas de permissão da seção 06 e nos hooks da seção 08. Um servidor de outro lugar, um processo nesta máquina ou um serviço do outro lado da rede, entra em `mcp_servers` do mesmo jeito, e as ferramentas dele ganham o mesmo tipo de nome. O agente não se importa com onde uma ferramenta roda; quem decide que ferramentas ele pode chamar deveria se importar.
