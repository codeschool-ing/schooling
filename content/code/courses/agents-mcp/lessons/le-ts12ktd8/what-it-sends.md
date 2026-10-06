---
title: What the SDK puts on the wire
version: 1
---

A library that builds requests for you is making choices you cannot see from your own code. labllm's log shows them. Here is the tool definition the SDK sent for `get_order`, and the start of the tool result it sent back after running it:

```
ana@lab:~/agents$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(json.dumps(r["request"]["tools"][0], indent=1)); print(r["request"]["messages"][3]["content"][:120])'
{
 "type": "function",
 "function": {
  "name": "get_order",
  "description": "Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.",
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
  "strict": true
 }
}
{'id': 'M-1043', 'customer_id': 'c-102', 'placed_on': '2026-09-28', 'status': 'shipped', 'delivered_on': None, 'shipping
```

Three things in that output are the SDK's decisions, not yours.

**`"strict": true`.** The SDK asks the provider to constrain the model's arguments to the schema exactly, which is the strict mode lesson 4 section 04 mentioned. For that to work the schema has to follow the provider's strict rules, so the SDK adds `"additionalProperties": false` and makes every property required. The decorator's `strict_mode=True` is the default; labllm ignores the flag, so in this lab the validation you see in section 05 is the SDK's own, done after the reply arrives.

**`"title"` fields.** Pydantic generates a title for every property (`"Order Id"`) and for the whole object (`"get_order_args"`). They cost tokens on every request and tell the model nothing the name does not; harmless, and an example of what a generated schema carries that a hand-written one would not.

**The result is Python, not JSON.** The second line begins `{'id': 'M-1043', ... 'delivered_on': None`: single quotes and `None`. `get_order` returned a dictionary, and the SDK turned it into text with Python's `str()`. A model reads it well enough, and lesson 3's rules for observations still apply: a result that is meant to be read as data is clearer as JSON. **Return a string you built with `json.dumps(...)`** if what the model reads matters to you: the SDK passes a string through unchanged, and turns most other values, a Pydantic model included, into text with `str()`.

None of these is a defect. Each is a default that somebody chose, and knowing it is the difference between an agent you can explain and one you can only run.
