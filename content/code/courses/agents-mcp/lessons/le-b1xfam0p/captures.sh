#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset) and the files ana wrote (put below), which the lesson shows
# in full. The failures in the retries section are injected through labllm's
# /lab/config, which ana calls with curl in the transcript itself.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE,
# as rules in lab/scripted/07-*.json, including the id typed without its
# hyphen, the refund it asks for and the tools that do not exist. minagent,
# its tests, the validation, the refusal, the retries made by the anthropic
# SDK, the timings and the token counts are real. Timings vary a little from
# run to run; the ones quoted are this run's.
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
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put minagent.py <<'PY'
"""minagent: an agent loop with nothing hidden, in one file.

    from minagent import Agent, AnthropicModel, tool
"""
import inspect
import json
import time
import typing
from dataclasses import dataclass, field

from jsonschema import Draft202012Validator

# ---------------------------------------------------------------- tools from functions

TYPES = {str: {"type": "string"}, int: {"type": "integer"}, float: {"type": "number"}, bool: {"type": "boolean"}}


def schema_for(annotation):
    """The JSON Schema for one parameter's type hint. A type it does not know is refused, not guessed."""
    if isinstance(annotation, type) and annotation in TYPES:
        return dict(TYPES[annotation])
    origin, args = typing.get_origin(annotation), typing.get_args(annotation)
    if origin is typing.Annotated:
        return {**schema_for(args[0]), **args[1]}
    if origin is typing.Literal:
        return {"enum": list(args)}
    if origin is list and len(args) == 1:
        return {"type": "array", "items": schema_for(args[0])}
    raise TypeError(f"no JSON Schema for {annotation!r}; write this tool's schema by hand")


@dataclass
class Tool:
    name: str
    description: str
    schema: dict
    fn: typing.Callable
    writes: bool = False

    def definition(self):
        return {"name": self.name, "description": self.description, "input_schema": self.schema}


def tool(fn=None, *, writes=False):
    """Turn a typed, documented function into a Tool. Its docstring is what the model reads."""
    def make(f):
        doc = inspect.getdoc(f)
        if not doc:
            raise ValueError(f"{f.__name__} has no docstring, and the docstring is the tool's description")
        hints = typing.get_type_hints(f, include_extras=True)
        props, required = {}, []
        for name, p in inspect.signature(f).parameters.items():
            if name not in hints:
                raise TypeError(f"{f.__name__}: parameter {name!r} has no type hint")
            props[name] = schema_for(hints[name])
            if p.default is inspect.Parameter.empty:
                required.append(name)
        schema = {"type": "object", "properties": props, "required": required, "additionalProperties": False}
        return Tool(f.__name__, doc, schema, f, writes)
    return make(fn) if fn else make


# ---------------------------------------------------------------- the model, behind one method

@dataclass
class Call:
    id: str
    name: str
    args: dict


@dataclass
class Reply:
    text: str
    calls: list
    stop: str
    tokens_in: int
    tokens_out: int
    content: list  # the reply as it goes back into the conversation


class AnthropicModel:
    """The one place that knows a provider's wire. Anything with complete() can stand in for it."""

    def __init__(self, model="scripted-1", max_tokens=1024, max_retries=2):
        import anthropic
        self.client = anthropic.Anthropic(max_retries=max_retries)
        self.model, self.max_tokens = model, max_tokens

    def complete(self, system, messages, tools):
        r = self.client.messages.create(model=self.model, max_tokens=self.max_tokens, system=system,
                                        tools=tools, messages=messages)
        return Reply(text="".join(b.text for b in r.content if b.type == "text"),
                     calls=[Call(b.id, b.name, b.input) for b in r.content if b.type == "tool_use"],
                     stop=r.stop_reason, tokens_in=r.usage.input_tokens, tokens_out=r.usage.output_tokens,
                     content=[b.model_dump(exclude_none=True) for b in r.content])


# ---------------------------------------------------------------- the loop

@dataclass
class Outcome:
    status: str  # "answered" or "stopped"
    answer: str | None
    reason: str | None
    steps: int
    tokens: int
    trace: list = field(repr=False)


