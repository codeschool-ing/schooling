---
title: A troca legada
version: 1
---

O mesmo servidor, abordado do jeito que os clientes do Claude e do Google da aula 11 o abordaram, na revisão 2025-11-25:

```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "by-hand", "version": "0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
```

```
ana@lab:~/agents$ python raw.py shop_mcp.py 300 < legacy.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "by-hand", "version": "0"}}}
< {"jsonrpc":"2.0","id":1,"result":{"capabilities":{"prompts":{"listChanged":false},"resources":{"listChanged":false,"subscribe":false},"tools":{"listChanged":false}},"protocolVersion":"2025-11-25","serverInfo":{"name":"marginalia-shop","version":""}}}
> {"jsonrpc": "2.0", "method": "notifications/initialized"}
> {"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
< {"jsonrpc":"2.0","id":2,"result":{"tools":[{"description":"Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.","inputSchema":{"properties":{"order_id":{"title":"Order Id","type":"string"}},"required":["order_id"],"type":"object","title":"ge
```

O `initialize` combina a versão para a conexão inteira, e a resposta diz que versão o servidor aceitou e o que ele suporta. O `notifications/initialized` não tem `id`, então o `raw.py` não esperou resposta e nenhuma veio. Depois disso, o `tools/list` não leva `_meta` nenhum: a conexão lembra.

Lado a lado com a troca da seção 03, as diferenças são as mudanças de 2026-07-28 em miniatura:

| | legada (2025-11-25) | moderna (2026-07-28) |
|---|---|---|
| combinar uma versão | `initialize`, uma vez por conexão | `_meta` em todo pedido |
| conhecer as capacidades | o resultado do `initialize` | `server/discover`, quando o cliente quiser |
| `resultType` nos resultados | ausente | sempre presente |
| `ttlMs`, `cacheScope` nas listas | ausentes | presentes |
| o nome do servidor | `serverInfo` no resultado do `initialize` | `serverInfo` no `_meta` de cada resultado |

Um detalhe nas capacidades: a resposta legada diz `listChanged: false` para ferramentas, prompts e recursos, e o `server/discover` moderno disse `true`. **O mesmo servidor declarou capacidades diferentes nas duas eras.** Numa conexão legada, um servidor avisa o cliente de uma lista alterada com uma notificação na conexão aberta; na revisão moderna, os clientes optam por esses avisos com o `subscriptions/listen`. As capacidades que um servidor oferece podem depender da revisão, então um cliente deve lê-las na conexão que tem, não supô-las de outra.
