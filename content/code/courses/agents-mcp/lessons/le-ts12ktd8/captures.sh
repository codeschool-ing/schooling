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
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full; and emptying labllm's log before the runs whose requests are counted,
# done as root because the log belongs to the labllm user.
#
# THE MODELS' WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE,
# as rules in lab/scripted/08-*.json, including the id sent without its
# prefix. The OpenAI Agents SDK (openai-agents 0.23.1), what it sent on the
# wire, its error messages, handoffs, agents as tools, approvals, guardrails,
# sessions and spans are real. The SDK talks to labllm through Chat
# Completions, because labllm does not implement the Responses API that the
# SDK uses by default; the lesson says so where it sets it. OpenAI's hosted
# products (Agent Builder, ChatKit) were not reachable and are not run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, with LAB_TODAY=2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
fresh_log() { : > /var/log/labllm/requests.jsonl; }
LAST_TOOL_MESSAGE="python -c 'import json; [print(m[\"content\"][:150]) for r in map(json.loads, open(\"/var/log/labllm/requests.jsonl\")) for m in r[\"request\"][\"messages\"][-1:] if m[\"role\"] == \"tool\"]'"
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

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
"""A first agent with the OpenAI Agents SDK, pointed at the lab's stand-in provider."""
import sys

from agents import Agent, MaxTurnsExceeded, Runner, set_default_openai_api, set_tracing_disabled

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")  # labllm speaks Chat Completions, not the Responses API
set_tracing_disabled(True)                    # traces would go to OpenAI's servers; section 08 keeps them here

support = Agent(
    name="Marginalia support",
    instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.",
    model="scripted-1",
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
fresh_log
on 'python oa_run.py "Where is my order M-1043?"'
block on-the-wire
on "tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(json.dumps(r[\"request\"][\"tools\"][0], indent=1)); print(r[\"request\"][\"messages\"][3][\"content\"][:120])'"
block max-turns
on 'python oa_run.py "Where is my order M-1043?" 2'

block errors-default
fresh_log
on 'python oa_run.py "What happened to my order M-9999?" | tail -n 1'
on 'python oa_run.py "Where is my order 1044?" | tail -n 1'
on "$LAST_TOOL_MESSAGE"

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
fresh_log
on 'python oa_run.py "What happened to my order M-9999?" | tail -n 1'
on 'python oa_run.py "Where is my order 1044?" | tail -n 1'
on "$LAST_TOOL_MESSAGE"

put oa_team.py <<'PY'
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
PY

block handoff
fresh_log
on 'python oa_team.py "My order M-1046 has not shipped. Why?" handoff'
on "sed -n 2p /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(m[\"role\"], str(m.get(\"content\"))[:90]) for m in json.loads(sys.stdin.read())[\"request\"][\"messages\"]]'"
block as-tool
on 'python oa_team.py "My order M-1046 has not shipped. Why?" tool'

put oa_guard.py <<'PY'
"""A guardrail on the customer's message, and a person in front of a refund, with the OpenAI Agents SDK."""
import asyncio
import re
import sys

from agents import (Agent, GuardrailFunctionOutput, InputGuardrailTripwireTriggered, Runner, input_guardrail,
                    set_default_openai_api, set_tracing_disabled)

from oa_tools import get_order, refund

set_default_openai_api("chat_completions")
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
    return Agent(name="Refunds", model="scripted-1", tools=[get_order, refund],
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
fresh_log
on 'python oa_guard.py parallel "Refund it to my card 4111 1111 1111 1111 please"'
on 'grep -c 4111 /var/log/labllm/requests.jsonl'
fresh_log
on 'python oa_guard.py blocking "Refund it to my card 4111 1111 1111 1111 please"'
on 'grep -c 4111 /var/log/labllm/requests.jsonl'

put oa_session.py <<'PY'
"""Two turns of one conversation, with and without the SDK's session memory."""
import sys

from agents import Agent, Runner, SQLiteSession, set_default_openai_api, set_tracing_disabled

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")
set_tracing_disabled(True)

agent = Agent(name="Support", model="scripted-1", tools=[get_order, search_help],
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

from agents import Agent, Runner, set_default_openai_api, set_trace_processors
from agents.tracing import TracingProcessor

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")


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
agent = Agent(name="Marginalia support", model="scripted-1", tools=[get_order, search_help],
              instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.")
Runner.run_sync(agent, sys.argv[1])
PY

block trace
on 'python oa_trace.py "Where is my order M-1043?"'
