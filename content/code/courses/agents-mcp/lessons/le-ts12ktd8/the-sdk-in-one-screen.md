---
title: The Agents SDK in one screen
version: 2
---

The OpenAI Agents SDK (`openai-agents` on PyPI, imported as `agents`; lesson 1 pins 0.23.1) has three objects you meet first: **`Agent`**, which is configuration (a name, instructions, a model, tools); **`Runner`**, which runs the loop; and **`function_tool`**, which turns a Python function into a tool. Lesson 7 wrote the same three as `Agent`, `Agent.run` and `@tool`.

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

The decorator reads the type hints and the docstring, like lesson 7's. Pydantic's `Field(pattern=...)` inside `Annotated` adds the pattern; `needs_approval=True` on `refund` is section 07's subject.

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
      "note": "**Four names from the SDK**, and an exception for the step limit."
    },
    {
      "code": "set_tracing_disabled(True)                    # traces would go to OpenAI's servers; section 08 keeps them here\n\n",
      "note": "**Tracing is on by default and sends spans to OpenAI's servers.** Here there is nowhere to send them; section 10 keeps them on the machine instead."
    },
    {
      "code": "support = Agent(\n    name=\"Marginalia support\",\n    instructions=\"You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.\",\n    model=\"llama3.2:3b\",\n    tools=[get_order, search_help],\n)\n\ntry:\n",
      "note": "**An agent is configuration**: name, instructions, model, tools."
    },
    {
      "code": "    result = Runner.run_sync(support, sys.argv[1], max_turns=int(sys.argv[2]) if len(sys.argv) > 2 else 10)\n",
      "note": "**The loop.** `max_turns` is the step limit, 10 if not given."
    },
    {
      "code": "except MaxTurnsExceeded as e:\n    print(f\"stopped: {e}\")\nelse:\n",
      "note": "**Hitting the limit raises**, rather than returning a stopped outcome."
    },
    {
      "code": "    for item in result.new_items:\n        print(f\"{type(item).__name__:20} {str(getattr(item, 'raw_item', ''))[:70]}\")\n    print(\"answer:\", result.final_output)",
      "note": "**What happened, as typed items**: tool calls, their outputs, messages."
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

The recorder from lesson 1 sits in front of Ollama for the whole lesson, and `OPENAI_BASE_URL` points the SDK at it. The SDK speaks OpenAI's newer **Responses API** by default, and Ollama answers that one too, so nothing in the program had to change for a local model. The run is lesson 1's agent, as `llama3.2:3b` runs it: a lookup and an answer. What the SDK adds is visible in the items: a `ToolCallItem` for the call, a `ToolCallOutputItem` for its result and a `MessageOutputItem` for the answer, each tied to the agent that produced it. `result.final_output` is the answer's text, and it reports the total in cents, `11070 cents`, because that is what the result said.

| lesson 7 (`minagent`) | Agents SDK |
|---|---|
| `@tool` | `@function_tool` |
| `Agent(model, system, tools)` | `Agent(name, instructions, model, tools)` |
| `agent.run(task)` | `Runner.run_sync(agent, task)` |
| `max_steps` | `max_turns` |
| `Outcome` with `stopped` | `MaxTurnsExceeded` raised |
| `trace.jsonl` | spans sent to a trace processor |
| a `confirm` callback | `needs_approval` and interruptions |
