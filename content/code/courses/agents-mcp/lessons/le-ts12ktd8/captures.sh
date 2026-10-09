#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset) and the files ana wrote (put below), which the lesson shows
# in full, each checked by lab/shown.py.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, captured on 2026-10-08, reached by the OpenAI Agents SDK
# (openai-agents 0.23.1) through Ollama's Responses API, the SDK's default.
# What the agents decided and wrote is what the model wrote that day. OpenAI's
# hosted products (Agent Builder, ChatKit) need an OpenAI account and are not
# run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null
LAST_TOOL_OUTPUT="python -c 'import json; [print(i[\"output\"][:150]) for r in map(json.loads, open(\"requests.jsonl\")) for i in r[\"request\"][\"input\"][-1:] if i.get(\"type\") == \"function_call_output\"]'"

put oa_tools.py <<'PY'
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
PY

put oa_run.py <<'PY'
"""A first agent with the OpenAI Agents SDK, pointed at Ollama."""
import sys

from agents import Agent, MaxTurnsExceeded, Runner, set_tracing_disabled

from oa_tools import get_order, search_help

set_tracing_disabled(True)                    # traces would go to OpenAI's servers; section 08 keeps them here

support = Agent(
    name="Marginalia support",
    instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.",
    model="llama3.2:3b",
    tools=[get_order, search_help],
)

try:
    result = Runner.run_sync(support, sys.argv[1], max_turns=int(sys.argv[2]) if len(sys.argv) > 2 else 10)
except MaxTurnsExceeded as e:
    print(f"stopped: {e}")
else:
    for item in result.new_items:
        print(f"{type(item).__name__:20} {str(getattr(item, 'raw_item', ''))[:70]}")
    print("answer:", result.final_output)
PY

block first-run
recorder
say 'export OPENAI_BASE_URL=http://127.0.0.1:11435/v1'
on 'python oa_run.py "Where is my order M-1043?"'
block on-the-wire
on "tail -n 1 requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r[\"path\"]); print(json.dumps(r[\"request\"][\"tools\"][0], indent=1)); print([i.get(\"type\", i.get(\"role\")) for i in r[\"request\"][\"input\"]])'"
block max-turns
on 'python oa_run.py "Where is my order M-1043?" 1'

block errors-default
on 'rm requests.jsonl'
on 'python oa_run.py "What happened to my order M-9999?" | tail -n 1'
on 'python oa_run.py "Where is my order 1044?" | tail -n 1'
on "$LAST_TOOL_OUTPUT"

put oa_tools.py <<'PY'
"""Marginalia's tools for the OpenAI Agents SDK: shop.py's functions, decorated."""
from typing import Annotated, Literal

from agents import function_tool
from pydantic import Field

import shop


def say_what_failed(ctx, error):
    """What the model reads when a tool fails: the error itself, not a generic apology."""
    return f"{type(error).__name__}: {error}"


@function_tool(failure_error_function=say_what_failed)
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
PY

block errors-clear
on 'rm requests.jsonl'
on 'python oa_run.py "What happened to my order M-9999?" | tail -n 1'
on 'python oa_run.py "Where is my order 1044?" | tail -n 1'
on "$LAST_TOOL_OUTPUT"

put oa_team.py <<'PY'
"""Two ways to combine agents in the OpenAI Agents SDK: a handoff, and an agent used as a tool."""
import sys

from agents import Agent, Runner, set_tracing_disabled

from oa_tools import get_order, search_help

set_tracing_disabled(True)

orders = Agent(name="Orders specialist", model="llama3.2:3b", tools=[get_order, search_help],
               instructions="You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orders.",
               handoff_description="Questions about a customer's orders: status, delivery, changes.")

triage = Agent(name="Triage", model="llama3.2:3b", handoffs=[orders],
               instructions="You are the triage agent of the OpenAI Agents SDK lesson. Hand off to the right agent.")

front_desk = Agent(name="Front desk", model="llama3.2:3b",
                   instructions="You are the front desk of the OpenAI Agents SDK lesson. Ask the specialist, then answer.",
                   tools=[orders.as_tool(tool_name="ask_orders",
                                         tool_description="Ask the orders specialist one question about an order.")])

agent = triage if sys.argv[2] == "handoff" else front_desk
result = Runner.run_sync(agent, sys.argv[1])
for item in result.new_items:
    print(f"{item.agent.name:18} {type(item).__name__:20} {str(getattr(item, 'raw_item', ''))[:56]}")
print(f"last agent: {result.last_agent.name}")
print("answer:", result.final_output)
PY

block handoff
on 'rm requests.jsonl'
on 'python oa_team.py "My order M-1046 has not shipped. Why?" handoff'
on "sed -n 2p requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read())[\"request\"]; print(\"instructions\", r[\"instructions\"][:80]); [print(i.get(\"role\", i.get(\"type\")), str(i.get(\"content\", i.get(\"output\", i.get(\"arguments\"))))[:80]) for i in r[\"input\"]]'"
block as-tool
on 'python oa_team.py "My order M-1046 has not shipped. Why?" tool'

