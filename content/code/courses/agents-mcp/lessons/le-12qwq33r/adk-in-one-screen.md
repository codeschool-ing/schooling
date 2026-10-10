---
title: The ADK in one screen
version: 2
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
    try:
        return shop.refund(order_id, int(cents), reason, approved_by="ana")  # the hint is not a check: "0" arrives as a string
    except ValueError as e:
        return {"error": str(e)}  # the model reads why, and the run goes on
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
      "note": "**The model, through LiteLLM.** The ADK speaks Gemini's API itself and hands any other model to LiteLLM, which here talks to Ollama's own API at the address in `OLLAMA_API_BASE`. With a Gemini key you would give the model's name instead."
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
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export OLLAMA_API_BASE=http://127.0.0.1:11435 LITELLM_LOCAL_MODEL_COST_MAP=True
ana@lab:~/agents$ python adk_run.py default "Where is my order M-1043?"
support  call    get_order {"order_id": "M-1043"}
support  result  get_order {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "s
support  text    Your order M-1043 was placed on 2026-09-28 and has been shipped. The tracking number is BR5512340003. You can track the status of your order by visiting the website of the shipping carrier mentioned in the tracking number. Your order includes items with order numbers b13, b14, and b26, totaling 11070 cents.
```

The model is `llama3.2:3b`, reached through the recorder of lesson 1, and the events are the ADK's. `LITELLM_LOCAL_MODEL_COST_MAP=True` is there because LiteLLM, when imported, fetches a table of model prices from GitHub; with the variable it uses the copy it ships with, and a program that never meant to reach the internet does not. Each event has an **author**, the agent that produced it, and content made of parts: a function call, a function response, or text. The function response is attributed to the agent as well, because the ADK ran the tool on its behalf. The same events are what the session stores, so the history of a conversation is the list of events, not a list of chat messages.
