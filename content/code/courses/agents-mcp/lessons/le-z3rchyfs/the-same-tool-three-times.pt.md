---
title: A mesma ferramenta, três vezes
version: 2
---

As aulas 8, 9 e 10 deram a três agentes o mesmo `get_order`. A cada vez ele foi escrito de novo para a biblioteca: uma função decorada, um `@tool` devolvendo conteúdo MCP, uma função simples. E cada biblioteca o descreveu ao seu modelo no formato do próprio fornecedor. Aqui está o primeiro pedido que cada hospedeiro mandou nesta aula, cortado até a ferramenta:

O `wire.py` lê o log do gravador da aula 1 e imprime as ferramentas do primeiro pedido, como o hospedeiro as escreveu:

```python
"""For the first request in the recorder's log that offered tools: which API it went to, and get_order as the host described it."""
import json
import textwrap

for line in open("requests.jsonl"):
    r = json.loads(line)
    tools = r["request"].get("tools", [])
    if not tools:
        continue   # LiteLLM's first request, /api/show, asks about the model and offers no tools
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

Três formatos para uma ferramenta. A Chat Completions da OpenAI a embrulha como `{"type": "function", "function": {...}}` com `parameters`; a API de Messages da Anthropic chama o esquema de `input_schema`; a declaração da API do Gemini tem `parameters_json_schema` e, aqui, também um `response_json_schema`. Os nomes diferem (`mcp__shop__get_order` num deles), e também detalhes como `"strict": false`.

Nada disso é problema enquanto uma equipe escreve um agente com uma biblioteca. Vira problema quando uma empresa tem vários assistentes (o de um editor, o de um app de chat, o de um agente de suporte) e vários sistemas para oferecer a eles como ferramentas (pedidos, a central de ajuda, a fila de chamados). Sem um formato comum, **cada par precisa de um adaptador próprio**: três hospedeiros e dois fornecedores de ferramentas são seis peças de cola, cada uma mantida por alguém, cada uma um lugar onde uma mudança na ferramenta é esquecida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Dois jeitos de ligar três hospedeiros a dois fornecedores de ferramentas. À esquerda, sem um protocolo comum, cada hospedeiro precisa de um adaptador próprio para cada fornecedor: seis adaptadores. À direita, cada hospedeiro tem um cliente MCP e cada fornecedor um servidor MCP: cinco peças, e um hospedeiro ou fornecedor novo acrescenta uma.\"><defs><marker id=\"l11pairs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11pairs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada par com seu adaptador</text><rect x=\"20\" y=\"40\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro A</text><rect x=\"20\" y=\"100\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro B</text><rect x=\"20\" y=\"160\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro C</text><rect x=\"250\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas X</text><rect x=\"250\" y=\"140\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas Y</text><path d=\"M120 58 L250 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 58 L250 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 118 L250 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 118 L250 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 178 L250 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M120 178 L250 158\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"390\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um protocolo</text><rect x=\"390\" y=\"40\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro A</text><rect x=\"390\" y=\"100\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro B</text><rect x=\"390\" y=\"160\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro C</text><rect x=\"530\" y=\"40\" width=\"20\" height=\"156\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MCP</text><rect x=\"590\" y=\"60\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor X</text><rect x=\"590\" y=\"140\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor Y</text><path d=\"M490 58 L530 58\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M490 118 L530 118\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M490 178 L530 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M550 78 L590 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M550 158 L590 158\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path></svg>", "caption": "Sem um protocolo, o trabalho cresce como hospedeiros vezes ferramentas. Com um, cresce como hospedeiros mais ferramentas.", "same": ["MCP"]}
```

O **Model Context Protocol** (MCP) é o formato comum. Um fornecedor de ferramentas escreve um **servidor MCP**; um hospedeiro inclui um **cliente MCP** por servidor que usa; o hospedeiro traduz o que o servidor oferece para o formato do próprio fornecedor. A aula 7 de `ai-dev` apresentou os três papéis e digitou uma sessão à mão. Esta aula e as cinco seguintes vão além: o que o protocolo é hoje, como ele é construído, e onde ficam as fronteiras de confiança.
