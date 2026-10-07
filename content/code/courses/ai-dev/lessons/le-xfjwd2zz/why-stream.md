---
title: The wait you can shorten
version: 2
---

A model writes its reply one token at a time, and a long reply takes seconds. **Streaming does not
make the reply faster.** It changes when the reader sees the first word: as soon as it exists,
instead of after the last one. This lesson measures that, reads the stream as it crosses the wire,
carries it to a browser, and handles the two ways a stream ends early.

The replies in this lesson come from `llama3.2:3b` on the recording machine, at about ten tokens a
second, which is slow enough that the difference is hard to miss.

## The same reply, twice

```python
"""The same reply twice: once waited for, once streamed. When does the first word arrive?"""
import time

import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]

t0 = time.monotonic()
r = model.messages.create(model="llama3.2:3b", max_tokens=300, messages=ASK)
done = time.monotonic() - t0
print(f"create: first word after {done:.1f} s, all {r.usage.output_tokens} tokens after {done:.1f} s")

t0 = time.monotonic()
first = None
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        if first is None:
            first = time.monotonic() - t0
    final = stream.get_final_message()
done = time.monotonic() - t0
print(f"stream: first word after {first:.1f} s, all {final.usage.output_tokens} tokens after {done:.1f} s")
```

```
ana@dev:~/shop$ python timing.py
create: first word after 13.6 s, all 132 tokens after 13.6 s
stream: first word after 0.3 s, all 154 tokens after 14.8 s
```

**The totals are the same to within a second**, 13.6 and 14.8, because the model needs about the
same time for 132 tokens as for 154; the two replies are two draws and not the same length. What
changed is the first number. Waited for, the first word arrives with the last one, after thirteen
seconds of nothing. Streamed, it arrives after three tenths of a second, and the reader is reading
while the rest is written.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Two timelines of the same 82-token reply, three point three seconds long. Waited for, nothing appears until the end, then everything at once. Streamed, the first word appears after a tenth of a second and the rest arrives steadily until the same end.\"><defs><marker id=\"wt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waited for</text><rect x=\"130\" y=\"40\" width=\"490\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"375.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing on the screen</text><rect x=\"620\" y=\"40\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">all of it at once</text><text x=\"115\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">streamed</text><rect x=\"146.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"158.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"171.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"183.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"196.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"209.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"221.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"234.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"246.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"259.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"284.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"297.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"309.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"322.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"335.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"347.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"360.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"372.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"385.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"410.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"423.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"435.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"448.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"461.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"473.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"486.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"498.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"511.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"524.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"536.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"549.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"561.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"574.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"587.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"599.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"612.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"624.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"637.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"146\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">first word, 0.1 s</text><path d=\"M654 34 L654 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"658\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.3 s</text></svg>", "caption": "Streaming moves the first word, not the last. The total time is the model's, either way."}
```

## Two numbers worth logging

- **Time to first token**: from sending the request to the first piece of text. It is what a
  person feels as "it is thinking" and it is mostly the provider's queue and the length of your
  prompt, since the model reads all of the input before it writes anything.
- **Total time**: from request to the last piece. It grows with the length of the reply, and
  streaming does nothing for it.

A slow first token and a fast total point at the input: a long prompt, a cold cache, a busy
model. A fast first token and a slow total point at the output: a reply longer than it needs to
be, which `max_tokens` and a tighter prompt address, as in lesson 2.

## When not to stream

**Streaming is for a person watching.** A program that parses the reply as JSON, as in lesson 8,
cannot use half of it, and a batch job that files tickets overnight has nobody to show the first
word to. For those, a plain request is simpler code with the same total time.
