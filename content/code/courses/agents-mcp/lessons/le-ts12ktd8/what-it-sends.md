---
title: What the SDK puts on the wire
version: 2
---

A library that builds requests for you is making choices you cannot see from your own code. The recorder's log shows them. Here is the path the SDK sent to, the tool definition it sent for `get_order`, and the kinds of item in the request's `input` after it ran the tool:

```
ana@lab:~/agents$ tail -n 1 requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["path"]); print(json.dumps(r["request"]["tools"][0], indent=1)); print([i.get("type", i.get("role")) for i in r["request"]["input"]])'
/v1/responses
{
 "name": "get_order",
 "parameters": {
  "properties": {
   "order_id": {
    "pattern": "^M-[0-9]{4}$",
    "title": "Order Id",
    "type": "string"
   }
  },
  "required": [
   "order_id"
  ],
  "title": "get_order_args",
  "type": "object",
  "additionalProperties": false
 },
 "strict": true,
 "type": "function",
 "description": "Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."
}
['user', 'function_call', 'function_call_output']
```

The path is `/v1/responses`, and the shape is the Responses API's: the tool's fields sit at the top level (`name`, `parameters`, `description`) rather than inside a `function` object as in lesson 4's Chat Completions, and the conversation is a list called `input` of typed items, `user`, `function_call` and `function_call_output`, rather than of messages with roles. Three more things in that output are the SDK's decisions, not yours.

**`"strict": true`.** The SDK asks the provider to constrain the model's arguments to the schema exactly, which is the strict mode lesson 4 section 04 mentioned. For that to work the schema has to follow the provider's strict rules, so the SDK adds `"additionalProperties": false` and makes every property required. The decorator's `strict_mode=True` is the default. Whether Ollama constrains `llama3.2:3b` by it, the request cannot tell you; the validation you see in section 05 is the SDK's own, done after the reply arrives.

**`"title"` fields.** Pydantic generates a title for every property (`"Order Id"`) and for the whole object (`"get_order_args"`). They cost tokens on every request and tell the model nothing the name does not; harmless, and an example of what a generated schema carries that a hand-written one would not.

**The result is Python, not JSON.** The first run's items show the result as `{'id': 'M-1043', 'customer_id'...`: single quotes, and `None` where JSON would say `null`. `get_order` returned a dictionary, and the SDK turned it into text with Python's `str()`. A model reads it well enough, and lesson 3's rules for observations still apply: a result that is meant to be read as data is clearer as JSON. **Return a string you built with `json.dumps(...)`** if what the model reads matters to you: the SDK passes a string through unchanged, and turns most other values, a Pydantic model included, into text with `str()`.

None of these is a defect. Each is a default that somebody chose, and knowing it is the difference between an agent you can explain and one you can only run.
