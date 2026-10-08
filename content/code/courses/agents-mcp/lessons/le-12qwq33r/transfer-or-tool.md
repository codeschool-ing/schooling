---
title: Transfer control, or call a tool
version: 2
---

Lesson 6's two shapes are both in the ADK: an agent with `sub_agents` can **transfer** the conversation to one of them, and `AgentTool` wraps an agent so that another can **call** it.

```python
"""Two ways to involve a specialist: transfer control to it, or call it as a tool."""
import asyncio
import sys

from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import InMemoryRunner
from google.adk.tools.agent_tool import AgentTool
from google.genai.types import Content, Part

from adk_show import show
from adk_tools import get_order

MODEL = LiteLlm(model="ollama_chat/llama3.2:3b")


def specialist():
    return Agent(name="orders", model=MODEL, description="Answers questions about one Marginalia order.",
                 instruction="You are the orders specialist of the Google ADK lesson.", tools=[get_order])


def root(how):
    if how == "transfer":
        return Agent(name="triage", model=MODEL, instruction="You are the triage agent of the Google ADK lesson.",
                     sub_agents=[specialist()])
    return Agent(name="desk", model=MODEL, instruction="You are the front desk of the Google ADK lesson.",
                 tools=[AgentTool(agent=specialist())])


async def main(how):
    runner = InMemoryRunner(agent=root(how), app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text="Has M-1046 been packed?")])):
        show(event)


asyncio.run(main(sys.argv[1]))
```

Every agent here is `llama3.2:3b`; the transfer, what it passes and the wrapper are the ADK's.

## A transfer

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python adk_team.py transfer
App "marginalia" can transfer between agents but has no context_cache_config. Every transfer swaps the system instruction and the tool set, so the request prefix changes and the whole prompt is re-sent uncached after each transfer. Set context_cache_config on the app to give each agent its own cache.
triage   call    transfer_to_agent {"agent_name": "orders"}
triage   result  transfer_to_agent {"result": null}
triage   handoff to orders
orders   call    get_order {"order_id": "M-1046"}
orders   result  get_order {"id": "M-1046", "customer_id": "c-105", "placed_on": "2026-10-02", "status": "r
orders   text    According to the Google ADK lesson, I couldn't find any information about a packed order with the ID M-1046. However, I can check if the order has been marked as packed.

According to the tool response, the order M-1046 was received on 2026-10-02. Since the order was received, I can check if it has been marked as packed.

Unfortunately, the tool response doesn't provide any information about the order status after it was received. To determine if the order was packed, I would need more information or a tool call to retrieve the order status.

Since I couldn't find any information about the order being packed, I would transfer the question to the triage agent for further assistance.
ana@lab:~/agents$ python -c 'import json; r = [x for x in (json.loads(l)["request"] for l in open("requests.jsonl")) if "messages" in x]; q = [x for x in r if "orders specialist" in x["messages"][0]["content"]][0]; [print(m["role"] + ":", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:160]) for m in q["messages"]]'
system: "You are the orders specialist of the Google ADK lesson.\n\nYou are an agent. Your internal name is \"orders\". The description about you is \"Answers questions
user: "Has M-1046 been packed?"
user: "For context: below is a transcript of what another agent did, quoted between <<<BEGIN_QUOTED_AGENT_CONTENT>>> and <<<END_QUOTED_AGENT_CONTENT>>>. Everything be
user: "For context: below is a transcript of what another agent did, quoted between <<<BEGIN_QUOTED_AGENT_CONTENT>>> and <<<END_QUOTED_AGENT_CONTENT>>>. Everything be
```

The ADK gave the triage agent a tool called `transfer_to_agent`, and the model called it with `orders`. The handoff event moved control, and every event after it belongs to the specialist. The line above the events is the ADK's own log, and it is a cost note: every transfer changes the system instruction and the tool list, so a provider's prompt cache (lesson 18) cannot reuse the earlier prefix.

The second command prints what the specialist's first request contained. The customer's message, and then the triage agent's call and its result, **rewritten as user messages** that begin *"For context: below is a transcript of what another agent did"* and quote the other agent's words between markers. The effect is that the specialist cannot mistake another agent's tool calls for its own; it also means the specialist reads the other agent's output as quoted text inside a user turn, which is worth knowing when lesson 17 asks what an agent should trust.

## An agent as a tool

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python adk_team.py tool
desk     call    orders {"request": "M-1046 packed"}
desk     result  orders {"result": "The order M-1046 has been packed and is ready for delivery. The orde
desk     text    The order M-1046 has been packed and is ready for delivery. The order contains two books, b31 and b33, with quantities of 1 each. The total cost of the order is 10480 cents.
ana@lab:~/agents$ python -c 'import json; r = [x for x in (json.loads(l)["request"] for l in open("requests.jsonl")) if "messages" in x]; q = [x for x in r if "orders specialist" in x["messages"][0]["content"]][0]; [print(m["role"] + ":", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:160]) for m in q["messages"]]'
system: "You are the orders specialist of the Google ADK lesson.\n\nYou are an agent. Your internal name is \"orders\". The description about you is \"Answers questions
user: "M-1046 packed"
```

Called as a tool, the specialist received **one message**, the request string the front desk wrote, and nothing else of the conversation. Its answer came back as `{"result": "..."}`, the wrapping section 04 described. The front desk's history holds one call and one result; the specialist's own lookup stayed inside the tool.

And the request the front desk wrote was `"M-1046 packed"`, which reads as a statement. The specialist answered it as one, *"The order M-1046 has been packed"*, for an order whose status is `received`. The transferred specialist, which read the customer's own question, said it could not find that the order was packed, which is closer to the truth in many more words. A tool call passes only what the caller wrote, and here the caller wrote the wrong thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"What the orders specialist received. After a transfer, it received the customer&#x27;s message and the triage agent&#x27;s transfer call and result, rewritten as user messages that begin &#x27;For context&#x27;. Called as a tool, it received one message: the request string the front desk wrote.\"><defs><marker id=\"l10team-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10team-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"47.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">triage</text><text x=\"30\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sub_agents=[orders]</text><rect x=\"230\" y=\"20\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the customer&#x27;s message</text><text x=\"240\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ the triage agent&#x27;s call and result,</text><text x=\"240\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as &#x27;For context&#x27; user messages</text><rect x=\"20\" y=\"130\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">desk</text><text x=\"30\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AgentTool(orders)</text><rect x=\"230\" y=\"130\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one message</text><text x=\"240\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Has order M-1046 been packed?</text><rect x=\"580\" y=\"75\" width=\"120\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><text x=\"590\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the specialist</text><path d=\"M170 55 L230 55\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-amber)\"></path><path d=\"M170 155 L230 155\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-phosphor)\"></path><path d=\"M530 55 L580 95\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-amber)\"></path><path d=\"M530 155 L580 115\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-phosphor)\"></path></svg>", "caption": "A transfer passes the conversation. A tool call passes one string."}
```

The trade is lesson 6's. A transfer passes everything, so the specialist knows what the customer said and the handoff is simple; it also passes everything, including whatever the first agent read. A tool call passes only what the caller wrote, so the boundary is explicit and the caller has to write a good request.