put oa_guard.py <<'PY'
"""A guardrail on the customer's message, and a person in front of a refund, with the OpenAI Agents SDK."""
import asyncio
import re
import sys

from agents import (Agent, GuardrailFunctionOutput, InputGuardrailTripwireTriggered, Runner, input_guardrail,
                    set_tracing_disabled)

from oa_tools import get_order, refund

set_tracing_disabled(True)
CARD = re.compile(r"\b(?:\d[ -]?){13,19}\b")


def card_check(parallel):
    @input_guardrail(name="no card numbers", run_in_parallel=parallel)
    async def no_card_numbers(ctx, agent, message):
        """Trip if the customer's message contains something shaped like a card number."""
        await asyncio.sleep(0.5)  # stands for a check that calls a model, which takes time
        return GuardrailFunctionOutput(output_info=None, tripwire_triggered=bool(CARD.search(str(message))))
    return no_card_numbers


def agent(parallel=True):
    return Agent(name="Refunds", model="llama3.2:3b", tools=[get_order, refund],
                 input_guardrails=[card_check(parallel)],
                 instructions="You handle refunds in the OpenAI Agents SDK lesson. Look up the order, then refund.")


mode, message = sys.argv[1], sys.argv[2]
if mode in ("parallel", "blocking"):
    try:
        Runner.run_sync(agent(parallel=mode == "parallel"), message)
    except InputGuardrailTripwireTriggered as e:
        print(f"refused by the guardrail {e.guardrail_result.guardrail.get_name()!r}")
else:
    result = Runner.run_sync(agent(), message)
    for pending in result.interruptions:
        print(f"waiting for approval: {pending.name}({pending.arguments})")
        state = result.to_state()
        if mode == "approve":
            state.approve(pending)
        else:
            state.reject(pending, rejection_message="A person declined this refund.")
        result = Runner.run_sync(agent(), state)
    print("answer:", result.final_output)
PY

block approval
on 'python oa_guard.py approve "One copy in my order M-1047 arrived damaged. Please refund 38.90."'
on 'python -c "import shop; print(shop.get_order(\"M-1047\")[\"refunded\"])"'
on 'python oa_guard.py decline "One copy in my order M-1047 arrived damaged. Please refund 38.90."'
block guardrail
on 'rm requests.jsonl'
on 'python oa_guard.py parallel "Refund it to my card 4111 1111 1111 1111 please"'
on 'sleep 20; grep -c 4111 requests.jsonl'
on 'rm requests.jsonl'
on 'python oa_guard.py blocking "Refund it to my card 4111 1111 1111 1111 please"'
on 'sleep 20; grep -c 4111 requests.jsonl'

put oa_session.py <<'PY'
"""Two turns of one conversation, with and without the SDK's session memory."""
import sys

from agents import Agent, Runner, SQLiteSession, set_tracing_disabled

from oa_tools import get_order, search_help

set_tracing_disabled(True)

agent = Agent(name="Support", model="llama3.2:3b", tools=[get_order, search_help],
              instructions="You remember the conversation in the OpenAI Agents SDK lesson. Use the tools.")
session = SQLiteSession("bia", "sessions.db") if sys.argv[1] == "--session" else None
for message in sys.argv[2:]:
    result = Runner.run_sync(agent, message, session=session)
    print(f"> {message}\n< {result.final_output}")
PY

block session
on 'python oa_session.py --none "Where is my order M-1042?" "Can I still return it?"'
on 'python oa_session.py --session "Where is my order M-1042?" "Can I still return it?"'

put oa_trace.py <<'PY'
"""The SDK's tracing, kept on this machine: a processor that prints every span as it ends."""
import sys
from datetime import datetime

from agents import Agent, Runner, set_trace_processors
from agents.tracing import TracingProcessor

from oa_tools import get_order, search_help



class PrintSpans(TracingProcessor):
    def on_trace_start(self, trace):
        print(f"trace {trace.name!r}")

    def on_span_end(self, span):
        data = span.span_data.export()
        label = data.get("name") or data.get("model") or ""
        took = datetime.fromisoformat(span.ended_at) - datetime.fromisoformat(span.started_at)
        ms = int(took.total_seconds() * 1000)
        print(f"  {data['type']:10} {label:22} {ms} ms")

    def on_trace_end(self, trace): pass
    def on_span_start(self, span): pass
    def shutdown(self): pass
    def force_flush(self): pass


set_trace_processors([PrintSpans()])  # replaces the default exporter, which sends traces to OpenAI
agent = Agent(name="Marginalia support", model="llama3.2:3b", tools=[get_order, search_help],
              instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.")
Runner.run_sync(agent, sys.argv[1])
PY

block trace
on 'python oa_trace.py "Where is my order M-1043?"'
