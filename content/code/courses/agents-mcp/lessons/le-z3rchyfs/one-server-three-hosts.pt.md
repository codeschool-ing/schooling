---
title: Um servidor, três hospedeiros
version: 1
---

A consulta de pedidos, escrita uma vez como servidor MCP com o SDK `mcp` (este laboratório fixa a 2.3.0):

```python
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
```

É a ferramenta da aula 4 de novo: um nome, uma anotação de tipo, uma docstring, e uma função que devolve texto. O `server.run()` fala MCP sobre **stdio**: o hospedeiro inicia o programa e os dois trocam uma mensagem JSON-RPC por linha na entrada e saída padrão dele.

Três hospedeiros, um por biblioteca, cada um mandado usar esse servidor:

```python
"""The same MCP server, used by three hosts built with three libraries."""
import asyncio
import sys

TASK = "Where is my order M-1043?"


def server(host):
    """How to start the server. `tee` keeps a copy of everything the host's client sends it."""
    return {"command": "sh", "args": ["-c", f"tee {host}.in.jsonl | python shop_mcp.py"]}


async def openai_host():
    from agents import Agent, Runner, set_tracing_disabled
    from agents.mcp import MCPServerStdio
    set_tracing_disabled(True)
    async with MCPServerStdio(params=server("openai"), name="shop") as shop:
        agent = Agent(name="support", model="llama3.2:3b", mcp_servers=[shop],
                      instructions="You are the OpenAI host of the MCP lesson.")
        print((await Runner.run(agent, TASK)).final_output)


async def claude_host():
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query
    options = ClaudeAgentOptions(model="qwen2.5:3b", system_prompt="You are the Claude host of the MCP lesson.",
                                 tools=[], setting_sources=[], allowed_tools=["mcp__shop__get_order"],
                                 mcp_servers={"shop": {"type": "stdio", **server("claude")}})
    async for message in query(prompt=TASK, options=options):
        if isinstance(message, ResultMessage):
            print(message.result)


async def google_host():
    from google.adk.agents import Agent
    from google.adk.models.lite_llm import LiteLlm
    from google.adk.runners import InMemoryRunner
    from google.adk.tools.mcp_tool import McpToolset, StdioConnectionParams
    from google.genai.types import Content, Part
    from mcp import StdioServerParameters
    shop = McpToolset(connection_params=StdioConnectionParams(server_params=StdioServerParameters(**server("google"))))
    agent = Agent(name="support", model=LiteLlm(model="ollama_chat/llama3.2:3b"),
                  instruction="You are the Google host of the MCP lesson.", tools=[shop])
    runner = InMemoryRunner(agent=agent, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text=TASK)])):
        for part in event.content.parts if event.content else []:
            if part.text:
                print(part.text)
    await shop.close()


asyncio.run({"openai": openai_host, "claude": claude_host, "google": google_host}[sys.argv[1]]())
```

Cada biblioteca tem o próprio jeito de nomear um servidor: `MCPServerStdio` no SDK da OpenAI, uma entrada em `mcp_servers` no Claude Agent SDK, `McpToolset` no ADK. Nenhum deles precisou de uma linha do próprio `get_order`. O `server()` inicia o programa por `sh -c "tee … | python shop_mcp.py"`: o `tee` copia num arquivo tudo o que o cliente do hospedeiro escreve para o servidor, para a seção 04 poder ler.

```
ana@lab:~/agents$ python hosts.py openai 2> /dev/null
Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
ana@lab:~/agents$ python hosts.py claude 2> /dev/null
Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
ana@lab:~/agents$ python hosts.py google 2> /dev/null
Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
```

**A chamada e a resposta do modelo foram escritas pelo curso**, a mesma regra para os três hospedeiros; os três clientes, o servidor e cada mensagem entre eles são reais. A saída de erro foi descartada (`2> /dev/null`) por causa dos avisos que as aulas anteriores já mostraram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Um hospedeiro fica entre duas conexões fáceis de confundir. Com o fornecedor do modelo ele fala a API do fornecedor, e cada fornecedor descreve uma ferramenta no próprio formato. Com cada servidor MCP ele fala MCP, igual para todo servidor. O hospedeiro traduz a lista de ferramentas do servidor para o formato do fornecedor, e o servidor nunca vê o modelo.\"><defs><marker id=\"l11wires-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11wires-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fornecedor do modelo</text><text x=\"30\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ollama :11434</text><rect x=\"280\" y=\"50\" width=\"160\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro</text><text x=\"290\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o laço, o modelo,</text><text x=\"290\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as permissões</text><rect x=\"540\" y=\"70\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop_mcp.py</text><text x=\"550\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um servidor MCP</text><path d=\"M280 100 L180 100\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l11wires-ah-wire)\"></path><text x=\"230\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">API do fornecedor</text><path d=\"M440 100 L540 100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l11wires-ah-phosphor)\"></path><text x=\"490\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MCP</text></svg>", "caption": "O MCP é o fio da direita. O da esquerda continua sendo o de cada fornecedor.", "same": ["MCP", "labllm :8600"]}
```

Esta é a divisão que o MCP faz. O hospedeiro continua falando com o modelo no formato do fornecedor, como a seção anterior mostrou; esse fio não é MCP. Entre o hospedeiro e o servidor, o fio é o mesmo seja quem for o hospedeiro, e o servidor nunca sabe que modelo, se algum, está do outro lado.
