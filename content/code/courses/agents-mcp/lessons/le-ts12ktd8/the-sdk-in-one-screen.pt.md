---
title: O Agents SDK numa tela
version: 2
---

O OpenAI Agents SDK (`openai-agents` no PyPI, importado como `agents`; a aula 1 fixa a 0.23.1) tem três objetos que você encontra primeiro: **`Agent`**, que é configuração (um nome, instruções, um modelo, ferramentas); **`Runner`**, que roda o laço; e **`function_tool`**, que transforma uma função Python numa ferramenta. A aula 7 escreveu os mesmos três como `Agent`, `Agent.run` e `@tool`.

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
      "code": "\"\"\"A first agent with the OpenAI Agents SDK, pointed at Ollama.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "from agents import Agent, MaxTurnsExceeded, Runner, set_tracing_disabled\n\nfrom oa_tools import get_order, search_help\n\n",
      "note": "**Quatro nomes do SDK**, e uma exceção para o limite de passos."
    },
    {
      "code": "set_tracing_disabled(True)                    # traces would go to OpenAI's servers; section 08 keeps them here\n\n",
      "note": "**O rastreamento vem ligado e manda spans para os servidores da OpenAI.** Aqui não há para onde mandá-los; a seção 10 os mantém na máquina."
    },
    {
      "code": "support = Agent(\n    name=\"Marginalia support\",\n    instructions=\"You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.\",\n    model=\"llama3.2:3b\",\n    tools=[get_order, search_help],\n)\n\ntry:\n",
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
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export OPENAI_BASE_URL=http://127.0.0.1:11435/v1
ana@lab:~/agents$ python oa_run.py "Where is my order M-1043?"
ToolCallItem         ResponseFunctionToolCall(arguments='{"order_id":"M-1043"}', call_id='c
ToolCallOutputItem   {'call_id': 'call_stnqmgl7', 'output': "{'id': 'M-1043', 'customer_id'
MessageOutputItem    ResponseOutputMessage(id='msg_499255', content=[ResponseOutputText(ann
answer: Your order M-1043 has been shipped and has a tracking number BR5512340003. The order was placed on 2026-09-28 and contains the books b13, b14, and b26. The total cost of the order is 11070 cents. You can use the tracking number to track the status of your order. If you have any further questions or concerns, please don't hesitate to reach out.
```

O gravador da aula 1 fica na frente do Ollama durante a aula inteira, e `OPENAI_BASE_URL` aponta o SDK para ele. Por padrão o SDK fala a **Responses API**, a API mais nova da OpenAI, e o Ollama também responde a ela, então nada no programa precisou mudar para um modelo local. A execução é o agente da aula 1, do jeito que o `llama3.2:3b` o roda: uma consulta e uma resposta. O que o SDK acrescenta aparece nos itens: um `ToolCallItem` para a chamada, um `ToolCallOutputItem` para o resultado dela e um `MessageOutputItem` para a resposta, cada um ligado ao agente que o produziu. `result.final_output` é o texto da resposta, e ele informa o total em centavos, `11070 cents`, porque é isso que o resultado dizia.

| aula 7 (`minagent`) | Agents SDK |
|---|---|
| `@tool` | `@function_tool` |
| `Agent(model, system, tools)` | `Agent(name, instructions, model, tools)` |
| `agent.run(task)` | `Runner.run_sync(agent, task)` |
| `max_steps` | `max_turns` |
| `Outcome` com `stopped` | `MaxTurnsExceeded` levantada |
| `trace.jsonl` | spans mandados a um processador de rastros |
| um callback `confirm` | `needs_approval` e interrupções |
