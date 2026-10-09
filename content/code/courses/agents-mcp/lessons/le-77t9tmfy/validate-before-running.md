---
title: Validate before running
version: 2
---

`agent.py` in this lesson is lesson 1's loop with one change: every call goes through `run_tool`, which validates the arguments against the tool's schema before the function runs, and every outcome comes back to the model as a `tool_result`, marked `is_error` when it failed.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"The lesson 1 loop, with the tools of tools.py: every call validated, every failure returned as an error.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\n"
    },
    {
      "code": "from tools import TOOLS, run_tool\n\n",
      "note": "**The tools and the gate come from `tools.py`**; the loop knows nothing about orders or books."
    },
    {
      "code": "SYSTEM = (\"You are Marginalia's support agent. Use the tools to find facts; \"\n          \"if a tool returns an error, read it and correct the call.\")\n",
      "note": "**One sentence about errors**: read them and correct the call."
    },
    {
      "code": "DROP_ONE = \"--drop-one\" in sys.argv\n\nclient = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**A deliberate bug for section 08**, switched on with a flag."
    },
    {
      "code": "for step in range(1, 6):\n    reply = client.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                   tools=TOOLS, messages=messages)\n    messages.append({\"role\": \"assistant\", \"content\": reply.content})\n    if reply.stop_reason != \"tool_use\":\n        print(f\"[{step}] answer: {reply.content[-1].text}\")\n        break\n    results = []\n    for block in reply.content:\n        if block.type == \"tool_use\":\n",
      "note": "**The same loop as lesson 1.**"
    },
    {
      "code": "            text, is_error = run_tool(block.name, block.input)\n            print(f\"[{step}] {block.name}({json.dumps(block.input)}) -> {'ERROR ' if is_error else ''}{text[:70]}\")\n",
      "note": "**Every call through the gate.** Nothing reaches `shop.py` with arguments the schema refused."
    },
    {
      "code": "            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": text, \"is_error\": is_error})\n    if DROP_ONE:\n        results = results[:1]\n    messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**`is_error` travels with the result**, so the model knows this content describes a failure rather than data."
    }
  ]
}
```

Here it is on the two questions most likely to produce a bad call: an order number written without its prefix, and a request for a list.

```
ana@lab:~/agents$ python agent.py "Where is my order 1043?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[2] answer: Your order 1043 has been shipped and has a tracking number BR5512340003. The order was placed on 2026-09-28 and contains the following items:

- Book 13 (2490 cents)
- Book 14 (2590 cents)
- Book 26 (5990 cents)

