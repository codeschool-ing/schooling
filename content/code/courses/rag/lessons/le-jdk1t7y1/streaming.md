---
title: Streaming
version: 2
---

A reply arrives faster than it seems if the first words are shown while the rest is still being
written. **Streaming** asks the provider to send the reply in pieces as they are produced, over one
long HTTP response, instead of waiting for the whole of it. For a support chat, it is the difference
between a blank box for two seconds and words appearing at once.

```schooling-example
{
  "language": "python",
  "file": "stream.py",
  "parts": [
    {
      "code": "import sys\n\nfrom openai import OpenAI\nfrom rag import SYSTEM, retrieve",
      "note": "The search and the instructions from `rag.py`."
    },
    {
      "code": "client = OpenAI()\nquestion = sys.argv[1]\nsources = retrieve(question)\nnumbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                       for n, (_, path, text, updated, _) in enumerate(sources, 1))",
      "note": "The prompt is built exactly as before."
    },
    {
      "code": "stream = client.chat.completions.create(\n    model=\"llama3.2:3b\", temperature=0, stream=True, stream_options={\"include_usage\": True},\n    messages=[{\"role\": \"system\", \"content\": SYSTEM},\n              {\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}])",
      "note": "`stream=True` turns the reply into an iterator of chunks, and `include_usage` asks for the token counts in a last chunk of its own."
    },
    {
      "code": "pieces = 0\nfor chunk in stream:\n    if chunk.choices and chunk.choices[0].delta.content:\n        print(chunk.choices[0].delta.content, end=\"\", flush=True)\n        pieces += 1\n    if chunk.usage:\n        usage = chunk.usage\nprint()\nprint(f\"{pieces} pieces; usage: {usage.prompt_tokens} in, {usage.completion_tokens} out\")",
      "note": "Each chunk's text is printed the moment it arrives; the usage is kept from the chunk that carries it."
    }
  ]
}
```

```
ana@vm:~/rag$ python stream.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought. This is also confirmed by [2], which states that gift cards are valid for two years from purchase.
41 pieces; usage: 336 in, 42 out
```

**The reply arrived in 41 pieces**, each about a token's worth of text, printed as
the model wrote it, and the usage arrived with the last piece because the request asked for it with
`include_usage`. On a processor with no graphics card the difference is the whole experience: the
first words appear within a second or two of the search, and the rest follows at reading speed.

## What streaming changes for a retrieval pipeline

**The search still happens first.** Nothing can be streamed until the sources are found and the
prompt is built, so the time before the first word is the search's time plus the model's time to its
first token. Streaming hides generation time, never retrieval time; a slow search is still a slow
first word.

**Citations arrive at the end, or in pieces.** In Chat Completions the `[1]` markers are ordinary text
and stream with the rest; turning them into links has to wait until each one is complete. In
Anthropic's API, citations arrive as their own `citations_delta` events attached to the block they
belong to.

**Checks run after.** Lesson 7's citation check and any refusal decided after generation need the
whole reply. So a streamed reply is shown as it arrives and then possibly corrected or annotated, which
is a choice of interface: some teams show the stream and add warnings at the end, others hold back a
legal answer until it has been checked. Either way, **the refusal decided by the floor needs no
streaming at all**, which is one more reason to decide it before the model is called.

## The usage line

Streaming changes how the usage arrives, not what it is: 336 tokens in and
42 out, which the log in the last section of this lesson records the same way
for a reply that was not streamed. Lesson 17 adds those two numbers up
across every query, and a streamed reply whose usage was never read is a query that cost something
nobody counted, which is why the program asks for it.
