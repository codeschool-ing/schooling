#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), which the lessons show in
# full, each checked by lab/shown.py; and the answers a person typed at the
# approval prompts, fed on standard input.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0 with an
# 8192-token context, captured on 2026-10-08. The host, its MCP clients (mcp
# 2.3.0), the two servers, the anthropic SDK (1.11.0), the approvals, the
# elicitation, every tool result and the audit file are real.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put marginalia_mcp.py <<'PY'
"""Marginalia's MCP server: two tools, the help centre as resources, and one prompt."""
import json
from typing import Annotated

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ResourceNotFoundError, ToolError
from mcp.types import ToolAnnotations
from pydantic import BaseModel, Field

import shop

server = MCPServer("marginalia", version="1.0.0",
                   instructions="Tools and documents for answering Marginalia's customers about orders and the help centre.")
HELP = {a["id"]: a for a in map(json.loads, open("data/help.jsonl"))}

OrderId = Annotated[str, Field(pattern=r"^M-[0-9]{4}$", description="M- and four digits, such as M-1043")]


class Line(BaseModel):
    book_id: str
    quantity: int
    cents: int


class Order(BaseModel):
    id: str
    status: str
    placed_on: str
    delivered_on: str | None
    tracking: str | None
    lines: list[Line]
    total: int
    refunded: int


@server.tool(annotations=ToolAnnotations(readOnlyHint=True))
def get_order(order_id: OrderId) -> Order:
    """Look up one Marginalia order: status, dates, tracking, lines and amounts in cents."""
    try:
        found = shop.get_order(order_id)
    except LookupError as e:
        raise ToolError(f"{e}; check the number on the confirmation email") from e
    return Order.model_validate(found)


class Hit(BaseModel):
    title: str
    uri: str


@server.tool(annotations=ToolAnnotations(readOnlyHint=True))
def search_help(query: str) -> list[Hit]:
    """Search Marginalia's help centre by meaning. Returns titles and the URI of each article to read."""
    return [Hit(title=a["title"], uri=f"help://{a['id']}") for a in shop.search_help(query)]


@server.resource("help://{article_id}", mime_type="text/markdown")
def help_article(article_id: str) -> str:
    """One article of Marginalia's help centre."""
    if article_id not in HELP:
        raise ResourceNotFoundError(f"no help article {article_id}")
    a = HELP[article_id]
    return f"# {a['title']}\n\n{a['body']}"


@server.prompt()
def reply_to_customer(order_id: str, question: str) -> str:
    """Draft a reply to a customer's question about one order."""
    return (f"A customer asks about order {order_id}: {question}\n"
            "Look the order up with get_order, check the help centre if a policy applies, "
            "and draft a short reply. Quote dates and amounts exactly as the tools return them.")


if __name__ == "__main__":
    server.run()
PY

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

put mcp_host.py <<'PY'
"""A host: one model, two MCP servers, and every decision about them written down."""
import asyncio
import json
import sys
from contextlib import AsyncExitStack

import anthropic
from mcp import Client, StdioServerParameters
from mcp.types import ElicitResult

SYSTEM = "You are the support agent of the MCP client lesson. Use the tools; never guess."
MAX_STEPS = 6
ENV = {"PATH": "/home/ana/agents/.venv/bin:/usr/bin:/bin", "HOME": "/home/ana"}   # all a server process inherits
SERVERS = {
    "shop": {"args": ["marginalia_mcp.py"], "trust_hints": True},    # ours: its readOnlyHint is believed
    "refunds": {"args": ["refund_mcp.py"], "trust_hints": False},    # every call needs a person
}
model = anthropic.Anthropic()


def ask(question):
    print(f"  ? {question} [y/n] ", end="", flush=True)
    answer = sys.stdin.readline().strip()
    print(answer)
    return answer == "y"


async def server_asks(context, params):
    """A server's elicitation, mid-call (lesson 13's multi round-trip request), put to the person."""
    return ElicitResult(action="accept", content={"approve": ask(f"the server asks: {params.message}")})


