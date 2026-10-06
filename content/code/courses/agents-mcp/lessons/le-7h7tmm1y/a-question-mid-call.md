---
title: A question in the middle of a call
version: 1
---

Lesson 11 named the 2026-07-28 way for a server to ask the client something during a request: **multi round-trip requests**. `refund_mcp.py` asks a member of staff before it refunds:

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

The `approval` parameter is not one the model fills in. `Resolve(ask_staff)` tells the SDK to fill it by running `ask_staff` first, and `ask_staff` returns `Elicit(...)`, which means *ask the client this question, then come back*. The input schema the client sees has only `order_id`, `cents` and `reason`.

`mrtr.py` plays the client, declaring in its `_meta` that it can ask a person (`elicitation`):

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

The first `tools/call` did not complete. Its result had **`resultType: "input_required"`**, an `inputRequests` entry holding an `elicitation/create` request with the question and the schema of the answer, and a **`requestState`**, an opaque string of about 350 characters. The client asked the person (the `y` came on standard input), then sent **the same `tools/call` again** with two additions: `inputResponses`, the answer under the same key, and the `requestState` exactly as it came. The second result was complete, and the refund is in the table, approved by `staff`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A multi round-trip request. The client sends tools/call. The server answers with resultType input_required, the question it needs answered, and a sealed requestState. The client asks the person, then sends the same tools/call again with inputResponses and the requestState unchanged. The server checks the seal and completes the call.\"><defs><marker id=\"l13mrtr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13mrtr-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">client</text><rect x=\"580\" y=\"70\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">server</text><path d=\"M140 92 L580 92\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13mrtr-ah-amber)\"></path><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1  tools/call</text><path d=\"M580 104 L140 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13mrtr-ah-phosphor)\"></path><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2  input_required: a question, a sealed requestState</text><rect x=\"20\" y=\"160\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a person</text><text x=\"30\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">y</text><path d=\"M80 120 L80 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M140 180 L580 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13mrtr-ah-amber)\"></path><text x=\"400\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3  tools/call again, with inputResponses and the state</text><text x=\"700\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4  seal checked, call completed</text></svg>", "caption": "No connection waits for the person. The question and the state travel in the messages."}
```

Nothing waited in between. The server kept no connection open and no session; everything it needed to resume was in the second request. That is why the protocol could become stateless and still ask questions, and why the same exchange works over HTTP, where each request is separate.

It also means the state travels through the client, which the server cannot trust. The specification says so, and this SDK **seals** the `requestState`: it is encrypted and authenticated, so the client can carry it but not read or change it. The same exchange with one character of the state changed on the way back:

```
ana@lab:~/agents$ echo y | python mrtr.py tamper
resultType:   input_required
asks:         __main__:ask_staff elicitation/create "Refund 3890 cents on M-1047?"
requestState: v1.GWCRIvuBtQoJqlp9NsDoD... (347 characters)
approve? [y/n] y
{"jsonrpc": "2.0", "id": 2, "error": {"code": -32602, "message": "Invalid or expired requestState", "data": {"reason": "invalid_request_state"}}}
```

`-32602`, *Invalid or expired requestState*, and no refund. A server that put the state in plain JSON would have let a client edit the amount between the question and the answer.
