---
title: The ADK in one screen
version: 1
---

In the ADK a tool is a **plain Python function**. There is no decorator: the library reads the name, the type hints and the docstring when the function is placed in an agent's `tools`.

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
      "note": "**The model, with the lab's address.** labllm also speaks the Gemini API's format, so the ADK's own Gemini class reaches it unmodified; with a real key you would give only the model's name."
    },
    {
      "code": "def say_what_failed(tool, args, tool_context, error):\n    return {\"error\": f\"{type(error).__name__}: {error}\"}\n\n\ndef agent(how):\n",
      "note": "**Section 05's subject**, attached only in the `caught` mode."
    },
    {
      "code": "    return Agent(name=\"support\", model=MODEL,\n                 instruction=\"You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\",\n                 tools=[get_order, search_help],\n                 on_tool_error_callback=say_what_failed if how == \"caught\" else None)\n\n\nasync def main(how, task):\n",
      "note": "**An agent is configuration**: a name, a model, instructions and tools, the same four pieces as in lessons 7, 8 and 9."
    },
    {
      "code": "    runner = InMemoryRunner(agent=agent(how), app_name=\"marginalia\")\n",
      "note": "**The runner owns the loop and the sessions.** `InMemoryRunner` keeps sessions in memory, so they are gone when the process ends."
    },
    {
      "code": "    session = await runner.session_service.create_session(app_name=\"marginalia\", user_id=\"bia\")\n",
      "note": "**Every run belongs to a session**, created first, for a user."
    },
    {
      "code": "    config = RunConfig(max_llm_calls=1 if how == \"one-call\" else 500)\n    try:\n",
      "note": "**The limit on model calls**: 500 is the library's default, 1 is section 05's."
    },
    {
      "code": "        async for event in runner.run_async(user_id=\"bia\", session_id=session.id, run_config=config,\n                                            new_message=Content(role=\"user\", parts=[Part(text=task)])):\n            show(event)\n    except Exception as e:\n        print(f\"raised   {type(e).__name__}: {e}\")\n\n\nasyncio.run(main(sys.argv[1], sys.argv[2]))",
      "note": "**The loop yields events**, each one written by an agent."
    }
  ]
}
```

`adk_show.py` prints each event on one line:

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

**The model's call and answer were written by the course**; the events are the ADK's. Each event has an **author**, the agent that produced it, and content made of parts: a function call, a function response, or text. The function response is attributed to the agent as well, because the ADK ran the tool on its behalf. The same events are what the session stores, so the history of a conversation is the list of events, not a list of chat messages.