class Agent:
    def __init__(self, model, system, tools, max_steps=8, max_tokens=20000, max_seconds=60,
                 confirm=None, trace_path=None):
        self.model, self.system = model, system
        self.tools = {t.name: t for t in tools}
        self.validators = {t.name: Draft202012Validator(t.schema) for t in tools}
        self.max_steps, self.max_tokens, self.max_seconds = max_steps, max_tokens, max_seconds
        self.confirm, self.trace_path = confirm, trace_path

    def run(self, task):
        messages, trace, seen = [{"role": "user", "content": task}], [], set()
        used, started, failing = 0, time.monotonic(), 0
        definitions = [t.definition() for t in self.tools.values()]
        for step in range(1, self.max_steps + 1):
            if used >= self.max_tokens:
                return self.stop(f"token budget: {used} of {self.max_tokens}", step - 1, used, trace)
            if time.monotonic() - started >= self.max_seconds:
                return self.stop(f"time budget: {self.max_seconds} s", step - 1, used, trace)
            if failing >= 3:
                return self.stop("no progress: 3 steps in a row with only errors", step - 1, used, trace)
            t0 = time.monotonic()
            reply = self.model.complete(self.system, messages, definitions)
            used += reply.tokens_in + reply.tokens_out
            record = {"step": step, "stop": reply.stop, "tokens_in": reply.tokens_in,
                      "tokens_out": reply.tokens_out, "model_ms": int((time.monotonic() - t0) * 1000),
                      "text": reply.text, "calls": []}
            messages.append({"role": "assistant", "content": reply.content})
            if not reply.calls:
                self.record(trace, record)
                return Outcome("answered", reply.text, None, step, used, trace)
            results = []
            for call in reply.calls:
                t1 = time.monotonic()
                content, is_error = self.call(call, seen)
                record["calls"].append({"tool": call.name, "args": call.args, "error": is_error,
                                        "ms": int((time.monotonic() - t1) * 1000), "result": content[:120]})
                results.append({"type": "tool_result", "tool_use_id": call.id, "content": content,
                                "is_error": is_error})
            failing = failing + 1 if all(c["error"] for c in record["calls"]) else 0
            self.record(trace, record)
            messages.append({"role": "user", "content": results})
        return self.stop(f"step limit: {self.max_steps}", self.max_steps, used, trace)

    def call(self, call, seen):
        """(content, is_error) for one tool call. Every way it can fail comes back as an error the model reads."""
        t = self.tools.get(call.name)
        if t is None:
            return f"unknown tool {call.name!r}; the tools are {', '.join(self.tools)}", True
        key = (call.name, json.dumps(call.args, sort_keys=True))
        if key in seen:
            return "this exact call was already made in this run; use its result", True
        seen.add(key)
        problems = sorted(self.validators[call.name].iter_errors(call.args), key=lambda e: list(e.path))
        if problems:
            return "invalid arguments: " + "; ".join(
                f"{'/'.join(map(str, p.path)) or 'arguments'}: {p.message}" for p in problems), True
        if t.writes and not (self.confirm and self.confirm(call)):
            return "refused: this tool changes data and needs a person's confirmation", True
        try:
            return json.dumps(t.fn(**call.args), ensure_ascii=False, default=str), False
        except (LookupError, ValueError) as e:
            return f"{type(e).__name__}: {e}", True

    def record(self, trace, record):
        trace.append(record)
        if self.trace_path:
            with open(self.trace_path, "a") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")

    def stop(self, reason, steps, used, trace):
        found = [f"{c['tool']}({json.dumps(c['args'])})" for r in trace for c in r["calls"] if not c["error"]]
        handoff = f"Stopped ({reason}). " + (f"Results so far: {'; '.join(found)}." if found else "Nothing found yet.")
        return Outcome("stopped", None, handoff, steps, used, trace)
PY

put marginalia.py <<'PY'
"""Marginalia's tools for minagent: the functions of shop.py, typed and documented."""
from typing import Annotated, Literal

import shop
from minagent import tool

OrderId = Annotated[str, {"pattern": "^M-[0-9]{4}$"}]
Genre = Literal["adventure", "children", "horror", "literary", "mystery", "non-fiction", "romance",
                "science fiction"]


@tool
def get_order(order_id: OrderId) -> dict:
    """Look up one Marginalia order by its id, M- and four digits, such as M-1042.
    Returns status, dates, lines and amounts in cents."""
    return shop.get_order(order_id)


@tool
def search_help(query: str) -> list:
    """Search Marginalia's help centre by meaning and return the three closest articles."""
    return [{"id": a["id"], "title": a["title"], "body": a["body"]} for a in shop.search_help(query)]


@tool
def find_books(genre: Genre, max_results: Annotated[int, {"minimum": 1, "maximum": 10}] = 3) -> list:
    """List books in stock in one genre, cheapest first, with prices in cents."""
    import json
    books = [shop.get_book(json.loads(line)["id"]) for line in open(shop.DATA / "books.jsonl")]
    stocked = sorted((b for b in books if b["genre"] == genre and b["stock"] > 0), key=lambda b: b["cents"])
    return [{"title": b["title"], "author": b["author"], "cents": b["cents"]} for b in stocked[:max_results]]


@tool(writes=True)
def refund(order_id: OrderId, cents: int, reason: str) -> dict:
    """Refund part or all of an order to the customer's original payment, in cents."""
    return shop.refund(order_id, cents, reason, approved_by="minagent")


TOOLS = [get_order, search_help, find_books, refund]
PY

put run.py <<'PY'
"""Run minagent on one customer message and print the outcome, then the trace."""
import json
import sys

from marginalia import TOOLS
from minagent import Agent, AnthropicModel

SYSTEM = ("You are Marginalia's support agent, built with minagent. Use the tools to find facts, "
          "correct a call when a tool returns an error, and then answer the customer.")

