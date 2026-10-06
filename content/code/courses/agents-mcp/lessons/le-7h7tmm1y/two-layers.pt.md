---
title: Duas camadas
version: 1
---

A especificação divide o MCP em duas camadas, e mantê-las separadas deixa toda troca mais fácil de ler.

A **camada de dados** são as mensagens. Elas são **JSON-RPC 2.0**: um **pedido** tem um `id`, um `method` e `params`; um **resultado** ou um **erro** o responde, levando o mesmo `id`; uma **notificação** tem um método e nenhum `id`, e ninguém a responde. Em cima desse formato o MCP define os métodos (`server/discover`, `tools/list`, `tools/call` e os demais) e o que os params e resultados deles contêm.

A **camada de transporte** é como as mensagens viajam. **stdio**: o hospedeiro inicia o servidor como processo filho e os dois trocam uma mensagem por linha na entrada e saída padrão dele. **Streamable HTTP**: cada pedido é um POST HTTP para o endereço do servidor, e a resposta volta no corpo da resposta HTTP. O mesmo `tools/call` é o mesmo JSON em qualquer um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"As duas camadas do MCP. A camada de dados são as mensagens JSON-RPC: pedidos com um id e um método, resultados e erros que os respondem, notificações que não esperam resposta. A camada de transporte as leva: stdio, uma mensagem por linha na entrada e saída padrão de um programa local, ou Streamable HTTP, um POST por pedido a um servidor em outro lugar. As mesmas mensagens viajam em qualquer um.\"><defs></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">camada de dados</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido</text><text x=\"30\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id, method, params</text><rect x=\"200\" y=\"40\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resultado</text><text x=\"210\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id, result</text><rect x=\"380\" y=\"40\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">erro</text><text x=\"390\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id, error.code</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">notificação</text><text x=\"570\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">method, sem id</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">camada de transporte</text><rect x=\"20\" y=\"130\" width=\"330\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stdio</text><text x=\"30\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma mensagem por linha, programa local</text><rect x=\"370\" y=\"130\" width=\"330\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Streamable HTTP</text><text x=\"380\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um POST por pedido, servidor em outro lugar</text></svg>", "caption": "As mensagens não mudam com o transporte.", "same": ["id, method, params", "id, result", "id, error.code"]}
```

O resto desta aula trabalha no fundo das duas camadas, sem biblioteca nenhuma do lado do cliente. O `raw.py` inicia um servidor, manda a ele mensagens de um arquivo uma linha por vez, e imprime cada resposta, cortada numa largura dada na linha de comando para caber na página:

```python
"""Send JSON-RPC messages to a stdio MCP server, one per line, and print each reply."""
import json
import subprocess
import sys

server = subprocess.Popen(["python", sys.argv[1]], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=open("server.err", "w"), text=True)  # the server's logs, kept apart
width = int(sys.argv[2]) if len(sys.argv) > 2 else 200
for line in sys.stdin:
    message = json.loads(line)
    print(">", json.dumps(message)[:width])
    server.stdin.write(json.dumps(message) + "\n")  # the framing: one message, one line
    server.stdin.flush()
    if "id" in message:                              # a request gets one reply; a notification none
        print("<", server.stdout.readline().strip()[:width])
server.stdin.close()
server.wait()
```

O servidor é o `shop_mcp.py` da aula 11, sem mudança. Nenhum modelo participa desta aula: todo pedido foi escrito à mão, e toda resposta é do servidor.
