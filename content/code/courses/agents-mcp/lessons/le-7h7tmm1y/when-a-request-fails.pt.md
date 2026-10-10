---
title: Quando um pedido falha
version: 2
---

O MCP tem dois jeitos de informar uma falha, e eles querem dizer coisas diferentes. Um **erro de protocolo** é um `error` JSON-RPC: o pedido em si não pôde ser tratado. Um **erro de execução de ferramenta** é um resultado comum com `isError: true`: o pedido estava certo, e a ferramenta falhou. O segundo tipo é feito para o modelo ler e agir.

Três chamadas que falham:

```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": 1043}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-9999"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_ordr", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

```
ana@lab:~/agents$ python raw.py shop_mcp.py 330 < errors.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": 1043}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"Error executing tool get_order: 1 validation error for get_orderArguments\norder_id\n  Input should be a valid string [type=string_type, input_value=1043, input_type=int]\n    For further information visit https://errors.pydantic.dev/2.13/v/string_type","type":"text"}],"isErr
> {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-9999"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":2,"result":{"content":[{"text":"Error executing tool get_order","type":"text"}],"isError":true,"resultType":"complete","_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia-shop","version":""}}}}
> {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_ordr", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"Unknown tool: get_ordr","type":"text"}],"isError":true,"resultType":"complete","_meta":{"io.modelcontextprotocol/serverInfo":{"name":"marginalia-shop","version":""}}}}
```

- **Um argumento de tipo errado** (`1043`, um número, onde o esquema diz string) voltou como erro de execução de ferramenta cujo texto é a mensagem de validação: campo, tipo esperado, valor dado. Um modelo consegue corrigir isso.
- **Uma ferramenta que levantou erro** (`M-9999` não existe) voltou como `"Error executing tool get_order"` e nada mais. O `LookupError` e a mensagem dele foram para o log do servidor; o cliente não recebeu nada disso. É a frase padrão da aula 8 em outra biblioteca, e a aula 14 corrige isso do lado do servidor.
- **Uma ferramenta que não existe** (`get_ordr`) também voltou como erro de execução de ferramenta. A especificação lista uma ferramenta desconhecida entre os erros de protocolo, respondida com um erro JSON-RPC de código `-32602`; esta versão do SDK respondeu com `isError`. Um cliente que só confere um dos dois tipos vai perder o outro, o que é motivo para conferir os dois.

Agora o próprio envelope. Uma versão que o servidor não suporta:

O arquivo, `old-version.jsonl`:

```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "1999-01-01", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

```
ana@lab:~/agents$ python raw.py shop_mcp.py < old-version.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "1999-01-01", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":1,"error":{"code":-32022,"message":"Unsupported protocol version","data":{"supported":["2026-07-28"],"requested":"1999-01-01"}}}
```

`-32022`, **Unsupported protocol version**, com as versões que o servidor suporta. A especificação diz que um cliente deve escolher uma delas e tentar de novo. E um pedido sem `_meta` nenhum, seguido de um correto na mesma conexão:

O arquivo, `no-meta.jsonl`:

```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

```
ana@lab:~/agents$ python raw.py shop_mcp.py 260 < no-meta.jsonl
> {"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}
< {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid request parameters","data":""}}
> {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
< {"jsonrpc":"2.0","id":2,"error":{"code":-32600,"message":"this connection serves the handshake protocol era; requests carrying the 2026-07-28 envelope are not accepted on it"}}
```

O primeiro recebeu `-32602`, *Invalid request parameters*, sem explicação. O segundo, correto desta vez, foi recusado com `-32600` porque **a primeira mensagem já tinha decidido o que esta conexão stdio é**: um pedido sem o envelope moderno a tornou uma conexão legada, e dali em diante o servidor recusou pedidos modernos nela. É o jeito deste SDK de ser de duas eras num cano só, e a lição prática é que a primeira mensagem numa conexão stdio importa mais que as outras.
