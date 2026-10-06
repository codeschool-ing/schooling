---
title: Testing it through a client
version: 1
---

The contract of a server is what a client sees: the schemas, the results, the errors. So the tests talk to it through a real MCP client. `Client(server)` connects to the server object in the same process, which needs no subprocess and no network, and every request goes through the same handlers a host's would.

```python
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
```

```
ana@lab:~/agents$ python -m pytest -q -W ignore::DeprecationWarning test_marginalia_mcp.py
.......                                                                  [100%]
7 passed in 1.09s
```

Seven tests, about a second. Each one is a sentence about the server that should stay true:

- the id's rule is **in the schema**, so a model is told it;
- the customer's id **never leaves** the server, which is a privacy property and the one most likely to break when somebody adds a field;
- a missing order and a malformed id each **say why**;
- search results **point at articles that can be read**;
- an unknown article is **an error, not an empty page**;
- the prompt **carries its arguments**.

None of them needs a model, because none of them is about what a model does. Lesson 7 tested its agent with a fake model for the same reason: test the parts you wrote with something you control. Lesson 15 connects this server to a host, and lesson 16 moves it onto the network.
