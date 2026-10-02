---
title: One window for the question and the answer
version: 1
---

Every model has a **context window**: the most tokens it can handle in one request. The common
mistake is to read it as the size of the question you may ask. **It is the size of the question
and the answer together.** The model writes its reply into the same window it read the prompt
from, one token at a time, so every token of output you allow is a token the input cannot use.

The request carries the second number. `max_tokens` is the most the model may write, and the API
requires it, because without it the provider would not know how much room to keep. A provider
publishes two limits per model, the window and the most output a single reply may have, and a
request has to fit both.

## Hitting the limits on purpose

labllm's `tiny-1` has a window of 2,048 tokens and lets a reply have at most 512, small on purpose
so the limits are a few lines of text away. `lab/window.py` sends the first *n* words of the
lab's corpus with a given `max_tokens`:

```
ana@dev:~/shop$ python lab/window.py 900 200
max_tokens: 1717 in, 200 out
ana@dev:~/shop$ python lab/window.py 900 400
400 prompt is too long: 1717 tokens + 400 max_tokens > 2048 maximum
ana@dev:~/shop$ python lab/window.py 1300 200
400 prompt is too long: 2292 tokens + 200 max_tokens > 2048 maximum
ana@dev:~/shop$ python lab/window.py 900 600
400 max_tokens: 600 > 512, which is the maximum allowed number of output tokens for tiny-1
```

Read the four lines as four different situations:

- **1,717 in and 200 out fits**, with 131 tokens to spare. The reply stopped at 200 tokens with
  `stop_reason` set to `max_tokens`, which lesson 2 section 08 deals with.
- **The same prompt with 400 out is refused**, although the prompt has not changed. 1,717 plus 400
  is over 2,048. The prompt was fine and the room asked for the answer was not.
- **2,292 in does not fit at all**, whatever `max_tokens` says.
- **600 out is refused before anything is counted**: it is over the per-reply limit of 512, and a
  smaller prompt would not change that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three requests against tiny-1&#x27;s window of 2,048 tokens. 1,717 in and 200 out fits. 1,717 in and 400 out is 2,117 and is refused. 2,292 in with 200 out is refused before output is even considered.\"><defs><marker id=\"wn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tiny-1&#x27;s window: 2,048 tokens</text><text x=\"140\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,717 + 200</text><rect x=\"150\" y=\"50\" width=\"343.40000000000003\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"493.40000000000003\" y=\"50\" width=\"40.0\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"541.4000000000001\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fits</text><text x=\"140\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,717 + 400</text><rect x=\"150\" y=\"102\" width=\"343.40000000000003\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"493.40000000000003\" y=\"102\" width=\"80.0\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"581.4000000000001\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused</text><text x=\"140\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2,292 + 200</text><rect x=\"150\" y=\"154\" width=\"458.40000000000003\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"608.4000000000001\" y=\"154\" width=\"40.0\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"656.4000000000001\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused</text><path d=\"M559.6 36 L559.6 47\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M559.6 77 L559.6 99\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M559.6 129 L559.6 151\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M559.6 181 L559.6 206\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"559.6\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2048</text><rect x=\"560\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"578\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in</text><rect x=\"630\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">out</text></svg>", "caption": "The prompt and the room for the reply share one window. The middle request has the same prompt as the first and is refused for asking for more room."}
```

**All four are `400` errors, raised before any generation**, so they cost nothing and finish in
milliseconds. The rule of adding the prompt to `max_tokens` is labllm's, and it is also how
Anthropic's API treats its recent models: it refuses rather than shortening the reply for you.
Other APIs and older models have quietly cut the output instead, which is worse, because the
request succeeds with less than you asked for. Either way, the check belongs in your code before
the request leaves, which is what lesson 2 section 09 builds.

## How big the real windows are

The windows of the models in lesson 2 section 04's price sheet run from 200,000 tokens to just
over a million, and the most output per reply from 64,000 to 128,000. A million tokens is several
thousand pages. It is easy to conclude from that that the limit no longer matters, and three
things say otherwise:

- **You pay for every input token on every request.** A window you fill is a bill you pay, each
  time; lesson 2 section 05 puts numbers on it.
- **A full window is slower.** The model reads all of it before writing the first token, and the
  wait before the first token grows with the prompt.
- **A full window is not a well-read window.** Models are measurably worse at using information
  buried in the middle of a very long context than at the start or the end, a result first
  published as *Lost in the Middle* (Liu and others, 2023). Putting the whole repository in the
  prompt is not the same as the model having understood it. Lesson 6 retrieves the few passages
  that matter instead.
