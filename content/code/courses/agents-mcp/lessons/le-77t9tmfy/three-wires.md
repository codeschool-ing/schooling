---
title: One tool on three wires
version: 1
---

Every major provider supports tool calls, and each spells them differently. `wires.py` defines one tool, asks one question and sends it through the three SDKs the lab has. **The tool call each reply carries was written by the course** as a rule for the stand-in, and labllm returns it in each provider's own format; the SDKs, the requests they built and the objects they parsed are real.

```python
"""One tool, one question, three providers' SDKs: what each one sends and gets back."""
import json

import anthropic
import openai
from google import genai
from google.genai import types

NAME, DESCRIPTION = "get_order", "Look up one Marginalia order by its id, such as M-1042."
SCHEMA = {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}
QUESTION = "Where is order M-1043?"

a = anthropic.Anthropic().messages.create(
    model="scripted-1", max_tokens=200, messages=[{"role": "user", "content": QUESTION}],
    tools=[{"name": NAME, "description": DESCRIPTION, "input_schema": SCHEMA}])
call = next(b for b in a.content if b.type == "tool_use")
print("anthropic ", a.stop_reason, call.name, json.dumps(call.input), call.id)

o = openai.OpenAI().chat.completions.create(
    model="scripted-1", messages=[{"role": "user", "content": QUESTION}],
    tools=[{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}])
call = o.choices[0].message.tool_calls[0]
print("openai    ", o.choices[0].finish_reason, call.function.name, call.function.arguments, call.id)

gemini = genai.Client(http_options=types.HttpOptions(base_url="http://127.0.0.1:8600"))
g = gemini.models.generate_content(
    model="scripted-1", contents=QUESTION,
    config=types.GenerateContentConfig(tools=[types.Tool(function_declarations=[
        types.FunctionDeclaration(name=NAME, description=DESCRIPTION, parameters_json_schema=SCHEMA)])]))
call = g.candidates[0].content.parts[0].function_call
print("gemini    ", g.candidates[0].finish_reason.name, call.name, json.dumps(call.args), call.id)
```

```
ana@lab:~/agents$ python wires.py
anthropic  tool_use get_order {"order_id": "M-1043"} toolu_lab_0014_1
openai     tool_calls get_order {"order_id": "M-1043"} call_lab_0015_1
gemini     STOP get_order {"order_id": "M-1043"} fc_lab_0016_1
ana@lab:~/agents$ tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["path"].split("/")[-1][:28].ljust(28), json.dumps(r["request"]["tools"])[:118]) for r in map(json.loads, sys.stdin)]'
messages                     [{"name": "get_order", "description": "Look up one Marginalia order by its id, such as M-1042.", "input_schema": {"typ
completions                  [{"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia order by its id, such a
scripted-1:generateContent   [{"functionDeclarations": [{"description": "Look up one Marginalia order by its id, such as M-1042.", "name": "get_ord
```

The first command shows what each SDK handed back; the second shows, from labllm's log, how each one put the same definition on the wire. The tool is identical in all three, a name, a description and a JSON Schema, and only the wrapping differs:

| | Anthropic Messages | OpenAI Chat Completions | Google Gemini |
|---|---|---|---|
| tools in the request | `tools: [{name, description, input_schema}]` | `tools: [{type: "function", function: {name, description, parameters}}]` | `tools: [{functionDeclarations: [{name, description, parametersJsonSchema}]}]`, which this SDK writes as `parameters_json_schema` |
| the call in the reply | a `tool_use` content block with `id`, `name`, `input` | `message.tool_calls[]` with `id`, `function.name`, `function.arguments` as a JSON **string** | a `functionCall` part with `id`, `name`, `args` |
| why the reply stopped | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` | `finishReason: "STOP"`; the call is in the parts |
| the result going back | a `tool_result` block in a user message, with `tool_use_id` | a message with role `tool` and `tool_call_id` | a `functionResponse` part with the call's `name` and `id` |

Two details in that table cause real bugs. **OpenAI's arguments arrive as a string of JSON**, not an object, so a program must parse them, and a model can produce a string that does not parse; the openai line above prints that string as it arrived. **Gemini's finish reason does not say a tool was called**: a reply with a function call ends with `STOP`, the same as a reply with an answer, so a loop that checks the finish reason, as `agent.py` checks `stop_reason`, never runs Gemini's tools. It has to look for `function_call` parts instead.

## Why the course writes most loops for one wire

Lessons 5 to 7 use Anthropic's shape, because the lab's examples need one shape and this one keeps the call and its result in two clearly named blocks. Nothing they teach depends on it: the validation gate, the errors, the limits and the trace work the same on all three. Lessons 8 and 10 use OpenAI's and Google's wires through their agent SDKs, and lesson 13 shows MCP's own shape for a tool, which is closest to Anthropic's: `name`, `description`, `inputSchema`.
