---
title: Handoffs and agents as tools
version: 1
---

Lesson 6 built both multi-agent shapes by hand. The SDK has both as one-line features: `handoffs=[...]` on an agent, and `agent.as_tool(...)`.

```python
"""Two ways to combine agents in the OpenAI Agents SDK: a handoff, and an agent used as a tool."""
import sys

from agents import Agent, Runner, set_default_openai_api, set_tracing_disabled

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")
set_tracing_disabled(True)

orders = Agent(name="Orders specialist", model="scripted-1", tools=[get_order, search_help],
               instructions="You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orders.",
               handoff_description="Questions about a customer's orders: status, delivery, changes.")

triage = Agent(name="Triage", model="scripted-1", handoffs=[orders],
               instructions="You are the triage agent of the OpenAI Agents SDK lesson. Hand off to the right agent.")

front_desk = Agent(name="Front desk", model="scripted-1",
                   instructions="You are the front desk of the OpenAI Agents SDK lesson. Ask the specialist, then answer.",
                   tools=[orders.as_tool(tool_name="ask_orders",
                                         tool_description="Ask the orders specialist one question about an order.")])

agent = triage if sys.argv[2] == "handoff" else front_desk
result = Runner.run_sync(agent, sys.argv[1])
for item in result.new_items:
    print(f"{item.agent.name:18} {type(item).__name__:20} {str(getattr(item, 'raw_item', ''))[:56]}")
print(f"last agent: {result.last_agent.name}")
print("answer:", result.final_output)
```

**The routing decisions were written by the course**; the handoff machinery, the history it passes and the agent-as-tool wrapper are the SDK's.

## A handoff

```
ana@lab:~/agents$ python oa_team.py "My order M-1046 has not shipped. Why?" handoff
Triage             HandoffCallItem      ResponseFunctionToolCall(arguments='{}', call_id='call_l
Triage             HandoffOutputItem    {'call_id': 'call_lab_0017_1', 'output': '{"assistant": 
Orders specialist  ToolCallItem         ResponseFunctionToolCall(arguments='{"order_id": "M-1046
Orders specialist  ToolCallOutputItem   {'call_id': 'call_lab_0018_1', 'output': "{'id': 'M-1046
Orders specialist  MessageOutputItem    ResponseOutputMessage(id='__fake_id__', content=[Respons
last agent: Orders specialist
answer: Order M-1046 still says Received, so it has not been packed yet. The tracking link comes by email when it ships.
ana@lab:~/agents$ sed -n 2p /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(m["role"], str(m.get("content"))[:90]) for m in json.loads(sys.stdin.read())["request"]["messages"]]'
system You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orders.
user My order M-1046 has not shipped. Why?
assistant None
tool {"assistant": "Orders specialist"}
```

The SDK turned `handoffs=[orders]` into a tool named `transfer_to_orders_specialist`, from the agent's name, and the triage agent called it. The items show the moment control moved: a `HandoffCallItem` and a `HandoffOutputItem` belong to Triage, and every item after them belongs to the Orders specialist, which answered. `result.last_agent` says who finished.

The second command prints the messages of the specialist's first request, which is what crossed the boundary (lesson 6 section 07). The specialist received the customer's message, **plus the triage agent's tool call and its result**, `{"assistant": "Orders specialist"}`. That is the SDK's default: the conversation so far, handoff included. An `input_filter` on the handoff changes what is passed, for instance to drop earlier tool calls; that is the decision lesson 6 said to make in code.

## An agent as a tool

```
ana@lab:~/agents$ python oa_team.py "My order M-1046 has not shipped. Why?" tool
Front desk         ToolCallItem         ResponseFunctionToolCall(arguments='{"input": "What is t
Front desk         ToolCallOutputItem   {'call_id': 'call_lab_0020_1', 'output': 'Order M-1046 s
Front desk         MessageOutputItem    ResponseOutputMessage(id='__fake_id__', content=[Respons
last agent: Front desk
answer: Your order M-1046 has been received and is not packed yet; you will get a tracking link by email when it ships.
```

`orders.as_tool(...)` wrapped the specialist as a tool called `ask_orders` with one string argument, `input`. The front desk called it, the specialist ran its own loop with its own tools, and its final answer came back as the tool's output; the front desk answered the customer. All the items belong to the front desk: the specialist's own steps are inside the tool call, not in the front desk's history, which is lesson 6's boundary again. **Nothing of the specialist's evidence crosses unless you pass it**: the `as_tool` wrapper returns the final output by default, and a custom output extractor can return more.
