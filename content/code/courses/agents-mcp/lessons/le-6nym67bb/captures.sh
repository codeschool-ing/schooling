#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), and the files ana wrote (put below), which the lesson shows
# in full, each checked by lab/shown.py.
#
# NO MODEL TAKES PART IN THIS LESSON. The server (mcp 2.3.0), the in-process
# client the scripts and tests use to talk to it, pytest 9.1.1, and every
# result are real; the help-centre search asks Ollama's all-minilm for its
# vectors, as shop.py does everywhere. pytest's one DeprecationWarning, raised
# by an installed library and not by the code here, is silenced with
# -W ignore::DeprecationWarning on the command line.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
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

put try_server.py <<'PY'
"""Talk to marginalia_mcp's server in-process, the way a test would, and print what comes back."""
import asyncio
import json
import sys

from mcp import Client

from marginalia_mcp import server


async def main(what):
    async with Client(server) as client:  # an MCPServer object: connected in-process, no subprocess
        if what == "schema":
            for tool in (await client.list_tools()).tools:
                print(tool.name)
                print("  input: ", json.dumps(tool.input_schema["properties"]))
                print("  output:", json.dumps(sorted(tool.output_schema["properties"]))
                      if "properties" in tool.output_schema else json.dumps(tool.output_schema)[:110])
                print("  hints: ", tool.annotations.model_dump(exclude_none=True))
        if what == "calls":
            for order_id in ("M-1043", "M-9999", "1043"):
                result = await client.call_tool("get_order", {"order_id": order_id})
                print(f"{order_id}: isError={result.is_error}")
                if result.structured_content:
                    print("  structured:", json.dumps(result.structured_content)[:150])
                else:
                    print("  text:", result.content[0].text.replace("\n", " ")[:150])
        if what == "resources":
            for t in (await client.list_resource_templates()).resource_templates:
                print("template:", t.uri_template, t.mime_type)
            hits = await client.call_tool("search_help", {"query": "send a book back"})
            print("search_help:", json.dumps(hits.structured_content)[:160])
            for uri in ("help://h14", "help://h99"):
                try:
                    print(uri, "->", (await client.read_resource(uri)).contents[0].text.replace("\n", " ")[:120])
                except Exception as e:
                    print(uri, "->", type(e).__name__, e)
        if what == "prompt":
            for p in (await client.list_prompts()).prompts:
                print("prompt:", p.name, [(a.name, a.required) for a in p.arguments])
            got = await client.get_prompt("reply_to_customer", {"order_id": "M-1042", "question": "Can I still return it?"})
            for m in got.messages:
                print(f"{m.role}: {m.content.text}")


asyncio.run(main(sys.argv[1]))
PY

put test_marginalia_mcp.py <<'PY'
"""The server's contract, tested through a real MCP client in the same process."""
import pytest
from mcp import Client
from mcp.shared.exceptions import MCPError

from marginalia_mcp import server

pytestmark = pytest.mark.anyio


@pytest.fixture
def anyio_backend():
    return "asyncio"


async def test_get_order_checks_the_id_in_its_schema():
    async with Client(server) as client:
        tools = {t.name: t for t in (await client.list_tools()).tools}
        assert tools["get_order"].input_schema["properties"]["order_id"]["pattern"] == "^M-[0-9]{4}$"


async def test_get_order_never_returns_the_customer():
    async with Client(server) as client:
        result = await client.call_tool("get_order", {"order_id": "M-1043"})
        assert result.structured_content["tracking"] == "BR5512340003"
        assert "customer_id" not in result.structured_content


async def test_a_missing_order_says_why():
    async with Client(server) as client:
        result = await client.call_tool("get_order", {"order_id": "M-9999"})
        assert result.is_error
        assert "no order M-9999" in result.content[0].text


async def test_a_malformed_id_is_refused_before_any_lookup():
    async with Client(server) as client:
        result = await client.call_tool("get_order", {"order_id": "1043"})
        assert result.is_error
        assert "pattern" in result.content[0].text


async def test_search_points_at_readable_articles():
    async with Client(server) as client:
        hits = (await client.call_tool("search_help", {"query": "send a book back"})).structured_content["result"]
        first = await client.read_resource(hits[0]["uri"])
        assert first.contents[0].text.startswith("# ")


async def test_an_unknown_article_is_an_error_not_an_empty_page():
    async with Client(server) as client:
        with pytest.raises(MCPError):
            await client.read_resource("help://h99")


async def test_the_prompt_carries_its_arguments():
    async with Client(server) as client:
        got = await client.get_prompt("reply_to_customer", {"order_id": "M-1042", "question": "Can I return it?"})
        assert "M-1042" in got.messages[0].content.text
PY

block server-runs
on "printf '%s\n' '{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"server/discover\", \"params\": {\"_meta\": {\"io.modelcontextprotocol/protocolVersion\": \"2026-07-28\", \"io.modelcontextprotocol/clientCapabilities\": {}}}}' | python marginalia_mcp.py 2> /dev/null"

block schema
on 'python try_server.py schema 2> server.log'

block calls
on 'python try_server.py calls 2> server.log'

block resources
on 'python try_server.py resources 2> server.log'

block prompt
on 'python try_server.py prompt 2> server.log'

block tests
on 'python -m pytest -q -W ignore::DeprecationWarning test_marginalia_mcp.py'
