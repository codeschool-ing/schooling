---
title: stdio, onde a saída padrão pertence ao protocolo
version: 2
---

Sobre **stdio** o enquadramento é uma mensagem por linha: o `raw.py` escreve `json.dumps(message) + "\n"` e lê uma linha de volta para cada pedido. Nada mais marca onde uma mensagem termina. Isso faz da saída padrão um canal com um uso só: **tudo o que o servidor escreve ali tem de ser uma mensagem do protocolo**, e tudo o que é feito para uma pessoa (logs, avisos, um traceback) vai para a saída de erro. O `raw.py` guarda a saída de erro do servidor à parte, em `server.err`.

O jeito comum de quebrar essa regra é uma linha de depuração esquecida numa ferramenta:

```python
"""The order server with one debugging line left in, written to standard output."""
import json

from mcp.server.mcpserver import MCPServer

import shop

server = MCPServer("noisy")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up one Marginalia order by its id."""
    print("looking up", order_id, flush=True)  # meant for the developer, not for the client
    return json.dumps(shop.get_order(order_id))


if __name__ == "__main__":
    server.run()
```

As duas mensagens, `noisy.jsonl`:

```json
{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
```

```
ana@lab:~/agents$ python raw.py noisy_mcp.py 120 < noisy.jsonl; cat server.err
> {"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion":
< {"jsonrpc":"2.0","id":1,"result":{"cacheScope":"private","capabilities":{"prompts":{"listChanged":true},"resources":{"li
> {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"},
< {"jsonrpc":"2.0","id":2,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"
looking up M-1043
```

As duas respostas chegaram intactas, e o `looking up M-1043` está no `server.err`, não no fluxo. O transporte stdio do SDK `mcp` toma a saída padrão real para si quando começa e aponta o `print()` do processo para a saída de erro, então uma linha perdida não chega ao cliente. Um servidor escrito sem essa proteção, à mão ou com uma biblioteca que não faz isso, teria mandado `looking up M-1043` pelo cano como a primeira linha da resposta, e o cliente teria lido uma linha que não é JSON onde esperava uma resposta.

Mais duas consequências do transporte aparecem nas capturas anteriores. O hospedeiro é dono do tempo de vida do servidor: o `raw.py` fechou a entrada padrão do servidor e o servidor saiu. E a saída de erro do servidor vai para onde o hospedeiro a mandar: o `raw.py` a escreve num arquivo, e as aulas 11 e 12 descartaram a saída de erro dos hospedeiros, e a dos servidores junto, com `2> /dev/null`. **Os logs de um servidor local só são tão visíveis quanto o hospedeiro os deixa**, o que importa no dia em que uma ferramenta falha com `"Error executing tool get_order"` e o motivo está nesse log.
