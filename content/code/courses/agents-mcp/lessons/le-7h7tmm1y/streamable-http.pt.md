---
title: Streamable HTTP
version: 1
---

O mesmo objeto `server` pode escutar em HTTP. O `shop_http.py` o prende a `127.0.0.1`, porta 8700, para só esta máquina alcançá-lo:

```python
"""The same server over Streamable HTTP, listening on this machine only."""
from shop_mcp import server

server.run("streamable-http", host="127.0.0.1", port=8700)
```

O `post.sh` manda um pedido com o `curl`, com os cabeçalhos que a revisão 2026-07-28 exige em todo POST:

```bash
# post.sh METHOD NAME BODY: one MCP request over HTTP, with the headers the 2026-07-28 revision requires.
curl -s -i --noproxy 127.0.0.1 http://127.0.0.1:8700/mcp \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: $1" ${2:+-H "Mcp-Name: $2"} ${ORIGIN:+-H "Origin: $ORIGIN"} \
  -d "$3" | grep -v '^date:'
```

```
ana@lab:~/agents$ bash post.sh tools/call get_order '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}' | cut -c1-200
HTTP/1.1 200 OK
server: uvicorn
content-length: 1032
content-type: application/json

{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"2026-09-28\", \"status\": \"shipped\", \"delivered_on\": null, \"shipping\": 0, 
ana@lab:~/agents$ bash post.sh tools/call '' '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'
HTTP/1.1 400 Bad Request
server: uvicorn
content-length: 127
content-type: application/json

{"jsonrpc":"2.0","id":1,"error":{"code":-32020,"message":"mcp-name header does not match the request body's 'name' parameter"}}
ana@lab:~/agents$ bash post.sh tools/list get_order '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'
HTTP/1.1 400 Bad Request
server: uvicorn
content-length: 119
content-type: application/json

{"jsonrpc":"2.0","id":1,"error":{"code":-32020,"message":"mcp-method header does not match the request body's method"}}
ana@lab:~/agents$ ORIGIN=http://elsewhere.example bash post.sh tools/call get_order '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'
HTTP/1.1 403 Forbidden
server: uvicorn
content-length: 21

Invalid Origin header
```

O primeiro pedido funcionou: `200 OK`, `content-type: application/json`, e o mesmo resultado que a seção 03 recebeu por stdio. Os cabeçalhos são onde o HTTP acrescenta algo.

- **`MCP-Protocol-Version`** repete a versão do `_meta` do corpo.
- **`Mcp-Method`** e **`Mcp-Name`** repetem o `method` do corpo e o `name` da ferramenta. A especificação dá o motivo: para que balanceadores de carga, gateways e ferramentas de monitoramento consigam rotear e inspecionar pedidos **sem ler o corpo**. Um gateway pode então recusar chamadas a uma ferramenta, ou contá-las, só pelos cabeçalhos.
- **O servidor confere se os cabeçalhos batem com o corpo.** Sem o `Mcp-Name`, e de novo com `Mcp-Method: tools/list` num corpo de `tools/call`, o servidor respondeu `400 Bad Request` com o erro `-32020`, uma divergência de cabeçalho. Se não fizesse isso, uma decisão de gateway baseada no cabeçalho poderia ser contornada por um corpo que diz outra coisa.
- **O `Origin` é conferido.** Um pedido dizendo vir de uma página em `http://elsewhere.example` recebeu `403 Forbidden`. A especificação exige isso, contra o **DNS rebinding**: uma página aberta no navegador da pessoa tentando alcançar um servidor que escuta na própria máquina dela. A outra metade dessa defesa está no `shop_http.py`: um servidor local deve escutar em `127.0.0.1`, não em todas as interfaces.

O que este servidor ainda não faz é conferir **quem** está pedindo. Qualquer um nesta máquina poderia ter mandado esses pedidos. A aula 16 leva o servidor para um namespace de rede próprio, com TLS e um token de portador, e lê os metadados de autorização que a especificação define para um servidor remoto.
