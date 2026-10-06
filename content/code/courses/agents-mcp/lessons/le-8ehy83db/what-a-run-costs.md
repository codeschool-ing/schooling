---
title: What a run costs
version: 1
---

A provider charges for tokens: those it reads (input) and those it writes (output), at different prices per million, which vary by model and change over time. This lesson counts tokens and leaves the prices to the provider's own page, because a price written in a course is out of date by the time it is read.

`cost_run.py` is lesson 1's agent with a measuring tape: the same two tools, a system prompt that carries Marginalia's forty help articles as policy, and a line per request with the tokens in and out and the time it took.

```python
"""One agent run, measured: tokens and time per request, per tool, and in total."""
import argparse
import json
import time

import anthropic

import shop

parser = argparse.ArgumentParser()
parser.add_argument("model")
parser.add_argument("--cache", action="store_true", help="mark the policy as a cacheable prefix")
parser.add_argument("--stamp", action="store_true", help="put the current time at the top of the system prompt")
args = parser.parse_args()

POLICY = "\n\n".join(f"## {a['title']}\n{a['body']}" for a in map(json.loads, open("data/help.jsonl")))
SYSTEM = [{"type": "text", "text": "You answer Marginalia's customers in the cost lesson. Use the tools; never guess."},
          {"type": "text", "text": "Marginalia's policies, which every answer must respect:\n\n" + POLICY}]
if args.stamp:                                    # a value that changes on every request, at the very front
    SYSTEM.insert(0, {"type": "text", "text": ""})
if args.cache:                                    # everything up to here is the same on every request
    SYSTEM[-1]["cache_control"] = {"type": "ephemeral"}
TOOLS = [
    {"name": "get_order", "description": "Look up one Marginalia order by its id, M- and four digits.",
     "input_schema": {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}},
    {"name": "search_help", "description": "Search Marginalia's help centre by meaning.",
     "input_schema": {"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}},
]
RUN = {"get_order": lambda a: shop.get_order(a["order_id"]),
       "search_help": lambda a: [x["title"] for x in shop.search_help(a["query"])]}

client = anthropic.Anthropic()
messages = [{"role": "user", "content": "Where is my order M-1043?"}]
totals = {"input": 0, "cache_write": 0, "cache_read": 0, "output": 0}
start = time.perf_counter()
print("step   input  c.write  c.read  output     ms  stop")
for step in range(1, 7):
    if args.stamp:
        SYSTEM[0]["text"] = f"Request sent at {time.time():.3f}."
    t0 = time.perf_counter()
    reply = client.messages.create(model=args.model, max_tokens=1024, system=SYSTEM, tools=TOOLS, messages=messages)
    ms = (time.perf_counter() - t0) * 1000
    u = reply.usage
    row = {"input": u.input_tokens, "cache_write": u.cache_creation_input_tokens or 0,
           "cache_read": u.cache_read_input_tokens or 0, "output": u.output_tokens}
    for k in totals:
        totals[k] += row[k]
    print(f"{step:4} {row['input']:7} {row['cache_write']:8} {row['cache_read']:7} {row['output']:7} {ms:6.0f}  {reply.stop_reason}")
    messages.append({"role": "assistant", "content": reply.content})
    calls = [b for b in reply.content if b.type == "tool_use"]
    if not calls:
        break
    results = []
    for call in calls:
        t0 = time.perf_counter()
        out = json.dumps(RUN[call.name](call.input))
        print(f"       tool {call.name}: {(time.perf_counter() - t0) * 1000:.0f} ms")
        results.append({"type": "tool_result", "tool_use_id": call.id, "content": out})
    messages.append({"role": "user", "content": results})
print(f"total {totals['input']:7} {totals['cache_write']:8} {totals['cache_read']:7} {totals['output']:7} "
      f"{(time.perf_counter() - start) * 1000:6.0f}")
```

```
ana@lab:~/agents$ python cost_run.py scripted-1
step   input  c.write  c.read  output     ms  stop
   1    2359        0       0      10    641  tool_use
       tool get_order: 1 ms
   2    2520        0       0       8    571  tool_use
       tool search_help: 348 ms
   3    2561        0       0      75   3208  end_turn
total    7440        0       0      93   4768
```

**The model's calls and answer were written by the course**; the counts and times are labllm's, by the rules at the top of `lab/labllm.py`: tokens counted with `o200k_base`, 200 ms before the first token and 40 ms for each one after, for `scripted-1`.

Read the columns. The answer took **three requests**, and they carried **7,440 input tokens** between them against **93 output tokens**. Each request carried everything before it: the tools, the system prompt with the policies, and the conversation so far. Lesson 1 said it in one sentence: the API keeps nothing, so whatever the model must remember travels in every request.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The three requests of one run, as bars of input tokens. Each carries the tools, the system prompt with the policies, and the conversation so far. The first two parts are the same in all three, about 2,350 tokens; the conversation grows from a few tokens to about 210. Marked as a cacheable prefix, the repeated part is written once and read twice.\"><defs></defs><text x=\"20\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request 1</text><rect x=\"110\" y=\"30\" width=\"451\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tools + system: 2,347</text><rect x=\"561\" y=\"30\" width=\"4\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"573\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conversation: 12</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request 2</text><rect x=\"110\" y=\"85\" width=\"451\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tools + system: 2,347</text><rect x=\"561\" y=\"85\" width=\"33\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conversation: 173</text><text x=\"20\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request 3</text><rect x=\"110\" y=\"140\" width=\"451\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tools + system: 2,347</text><rect x=\"561\" y=\"140\" width=\"41\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conversation: 214</text></svg>", "caption": "Most of each request is text the provider has already seen."}
```

Two things follow. **The fixed part dominates**: about 2,350 tokens of tools and policy went out three times, and the conversation added only 161 and 41 tokens on the next two requests. And **the input grows with every step**, so an agent that takes ten steps pays for its early turns ten times. Both are why the levers in this lesson's next sections work.
