#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full, each checked by lab/shown.py; starting and stopping the HTTP server,
# which the lesson starts in a second terminal; and the answer a person typed
# at the approval prompt, fed on standard input.
#
# NO MODEL TAKES PART IN THIS LESSON. Every message is typed by hand or sent by
# a short script, and every reply came from the servers (mcp 2.3.0) and the
# HTTP server underneath (uvicorn). Replies are cut to the page's width where
# a command says so; nothing else is edited.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh

put shop_mcp.py <<'PY'
"""Marginalia's order lookup as an MCP server: written once, for any host."""
import json

from mcp.server.mcpserver import MCPServer

import shop

server = MCPServer("marginalia-shop")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."""
    return json.dumps(shop.get_order(order_id))


if __name__ == "__main__":
    server.run()  # stdio: one JSON-RPC message per line on standard input and output
PY

put raw.py <<'PY'
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
PY

put modern.jsonl <<'JSON'
{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
JSON

put errors.jsonl <<'JSON'
{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": 1043}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-9999"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "get_ordr", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
JSON

put old-version.jsonl <<'JSON'
{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "1999-01-01", "io.modelcontextprotocol/clientCapabilities": {}}}}
JSON

put no-meta.jsonl <<'JSON'
{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
JSON

put legacy.jsonl <<'JSON'
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "by-hand", "version": "0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
JSON

put noisy.jsonl <<'JSON'
{"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}
JSON

put refund_mcp.py <<'PY'
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
PY

put mrtr.py <<'PY'
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
PY

put noisy_mcp.py <<'PY'
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
PY

put shop_http.py <<'PY'
"""The same server over Streamable HTTP, listening on this machine only."""
from shop_mcp import server

server.run("streamable-http", host="127.0.0.1", port=8700)
PY

put post.sh <<'SH'
# post.sh METHOD NAME BODY: one MCP request over HTTP, with the headers the 2026-07-28 revision requires.
curl -s -i --noproxy 127.0.0.1 http://127.0.0.1:8700/mcp \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: $1" ${2:+-H "Mcp-Name: $2"} ${ORIGIN:+-H "Origin: $ORIGIN"} \
  -d "$3" | grep -v '^date:'
SH

BODY='{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_order", "arguments": {"order_id": "M-1043"}, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}'

block modern
on 'python raw.py shop_mcp.py 400 < modern.jsonl'

block errors
on 'python raw.py shop_mcp.py 330 < errors.jsonl'

block old-version
on 'python raw.py shop_mcp.py < old-version.jsonl'

block no-meta
on 'python raw.py shop_mcp.py 260 < no-meta.jsonl'

block legacy
on 'python raw.py shop_mcp.py 300 < legacy.jsonl'

block mrtr
on 'echo y | python mrtr.py'
on "python -c 'import sqlite3; print(sqlite3.connect(\"data/shop.db\").execute(\"SELECT order_id, cents, approved_by FROM refunds\").fetchall())'"

block tamper
on 'echo y | python mrtr.py tamper'

block noisy
on 'python raw.py noisy_mcp.py 120 < noisy.jsonl; cat server.err'

block http
lab exec 'python shop_http.py > http.log 2>&1 & echo $! > http.pid; sleep 3'
on "bash post.sh tools/call get_order '$BODY' | cut -c1-200"
on "bash post.sh tools/call '' '$BODY'"
on "bash post.sh tools/list get_order '$BODY'"
on "ORIGIN=http://elsewhere.example bash post.sh tools/call get_order '$BODY'"
lab exec 'kill $(cat http.pid)'
