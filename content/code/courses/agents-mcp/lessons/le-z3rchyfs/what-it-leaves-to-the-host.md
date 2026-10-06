---
title: What it leaves to the host
version: 1
---

The server described `get_order` once. Everything after that, the three hosts decided differently, and the protocol let them:

- **The name the model sees.** The Claude host renamed the tool `mcp__shop__get_order`; the OpenAI and Google hosts passed `get_order` through. Prefixing means two servers that both offer a `get_order` cannot be confused with each other; passing the name through keeps it short. Either way it is the host's choice.
- **How strict the schema is.** The OpenAI host sent `"strict": false` for this tool, where lesson 8's function tools went with `"strict": true`.
- **How often the list is fetched.** The OpenAI host's client asked for the tool list twice in one run:

```
ana@lab:~/agents$ python -c 'import json; [print(json.loads(l)["method"]) for l in open("openai.in.jsonl")]' | sort | uniq -c
      1 server/discover
      1 tools/call
      2 tools/list
```

  once before each model request, so a server whose tools changed between turns would be noticed. The OpenAI SDK has a `cache_tools_list` option to fetch it once; the 2026-07-28 revision adds `ttlMs` to list results so a server can say how long its answer stays fresh.
- **How much the description is trusted.** The Google host wrapped the server's description between `<<<BEGIN_UNTRUSTED_TOOL_DESCRIPTION>>>` and `<<<END_UNTRUSTED_TOOL_DESCRIPTION>>>` before the model saw it, as section 02's capture shows. The other two passed it as written.

That last one deserves a sentence of its own. **A tool's description is text written by whoever wrote the server, and the model reads it as guidance.** A server the host did not write can say anything in a description, including things meant for the model rather than for a person reading the list. The ADK marks the text as untrusted; marking it does not make the model ignore it, but it tells the model whose words those are. Lesson 17 treats this as a risk to test for, against this course's own lab, and the defence is the host's: which servers it connects to, which tools it exposes, and what it asks a person before a call.

And above all of these sit the decisions MCP does not touch at all: **which model**, **the loop**, **which calls need a person**, **what the agent may do with a result**. A server cannot grant itself permission. A host that connects to a server and lets its model call every tool without looking has made a decision; it just did not make it on purpose.