agent = Agent(AnthropicModel(), SYSTEM, TOOLS, max_steps=6, trace_path="trace.jsonl")
outcome = agent.run(sys.argv[1])
print(f"{outcome.status} after {outcome.steps} steps, {outcome.tokens} tokens")
print(outcome.answer or outcome.reason)
for r in outcome.trace:
    calls = ", ".join(f"{c['tool']}{' ERROR' if c['error'] else ''} {c['ms']} ms" for c in r["calls"])
    print(f"  step {r['step']}: model {r['model_ms']} ms, {r['tokens_in']} in / {r['tokens_out']} out"
          + (f"; {calls}" if calls else ""))
PY

put test_minagent.py <<'PY'
"""Tests for minagent that need no model: a fake model replays replies the test writes."""
import pytest

from minagent import Agent, Call, Reply, tool


class FakeModel:
    def __init__(self, *replies):
        self.replies, self.seen = list(replies), []

    def complete(self, system, messages, tools):
        self.seen.append(messages[-1]["content"])
        return self.replies.pop(0)


def asks(*calls):
    return Reply("", [Call(f"c{i}", name, args) for i, (name, args) in enumerate(calls)], "tool_use", 10, 5,
                 [{"type": "tool_use", "id": f"c{i}", "name": n, "input": a} for i, (n, a) in enumerate(calls)])


def says(text):
    return Reply(text, [], "end_turn", 10, 5, [{"type": "text", "text": text}])


@tool
def double(n: int) -> int:
    """Double a number."""
    return n * 2


@tool(writes=True)
def delete_everything(confirm: bool) -> str:
    """Delete everything."""
    return "deleted"


def test_a_typed_function_becomes_a_schema():
    assert double.schema == {"type": "object", "properties": {"n": {"type": "integer"}}, "required": ["n"],
                             "additionalProperties": False}


def test_a_function_with_no_docstring_is_refused():
    with pytest.raises(ValueError, match="no docstring"):
        tool(lambda n: n)


def test_bad_arguments_come_back_as_an_error_and_the_model_can_correct_them():
    model = FakeModel(asks(("double", {"n": "two"})), asks(("double", {"n": 2})), says("4"))
    out = Agent(model, "", [double]).run("double two")
    assert model.seen[1][0]["is_error"] and "'two' is not of type 'integer'" in model.seen[1][0]["content"]
    assert (out.status, out.answer, out.steps) == ("answered", "4", 3)


def test_a_repeated_call_is_refused_with_its_reason():
    model = FakeModel(asks(("double", {"n": 2})), asks(("double", {"n": 2})), says("4"))
    Agent(model, "", [double]).run("double two")
    assert model.seen[2][0]["content"] == "this exact call was already made in this run; use its result"


def test_the_step_limit_stops_the_run_and_says_what_was_found():
    model = FakeModel(*[asks(("double", {"n": n})) for n in range(5)])
    out = Agent(model, "", [double], max_steps=3).run("keep doubling")
    assert out.status == "stopped" and out.reason.startswith("Stopped (step limit: 3).")
    assert 'double({"n": 2})' in out.reason


def test_a_write_without_confirmation_never_runs():
    model = FakeModel(asks(("delete_everything", {"confirm": True})), says("I could not."))
    out = Agent(model, "", [delete_everything]).run("delete it all")
    assert out.trace[0]["calls"][0]["result"].startswith("refused: this tool changes data")


def test_three_steps_of_only_errors_stop_the_run():
    model = FakeModel(*[asks(("nope", {})) for _ in range(5)])
    out = Agent(model, "", [double]).run("call something that does not exist")
    assert out.reason.startswith("Stopped (no progress: 3 steps in a row with only errors)")
PY

block schemas
on 'python -c "import json; from marginalia import get_order, find_books; print(json.dumps(get_order.definition(), indent=1)); print(json.dumps(find_books.schema))"'
on 'python -c "from minagent import tool
@tool
def lookup(filters: dict) -> list:
    \"\"\"Look things up.\"\"\"" 2>&1 | tail -n 1'

block tests
on 'python -m pytest -v test_minagent.py 2>&1 | grep -E "PASSED|FAILED|passed|failed"'

block run-return
on 'python run.py "Can I return the copy of Dracula I bought in September? My order is M1047."'
block run-refund
on 'python run.py "One of the two copies of Dracula in my order M-1047 arrived damaged. Please refund it."'
on 'python -c "import shop; print(shop.get_order(\"M-1047\")[\"refunded\"])"'
block run-stuck
on 'python run.py "Track my parcel for order M-1043, please."'

block trace-file
on 'wc -l trace.jsonl'
on 'tail -n 1 trace.jsonl'

RETURN="Can I return the copy of Dracula I bought in September? My order is M1047."
block retries
on 'curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_next\": 529, \"fail_count\": 2}"; echo'
on "python run.py \"$RETURN\" | head -n 1"
on "tail -n 6 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(*[json.loads(l)[\"status\"] for l in sys.stdin])'"
on 'curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_next\": 529, \"fail_count\": 3}"; echo'
on "python run.py \"$RETURN\" 2>&1 | tail -n 1"
