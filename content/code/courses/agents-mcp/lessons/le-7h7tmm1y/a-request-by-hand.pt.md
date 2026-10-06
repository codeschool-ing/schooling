---
title: Um pedido, à mão
version: 1
---

Três pedidos na revisão 2026-07-28: descobrir o servidor, listar as ferramentas dele, chamar uma.

```json
{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

Todo pedido leva o mesmo `_meta`: `io.modelcontextprotocol/protocolVersion` diz que revisão o cliente fala, e `io.modelcontextprotocol/clientCapabilities` o que ele consegue fazer, aqui nada. Foi isso que substituiu o handshake: não há acordo da conexão inteira para lembrar, então cada pedido o repete.

```
ana@lab:~/agents$ python raw.py shop_mcp.py 400 < modern.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":1,"result":{"cacheScope":"private","capabilities":{"prompts":{"listChanged":true},"resources":{"listChanged":true,"subscribe":true},"tools":{"listChanged":true}},"resultType":"complete","supportedVersions":["2026-07-28"],"ttlMs":0,"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia-shop","version":""}}}}
> {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":2,"result":{"cacheScope":"private","resultType":"complete","tools":[{"description":"Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.","inputSchema":{"type":"object","properties":{"order_id":{"title":"Order Id","type":"string"}},"required":["order_id"],"title":"get_orderArguments"},"name":"get_order","outputSchema":
> {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"2026-09-28\", \"status\": \"shipped\", \"delivered_on\": null, \"shipping\": 0, \"tracking\": \"BR5512340003\", \"lines\": [{\"book_id\": \"b13\", \"quantity\": 1, \"cents\": 2490}, {\"book_id\": \"b14\", \"quantity\": 1, \"cents\": 2590}, {\"book_id\": \"b26\", \"quantity\": 1, 
```

Leia as respostas campo por campo.

- **O `server/discover`** devolveu as `capabilities` do servidor (ferramentas, recursos e prompts, cada um capaz de anunciar mudanças na própria lista), as `supportedVersions`, e o nome do servidor no `_meta` do resultado como `serverInfo`. Um cliente que o chama primeiro descobre, antes de qualquer coisa, se os dois conseguem conversar.
- **Todo resultado tem `resultType: "complete"`**. A seção 06 mostra o outro valor.
- **Os resultados de lista levam `ttlMs` e `cacheScope`**: por quanto tempo a resposta pode ser reaproveitada, aqui `0`, e se um cache compartilhado pode guardá-la, aqui `private`. A aula 11 notou um cliente pedindo a lista de ferramentas antes de cada pedido ao modelo; esses dois campos são o jeito de o servidor dizer com que frequência isso é necessário.
- **A lista de ferramentas inclui um `outputSchema`** além do `inputSchema`, porque o `get_order` é declarado como devolvendo uma string; a aula 14 o faz devolver dados estruturados.
- **O resultado da chamada é `content`**, uma lista de blocos, aqui um bloco de texto com o pedido. O mesmo valor aparece de novo como `structuredContent` mais adiante na linha, além do que a página mostra.
