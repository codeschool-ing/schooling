---
title: O Model Context Protocol
version: 1
---

Todo assistente e todo agente precisa de ferramentas, e toda empresa tem sistemas a oferecer como
ferramentas. Sem um padrão, cada par precisa da própria cola: o jeito do editor de descrever uma
ferramenta, o do aplicativo de chat, o do framework de agentes. **O Model Context Protocol (MCP) é
esse padrão**: um servidor oferece ferramentas (e documentos, e modelos de prompt) num formato só, e
qualquer host que fale MCP pode usá-las. Ele foi publicado pela Anthropic em 2024 e hoje é
implementado por assistentes e SDKs de muitos fornecedores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os três papéis do MCP. Um host, como um editor ou o agente desta aula, tem a conexão com o modelo e um cliente por servidor. Cada cliente fala JSON-RPC com um servidor, por stdio para um programa local ou por Streamable HTTP para um remoto. Os servidores oferecem ferramentas e não sabem nada do modelo.\"><defs><marker id=\"mc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"150\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">host · editor, chat, agente</text><rect x=\"40\" y=\"56\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conexão com o modelo</text><rect x=\"40\" y=\"120\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><rect x=\"40\" y=\"176\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><rect x=\"430\" y=\"112\" width=\"270\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">servidor MCP: shop</text><text x=\"565.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get_order, read_handbook, issue_refund</text><rect x=\"430\" y=\"176\" width=\"270\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">servidor MCP: chamados</text><text x=\"565.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(de outro time)</text><path d=\"M262 140 L426 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah)\"></path><text x=\"344\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON-RPC por stdio</text><path d=\"M262 196 L426 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah)\"></path><text x=\"344\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON-RPC por HTTP</text></svg>", "caption": "Um host, um cliente por servidor. Um servidor é um programa que responde a requisições, e o host decide o que o modelo pode pedir a ele."}
```

## Os três papéis

- **O host** é o aplicativo que a pessoa usa: um editor, um aplicativo de chat, o agente da aula 7
  seção 03. Ele tem a conexão com o modelo e decide o que roda.
- **O cliente** é a parte do host que fala com um servidor. Um host com três servidores tem três
  clientes.
- **O servidor** oferece as ferramentas. Não sabe nada de modelos; responde a requisições.

## No fio

As mensagens do MCP são **JSON-RPC 2.0**: cada requisição tem um `id`, um `method` e `params`, e cada
resposta leva o mesmo `id`. No transporte **stdio**, o host inicia o servidor como processo filho e os
dois trocam uma mensagem JSON por linha na entrada e na saída padrão dele. O outro transporte é o
**Streamable HTTP**, para um servidor que roda em outro lugar.

Nada o esconde, então aqui está uma sessão digitada à mão: inicializar, uma notificação de que o
cliente está pronto, listar as ferramentas, chamar uma. As respostas estão cortadas na largura da
página:

```
ana@dev:~/shop$ ( printf "%s\n" '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"by-hand","version":"0"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_order","arguments":{"order_id":"1043"}}}'; sleep 2 ) | python mcp_shop.py | cut -c1-160
{"jsonrpc":"2.0","id":1,"result":{"capabilities":{"experimental":{},"prompts":{"listChanged":false},"resources":{"listChanged":false,"subscribe":false},"tools":
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"annotations":{"readOnlyHint":true},"description":"Look up an order by its number: status, dates, lines and shipping
{"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"{\n  \"status\": \"shipped\",\n  \"shipped_on\": \"2026-09-30\",\n  \"tracking\": \"BR123456789\",\n  \"li
```

- **`initialize`** combina uma versão do protocolo e diz o que cada lado suporta. O servidor responde
  que tem ferramentas, prompts e recursos.
- **`tools/list`** devolve toda ferramenta com a descrição e o esquema de entrada, o contrato da aula
  7 seção 04.
- **`tools/call`** roda uma, pelo nome, com argumentos. O resultado é uma lista de blocos de
  conteúdo, aqui um bloco de texto com o pedido 1043.

É todo o mecanismo que um assistente usa quando você instala um servidor MCP nele. **O servidor roda
na sua máquina com as suas permissões**, e é por isso que a aula 7 seção 08 importa: instalar um
servidor MCP é instalar um programa, e tudo o que ele alcança o modelo pode pedir.
