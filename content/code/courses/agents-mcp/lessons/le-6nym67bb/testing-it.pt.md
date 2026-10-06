---
title: Testando por um cliente
version: 1
---

O contrato de um servidor é o que um cliente vê: os esquemas, os resultados, os erros. Então os testes falam com ele por um cliente MCP de verdade. O `Client(server)` conecta ao objeto do servidor no mesmo processo, o que dispensa subprocesso e rede, e todo pedido passa pelos mesmos handlers que os de um hospedeiro.

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

Sete testes, cerca de um segundo. Cada um é uma frase sobre o servidor que deve continuar verdadeira:

- a regra do id está **no esquema**, então o modelo fica sabendo dela;
- o id do cliente **nunca sai** do servidor, que é uma propriedade de privacidade e a mais provável de quebrar quando alguém acrescenta um campo;
- um pedido inexistente e um id malformado **dizem por quê**;
- os resultados da busca **apontam para artigos que dá para ler**;
- um artigo desconhecido é **um erro, não uma página vazia**;
- o prompt **leva os argumentos**.

Nenhum deles precisa de modelo, porque nenhum é sobre o que um modelo faz. A aula 7 testou o próprio agente com um modelo falso pelo mesmo motivo: teste as partes que você escreveu com algo que você controla. A aula 15 conecta este servidor a um hospedeiro, e a aula 16 o leva para a rede.
