---
title: Uma pergunta no meio de uma chamada
version: 1
---

A aula 11 deu nome ao jeito de 2026-07-28 de um servidor perguntar algo ao cliente durante um pedido: **pedidos de várias idas e voltas**. O `refund_mcp.py` pergunta a alguém da equipe antes de reembolsar:

```python
"""A refund tool that asks a member of staff before it runs, in the middle of the call."""
import json
from typing import Annotated

from mcp.server.mcpserver import Elicit, MCPServer, Resolve
from pydantic import BaseModel

import shop

server = MCPServer("refunds")


class Approval(BaseModel):
    approve: bool


def ask_staff(order_id: str, cents: int) -> Elicit[Approval]:
    """Runs before the tool: returning Elicit means "ask the client, then come back"."""
    return Elicit(f"Refund {cents} cents on {order_id}?", Approval)


@server.tool()
def refund(order_id: str, cents: int, reason: str, approval: Annotated[Approval, Resolve(ask_staff)]) -> str:
    """Refund part or all of an order, in cents, after a member of staff approves it."""
    if not approval.approve:
        return "Not approved by staff."
    return json.dumps(shop.refund(order_id, cents, reason, approved_by="staff"))


if __name__ == "__main__":
    server.run()
```

O parâmetro `approval` não é preenchido pelo modelo. O `Resolve(ask_staff)` diz ao SDK para preenchê-lo rodando `ask_staff` antes, e o `ask_staff` devolve `Elicit(...)`, que quer dizer *pergunte isto ao cliente, depois volte*. O esquema de entrada que o cliente vê tem só `order_id`, `cents` e `reason`.

O `mrtr.py` faz o papel do cliente, declarando no `_meta` que consegue perguntar a uma pessoa (`elicitation`):

```python
"""One tools/call that the server answers with input_required, and the retry that carries the answer."""
import json
import subprocess
import sys

META = {"io.modelcontextprotocol/protocolVersion": "2026-07-28",
        "io.modelcontextprotocol/clientCapabilities": {"elicitation": {"form": {}}}}  # "I can ask a person"
server = subprocess.Popen(["python", "refund_mcp.py"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, text=True)


def send(message):
    server.stdin.write(json.dumps(message) + "\n")
    server.stdin.flush()
    return json.loads(server.stdout.readline())


call = {"name": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}}
first = send({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {**call, "_meta": META}})["result"]
print("resultType:  ", first["resultType"])
for key, request in first["inputRequests"].items():
    print("asks:        ", key, request["method"], json.dumps(request["params"]["message"]))
print("requestState:", first["requestState"][:24] + "...", f"({len(first['requestState'])} characters)")

answer = input("approve? [y/n] ")
print(answer)
state = first["requestState"]
if sys.argv[1:] == ["tamper"]:
    state = state[:-6] + ("A" if state[-6] != "A" else "B") + state[-5:]  # one character changed on the way back
responses = {key: {"action": "accept", "content": {"approve": answer == "y"}} for key in first["inputRequests"]}
second = send({"jsonrpc": "2.0", "id": 2, "method": "tools/call",
               "params": {**call, "inputResponses": responses, "requestState": state, "_meta": META}})
print(json.dumps(second.get("result", second))[:200])
```

```
ana@lab:~/agents$ echo y | python mrtr.py
resultType:   input_required
asks:         __main__:ask_staff elicitation/create "Refund 3890 cents on M-1047?"
requestState: v1.JfQ2jp335h2SsMV9nh7vL... (347 characters)
approve? [y/n] y
{"content": [{"text": "{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}", "type": "text"}], "isError": false, "resultType": "complete", "structuredContent": {"result": "{\"order_id\": \"
ana@lab:~/agents$ python -c 'import sqlite3; print(sqlite3.connect("data/shop.db").execute("SELECT order_id, cents, approved_by FROM refunds").fetchall())'
[('M-1047', 3890, 'staff')]
```

O primeiro `tools/call` não terminou. O resultado dele tinha **`resultType: "input_required"`**, uma entrada em `inputRequests` com um pedido `elicitation/create` trazendo a pergunta e o esquema da resposta, e um **`requestState`**, uma string opaca de uns 350 caracteres. O cliente perguntou à pessoa (o `y` veio pela entrada padrão), depois mandou **o mesmo `tools/call` de novo** com dois acréscimos: `inputResponses`, a resposta sob a mesma chave, e o `requestState` exatamente como veio. O segundo resultado veio completo, e o reembolso está na tabela, aprovado por `staff`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um pedido de várias idas e voltas. O cliente manda tools/call. O servidor responde com resultType input_required, a pergunta que precisa de resposta, e um requestState selado. O cliente pergunta à pessoa, depois manda o mesmo tools/call de novo com inputResponses e o requestState inalterado. O servidor confere o selo e completa a chamada.\"><defs><marker id=\"l13mrtr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13mrtr-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cliente</text><rect x=\"580\" y=\"70\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor</text><path d=\"M140 92 L580 92\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13mrtr-ah-amber)\"></path><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1  tools/call</text><path d=\"M580 104 L140 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13mrtr-ah-phosphor)\"></path><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2  input_required: uma pergunta, um requestState selado</text><rect x=\"20\" y=\"160\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma pessoa</text><text x=\"30\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">y</text><path d=\"M80 120 L80 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M140 180 L580 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13mrtr-ah-amber)\"></path><text x=\"400\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3  tools/call de novo, com inputResponses e o estado</text><text x=\"700\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4  selo conferido, chamada completa</text></svg>", "caption": "Nenhuma conexão espera pela pessoa. A pergunta e o estado viajam nas mensagens.", "same": ["y"]}
```

Nada ficou esperando no meio. O servidor não manteve conexão aberta nem sessão; tudo o que ele precisava para retomar estava no segundo pedido. É por isso que o protocolo pôde ficar sem estado e ainda fazer perguntas, e por que a mesma troca funciona sobre HTTP, onde cada pedido é separado.

Isso também quer dizer que o estado viaja pelo cliente, em que o servidor não pode confiar. A especificação diz isso, e este SDK **sela** o `requestState`: ele é cifrado e autenticado, então o cliente consegue carregá-lo mas não lê-lo nem alterá-lo. A mesma troca com um caractere do estado alterado na volta:

```
ana@lab:~/agents$ echo y | python mrtr.py tamper
resultType:   input_required
asks:         __main__:ask_staff elicitation/create "Refund 3890 cents on M-1047?"
requestState: v1.GWCRIvuBtQoJqlp9NsDoD... (347 characters)
approve? [y/n] y
{"jsonrpc": "2.0", "id": 2, "error": {"code": -32602, "message": "Invalid or expired requestState", "data": {"reason": "invalid_request_state"}}}
```

`-32602`, *Invalid or expired requestState*, e nenhum reembolso. Um servidor que pusesse o estado em JSON simples teria deixado um cliente editar o valor entre a pergunta e a resposta.
