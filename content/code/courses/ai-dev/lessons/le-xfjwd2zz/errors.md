---
title: A stream that breaks halfway
version: 2
---

A plain request either succeeds or fails. **A stream can do both**: it starts, delivers part of the
reply, and then fails. The status code was 200 when the first byte left, so the failure has to
travel inside the stream, as an `error` event.

The easiest way to see one is to take the server away while it is writing. Ollama is stopped
below with `sudo pkill -x ollama` five seconds into a reply, which is what closing the terminal that
runs `ollama serve` does, and close to what a dropped connection or a crashed server looks like from
the program's side. Start it again afterwards, with `sudo systemctl start ollama` or `ollama serve`.

## What the reader had when it broke

```python
"""A stream that fails partway: what the reader had, and what to do with it."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
shown = ""
try:
    with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
        for text in stream.text_stream:
            shown += text
            print(text, end="", flush=True)
except Exception as e:  # an API error, or the connection itself, as below
    print(f"\n[{type(e).__module__}.{type(e).__name__}: {e}]")
    print(f"[{len(shown)} characters were on the screen and are not an answer]")
```

```
ana@dev:~/shop$ python midstream.py & sleep 5; sudo pkill -x ollama; wait
The practice of pricing products in cents in cart stores is a historical and cultural convention that originated in the United States. The reason for this is rooted in the country's early commerce practices,
[httpx2.RemoteProtocolError: peer closed connection without sending complete message body (incomplete chunked read)]
[207 characters were on the screen and are not an answer]
```

**Two hundred and seven characters reached the screen before the error.** And the error is not one
of the SDK's: it is `httpx2.RemoteProtocolError`, from the HTTP library underneath, which the SDK
lets through when a connection dies in the middle of a stream. A program that caught only
`anthropic.APIError` would have ended in a traceback with
the half answer on the screen. That is why `midstream.py` catches every exception at this point and
says which one it was: whatever ended the stream, what the reader has is not an answer.

An error the provider sends in the stream, such as `overloaded_error` when it is busy, does arrive
as an `anthropic.APIStatusError`; this one never got the chance, because there was no server left
to send it.

## Through the relay

The relay of lesson 9 section 04 catches the same failure, with the same broad `except`, and sends
its own `error` event to the page:

```
ana@dev:~/shop$ python relay.py & sleep 3; node client.mjs "Explain in a paragraph why the cart stores prices in cents." & sleep 5; sudo pkill -x ollama; wait %2; kill %1
The practice of storing prices in cents in retail stores, particularly in the United States, dates back to the early 20th century. One reason for this convention is historical and practical. Prior
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
