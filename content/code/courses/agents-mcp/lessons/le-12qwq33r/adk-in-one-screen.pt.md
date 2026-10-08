---
title: O ADK numa tela
version: 1
---

No ADK uma ferramenta é uma **função Python simples**. Não há decorador: a biblioteca lê o nome, as anotações de tipo e a docstring quando a função entra nas `tools` de um agente.

```python
"""Marginalia's tools for the Google ADK: plain functions, read by their type hints and docstrings."""
import shop


def get_order(order_id: str) -> dict:
    """Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."""
    return shop.get_order(order_id)


def search_help(query: str) -> list[dict]:
    """Search Marginalia's help centre by meaning and return the three closest articles."""
    return [{"title": a["title"], "body": a["body"]} for a in shop.search_help(query)]


def refund(order_id: str, cents: int, reason: str) -> dict:
    """Refund part or all of an order to the customer's original payment, in cents."""
    return shop.refund(order_id, cents, reason, approved_by="ana")
```

```schooling-example
{
  "language": "python",
  "file": "adk_run.py",
  "parts": [
    {
      "code": "\"\"\"A first agent with the Google ADK, pointed at Ollama through LiteLLM.\"\"\"\nimport asyncio\nimport sys\n\nfrom google.adk.agents import Agent\nfrom google.adk.agents.run_config import RunConfig\nfrom google.adk.models.lite_llm import LiteLlm\nfrom google.adk.runners import InMemoryRunner\nfrom google.genai.types import Content, Part\n\nfrom adk_show import show\nfrom adk_tools import get_order, search_help\n\n"
    },
    {
      "code": "MODEL = LiteLlm(model=\"ollama_chat/llama3.2:3b\")  # ADK reaches Ollama through LiteLLM\n\n\n",
      "note": "**O modelo, com o endereço do laboratório.** O labllm também fala o formato da API do Gemini, então a própria classe Gemini do ADK chega até ele sem modificação; com uma chave real você daria só o nome do modelo."
    },
    {
      "code": "def say_what_failed(tool, args, tool_context, error):\n    return {\"error\": f\"{type(error).__name__}: {error}\"}\n\n\ndef agent(how):\n",
      "note": "**O assunto da seção 05**, preso só no modo `caught`."
    },
    {
      "code": "    return Agent(name=\"support\", model=MODEL,\n                 instruction=\"You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\",\n                 tools=[get_order, search_help],\n                 on_tool_error_callback=say_what_failed if how == \"caught\" else None)\n\n\nasync def main(how, task):\n",
      "note": "**Um agente é configuração**: um nome, um modelo, instruções e ferramentas, as mesmas quatro peças das aulas 7, 8 e 9."
    },
    {
      "code": "    runner = InMemoryRunner(agent=agent(how), app_name=\"marginalia\")\n",
      "note": "**O runner é dono do laço e das sessões.** O `InMemoryRunner` guarda as sessões na memória, então elas somem quando o processo termina."
    },
    {
      "code": "    session = await runner.session_service.create_session(app_name=\"marginalia\", user_id=\"bia\")\n",
      "note": "**Toda execução pertence a uma sessão**, criada antes, para um usuário."
    },
    {
      "code": "    config = RunConfig(max_llm_calls=1 if how == \"one-call\" else 500)\n    try:\n",
      "note": "**O limite de chamadas ao modelo**: 500 é o padrão da biblioteca, 1 é o da seção 05."
    },
    {
      "code": "        async for event in runner.run_async(user_id=\"bia\", session_id=session.id, run_config=config,\n                                            new_message=Content(role=\"user\", parts=[Part(text=task)])):\n            show(event)\n    except Exception as e:\n        print(f\"raised   {type(e).__name__}: {e}\")\n\n\nasyncio.run(main(sys.argv[1], sys.argv[2]))",
      "note": "**O laço produz eventos**, cada um escrito por um agente."
    }
  ]
}
```

O `adk_show.py` imprime cada evento numa linha:

```python
"""Print ADK's events one line per part, shortened for reading."""
import json


def show(event):
    for part in event.content.parts if event.content else []:
        if part.function_call:
            args = json.dumps(part.function_call.args, ensure_ascii=False)
            print(f"{event.author:8} call    {part.function_call.name} {args[:80]}")
        elif part.function_response:
            body = json.dumps(part.function_response.response, ensure_ascii=False)
            print(f"{event.author:8} result  {part.function_response.name} {body[:80]}")
        elif part.text:
            print(f"{event.author:8} text    {part.text}")
    if getattr(event, "output", None) is not None:
        print(f"{event.author:8} output  {event.output}")
    if event.actions.state_delta:
        print(f"{event.author:8} state   {event.actions.state_delta}")
    if event.actions.transfer_to_agent:
        print(f"{event.author:8} handoff to {event.actions.transfer_to_agent}")
```

```
ana@lab:~/agents$ python adk_run.py default "Where is my order M-1043?"
support  call    get_order {"order_id": "M-1043"}
support  result  get_order {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "s
support  text    Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
```

**A chamada e a resposta do modelo foram escritas pelo curso**; os eventos são do ADK. Cada evento tem um **autor**, o agente que o produziu, e um conteúdo feito de partes: uma chamada de função, uma resposta de função, ou texto. A resposta de função também é atribuída ao agente, porque o ADK rodou a ferramenta em nome dele. Os mesmos eventos são o que a sessão guarda, então o histórico de uma conversa é a lista de eventos, não uma lista de mensagens de chat.
