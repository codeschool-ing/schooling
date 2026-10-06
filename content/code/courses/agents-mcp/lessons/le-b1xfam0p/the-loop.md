---
title: The loop, with its guards
version: 1
---

`Agent.run` is lesson 1's loop with lesson 5's budget and the bookkeeping a real run needs. Read it against the earlier versions: nothing in it is new, and everything is in one place.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "# ---------------------------------------------------------------- the loop\n\n@dataclass\n"
    },
    {
      "code": "class Outcome:\n    status: str  # \"answered\" or \"stopped\"\n    answer: str | None\n    reason: str | None\n    steps: int\n    tokens: int\n    trace: list = field(repr=False)\n\n\n",
      "note": "**Every run ends in one of these**: answered or stopped, the answer or the reason, the steps, the tokens and the trace."
    },
    {
      "code": "class Agent:\n    def __init__(self, model, system, tools, max_steps=8, max_tokens=20000, max_seconds=60,\n                 confirm=None, trace_path=None):\n        self.model, self.system = model, system\n        self.tools = {t.name: t for t in tools}\n",
      "note": "**The agent is configuration**: a model, a system prompt, tools, three limits, a confirmation callback and a trace file. Nothing in it changes during a run except the conversation."
    },
    {
      "code": "        self.validators = {t.name: Draft202012Validator(t.schema) for t in tools}\n        self.max_steps, self.max_tokens, self.max_seconds = max_steps, max_tokens, max_seconds\n        self.confirm, self.trace_path = confirm, trace_path\n\n",
      "note": "**Validators are built once per tool**, not once per call."
    },
    {
      "code": "    def run(self, task):\n        messages, trace, seen = [{\"role\": \"user\", \"content\": task}], [], set()\n        used, started, failing = 0, time.monotonic(), 0\n        definitions = [t.definition() for t in self.tools.values()]\n        for step in range(1, self.max_steps + 1):\n",
      "note": "**The state of a run is local**: the conversation, the trace, the calls already made, the tokens used, the clock, and a count of failing steps."
    },
    {
      "code": "            if used >= self.max_tokens:\n                return self.stop(f\"token budget: {used} of {self.max_tokens}\", step - 1, used, trace)\n            if time.monotonic() - started >= self.max_seconds:\n                return self.stop(f\"time budget: {self.max_seconds} s\", step - 1, used, trace)\n",
      "note": "**The three limits, checked before every request**, so a run overshoots by one step at most (lesson 5)."
    },
    {
      "code": "            if failing >= 3:\n                return self.stop(\"no progress: 3 steps in a row with only errors\", step - 1, used, trace)\n",
      "note": "**A fourth stop: no progress.** Three steps in a row in which every call failed means the model is stuck, whatever the step limit says."
    },
    {
      "code": "            t0 = time.monotonic()\n            reply = self.model.complete(self.system, messages, definitions)\n            used += reply.tokens_in + reply.tokens_out\n            record = {\"step\": step, \"stop\": reply.stop, \"tokens_in\": reply.tokens_in,\n                      \"tokens_out\": reply.tokens_out, \"model_ms\": int((time.monotonic() - t0) * 1000),\n                      \"text\": reply.text, \"calls\": []}\n            messages.append({\"role\": \"assistant\", \"content\": reply.content})\n",
      "note": "**Each step is timed**, and the record of it starts here."
    },
    {
      "code": "            if not reply.calls:\n                self.record(trace, record)\n                return Outcome(\"answered\", reply.text, None, step, used, trace)\n            results = []\n",
      "note": "**No tool call means an answer.** `minagent` keeps lesson 1's convention rather than lesson 5's `finish` tool, to stay small; adding `finish` is a tool and an `if`."
    },
    {
      "code": "            for call in reply.calls:\n                t1 = time.monotonic()\n                content, is_error = self.call(call, seen)\n                record[\"calls\"].append({\"tool\": call.name, \"args\": call.args, \"error\": is_error,\n                                        \"ms\": int((time.monotonic() - t1) * 1000), \"result\": content[:120]})\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": call.id, \"content\": content,\n                                \"is_error\": is_error})\n",
      "note": "**Every call goes through `call`**, which never raises for a failure the model could fix. Each one is timed and recorded."
    },
    {
      "code": "            failing = failing + 1 if all(c[\"error\"] for c in record[\"calls\"]) else 0\n            self.record(trace, record)\n            messages.append({\"role\": \"user\", \"content\": results})\n        return self.stop(f\"step limit: {self.max_steps}\", self.max_steps, used, trace)\n",
      "note": "**The progress counter** resets the moment any call in a step succeeds."
    }
  ]
}
```

## Where each lesson went

| lesson | idea | in `run` |
|---|---|---|
| 1 | the conversation is the state; the loop sends it all each time | `messages`, appended twice per step |
| 3 | log every step; guard against repeats | `record`, `seen` |
| 4 | validate before running; errors are results | `self.validators`, `call` |
| 5 | budgets checked before the request; say why you stopped | the three `if`s at the top, `stop` |
| 6 | an agent is a loop with its own tools and prompt | `Agent` is that loop as an object, so an orchestrator can hold several |

Lesson 6's multi-agent designs drop straight onto this. A specialist is an `Agent`; asking it is a `@tool` whose function calls `specialist.run(question)` and returns the answer, or the answer and the trace's results as evidence.
