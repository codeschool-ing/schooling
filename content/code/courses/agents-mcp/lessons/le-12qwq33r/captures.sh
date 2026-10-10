#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full, each checked by lab/shown.py; and the answers a person typed at the
# approval prompts, fed on standard input.
#
# PYTHONWARNINGS=ignore::UserWarning is set for every command except the
# first refund run: ADK announces each feature it marks experimental with a
# Python warning on every run, and the lesson shows those warnings once,
# there, and says so.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, captured on 2026-10-08, reached by Google's Agent
# Development Kit (google-adk 2.11.0) through LiteLLM (litellm 1.83.0) and
# Ollama's own /api/chat. What the agents decided and wrote is what the model
# wrote that day. Nothing was deployed: Agent Engine and Cloud Run need a
# Google Cloud project, and the Gemini API needs a Google account.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$SHELL_STATE export PYTHONWARNINGS=ignore::UserWarning; $*" < /dev/null 2>&1 || true; }
loud() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$SHELL_STATE $*" < /dev/null 2>&1 || true; }
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put adk_tools.py <<'PY'
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
PY

put adk_show.py <<'PY'
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
PY

put adk_run.py <<'PY'
"""A first agent with the Google ADK, pointed at Ollama through LiteLLM."""
import asyncio
import sys

from google.adk.agents import Agent
from google.adk.agents.run_config import RunConfig
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import InMemoryRunner
from google.genai.types import Content, Part

from adk_show import show
from adk_tools import get_order, search_help

MODEL = LiteLlm(model="ollama_chat/llama3.2:3b")  # ADK reaches Ollama through LiteLLM


def say_what_failed(tool, args, tool_context, error):
    return {"error": f"{type(error).__name__}: {error}"}


def agent(how):
    return Agent(name="support", model=MODEL,
                 instruction="You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.",
                 tools=[get_order, search_help],
                 on_tool_error_callback=say_what_failed if how == "caught" else None)


async def main(how, task):
    runner = InMemoryRunner(agent=agent(how), app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    config = RunConfig(max_llm_calls=1 if how == "one-call" else 500)
    try:
        async for event in runner.run_async(user_id="bia", session_id=session.id, run_config=config,
                                            new_message=Content(role="user", parts=[Part(text=task)])):
            show(event)
    except Exception as e:
        print(f"raised   {type(e).__name__}: {e}")


asyncio.run(main(sys.argv[1], sys.argv[2]))
PY

put wire.py <<'PY'
"""What each request in the recorder's log carried, in the format of Ollama's own API."""
import json

for n, line in enumerate(open("requests.jsonl"), 1):
    r = json.loads(line)
    q = r["request"]
    print(f"request {n}: {r['path']}")
    for tool in q.get("tools", []):
        f = tool["function"]
        print(f"  tool {f['name']}:", json.dumps(f["parameters"]))
    for m in q.get("messages", []):   # LiteLLM's first request, /api/show, asks about the model and carries none
        print(f"  {m['role']}:", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:150])
PY

put adk_refund.py <<'PY'
"""A refund that needs a person's confirmation, and a callback that refuses large ones first."""
import asyncio
import sys

from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import InMemoryRunner
from google.adk.tools import FunctionTool
from google.genai.types import Content, FunctionResponse, Part

from adk_show import show
from adk_tools import get_order, refund

MODEL = LiteLlm(model="ollama_chat/llama3.2:3b")
LIMIT = 5000  # cents; above this a refund is refused in code and no person is asked


def limit_refunds(tool, args, tool_context):
    if tool.name != "refund":
        return None                                                      # None: carry on
    try:
        cents = int(args["cents"])   # the model's arguments arrive unchecked: "7780", or not a number at all
    except (KeyError, ValueError):
        return {"error": "cents must be a whole number of cents"}        # returned instead of running the tool
    if cents > LIMIT:
        return {"error": f"Refunds above {LIMIT} cents need a manager."}
    return None


agent = Agent(name="refunds", model=MODEL,
              instruction="You handle refunds in the Google ADK lesson.",
              tools=[get_order, FunctionTool(refund, require_confirmation=True)],
              before_tool_callback=limit_refunds)


async def run(runner, session, message):
    """One run of the agent; returns the confirmation it stopped to wait for, if any."""
    waiting = None
    async for event in runner.run_async(user_id="bia", session_id=session.id, new_message=message):
        show(event)
        for part in event.content.parts if event.content else []:
            if part.function_call and part.function_call.name == "adk_request_confirmation":
                waiting = part.function_call
    return waiting


