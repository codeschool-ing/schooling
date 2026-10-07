---
title: Why a long conversation costs more than it looks
version: 2
---

Lesson 1 section 10 showed that a chat sends the whole conversation with every new message. The
consequence for cost is the one people do not expect: **the price of a conversation grows with the
square of its length**, not in proportion to it. The tenth message is not ten times the first; the
tenth *request* carries the first nine exchanges, and so did the ninth, and the eighth.

## Measuring it

`~/shop/scratch/conversation.py` simulates twenty turns. Each question is about thirty tokens and
each reply the same fixed text of about a hundred, so that the only thing growing is the history.
Every request is sent with `max_tokens=1`, which makes Ollama read the whole conversation, write a
single token and report how much it read: the counting of lesson 2 section 03, twenty times.

```python
import anthropic

client = anthropic.Anthropic()
REPLY = "Here is a reply of about a hundred tokens. " * 10
history, sent = [], 0
for turn in range(1, 21):
    history.append({"role": "user", "content": f"Question number {turn} about the cart, in about thirty tokens of text."})
    r = client.messages.create(model="llama3.2:3b", max_tokens=1, messages=history)
    n = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    sent += n
    if turn in (1, 2, 5, 10, 15, 20):
        print(f"turn {turn:2}: this request {n:5} tokens, all requests so far {sent:6}")
    history.append({"role": "assistant", "content": REPLY})
```

```
ana@dev:~/shop$ python scratch/conversation.py
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two curves over twenty turns of a conversation. The size of each request grows in a straight line, to 2,434 tokens at turn 20. The total of all requests so far curves upwards, to 24,740 tokens at turn 20.\"><defs><marker id=\"gr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 260 L650 260\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 260 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"216.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5,000</text><text x=\"72\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10,000</text><text x=\"72\" y=\"128.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15,000</text><text x=\"72\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20,000</text><text x=\"72\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25,000</text><text x=\"80.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turn 1</text><text x=\"197.89473684210526\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turn 5</text><text x=\"345.2631578947368\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turn 10</text><text x=\"492.63157894736844\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turn 15</text><text x=\"640.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turn 20</text><path d=\"M80.0 259.6 L109.5 258.5 L197.9 255.2 L345.3 249.7 L492.6 244.1 L640.0 238.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M80.0 259.6 L109.5 258.2 L197.9 247.2 L345.3 206.6 L492.6 138.3 L640.0 42.3\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"259.6\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"109.5\" cy=\"258.5\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"197.9\" cy=\"255.2\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"345.3\" cy=\"249.7\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"492.6\" cy=\"244.1\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"640.0\" cy=\"238.6\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"80.0\" cy=\"259.6\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"109.5\" cy=\"258.2\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"197.9\" cy=\"247.2\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"345.3\" cy=\"206.6\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"492.6\" cy=\"138.3\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"640.0\" cy=\"42.3\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"648.0\" y=\"238.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2,434</text><text x=\"648.0\" y=\"42.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">24,740</text><text x=\"404.2\" y=\"234.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">this request</text><text x=\"374.7\" y=\"180.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">all requests so far</text></svg>", "caption": "Each request grows by one exchange; the total grows by the whole request each turn. Measured by `conversation.py`, with the six turns it printed marked."}
```

The twentieth request is 2,434 tokens, about fifteen times the second. That part is linear. The
second column is the bill: **24,740 input tokens over twenty requests**, for a conversation whose
text, read once, is under two and a half thousand. Doubling the length of a conversation roughly quadruples what its
input costs, which is what happens between turn 10 (6,070) and turn 20.

## What to do about it

- **Cap the history.** Keep the system prompt and the last few exchanges, and drop the oldest.
  The model forgets what was dropped, so do it where forgetting is acceptable, such as a support
  chat that is about one problem at a time.
- **Summarise instead of dropping.** Replace the old turns with a short summary written by a
  cheap model. It costs one extra request now and then, and keeps the gist of what was said.
- **Start fresh when the subject changes.** A new question in an old conversation pays for every
  turn of the old one. Chat interfaces that offer a "new chat" button are offering you a discount.
- **Cache the part that does not change.** The start of every request in a conversation is
  identical to the start of the previous one; lesson 2 section 07 shows how to pay less for it.

None of these is free: each one removes something the model could have used. The measurement is
what lets you decide, and the measurement is `usage`, logged per request and summed per
conversation.
