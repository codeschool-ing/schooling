---
title: A stream that breaks halfway
version: 1
---

A plain request either succeeds or fails. **A stream can do both**: it starts, delivers part of the
reply, and then fails. The status code was 200 when the first byte left, so the failure has to
travel inside the stream, as an `error` event.

labllm can be told to fail a stream on purpose. This is the lab's switch, not something a provider
offers:

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"stream_error_after": 12}'; echo
{"rpm": 50, "fail_next": null, "fail_count": 0, "stream_error_after": 12}
```

## What the reader had when it broke

```python
"""A stream that fails partway: what the reader had, and what to do with it."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
shown = ""
try:
    with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
        for text in stream.text_stream:
            shown += text
            print(text, end="", flush=True)
except anthropic.APIError as e:
    print(f"\n[{type(e).__name__}: {e.message}]")
    print(f"[{len(shown)} characters were on the screen and are not an answer]")
```

```
ana@dev:~/shop$ python midstream.py
The cart stores prices as integer cents because a float cannot hold
[APIStatusError: {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}}]
[67 characters were on the screen and are not an answer]
```

**Sixty-seven characters reached the screen before the error.** The SDK raised `APIStatusError`
from inside the loop, with the provider's error in its message. An `overloaded_error` like this one
is a real error type, and it is the provider saying it is busy, not that the request was wrong.

## Through the relay

The relay of lesson 9 section 04 catches the same error and sends its own `error` event to the
page:

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"stream_error_after": 12}' >/dev/null; python relay.py & sleep 1; node client.mjs 'Explain in a paragraph why the cart stores prices in cents.'; kill $!
The cart stores prices as integer cents because a float cannot hold
[error: the answer stopped halfway; please ask again]
```

The page shows the partial text and then the message, and **that pair is the honest state**: these
words arrived, the answer did not. Two wrong ways to handle it are common:

- **Leaving the partial text as if it were the answer.** It reads like an answer, and it stops in
  the middle of a sentence. Mark it, or replace it.
- **Retrying and appending.** A second request starts the reply again from the first word.
  Appended to what is on the screen, it repeats a sentence and a half. A retry replaces.

## Retrying a stream

A failure before the first piece is the same as a failed plain request: retry with backoff, as
lesson 10 shows. A failure after pieces were shown is a decision for the page. **Retrying on its
own** is fine if the new reply replaces the old one and the person can see that it restarted.
**Asking the person** is better when the reply is long and they may have read enough. Either way,
the log should say that a stream broke after N tokens, because those tokens were billed.
