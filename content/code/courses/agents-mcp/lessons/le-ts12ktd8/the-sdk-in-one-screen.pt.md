---
title: O Agents SDK numa tela
version: 1
---

O OpenAI Agents SDK (`openai-agents` no PyPI, importado como `agents`; este laboratório fixa a 0.23.1) tem três objetos que você encontra primeiro: **`Agent`**, que é configuração (um nome, instruções, um modelo, ferramentas); **`Runner`**, que roda o laço; e **`function_tool`**, que transforma uma função Python numa ferramenta. A aula 7 escreveu os mesmos três como `Agent`, `Agent.run` e `@tool`.

```python
"""Marginalia's tools for the OpenAI Agents SDK: shop.py's functions, decorated."""
from typing import Annotated, Literal

from agents import function_tool
from pydantic import Field

import shop


@function_tool
def get_order(order_id: Annotated[str, Field(pattern="^M-[0-9]{4}$")]) -> dict:
    """Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."""
    return shop.get_order(order_id)


@function_tool
def search_help(query: str) -> list[dict]:
    """Search Marginalia's help centre by meaning and return the three closest articles."""
    return [{"title": a["title"], "body": a["body"]} for a in shop.search_help(query)]


@function_tool(needs_approval=True)
def refund(order_id: Annotated[str, Field(pattern="^M-[0-9]{4}$")], cents: int, reason: str) -> dict:
    """Refund part or all of an order to the customer's original payment, in cents."""
    return shop.refund(order_id, cents, reason, approved_by="ana")
```

O decorador lê as anotações de tipo e a docstring, como o da aula 7. O `Field(pattern=...)` do Pydantic dentro de `Annotated` acrescenta o padrão; o `needs_approval=True` em `refund` é o assunto da seção 07.

```schooling-example
{
  "language": "python",
  "file": "oa_run.py",
  "parts": [
    {
      "code": "\"\"\"A first agent with the OpenAI Agents SDK, pointed at the lab's stand-in provider.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "from agents import Agent, MaxTurnsExceeded, Runner, set_default_openai_api, set_tracing_disabled\n\nfrom oa_tools import get_order, search_help\n\n",
      "note": "**Quatro nomes do SDK**, e uma exceção para o limite de passos."
    },
    {
      "code": "set_default_openai_api(\"chat_completions\")  # labllm speaks Chat Completions, not the Responses API\n",
      "note": "**A única concessão ao laboratório.** O SDK fala com a Responses API da OpenAI por padrão, e o labllm implementa a Chat Completions; esta linha passa o SDK para a Chat Completions. Com uma chave real da OpenAI você a deixaria de fora."
    },
    {
      "code": "set_tracing_disabled(True)                    # traces would go to OpenAI's servers; section 08 keeps them here\n\n",
      "note": "**O rastreamento vem ligado e manda spans para os servidores da OpenAI.** Aqui não há para onde mandá-los; a seção 10 os mantém na máquina."
    },
    {
      "code": "support = Agent(\n    name=\"Marginalia support\",\n    instructions=\"You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.\",\n    model=\"scripted-1\",\n    tools=[get_order, search_help],\n)\n\ntry:\n",
      "note": "**Um agente é configuração**: nome, instruções, modelo, ferramentas."
    },
    {
      "code": "    result = Runner.run_sync(support, sys.argv[1], max_turns=int(sys.argv[2]) if len(sys.argv) > 2 else 10)\n",
      "note": "**O laço.** `max_turns` é o limite de passos, 10 se não for dado."
    },
    {
      "code": "except MaxTurnsExceeded as e:\n    print(f\"stopped: {e}\")\nelse:\n",
      "note": "**Bater no limite levanta exceção**, em vez de devolver um resultado interrompido."
    },
    {
      "code": "    for item in result.new_items:\n        print(f\"{type(item).__name__:20} {str(getattr(item, 'raw_item', ''))[:70]}\")\n    print(\"answer:\", result.final_output)",
      "note": "**O que aconteceu, como itens tipados**: chamadas de ferramenta, as saídas delas, mensagens."
    }
  ]
}
```

```
ana@lab:~/agents$ python oa_run.py "Where is my order M-1043?"
ToolCallItem         ResponseFunctionToolCall(arguments='{"order_id": "M-1043"}', call_id='
ToolCallOutputItem   {'call_id': 'call_lab_0002_1', 'output': "{'id': 'M-1043', 'customer_i
ToolCallItem         ResponseFunctionToolCall(arguments='{"query": "tracking a parcel"}', c
ToolCallOutputItem   {'call_id': 'call_lab_0003_1', 'output': "[{'title': 'Tracking a parce
MessageOutputItem    ResponseOutputMessage(id='__fake_id__', content=[ResponseOutputText(an
answer: Order M-1043 has shipped and is on its way; its tracking code is BR5512340003, and the tracking link in your shipping email updates at each step of the journey.
```

**As chamadas e a resposta do modelo foram escritas pelo curso** como regras para o substituto; todo o resto é o SDK. A execução é o agente da aula 1: uma consulta, uma busca, uma resposta. O que o SDK acrescenta aparece nos itens: um `ToolCallItem` para cada chamada, um `ToolCallOutputItem` para cada resultado e um `MessageOutputItem` para a resposta, cada um ligado ao agente que o produziu. `result.final_output` é o texto da resposta.

| aula 7 (`minagent`) | Agents SDK |
|---|---|
| `@tool` | `@function_tool` |
| `Agent(model, system, tools)` | `Agent(name, instructions, model, tools)` |
| `agent.run(task)` | `Runner.run_sync(agent, task)` |
| `max_steps` | `max_turns` |
| `Outcome` com `stopped` | `MaxTurnsExceeded` levantada |
| `trace.jsonl` | spans mandados a um processador de rastros |
| um callback `confirm` | `needs_approval` e interrupções |
