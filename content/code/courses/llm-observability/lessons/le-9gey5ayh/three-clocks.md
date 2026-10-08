---
title: Three clocks on one call
version: 2
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
stream = client.chat.completions.create(model="llama3.2:3b", temperature=0, stream=True, messages=[
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
ana@dev:~/obs$ python stream.py
    720 ms   first  'A'
    816 ms     +96  ' gift'
    912 ms     +96  ' card'
    998 ms     +87  ' is'
   1091 ms     +93  ' valid'
   1198 ms    +107  ' for'
   1304 ms    +106  ' two'
   1412 ms    +108  ' years'
   1524 ms    +112  ' from'
   1631 ms    +107  ' purchase'
   1739 ms    +108  '.'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A time axis from 0 to 1,800 ms. The request leaves at 0. Nothing arrives until the first piece at 720 ms. After that a piece arrives every 100 ms or so, eleven in all, the last at 1,739 ms. The span from 0 to 720 is labelled time to first token; the span from 720 to 1,739 is labelled time per output token, times the number of tokens.\"><path d=\"M50 110 L680 110\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"50\" cy=\"110\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"50\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">request sent</text><rect x=\"299.0\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"332.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"366.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"396.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"428.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"466.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"503.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"541.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"580.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"617.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"655.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M50 136 L302.0 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50 130 L50 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130 L302.0 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"176.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">time to first token: 720 ms</text><path d=\"M302.0 80 L658.6 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 74 L302.0 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M658.6 74 L658.6 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"480.3\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">then about 100 ms a token, 11 pieces</text><text x=\"658.6\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">whole call: 1,739 ms</text><path d=\"M50 170 L680 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50.0 170 L50.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M155.0 170 L155.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"155.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M260.0 170 L260.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"260.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M365.0 170 L365.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"365.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900</text><path d=\"M470.0 170 L470.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,200</text><path d=\"M575.0 170 L575.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"575.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,500</text><path d=\"M680.0 170 L680.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,800</text><text x=\"365\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milliseconds since the request left</text></svg>", "caption": "Two different waits. The first is the model reading the prompt; the second grows with the length of the answer."}
```

**Time to first token**, 720 ms here, is how long the customer stares at an empty reply. The model
spends it reading the prompt and producing the first token, and a hosted provider adds the time the
request waits in its queue; the longer the prompt, the longer the reading. It decides whether the
assistant *feels* fast, because once text is moving a reader is reading.

**Time per output token**, about 100 ms here after the first, is how fast the text arrives once it
starts. It is a property of the model and of the machine running it, and of how busy that machine
is, and it sets how long a long answer takes: eleven pieces at 100 ms is about a second, a hundred
would be ten.

**The whole call**, 1,739 ms, is the first plus the second times the number of tokens. It decides
how long the request holds a connection, a worker and a place in any rate limit, and it is what the
application waits for before it can check citations or store the reply.

These are a processor's numbers: four cores and no graphics card, running a three-billion-parameter
model. A hosted provider on its own hardware is several times faster on both clocks, and a graphics
card on your machine would be too. **The shape is the same**, which is why it is worth measuring
each clock separately.

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
