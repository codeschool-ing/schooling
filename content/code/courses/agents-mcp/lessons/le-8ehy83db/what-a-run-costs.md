---
title: What a run costs
version: 2
---

A provider charges for tokens: those it reads (input) and those it writes (output), at different prices per million, which vary by model and change over time. Ollama on your own machine charges nothing per token, and pays in time instead, which this lesson measures as well. Prices are left to each provider's own page, because a price written in a course is out of date by the time it is read.

`cost_run.py` is lesson 1's agent with a measuring tape: the same two tools, a system prompt that carries Marginalia's fourteen help articles as policy, and a line per request with the tokens in and out and the time it took.

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
        print(f"       tool {call.name} {json.dumps(call.input)}", end="", flush=True)
        out = json.dumps(RUN[call.name](call.input))
        print(f": {(time.perf_counter() - t0) * 1000:.0f} ms")
        results.append({"type": "tool_result", "tool_use_id": call.id, "content": out})
    messages.append({"role": "user", "content": results})
print(f"total {totals['input']:7} {totals['cache_write']:8} {totals['cache_read']:7} {totals['output']:7} "
      f"{(time.perf_counter() - start) * 1000:6.0f}")
```

```
ana@lab:~/agents$ python cost_run.py llama3.2:3b
step   input  c.write  c.read  output     ms  stop
   1     994        0      15      16  10447  tool_use
       tool search_help {"query": "M-1043"}: 166 ms
   2      65        0     847      67   8629  end_turn
total    1059        0     862      83  19242
```

The columns come from the reply's `usage`, in the Anthropic API's shape. **`input`** is the input the model read fresh; **`c.read`** is input it did not have to read again, because Ollama still held it from the request before; **`c.write`** is what a provider reports when it stores a prefix on request, and Ollama never reports one, so the column stays at zero here. The times are this machine's: a CPU, with nothing else running. Yours will differ, and so will the model's words and even its choice of tool: asked about an order, it searched the help centre for *"M-1043"* instead of looking the order up. A run is a sample, and the next sections are three more of them.

The answer took **two requests**. The first read 994 tokens and wrote 16; the second read 65 new tokens on top of 847 it reused, and wrote the 67-token answer. Each request carried everything before it: the tools, the system prompt with the policies, and the conversation so far. Lesson 1 said it in one sentence: the API keeps nothing, so whatever the model must remember travels in every request.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" aria-label=\"The two requests of one run, as bars of input tokens. The first read 994 tokens and reused 15. The second reused 847 tokens Ollama had kept from the first, the system prompt with the policies among them, and read only 65 new ones.\"><defs></defs><text x=\"20\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request 1</text><rect x=\"110\" y=\"30\" width=\"8\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"117\" y=\"30\" width=\"447\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"127\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read: 994</text><text x=\"577\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reused: 15</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request 2</text><rect x=\"110\" y=\"85\" width=\"381\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reused: 847</text><rect x=\"491\" y=\"85\" width=\"29\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read: 65</text></svg>", "caption": "Most of the second request is text the model had already read."}
```

Two things follow. **The fixed part dominates**: the policies are most of every request, and the conversation added only 65 tokens on the second. And **the input grows with every step**, so an agent that takes ten steps pays for its early turns ten times. Here reuse hid most of that cost, and the next sections show when it does and when it does not.
