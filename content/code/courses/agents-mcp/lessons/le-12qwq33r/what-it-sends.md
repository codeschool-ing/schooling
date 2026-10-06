---
title: What the ADK puts on the wire
version: 1
---

`wire.py` prints each request in labllm's log in the Gemini API's own terms: the system instruction, the parameter schema of each tool, and the contents.

```python
"""What each request in labllm's log carried, in the Gemini API's format."""
import json

for n, line in enumerate(open("/var/log/labllm/requests.jsonl"), 1):
    q = json.loads(line)["request"]
    print(f"request {n}:")
    print("  systemInstruction:", json.dumps(q["systemInstruction"]["parts"][0]["text"]))
    for tool in q.get("tools", []):
        for f in tool["functionDeclarations"]:
            print(f"  tool {f['name']}:", json.dumps(f["parameters_json_schema"]))
    for c in q["contents"]:
        print(f"  {c['role']}:", json.dumps(c["parts"][0], ensure_ascii=False)[:150])
```

```
ana@lab:~/agents$ python wire.py
request 1:
  systemInstruction: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  user: {"text": "Where is my order M-1043?"}
request 2:
  systemInstruction: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  user: {"text": "Where is my order M-1043?"}
  model: {"functionCall": {"id": "fc_lab_0002_1", "args": {"order_id": "M-1043"}, "name": "get_order"}}
  user: {"functionResponse": {"id": "fc_lab_0002_1", "name": "get_order", "response": {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "sta
```

Three things are the library's choices.

**The instruction has a sentence added.** The agent's `instruction` is followed by *"You are an agent. Your internal name is \"support\"."* The ADK adds it to every agent, and section 06 shows that it adds much more when an agent has others to transfer to. What the model reads is your text plus the library's, and the only way to see the whole of it is to look at the request.

**The schema is generated.** `get_order(order_id: str)` became an object schema with one required string property, and Pydantic's titles came with it (`"Order Id"`, `"get_orderParams"`), as in lesson 8. The docstring became the description. A pattern for `M-` and four digits is not there, because nothing in the type hint said so; lesson 4's rule that the schema should carry what the code checks applies here too.

**The result is an object, not text.** The last line is a `functionResponse` whose `response` is the order itself, as JSON. The Gemini API takes a function's result as a structured value, and the ADK passes the dictionary through. Lesson 8's SDK turned the same dictionary into Python's `str()`; lesson 9's tool wrote its own text. A function that returns something other than a dictionary is wrapped in one, under the key `result`: section 06 shows it, as `{"result": null}` and `{"result": "Order M-1046 still says..."}`.
