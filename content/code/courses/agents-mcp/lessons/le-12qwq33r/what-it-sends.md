---
title: What the ADK puts on the wire
version: 2
---

`wire.py` prints each request in the recorder's log in the terms of Ollama's own API: the path, the parameter schema of each tool, and the messages.

```python
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
```

```
ana@lab:~/agents$ python wire.py
request 1: /api/show
request 2: /api/show
request 3: /api/chat
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  system: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  user: "Where is my order M-1043?"
request 4: /api/show
request 5: /api/chat/api/show
request 6: /api/show
request 7: /api/show
request 8: /api/chat
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  system: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  user: "Where is my order M-1043?"
  assistant: null
  tool: "{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"2026-09-28\", \"status\": \"shipped\", \"delivered_on\": null, \"shipping\": 0, \"t
```

**Eight requests for one answer, and two of them were the conversation.** The other six are LiteLLM asking Ollama about the model, `/api/show`, before and between the two chats, and one of them went to `/api/chat/api/show`, a path Ollama does not have: LiteLLM built that address itself, and Ollama answered it with a `404`. None of this is in `adk_run.py`. It is what a library one step removed from your code does on your behalf, and the recorder is the only reason it is visible.

Three more things are the library's choices.

**The instruction has a sentence added.** The agent's `instruction` is followed by *"You are an agent. Your internal name is \"support\"."* The ADK adds it to every agent, and section 06 shows that it adds much more when an agent has others to transfer to. What the model reads is your text plus the library's, and the only way to see the whole of it is to look at the request.

**The schema is generated.** `get_order(order_id: str)` became an object schema with one required string property, and Pydantic's titles came with it (`"Order Id"`, `"get_orderParams"`), as in lesson 8. The docstring became the description. A pattern for `M-` and four digits is not there, because nothing in the type hint said so; lesson 4's rule that the schema should carry what the code checks applies here too.

**The call did not reach the model; its result did.** In the second request the tool's result is there, the order as JSON in a `tool` message. The call that produced it is not: the assistant's turn arrives with empty content and no `tool_calls`, which `wire.py` prints as `null`. The ADK's events hold the call, and somewhere between them and Ollama it was dropped, so the model read a result with no question before it. It answered correctly anyway. **What the model read is not the conversation the ADK holds**, and nothing in the ADK's output says so; the request does. A function that returns something other than a dictionary is wrapped in one, under the key `result`: section 06 shows it, as `{"result": null}` and `{"result": "The order M-1046 has been packed..."}`.
