---
title: A plan the host can read
version: 2
---

This lesson's `agent.py` adds two tools to lesson 4's: `update_plan`, which takes the whole list of steps with a status for each, and `finish`, which takes the final answer and the tool calls it rests on. It also runs every request inside a budget, which section 04 explains. The model is `llama3.2:3b` first, and then the stand-in from lesson 3, for a reason the first run makes plain.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"An agent that keeps a written plan, answers through finish, and runs inside a budget set by the host.\"\"\"\nimport argparse\nimport json\nimport time\n\nimport anthropic\n\nfrom jsonschema import Draft202012Validator\n\nfrom tools import TOOLS as SHOP_TOOLS, run_tool\n\n"
    },
    {
      "code": "PLAN_TOOLS = [\n    {\"name\": \"update_plan\",\n     \"description\": \"Write or rewrite your plan: the whole list of steps, each with a status.\",\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"steps\"],\n                      \"properties\": {\"steps\": {\"type\": \"array\", \"minItems\": 1, \"maxItems\": 8, \"items\": {\n                          \"type\": \"object\", \"additionalProperties\": False, \"required\": [\"step\", \"status\"],\n                          \"properties\": {\"step\": {\"type\": \"string\"},\n                                         \"status\": {\"enum\": [\"todo\", \"done\", \"dropped\"]}}}}}}},\n",
      "note": "**The plan as a schema**: up to eight steps, each `todo`, `done` or `dropped`. Nothing else is a valid status, so a plan is always readable by code."
    },
    {
      "code": "    {\"name\": \"finish\",\n     \"description\": \"Give the final answer to the customer, and list the tool calls it rests on.\",\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"answer\", \"sources\"],\n                      \"properties\": {\"answer\": {\"type\": \"string\", \"minLength\": 1},\n                                     \"sources\": {\"type\": \"array\", \"items\": {\"type\": \"string\"}}}}},\n]\n",
      "note": "**The answer as a tool call.** The run ends when the model calls this, with an answer and its sources, not when it happens to stop writing."
    },
    {
      "code": "TOOLS = [t for t in SHOP_TOOLS if t[\"name\"] != \"issue_refund\"] + PLAN_TOOLS\nCHECK = {t[\"name\"]: Draft202012Validator(t[\"input_schema\"]) for t in PLAN_TOOLS}\n",
      "note": "**Lesson 4's tools minus `issue_refund`**, plus the two above. An agent is given only what its task needs."
    },
    {
      "code": "SYSTEM = (\"You are Marginalia's support agent. Keep a plan with update_plan before you start and whenever \"\n          \"it changes. Use the tools to find facts. When you know the answer, call finish.\")\nMARKS = {\"todo\": \" \", \"done\": \"x\", \"dropped\": \"-\"}\n\n\n",
      "note": "**The instruction to plan**: before starting, and whenever the plan changes."
    },
    {
      "code": "def stopped(reason, plan):\n    \"\"\"A run that did not finish still returns something a person can pick up.\"\"\"\n    done = [s[\"step\"] for s in plan if s[\"status\"] == \"done\"]\n    todo = [s[\"step\"] for s in plan if s[\"status\"] == \"todo\"]\n    return {\"status\": \"stopped\", \"reason\": reason, \"done\": done, \"not_done\": todo,\n            \"handoff\": \"Passed to a person. \" + (f\"Done: {'; '.join(done)}. \" if done else \"\")\n                       + (f\"Not done: {'; '.join(todo)}.\" if todo else \"No plan was written.\")}\n\n\n",
      "note": "**What a run that did not finish returns**: what was done, what was not, and a sentence for a person. Section 06."
    },
    {
      "code": "def run(task, max_steps, max_tokens, max_seconds):\n    client = anthropic.Anthropic()\n    messages = [{\"role\": \"user\", \"content\": task}]\n    plan, used, started = [], 0, time.monotonic()\n    for step in range(1, max_steps + 1):\n",
      "note": "**The budget's three counters**: steps, tokens and seconds."
    },
    {
      "code": "        if used >= max_tokens:\n            return stopped(f\"token budget: {used} of {max_tokens} used\", plan)\n        if time.monotonic() - started >= max_seconds:\n            return stopped(f\"time budget: {max_seconds} s\", plan)\n        reply = client.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                       tools=TOOLS, messages=messages)\n        used += reply.usage.input_tokens + (reply.usage.cache_read_input_tokens or 0) + reply.usage.output_tokens\n        messages.append({\"role\": \"assistant\", \"content\": reply.content})\n        results = []\n        for block in reply.content:\n            if block.type != \"tool_use\":\n                continue\n",
      "note": "**Checked before every request**, never after. Section 04 says why the order matters."
    },
    {
      "code": "            problem = next(CHECK[block.name].iter_errors(block.input), None) if block.name in CHECK else None\n            if problem:\n                text, is_error = f\"invalid arguments: {problem.message}\", True\n                print(f\"[{step}] {block.name} -> ERROR {text}\")\n            elif block.name == \"finish\":\n                return {\"status\": \"answered\", \"steps\": step, \"tokens\": used,\n                        \"answer\": block.input[\"answer\"], \"sources\": block.input[\"sources\"]}\n",
      "note": "**Its own two tools are checked too**, against their schemas, before anything else. A `finish` with an empty answer comes back as an error instead of ending the run. Then `finish` is the only way to an answered outcome."
    },
    {
      "code": "            elif block.name == \"update_plan\":\n                plan = block.input[\"steps\"]\n                print(f\"[{step}] plan\")\n                for s in plan:\n                    print(f\"      [{MARKS[s['status']]}] {s['step']}\")\n                text, is_error = \"plan recorded\", False\n            else:\n                text, is_error = run_tool(block.name, block.input)\n                print(f\"[{step}] {block.name}({json.dumps(block.input)}) -> {'ERROR ' if is_error else ''}{text[:60]}\")\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": text, \"is_error\": is_error})\n",
      "note": "**The host keeps the plan and prints it.** The tool's result is a receipt, `plan recorded`."
    },
    {
      "code": "        if not results:\n            return stopped(\"replied without calling finish\", plan)\n        messages.append({\"role\": \"user\", \"content\": results})\n    return stopped(f\"step limit: {max_steps}\", plan)\n\n\nif __name__ == \"__main__\":\n    p = argparse.ArgumentParser()\n    p.add_argument(\"task\")\n    p.add_argument(\"--max-steps\", type=int, default=8)\n    p.add_argument(\"--max-tokens\", type=int, default=20000)\n    p.add_argument(\"--max-seconds\", type=float, default=60)\n    a = p.parse_args()\n    print(json.dumps(run(a.task, a.max_steps, a.max_tokens, a.max_seconds), indent=1, ensure_ascii=False))",
      "note": "**A reply with no tool call is a stop**, not an answer: the model was asked to answer through `finish`."
    }
  ]
}
```

A customer asks two things at once: a gift for a nephew who likes adventure stories, and whether order M-1045 is on its way.

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?"
[1] find_books({"genre": "adventure", "max_results": 10}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[1] finish -> ERROR invalid arguments: '' should be non-empty
{
 "status": "stopped",
 "reason": "replied without calling finish",
 "done": [],
 "not_done": [],
 "handoff": "Passed to a person. No plan was written."
}
```