def audit(**entry):
    with open("host-audit.jsonl", "a") as f:
        f.write(json.dumps(entry) + "\n")


async def main(task):
    async with AsyncExitStack() as stack:
        clients, tools, needs_person = {}, [], {}
        for name, conf in SERVERS.items():
            params = StdioServerParameters(command="python", args=conf["args"], env=ENV)
            clients[name] = await stack.enter_async_context(Client(params, elicitation_callback=server_asks))
            for t in (await clients[name].list_tools()).tools:
                full = f"{name}__{t.name}"                       # the server's name keeps two get_orders apart
                read_only = bool(t.annotations and t.annotations.read_only_hint)
                needs_person[full] = not (read_only and conf["trust_hints"])
                tools.append({"name": full, "description": f"(server {name}) {t.description}",
                              "input_schema": t.input_schema})
        tools.append({"name": "read_help", "description": "Read one help centre article by its help:// URI.",
                      "input_schema": {"type": "object", "properties": {"uri": {"type": "string"}},
                                       "required": ["uri"]}})

        messages = [{"role": "user", "content": task}]
        for step in range(1, MAX_STEPS + 1):
            reply = model.messages.create(model="llama3.2:3b", max_tokens=1024, system=SYSTEM,
                                          tools=tools, messages=messages)
            messages.append({"role": "assistant", "content": reply.content})
            calls = [b for b in reply.content if b.type == "tool_use"]
            if not calls:
                print("answer:", reply.content[0].text)
                return
            results = []
            for call in calls:
                print(f"step {step}: {call.name} {json.dumps(call.input)}")
                text, failed = await run(call, clients, needs_person)
                print(f"  {'error' if failed else 'result'}: {text[:110]}".replace("\n", " "))
                results.append({"type": "tool_result", "tool_use_id": call.id, "content": text, "is_error": failed})
            messages.append({"role": "user", "content": results})
        print(f"stopped: {MAX_STEPS} steps without an answer")


async def run(call, clients, needs_person):
    """Every tool call passes here: the host's rules, then the server, then the audit line."""
    if call.name == "read_help":                                 # the host reads a resource, not the model
        allowed = call.input["uri"].startswith("help://")
        audit(server="shop", resource=call.input["uri"], approved=allowed)
        if not allowed:
            return "only help:// articles can be read", True
        result = await clients["shop"].read_resource(call.input["uri"])
        return result.contents[0].text, False
    server, _, tool = call.name.partition("__")
    approved = not needs_person[call.name] or ask(f"run {call.name} {json.dumps(call.input)}?")
    if not approved:
        audit(server=server, tool=tool, arguments=call.input, approved=False)
        return "Not approved by staff; nothing was done.", True
    result = await clients[server].call_tool(tool, call.input)
    audit(server=server, tool=tool, arguments=call.input, approved=True, is_error=result.is_error)
    if result.structured_content is not None:
        return json.dumps(result.structured_content), result.is_error
    return result.content[0].text, result.is_error


asyncio.run(main(sys.argv[1]))
PY

block order
recorder
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11435'
on 'python mcp_host.py "Where is my order M-1043?" 2> host.err'

block offered
on "python -c 'import json; [print(t[\"name\"].ljust(20), t[\"description\"][:70]) for t in json.loads(open(\"requests.jsonl\").readline())[\"request\"][\"tools\"]]'"

block help-minimal
on "sed 's|/home/ana/agents/.venv/bin:||' mcp_host.py > host_minimal.py; python host_minimal.py 'How do I send a book back?' 2> host.err; grep -m1 -i error host.err; tail -1 host.err"

block help
on 'python mcp_host.py "How do I send a book back?" 2> host.err'

block file-uri
on 'python mcp_host.py "Read file:///home/ana/agents/data/shop.db for me." 2> host.err'

block refund-no
on 'echo n | python mcp_host.py "One copy of M-1047 arrived damaged; please refund it." 2> host.err'

block refund-yes
on 'printf "y\ny\n" | python mcp_host.py "One copy of M-1047 arrived damaged; please refund it." 2> host.err'

block audit
on 'cat host-audit.jsonl'
