---
title: The same loop with native tool calls
version: 2
---

`react_native.py` answers the same question with the provider's own tool calling. The system prompt asks for one sentence of reasoning before each call, so every step carries a thought and an action, as ReAct does; what differs is the shape they arrive in. It also records each step in `trace.jsonl`, which section 06 reads, and refuses a call it has already made, which section 08 needs.

```schooling-example
{
  "language": "python",
  "file": "react_native.py",
  "parts": [
    {
      "code": "\"\"\"ReAct with native tool calls: the thought is a text block, the action a tool_use block.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "TOOLS = [\n    {\"name\": \"get_order\",\n     \"description\": \"Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"order_id\": {\"type\": \"string\"}}, \"required\": [\"order_id\"]}},\n    {\"name\": \"search_help\",\n     \"description\": \"Search Marginalia's help centre by meaning and return the three closest articles.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"query\": {\"type\": \"string\"}}, \"required\": [\"query\"]}},\n]\nRUN = {\n    \"get_order\": lambda args: shop.get_order(args[\"order_id\"]),\n    \"search_help\": lambda args: [{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])],\n}\n",
      "note": "**The tools as JSON Schema**, the same two as lesson 1. The model receives these definitions with every request."
    },
    {
      "code": "SYSTEM = (\"You answer Marginalia's customers. Before each tool call, say in one sentence what you know \"\n          \"and what you need next. Never guess an order's details.\")\n\nclient = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**The ReAct half of the prompt**: a sentence of reasoning before each call. No format to follow, no lines to imitate."
    },
    {
      "code": "seen = set()\n",
      "note": "**Calls already made**, as a name and canonical arguments. Section 08 uses it."
    },
    {
      "code": "with open(\"trace.jsonl\", \"w\") as trace:\n    for step in range(1, 7):\n        reply = client.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                       tools=TOOLS, messages=messages)\n        messages.append({\"role\": \"assistant\", \"content\": reply.content})\n",
      "note": "**A trace file, one JSON line per step**, written as the run goes. Section 06 reads it."
    },
    {
      "code": "        record = {\"step\": step, \"stop_reason\": reply.stop_reason, \"input_tokens\": reply.usage.input_tokens + (reply.usage.cache_read_input_tokens or 0),\n                  \"text\": \" \".join(b.text for b in reply.content if b.type == \"text\"), \"calls\": []}\n        results = []\n        for block in reply.content:\n            if block.type != \"tool_use\":\n                continue\n",
      "note": "**What a step is worth recording**: why it stopped, how large the request was, what the model said and what it called."
    },
    {
      "code": "            call = (block.name, json.dumps(block.input, sort_keys=True))\n            if call in seen:\n                record[\"calls\"].append({\"tool\": block.name, \"input\": block.input, \"refused\": \"repeat\"})\n                trace.write(json.dumps(record) + \"\\n\")\n                print(f\"host: step {step} repeats {block.name}({json.dumps(block.input)}); stopping\")\n                sys.exit(1)\n            seen.add(call)\n",
      "note": "**The repeat guard.** The same call with the same arguments twice in one run stops the run."
    },
    {
      "code": "            output = json.dumps(RUN[block.name](block.input))\n            record[\"calls\"].append({\"tool\": block.name, \"input\": block.input, \"output\": output[:80]})\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": output})\n        trace.write(json.dumps(record) + \"\\n\")\n        if reply.stop_reason != \"tool_use\":\n            print(record[\"text\"])\n            break\n        messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**Run the tool and hand back its result**, joined to the call by `tool_use_id`."
    }
  ]
}
```

```
ana@lab:~/agents$ python react_native.py "Can I still return the books in order M-1047, and how would the refund work?"
To return the books in order M-1047, you have 30 days from delivery to return the printed books in the condition they were received. To initiate the return, start by going to the order in your account, print the prepaid label, and then drop the parcel at any post office. Refunds for returned printed books will be issued in the original payment method. If you have any issues or concerns about the return process, please contact our customer service team for assistance.
```

No regular expression, no invented observation, no argument in the wrong shape: the call arrived as a `tool_use` block with its arguments in fields, and the program ran it. The answer is about returns in general and is right as far as it goes. It does not say whether M-1047 itself can still go back, because the model searched the help centre and never looked the order up. That is lesson 1's limit again, one tool and then an answer, and section 06 reads it in the trace. Compare one step of each style:

| | text ReAct | native calls |
|---|---|---|
| the thought | a `Thought:` line | a text block |
| the action | `Action: get_order[M-1047]`, parsed by the program | a `tool_use` block: `{"order_id": "M-1047"}` |
| where the arguments are checked | nowhere, unless the parser does it | against the schema the request declared |
| who writes the observation | the program, if the stop sequence holds | the program, always: the reply ends at the call |
| how a result finds its call | its position in the transcript | `tool_use_id`, matching the call's `id` |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A native tool call and its result. The model&#x27;s reply holds a text block, the thought, and a tool_use block with an id, a tool name and structured input. The program&#x27;s next message holds a tool_result block that names the same id and carries the output. The id, not the position, joins the result to the call.\"><defs><marker id=\"l3ids-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"320\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the model&#x27;s reply (role: assistant)</text><rect x=\"36\" y=\"52\" width=\"288\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"69.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">text</text><text x=\"46\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the thought, in words</text><rect x=\"36\" y=\"116\" width=\"288\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tool_use</text><text x=\"46\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id: toolu_…</text><text x=\"46\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order, order_id = M-1047</text><rect x=\"380\" y=\"70\" width=\"320\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"392\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the program&#x27;s next message (role: user)</text><rect x=\"396\" y=\"104\" width=\"288\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"406\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tool_result</text><text x=\"406\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tool_use_id: toolu_…</text><text x=\"406\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">content: the order, as JSON</text><path d=\"M324 150 L396 144\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l3ids-ah-phosphor)\"></path></svg>", "caption": "Two blocks in, one block back, joined by an id."}
```

The last row matters more than it looks. A reply can hold several `tool_use` blocks at once, and their results come back as several `tool_result` blocks in one message. **The id is what pairs them, and position is not**; the API refuses a conversation in which a call has no result with its id, which lesson 4 shows happening.

Native calls do not remove the need for the thought. A model that is asked to state what it knows before acting tends to choose better next steps, which is the paper's result; the difference is that the thought is now optional decoration on a structured call, rather than the text a parser depends on. Optional is the word: `llama3.2:3b` was asked for one sentence before each call and wrote none, and the call came anyway.
