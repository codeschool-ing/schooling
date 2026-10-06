---
title: Um laço num subprocesso
version: 1
---

O OpenAI Agents SDK da aula 8 é um laço escrito em Python, rodando no seu processo. O **Claude Agent SDK** (`claude-agent-sdk` no PyPI, importado como `claude_agent_sdk`; este laboratório fixa a 0.2.163) é construído de outro jeito. Ele traz uma cópia do **Claude Code**, o agente de linha de comando da Anthropic, e o executa:

```
ana@lab:~/agents$ CLI=$(python -c "import claude_agent_sdk, pathlib; print(pathlib.Path(claude_agent_sdk.__file__).parent / \"_bundled/claude\")"); du -h $CLI; $CLI --version
231M	/opt/agents/lib/python3.11/site-packages/claude_agent_sdk/_bundled/claude
2.1.286 (Claude Code)
```

Um programa de 231 MB dentro de um pacote Python. Quando o seu código chama `query()`, o SDK inicia esse programa como subprocesso e troca linhas JSON com ele pela entrada e saída padrão. O laço (as chamadas ao modelo, o despacho das ferramentas, as verificações de permissão, os arquivos de sessão) roda no subprocesso; o seu programa manda um prompt e lê de volta um fluxo de mensagens.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"Três processos. O seu programa Python chama query(); o SDK inicia o programa de linha de comando do Claude Code como subprocesso e conversa com ele em linhas JSON pela entrada e saída padrão. O subprocesso manda pedidos HTTP ao fornecedor do modelo, aqui o labllm na porta 8600. Quando o modelo chama uma ferramenta da loja, o subprocesso manda a chamada de volta pelo mesmo cano, e a ferramenta roda dentro do seu programa.\"><defs><marker id=\"l9proc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9proc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l9proc-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu processo</text><rect x=\"20\" y=\"44\" width=\"190\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cs_run.py</text><text x=\"30\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama query()</text><rect x=\"20\" y=\"124\" width=\"190\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop_server</text><text x=\"30\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as ferramentas, no processo</text><rect x=\"280\" y=\"44\" width=\"190\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">claude 2.1.286</text><text x=\"290\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subprocesso: o laço</text><rect x=\"540\" y=\"80\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">labllm :8600</text><text x=\"550\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o fornecedor do modelo</text><path d=\"M210 70 L280 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9proc-ah-amber)\"></path><text x=\"245\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linhas JSON</text><path d=\"M280 150 L210 150\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l9proc-ah-phosphor)\"></path><text x=\"245\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chamadas</text><path d=\"M470 110 L540 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l9proc-ah-wire)\"></path><text x=\"505\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTP</text></svg>", "caption": "O laço roda no subprocesso. As suas ferramentas rodam no seu processo.", "same": ["HTTP"]}
```

```python
"""The first agent with the Claude Agent SDK, in three configurations."""
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, ClaudeSDKError, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You answer Marginalia's customers in the Claude Agent SDK lesson. Use the tools; never guess."


def options(how):
    o = ClaudeAgentOptions(model="scripted-1", system_prompt=SYSTEM,
                           mcp_servers={"shop": shop_server},
                           allowed_tools=["mcp__shop__get_order", "mcp__shop__search_help"])
    if how in ("no-builtins", "isolated", "one-turn"):
        o.tools = []                # none of Claude Code's own tools: only the shop's
    if how in ("isolated", "one-turn"):
        o.setting_sources = []      # read no settings files and no CLAUDE.md
    if how == "one-turn":
        o.max_turns = 1
    return o


async def main(how, task):
    try:
        async for message in query(prompt=task, options=options(how)):
            show(message)
    except ClaudeSDKError as e:
        print(f"raised     {type(e).__name__}: {e}")


anyio.run(main, sys.argv[1], sys.argv[2])
```

O `ClaudeAgentOptions` guarda a configuração que a aula 8 dividia entre `Agent` e `Runner`; `query()` é um iterador assíncrono de mensagens. A seção 04 explica as três configurações; esta execução usa a primeira, a padrão. O `cs_show.py` imprime uma linha por mensagem:

```python
"""Print the SDK's message stream one line per message, shortened for reading."""
from claude_agent_sdk import (AssistantMessage, ResultMessage, SystemMessage, TextBlock,
                              ToolResultBlock, ToolUseBlock, UserMessage)


def show(m):
    if isinstance(m, SystemMessage):
        extra = f" tools={len(m.data['tools'])}" if m.subtype == "init" else ""
        print(f"system     {m.subtype}{extra}")
    elif isinstance(m, AssistantMessage):
        for b in m.content:
            if isinstance(b, ToolUseBlock):
                print(f"assistant  tool_use {b.name} {b.input}")
            elif isinstance(b, TextBlock):
                print(f"assistant  {b.text}")
    elif isinstance(m, UserMessage):
        for b in m.content if isinstance(m.content, list) else []:
            if isinstance(b, ToolResultBlock):
                body = b.content if isinstance(b.content, str) else b.content[0]["text"]
                print(f"user       tool_result{' (error)' if b.is_error else ''} {body[:90]}")
    elif isinstance(m, ResultMessage):
        print(f"result     {m.subtype} turns={m.num_turns} {m.duration_ms} ms "
              f"cost_usd={m.total_cost_usd:.4f} session={m.session_id[:8]}")
```

```
ana@lab:~/agents$ python cs_run.py default "Where is my order M-1043?"
system     init tools=23
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
system     informational
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
assistant  Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
result     success turns=2 1807 ms cost_usd=0.1370 session=e57cf1f2
```

**A chamada e a resposta do modelo foram escritas pelo curso**; cada linha do fluxo é do SDK. O fluxo começa com uma mensagem `system` de subtipo `init`, que lista as ferramentas da sessão, e termina com um `result` que traz o número de turnos, o tempo, um custo e um id de sessão. Entre os dois ficam as mensagens que a aula 1 descreveu, como objetos tipados: uma mensagem do assistente com um uso de ferramenta, uma mensagem do usuário com o resultado, uma mensagem do assistente com a resposta. Uma linha a mais veio do próprio CLI, uma mensagem `system` de subtipo `informational`, que o `cs_show.py` imprime sem o texto; é um aviso sobre um recurso de produto do Claude Code e não tem relação com este agente.

Duas outras coisas saem do CLI e não estão na captura. Cada execução escreve um aviso na saída de erro, de que não reconhece o nome de modelo `scripted-1`; o `captures.sh` o descarta e diz isso. E `cost_usd=0.1370` não é uma fatura: o CLI estima um custo a partir da própria tabela de preços, e para um modelo que não reconhece ele chuta. A seção 04 mostra por que o número teve esse tamanho mesmo assim.

| aula 8 (Agents SDK) | Claude Agent SDK |
|---|---|
| um laço no seu processo | o CLI do Claude Code como subprocesso |
| `Agent(...)` mais `Runner.run_sync(...)` | `query(prompt, ClaudeAgentOptions(...))` |
| `@function_tool` | `@tool` dentro de um servidor MCP no processo (seção 03) |
| `max_turns`, levanta exceção | `max_turns`, um `result` com subtipo de erro, depois exceção (seção 09) |
| `needs_approval` | `allowed_tools`, modos de permissão, `can_use_tool` (seções 06 e 07) |
| guardrails | hooks (seção 08) |
| `SQLiteSession` | arquivos de sessão escritos pelo CLI, e `resume` (seção 09) |
