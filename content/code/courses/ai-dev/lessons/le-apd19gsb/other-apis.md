---
title: The same idea in another API
version: 1
---

Every provider this course talks to has function calling, and the idea is the same everywhere:
**tools described by JSON Schema, a reply that asks for one, a result sent back with an id**. The
shapes differ, and the differences are where code written for one API breaks on another.

## OpenAI's chat completions

The same tools, wrapped in OpenAI's shape, against labllm's OpenAI endpoint:

```schooling-example
{
  "language": "python",
  "file": "openai_stock.py",
  "parts": [
    {
      "code": "\"\"\"The same round trip through OpenAI's chat completions: the arguments arrive as a string.\"\"\"\nimport json\nimport sys\n\nimport openai\n\nfrom shop_tools import FUNCTIONS, TOOLS\n\n"
    },
    {
      "code": "tools = [{\"type\": \"function\", \"function\": {\"name\": t[\"name\"], \"description\": t[\"description\"],\n                                           \"parameters\": t[\"input_schema\"]}} for t in TOOLS]\nclient = openai.OpenAI()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**The same `TOOLS`, wrapped** in the shape this API expects."
    },
    {
      "code": "while True:\n    r = client.chat.completions.create(model=\"scripted-1\", messages=messages, tools=tools)\n    choice = r.choices[0]\n    print(\"<- finish_reason:\", choice.finish_reason)\n    messages.append(choice.message.model_dump(exclude_none=True))\n    if not choice.message.tool_calls:\n        print(\"  \", choice.message.content)\n        break\n",
      "note": "**`finish_reason` says why the reply stopped**; `tool_calls` means the model wants a function."
    },
    {
      "code": "    for call in choice.message.tool_calls:\n        print(\"   arguments:\", repr(call.function.arguments))\n        out = FUNCTIONS[call.function.name](**json.loads(call.function.arguments))\n        messages.append({\"role\": \"tool\", \"tool_call_id\": call.id, \"content\": json.dumps(out)})",
      "note": "**The arguments are a string.** `json.loads` is your code's job, and a result goes back as a `tool` message joined by `tool_call_id`."
    }
  ]
}
```

```
ana@dev:~/shop$ python openai_stock.py "Is LAMP-02 in stock?"
<- finish_reason: tool_calls
   arguments: '{"sku": "LAMP-02"}'
<- finish_reason: stop
   Yes. LAMP-02 is in stock, 4 units, at 210.00.
```

Same question, same tool, same answer. **The arguments are the difference**: `repr` shows quotes
around them because they arrive as a string of JSON, not as an object. The code must call
`json.loads` itself, and a string can fail to parse in a way a parsed object cannot. Without
strict mode, a malformed string is a real possibility, and it belongs in the same error path as a
schema failure.

## Side by side

| | Anthropic Messages | OpenAI chat completions |
| --- | --- | --- |
| tool definition | `name`, `description`, `input_schema` | `{"type": "function", "function": {..., "parameters"}}` |
| the model wants a tool | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` |
| the call | a `tool_use` block in `content` | an entry in `message.tool_calls` |
| the arguments | `input`, an object | `function.arguments`, a string |
| the result | a `tool_result` block in a `user` message | a message with `role: "tool"` |
| the join | `tool_use_id` | `tool_call_id` |

Google's Gemini API follows the same outline with its own names: a function declaration with a
schema, a `functionCall` part in the reply, a `functionResponse` part sent back. The lab does not
serve Gemini's function calling, so this lesson shows no capture of it.

## Keep your tools in one shape

`openai_stock.py` did not define its tools again. It converted `TOOLS`, which is in Anthropic's
shape, with one list comprehension. **Hold one definition of each tool, and convert at the edge.**
Two copies drift, and the drift shows up as a model that obeys a description you already changed
in the other file.