**No plan, and no answer.** In one reply the model made both lookups at once and called `finish` beside them with an empty answer, before either lookup had returned anything. The host refused the empty answer, as the schema says it must, and that reply was the model's last tool call: the next one was text, and a reply without a tool call is a stop. The plan tool was never touched. A model that cannot make a second tool call in a row (lesson 1) cannot keep a plan either, because keeping one is a tool call in every step.

So the rest of this section uses the stand-in, with the four steps a model that plans would take written into a file. Save it as `~/agents/plan.json`; its second entry is for section 07.

```json
{"adventure stories": [
  {"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1045", "status": "todo"},
    {"step": "Find adventure books in stock", "status": "todo"},
    {"step": "Answer both questions", "status": "todo"}]}},
  {"tool": "get_order", "input": {"order_id": "M-1045"}},
  [{"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1045", "status": "done"},
    {"step": "Find adventure books in stock", "status": "todo"},
    {"step": "Answer both questions", "status": "todo"}]}},
   {"tool": "find_books", "input": {"genre": "adventure"}}],
  {"tool": "finish", "input": {
    "answer": "Your order M-1045 is packed and will leave our warehouse soon; the tracking link comes by email when it ships. For a nephew who likes adventure, we have Moby-Dick by Herman Melville at 49.90 and The Count of Monte Cristo by Alexandre Dumas at 59.90 in stock.",
    "sources": ["get_order M-1045", "find_books adventure"]}}
 ],
 "M-1049": [
  {"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1049", "status": "todo"},
    {"step": "Check the return window", "status": "todo"},
    {"step": "Answer", "status": "todo"}]}},
  {"tool": "get_order", "input": {"order_id": "M-1049"}},
  {"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1049", "status": "done"},
    {"step": "Check the return window", "status": "dropped"},
    {"step": "Ask the customer for the order number", "status": "todo"}]}},
  {"tool": "finish", "input": {
    "answer": "I cannot find an order M-1049, so I cannot check its return window yet. Could you send the order number from your confirmation email? It starts with M- and has four digits.",
    "sources": ["get_order M-1049"]}}
 ]
}
```

Start the stand-in and point this terminal at it:

```
ana@lab:~/agents$ python standin.py plan.json &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11436
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?"
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[2] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[3] plan
      [x] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[3] find_books({"genre": "adventure"}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
{
 "status": "answered",
 "steps": 4,
 "tokens": 0,
 "answer": "Your order M-1045 is packed and will leave our warehouse soon; the tracking link comes by email when it ships. For a nephew who likes adventure, we have Moby-Dick by Herman Melville at 49.90 and The Count of Monte Cristo by Alexandre Dumas at 59.90 in stock.",
 "sources": [
  "get_order M-1045",
  "find_books adventure"
 ]
}
```

Four steps. Step 1 wrote a three-item plan; step 2 did its first item; step 3 updated the plan **and** searched for books in the same reply; step 4 called `finish`. The outcome is a JSON object the host built, `"status": "answered"`, with the answer and the two sources the reply named; `tokens` is 0 because the stand-in counts none. Both halves of the request were answered, and the plan is the reason the second half was not forgotten after the first.

The answer was written in advance, and it says what the results say: M-1045 is packed, and Moby-Dick at 49.90 and The Count of Monte Cristo at 59.90 are the adventure books in stock. Check it against what `get_order` and `find_books` return and it holds. `sources` lets a reviewer, or a test, check that without reading the whole conversation.
