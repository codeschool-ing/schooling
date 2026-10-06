---
title: Três papéis, achados nesta máquina
version: 1
---

A especificação descreve o MCP como uma arquitetura **cliente-hospedeiro-servidor**. A aula 7 de `ai-dev` deu nome aos três papéis; esta aula acha cada um deles num sistema rodando e pergunta o que cada um consegue ver e fazer.

- **O hospedeiro** é a aplicação: os três programas da aula 11, um editor, um app de chat. Ele guarda a conversa e a conexão com o modelo, roda o laço, e decide o que o modelo pode fazer.
- **Um cliente** é a parte do hospedeiro que fala com **exatamente um servidor**. Um hospedeiro com dois servidores tem dois clientes. Na aula 11 os clientes eram o `MCPServerStdio` no SDK da OpenAI, o `McpToolset` no ADK e um componente dentro do CLI do Claude Code.
- **Um servidor** oferece ferramentas, recursos e prompts, e responde a pedidos. É um processo separado, ou um serviço em outro lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Os três papéis do MCP. O hospedeiro é a aplicação e guarda a conversa e o modelo. Dentro dele, um cliente por servidor: cada cliente fala com exatamente um servidor. Os servidores são processos ou serviços separados; cada um recebe só os pedidos que o seu cliente manda, e nenhum vê a conversa nem outro servidor.\"><defs><marker id=\"l12roles-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hospedeiro: a conversa, o modelo, o laço</text><rect x=\"40\" y=\"64\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cliente 1</text><text x=\"50\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fala com orders</text><rect x=\"40\" y=\"140\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cliente 2</text><text x=\"50\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fala com help</text><rect x=\"470\" y=\"64\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor: orders</text><text x=\"480\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order</text><rect x=\"470\" y=\"140\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor: help</text><text x=\"480\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">search_help</text><path d=\"M180 89 L470 89\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12roles-ah-phosphor)\"></path><path d=\"M180 165 L470 165\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12roles-ah-phosphor)\"></path><text x=\"585\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum caminho entre servidores</text></svg>", "caption": "A conversa fica no hospedeiro. Cada servidor vê só as próprias chamadas.", "same": ["get_order", "search_help"]}
```

Entre os princípios de desenho que a especificação lista, um está escrito como negação: **servidores não devem conseguir ler a conversa inteira, nem "enxergar dentro" de outros servidores.** O histórico completo fica com o hospedeiro, cada servidor recebe só o que precisa, e tudo o que passa de um servidor para outro passa pelo hospedeiro, porque nada mais os liga.

O resto desta aula testa esse princípio, e as partes dele que dependem do hospedeiro. Ela usa três servidores: um escrito para se descrever, o servidor de pedidos da aula 11 com o nome `orders`, e `archive`, um segundo servidor de outra equipe, que o curso escreveu para isso. O `hosts.py` são os três hospedeiros da aula 11, agora informados na linha de comando de quais servidores iniciar:

```python
"""Three hosts, each given a set of MCP servers to start: python hosts.py HOST TASK SERVER..."""
import asyncio
import sys

host, task, names = sys.argv[1], sys.argv[2], sys.argv[3:]
WRAP = {"tee": lambda n: ["sh", "-c", f"tee {n}.in.jsonl | python {n}_mcp.py"],   # keep a copy of what the client sent
        "clean": lambda n: ["env", "-i", "PATH=/opt/agents/bin:/usr/bin:/bin", "HOME=/home/ana", "python", f"{n}_mcp.py"]}


def command(entry):
    """'probe' starts probe_mcp.py; 'probe:tee' or 'probe:clean' wraps it; 'probe:env' adds one variable."""
    name, _, wrap = entry.partition(":")
    argv = WRAP[wrap](name) if wrap in WRAP else ["python", f"{name}_mcp.py"]
    params = {"command": argv[0], "args": argv[1:]}
    if wrap == "env":
        params["env"] = {"ONLY_THIS": "1"}
    return name, params


SERVERS = dict(command(e) for e in names)
SYSTEM = f"You are the {host} host of the components lesson."


async def openai_host():
    from contextlib import AsyncExitStack
    from agents import Agent, Runner, set_default_openai_api, set_tracing_disabled
    from agents.mcp import MCPServerStdio
    set_default_openai_api("chat_completions")
    set_tracing_disabled(True)
    async with AsyncExitStack() as stack:
        servers = [await stack.enter_async_context(MCPServerStdio(params=p, name=n)) for n, p in SERVERS.items()]
        agent = Agent(name="support", model="scripted-1", instructions=SYSTEM, mcp_servers=servers)
        try:
            print((await Runner.run(agent, task)).final_output)
        except Exception as e:
            print(f"raised {type(e).__name__}: {e}")


async def claude_host():
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query
    options = ClaudeAgentOptions(model="scripted-1", system_prompt=SYSTEM, tools=[], setting_sources=[],
                                 allowed_tools=[f"mcp__{n}" for n in SERVERS],
                                 mcp_servers={n: {"type": "stdio", **p} for n, p in SERVERS.items()})
    async for message in query(prompt=task, options=options):
        if isinstance(message, ResultMessage):
            print(message.result)


async def google_host():
    from google.adk.agents import Agent
    from google.adk.models.google_llm import Gemini
    from google.adk.runners import InMemoryRunner
    from google.adk.tools.mcp_tool import McpToolset, StdioConnectionParams
    from google.genai.types import Content, Part
    from mcp import StdioServerParameters
    toolsets = [McpToolset(connection_params=StdioConnectionParams(server_params=StdioServerParameters(**p)))
                for p in SERVERS.values()]
    agent = Agent(name="support", model=Gemini(model="scripted-1", base_url="http://127.0.0.1:8600"),
                  instruction=SYSTEM, tools=toolsets)
    runner = InMemoryRunner(agent=agent, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text=task)])):
        for part in event.content.parts if event.content else []:
            if part.text:
                print(part.text)
    for t in toolsets:
        await t.close()


asyncio.run({"OpenAI": openai_host, "Claude": claude_host, "Google": google_host}[host]())
```
