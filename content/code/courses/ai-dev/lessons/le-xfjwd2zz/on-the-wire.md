---
title: What a stream looks like
version: 1
---

A streamed reply is an ordinary HTTP response that does not end straight away. Its content type is
`text/event-stream`, the format browsers call **server-sent events**: blocks of lines separated by
a blank line, each with an `event:` name and a `data:` line of JSON. `curl -N` prints them as they
arrive. The `cut` keeps each line to 110 characters, which shortens two of them here.

```
ana@dev:~/shop$ curl -sN $ANTHROPIC_BASE_URL/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' -d '{"model": "scripted-1", "max_tokens": 50, "stream": true, "messages": [{"role": "user", "content": "Say hello in five words."}]}' | cut -c1-110
event: message_start
data: {"type": "message_start", "message": {"id": "msg_lab_0003", "type": "message", "role": "assistant", "mod

event: content_block_start
data: {"type": "content_block_start", "index": 0, "content_block": {"type": "text", "text": ""}}

event: ping
data: {"type": "ping"}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Hello"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": " from"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": " the"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": " shop"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "'s"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": " assistant"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "."}}

event: content_block_stop
data: {"type": "content_block_stop", "index": 0}

event: message_delta
data: {"type": "message_delta", "delta": {"stop_reason": "end_turn", "stop_sequence": null}, "usage": {"output

event: message_stop
data: {"type": "message_stop"}
```

## Reading the events

- **`message_start`** opens the reply with its id, model and the input tokens, which are known
  before the model writes anything.
- **`content_block_start`** opens one block of the reply, here text. A reply with a tool call has a
  second block, as lesson 9 section 08 shows.
- **`ping`** carries nothing. It keeps a quiet connection from being closed by something in
  between.
- **`content_block_delta`** carries a piece: a `text_delta` with a few characters. Seven of them
  spell the reply, and the pieces follow the tokens: `'s` arrives on its own.
- **`content_block_stop`**, then **`message_delta`** with the `stop_reason` and the output tokens,
  then **`message_stop`**. Only after these is the reply complete.

**The ending is an event, not the connection closing.** A connection that closes without
`message_stop` is a reply that did not finish, and lesson 9 section 07 is about telling the two
apart.

## Why this format

Server-sent events are text, one direction, over plain HTTP. They pass through proxies that would
block other kinds of long-lived connection, a browser has a built-in reader for them, and a person
can debug them with `curl`, as here. Every provider in this course streams this way, with its own
event names inside the same format.
