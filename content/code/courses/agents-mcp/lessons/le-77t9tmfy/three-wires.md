---
title: One tool on three wires
version: 2
---

Every major provider supports tool calls, and each spells them differently. `wires.py` defines one tool, asks one question and sends it three ways to the same `llama3.2:3b`: through Anthropic's SDK, through OpenAI's, and to Ollama's own `/api/chat` with nothing but the standard library. Ollama answers each in that API's format, so the three replies differ only in how they are wrapped.

```python
"""One tool, one question, three wire formats: Anthropic's, OpenAI's and Ollama's own."""
import json
import os
import urllib.request

import anthropic
import openai

NAME, DESCRIPTION = "get_order", "Look up one Marginalia order by its id, such as M-1042."
SCHEMA = {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}
QUESTION = "Where is order M-1043?"

a = anthropic.Anthropic().messages.create(
    model="llama3.2:3b", max_tokens=200, messages=[{"role": "user", "content": QUESTION}],
    tools=[{"name": NAME, "description": DESCRIPTION, "input_schema": SCHEMA}])
call = next(b for b in a.content if b.type == "tool_use")
print("anthropic ", a.stop_reason, call.name, json.dumps(call.input), call.id)

o = openai.OpenAI().chat.completions.create(
    model="llama3.2:3b", messages=[{"role": "user", "content": QUESTION}],
    tools=[{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}])
call = o.choices[0].message.tool_calls[0]
print("openai    ", o.choices[0].finish_reason, call.function.name, call.function.arguments, call.id)

body = {"model": "llama3.2:3b", "stream": False, "messages": [{"role": "user", "content": QUESTION}],
        "tools": [{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}]}
req = urllib.request.Request(os.environ["OLLAMA_API_BASE"] + "/api/chat", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
n = json.load(urllib.request.urlopen(req))
call = n["message"]["tool_calls"][0]
print("ollama    ", n["done_reason"], call["function"]["name"], json.dumps(call["function"]["arguments"]), call.get("id"))
```

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 OPENAI_BASE_URL=http://127.0.0.1:11435/v1 OLLAMA_API_BASE=http://127.0.0.1:11435
ana@lab:~/agents$ python wires.py
anthropic  tool_use get_order {"order_id": "M-1043"} call_oeyqxw0z
openai     tool_calls get_order {"order_id":"M-1043"} call_em8p21jq
ollama     stop get_order {"order_id": "M-1043"} call_yvigs7hi
ana@lab:~/agents$ python -c 'import json; [print(r["path"].ljust(22), json.dumps(r["request"]["tools"])[:118]) for r in map(json.loads, open("requests.jsonl"))]'
/v1/messages           [{"name": "get_order", "description": "Look up one Marginalia order by its id, such as M-1042.", "input_schema": {"typ
/v1/chat/completions   [{"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia order by its id, such a
/api/chat              [{"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia order by its id, such a
```

With the recorder from lesson 1 in front of all three, the first command shows what each reply held and the second shows how each request put the same definition on the wire. The tool is identical in all three, a name, a description and a JSON Schema, and only the wrapping differs. Google's Gemini API is the fourth column of the table and was not run here, because nothing on this machine speaks it; its shape comes from Google's documentation:

| | Anthropic Messages | OpenAI Chat Completions | Ollama `/api/chat` | Google Gemini (not run) |
|---|---|---|---|---|
| tools in the request | `tools: [{name, description, input_schema}]` | `tools: [{type: "function", function: {name, description, parameters}}]` | the same as OpenAI's | `tools: [{functionDeclarations: [{name, description, parametersJsonSchema}]}]` |
| the call in the reply | a `tool_use` content block with `id`, `name`, `input` | `message.tool_calls[]` with `id`, `function.name`, `function.arguments` as a JSON **string** | `message.tool_calls[]` with `function.arguments` as an **object** | a `functionCall` part with `id`, `name`, `args` |
| why the reply stopped | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` | `done_reason: "stop"`; the call is in the message | `finishReason: "STOP"`; the call is in the parts |
| the result going back | a `tool_result` block in a user message, with `tool_use_id` | a message with role `tool` and `tool_call_id` | a message with role `tool` | a `functionResponse` part with the call's `name` and `id` |

Two details in that table cause real bugs. **OpenAI's arguments arrive as a string of JSON**, not an object, so a program must parse them, and a model can produce a string that does not parse; the openai line above prints that string as it arrived. **Two of the four finish reasons do not say a tool was called**: Ollama's own API ends a reply with a call as `stop`, and Gemini's as `STOP`, the same as a reply with an answer. A loop that checks the finish reason, as `agent.py` checks `stop_reason`, never runs their tools; it has to look for the calls themselves. The ollama line above shows it: `stop`, and a call.

## Why the course writes most loops for one wire

Lessons 5 to 7 use Anthropic's shape, because the course's examples need one shape and this one keeps the call and its result in two clearly named blocks. Nothing they teach depends on it: the validation gate, the errors, the limits and the trace work the same on all three. Lesson 8's SDK uses OpenAI's Responses API, lesson 10's reaches Ollama's own `/api/chat` through LiteLLM, and lesson 13 shows MCP's own shape for a tool, which is closest to Anthropic's: `name`, `description`, `inputSchema`.