The total cost of the order is 11070 cents. If you would like to track the status of your order or have any questions, please contact our customer service team.
```

```
ana@lab:~/agents$ python agent.py "Which mystery novels do you have in stock?"
[1] find_books({"genre": "mystery"}) -> [{"id": "b11", "title": "The Mysterious Affair at Styles", "author": "
[2] answer: Here are some mystery novels that I have in stock:

1. "The Mysterious Affair at Styles" by Agatha Christie - This is a classic whodunit novel that introduces the iconic character of Hercule Poirot. It's a great starting point for anyone looking to explore the world of mystery fiction.

If you're interested in more mystery novels, I can suggest some additional titles. Would you like more recommendations?
```

**No bad call, so nothing for the gate to do.** The customer wrote `1043`, and the model sent `M-1043`, because the description says an id is M- followed by four digits. It asked for mysteries without a `max_results` and got the default of three, of which one was in stock. (Its answer then offers "additional titles" the shop does not have: the result said one book, and a careful reader would stop there.)

A real model makes these mistakes on some runs and not others, which is no way to watch a gate. To see it work every time, use the stand-in from lesson 3 with replies that make two common mistakes, drop the prefix and write a number as a word, and then correct each one. Save this as `~/agents/retry.json`:

```json
{"order 1043": [
  {"tool": "get_order", "input": {"order_id": "1043"}},
  {"tool": "get_order", "input": {"order_id": "M-1043"}},
  {"text": "Order M-1043 has shipped and is on its way, with tracking code BR5512340003. It has not been delivered yet."}
 ],
 "mystery novels": [
  {"tool": "find_books", "input": {"genre": "mystery", "max_results": "five"}},
  {"tool": "find_books", "input": {"genre": "mystery", "max_results": 5}},
  {"text": "Right now we have one mystery in stock: The Mysterious Affair at Styles by Agatha Christie, at 31.90."}
 ]
}
```

Start it as lesson 3 did, and point `agent.py` at it:

```
ana@lab:~/agents$ python standin.py retry.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python agent.py "Where is my order 1043?"
[1] get_order({"order_id": "1043"}) -> ERROR invalid arguments: order_id: '1043' does not match '^M-[0-9]{4}$'
[2] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[3] answer: Order M-1043 has shipped and is on its way, with tracking code BR5512340003. It has not been delivered yet.
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python agent.py "Which mystery novels do you have in stock?"
[1] find_books({"genre": "mystery", "max_results": "five"}) -> ERROR invalid arguments: max_results: 'five' is not of type 'integer'
[2] find_books({"genre": "mystery", "max_results": 5}) -> [{"id": "b11", "title": "The Mysterious Affair at Styles", "author": "
[3] answer: Right now we have one mystery in stock: The Mysterious Affair at Styles by Agatha Christie, at 31.90.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The validation gate. A tool call from the model goes first to the schema check. If the arguments fail, an error describing what failed goes back to the model as the tool&#x27;s result, and no function runs. If they pass, the function runs; if it raises a known error, that error goes back the same way; otherwise its result does.\"><defs><marker id=\"l4gate-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4gate-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tool call</text><text x=\"30\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from the model</text><rect x=\"200\" y=\"90\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">schema check</text><text x=\"210\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jsonschema</text><rect x=\"400\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the function</text><text x=\"410\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop.py</text><rect x=\"580\" y=\"20\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">is_error: true</text><text x=\"590\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what failed</text><rect x=\"580\" y=\"160\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">is_error: false</text><text x=\"590\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the result</text><path d=\"M150 115 L200 115\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-amber)\"></path><path d=\"M340 115 L400 115\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-phosphor)\"></path><text x=\"370\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pass</text><path d=\"M270 90 L270 45 L580 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-amber)\"></path><text x=\"330\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fail</text><path d=\"M465 90 L465 60 L580 60\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-amber)\"></path><text x=\"520\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">raises</text><path d=\"M465 140 L465 185 L580 185\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-phosphor)\"></path><text x=\"520\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">returns</text></svg>", "caption": "Every path ends in a tool result. None of them ends in a crash."}
```

The calls and the final sentences are the file's; the refusals are the validator's own messages, and the results are the shop's. In both runs the bad call cost one step and nothing else. The validator refused it, its message went back as an error, and the next call was right. With `llama3.2:3b` that second call cannot happen, because its template hides the tools once a tool result is the last message (lesson 1); the error still reaches the model, and the best it can do is say so in its answer. A model that can call again is the case this gate was built for. Without the gate, `get_order("1043")` would have raised a `LookupError` inside the host, which is the better case; `find_books(max_results="five")` would have reached `stocked[:max_results]` and crashed with a `TypeError`, which is a host failure instead of a correctable model mistake.

**This is the compounding of lesson 2 being cut short.** A wrong step that becomes an error the model can read is a step that gets corrected instead of built on. The cost is one extra request, and the trace shows exactly where it happened.

Notice also what the mystery runs returned: one book, whether three or five were asked for. `find_books` lists only what is in stock, and two of the three mysteries Marginalia prices are sold out. A tool that answers honestly, even when the answer is small, is worth more than one that pads, and it is worth exactly as much as the model's willingness to report it: the real model's offer of more titles came from nowhere.
