---
title: Three clocks on one call
version: 1
---

A web request has one latency: from the request to the response. A streamed model call has three,
and they answer different questions, so a single number for "how long the model took" hides most of
what matters.

`stream.py` asks for one streamed reply and prints the moment each piece of it arrived:

```python
"""stream.py: one streamed reply, with the moment each piece arrived."""
import time

from openai import OpenAI

client = OpenAI()
start = time.monotonic()
stream = client.chat.completions.create(model="extract-1", stream=True, messages=[
    {"role": "user", "content": "[1] gift-cards.md\nGift cards are valid for two years from purchase "
     "and cannot be exchanged for cash.\n\nQuestion: How long is a gift card valid?"}])
last = None
for chunk in stream:
    for c in chunk.choices:
        if c.delta.content:
            now = (time.monotonic() - start) * 1000
            gap = f"+{now - last:.0f}" if last is not None else "first"
            print(f"{now:7.0f} ms  {gap:>6}  {c.delta.content!r}")
            last = now
```

```
ana@lab:~/obs$ python stream.py
    244 ms   first  'Gift'
    262 ms     +17  ' cards'
    286 ms     +24  ' are'
    309 ms     +24  ' valid'
    333 ms     +24  ' for'
    357 ms     +24  ' two'
    381 ms     +24  ' years'
    404 ms     +24  ' from'
    428 ms     +24  ' purchase'
    452 ms     +24  ' and'
    476 ms     +24  ' cannot'
    500 ms     +24  ' be'
    524 ms     +24  ' exchanged'
    548 ms     +24  ' for'
    571 ms     +24  ' cash'
    595 ms     +24  '.'
    619 ms     +24  ' ['
    643 ms     +24  '1'
    667 ms     +24  ']'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A time axis from 0 to 700 ms. The request leaves at 0. Nothing arrives until the first piece at 244 ms. After that a piece arrives every 24 ms or so, nineteen in all, the last at 667 ms. The span from 0 to 244 is labelled time to first token; the span from 244 to 667 is labelled time per output token, times the number of tokens.\"><path d=\"M50 110 L680 110\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"50\" cy=\"110\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"50\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">request sent</text><rect x=\"266.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"282.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"304.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"325.1\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"346.7\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"368.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"389.9\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"410.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"432.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"453.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"475.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"497\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"518.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"540.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"560.9\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"582.5\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"604.1\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"625.7\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"647.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M50 136 L269.6 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50 130 L50 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M269.6 130 L269.6 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"159.8\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">time to first token: 244 ms</text><path d=\"M269.6 80 L650.3 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M269.6 74 L269.6 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M650.3 74 L650.3 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"459.5\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">then about 24 ms a token, 19 pieces</text><text x=\"650.3\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">whole call: 667 ms</text><path d=\"M50 170 L50 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M140 170 L140 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M230 170 L230 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M320 170 L320 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"320\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M410 170 L410 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"410\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M500 170 L500 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"500\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500</text><path d=\"M590 170 L590 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"590\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M680 170 L680 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">700</text><path d=\"M50 170 L680 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"365\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milliseconds since the request left</text></svg>", "caption": "Two different waits. The first is the provider queueing the request and reading the prompt; the second grows with the length of the answer."}
```

**Time to first token**, 244 ms here, is how long the customer stares at an empty reply. A provider
spends it queueing the request, reading the prompt, and producing the first token; the longer the
prompt, the longer the reading. It decides whether the assistant *feels* fast, because once text is
moving a reader is reading.

**Time per output token**, about 24 ms here after the first, is how fast the text arrives once it
starts. It is a property of the model and of how busy the provider is, and it sets how long a long
answer takes: nineteen pieces at 24 ms is about 420 ms, a hundred would be over two seconds.

**The whole call**, 667 ms, is the first plus the second times the number of tokens. It decides how
long the request holds a connection, a worker and a place in any rate limit, and it is what the
application waits for before it can check citations or store the reply.

The first two are labobs' rules showing through: 180 ms plus a little per input token before the
first, 25 ms per token after it, both multiplied by a factor drawn per request. A real provider's
numbers are larger or smaller and vary more; **the shape is the same**, which is why it is worth
measuring each clock separately.

## On the span

The assistant records all three. The span's start and end give the whole call. The first piece of
text sets `app.time_to_first_token_ms` and adds an event called `gen_ai.first_token` at that moment,
so a tool drawing the trace can mark it on the bar. The time per token is not recorded, because it is
arithmetic on the other two and the output token count, and the next section computes it for the
whole week.

Recording the first token needs **streaming**. A non-streamed call returns everything at once, and
its first token and its last arrive in the same instant, as far as the client can tell. That is one
reason the assistant streams even where nothing displays the text as it comes: the clock is worth
having.
