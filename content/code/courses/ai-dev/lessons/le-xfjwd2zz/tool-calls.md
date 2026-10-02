---
title: Tool calls in a stream
version: 1
---

Lesson 8's tool calls stream too. The text arrives as text deltas, and **a tool call's arguments
arrive as pieces of JSON**, in `input_json_delta` events. `tool_stream.py` prints each piece and
says whether everything so far is valid JSON yet.

```python
"""A tool call, streamed: its arguments arrive as pieces of JSON that do not parse until the end."""
import json

import anthropic

TOOLS = [{"name": "get_stock", "description": "Units in stock and unit price in cents for one product, by its SKU.",
          "input_schema": {"type": "object", "properties": {"sku": {"type": "string"}}, "required": ["sku"]}}]
model = anthropic.Anthropic()
with model.messages.stream(model="scripted-1", max_tokens=300, tools=TOOLS,
                           messages=[{"role": "user", "content": "Is LAMP-02 in stock?"}]) as stream:
    sofar = ""
    for event in stream:
        if event.type == "content_block_delta" and event.delta.type == "input_json_delta":
            sofar += event.delta.partial_json
            try:
                json.loads(sofar)
                parses = "parses"
            except json.JSONDecodeError:
                parses = "does not parse yet"
            print(f"{event.delta.partial_json!r:16} {parses}")
    call = stream.get_final_message().content[-1]
print(call.name, call.input)
```

```
ana@dev:~/shop$ python tool_stream.py
'{"sku": "LAM'   does not parse yet
'P-02"}'         parses
get_stock {'sku': 'LAMP-02'}
```

**The first piece does not parse.** It is half a string inside half an object, and no JSON parser
can read it. Only after the last piece is there a complete object, and the SDK hands it over as
`input` on the message it builds at the end.

## What follows from that

- **Run nothing until the block is complete.** A host that acted on a partial argument would look
  up `LAM`, or worse, refund an amount whose last digits had not arrived. Wait for
  `content_block_stop`, or use the final message.
- **Validate as in lesson 8.** A streamed call is checked against its schema exactly like one that
  arrived whole. The pieces change when the arguments arrive, not what they must be.
- **Showing progress is still possible.** A page can say "checking stock…" as soon as
  `content_block_start` names the tool, before any argument has arrived. That is a message about
  what is happening, and it needs nothing parsed.