async def main(task):
    runner = InMemoryRunner(agent=agent, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    waiting = await run(runner, session, Content(role="user", parts=[Part(text=task)]))
    while waiting:
        call = waiting.args["originalFunctionCall"]
        print(f"approve? {call['name']} {call['args']} [y/n] ", end="", flush=True)
        answer = sys.stdin.readline().strip()
        print(answer)
        reply = FunctionResponse(id=waiting.id, name="adk_request_confirmation", response={"confirmed": answer == "y"})
        waiting = await run(runner, session, Content(role="user", parts=[Part(function_response=reply)]))


asyncio.run(main(sys.argv[1]))
PY

put adk_team.py <<'PY'
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
PY

put adk_pipeline.py <<'PY'
"""A fixed two-step workflow: plain code finds the facts, then an agent writes the reply from them."""
import asyncio
import json
import re

from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import InMemoryRunner
from google.adk.workflow import START, Workflow
from google.genai.types import Content, Part

import shop
from adk_show import show

MODEL = LiteLlm(model="ollama_chat/llama3.2:3b")


def find_facts(node_input: str) -> str:
    """No model: the order id is a pattern, and the facts are a lookup."""
    order = shop.get_order(re.search(r"M-[0-9]{4}", node_input).group(0))
    return json.dumps({k: order[k] for k in ("id", "status", "delivered_on")})


writer = Agent(name="writer", model=MODEL,
               instruction="You write the customer's reply in the Google ADK lesson, from the facts you are given.")
pipeline = Workflow(name="pipeline", edges=[(START, find_facts, writer)])


async def main():
    runner = InMemoryRunner(agent=pipeline, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text="When was M-1042 delivered?")])):
        show(event)


asyncio.run(main())
PY

SPECIALIST_SAW="python -c 'import json; r = [x for x in (json.loads(l)[\"request\"] for l in open(\"requests.jsonl\")) if \"messages\" in x]; q = [x for x in r if \"orders specialist\" in x[\"messages\"][0][\"content\"]][0]; [print(m[\"role\"] + \":\", json.dumps(m.get(\"content\") or m.get(\"tool_calls\"), ensure_ascii=False)[:160]) for m in q[\"messages\"]]'"

block deploy-help
on 'adk deploy --help'

block first-run
recorder
say 'export OLLAMA_API_BASE=http://127.0.0.1:11435 LITELLM_LOCAL_MODEL_COST_MAP=True'
on 'python adk_run.py default "Where is my order M-1043?"'

block first-wire
on 'python wire.py'

block missing
on 'python adk_run.py default "Where is my order M-9999?" 2> stderr.txt; wc -l < stderr.txt; tail -1 stderr.txt'

block caught
on 'python adk_run.py caught "Where is my order M-9999?"'

block one-call
on 'python adk_run.py one-call "Where is my order M-1043?" 2> stderr.txt; wc -l < stderr.txt'

block confirm-no
on 'rm -f requests.jsonl'
loud 'echo n | python adk_refund.py "One copy of M-1047 arrived damaged; please refund it."'
on 'wc -l < requests.jsonl'

block confirm-yes
on 'echo y | python adk_refund.py "One copy of M-1047 arrived damaged; please refund it."'
on "python -c 'import sqlite3; print(sqlite3.connect(\"data/shop.db\").execute(\"SELECT order_id, cents, approved_by FROM refunds\").fetchall())'"

block limit
on 'echo y | python adk_refund.py "Please refund the whole order M-1047."'

block transfer
on 'rm -f requests.jsonl'
on 'python adk_team.py transfer'
on "$SPECIALIST_SAW"

block as-tool
on 'rm -f requests.jsonl'
on 'python adk_team.py tool'
on "$SPECIALIST_SAW"

block sequential
on "python -c 'from google.adk.agents import SequentialAgent; SequentialAgent(name=\"pipeline\", sub_agents=[])'"

block pipeline
on 'rm -f requests.jsonl'
on 'python adk_pipeline.py 2> /dev/null'
on "python -c 'import json; [print(m[\"role\"] + \":\", json.dumps(m.get(\"content\"), ensure_ascii=False)[:200]) for l in open(\"requests.jsonl\") for m in json.loads(l)[\"request\"].get(\"messages\", [])]'"
