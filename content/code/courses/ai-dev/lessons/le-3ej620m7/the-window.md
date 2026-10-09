---
title: One window for the question and the answer
version: 2
---

Every model has a **context window**: the most tokens it can handle in one request. The common
mistake is to read it as the size of the question you may ask. **It is the size of the question
and the answer together.** The model writes its reply into the same window it read the prompt
from, one token at a time, so every token of output you allow is a token the input cannot use.

The request carries the second number. `max_tokens` is the most the model may write, and
Anthropic's API requires it, because without it the provider would not know how much room to
keep. A provider publishes two limits per model, the window and the most output a single reply
may have, and a request has to fit both.

## What happens past the edge

Llama 3.2 was trained for a window of 128,000 tokens, but **Ollama runs it with a window of
4,096** unless told otherwise, because every token of window costs memory: that is the `CONTEXT`
column `ollama ps` printed in lesson 1. Four thousand tokens is a few pages, close enough to reach
on purpose. `~/shop/scratch/window.py` writes a password at the top of a long text, pads it with
copies of `CONVENTIONS.md`, and asks for the password at the bottom:

```python
import sys

import anthropic
import tiktoken

client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
copies = int(sys.argv[1])
text = ("The password for this exercise is PINEAPPLE.\n\n" + open("CONVENTIONS.md").read() * copies
        + "\n\nWhat is the password for this exercise? Answer with the word only.")
r = client.messages.create(model="llama3.2:3b", max_tokens=20,
                           messages=[{"role": "user", "content": text}])
read = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
print(f"sent about {len(enc.encode(text))}, read {read}: {r.stop_reason}, {r.content[0].text!r}")
```

It prints two numbers: what `tiktoken` estimates was sent, and what Ollama says the model read.
Two copies, ten, and twelve:

```
ana@dev:~/shop$ python scratch/window.py 2
sent about 772, read 805: end_turn, 'PINEAPPLE'
ana@dev:~/shop$ python scratch/window.py 10
sent about 3764, read 3829: end_turn, 'PINEAPPLE'
ana@dev:~/shop$ python scratch/window.py 12
sent about 4512, read 2050: end_turn, 'shop'
```

Read the three lines as three situations:

- **Two copies fit easily.** The two counts differ by a few dozen tokens, because `tiktoken` is
  not this model's tokenizer and does not see the wrapping around a message; the next section is
  about that difference.
- **Ten copies fit too, barely.** 3,829 tokens read, of 4,096, with room left for the twenty of
  the answer. The password at the very top was found.
- **Twelve copies did not fit, and nothing said so.** About 4,512 tokens were sent and the model
  read 2,050. Ollama kept the end of the prompt, dropped the beginning, and the password went with
  it. The request still ended with `end_turn`, and the model still answered, with a word from the
  part it was given.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three requests against Ollama&#x27;s window of 4,096 tokens for llama3.2:3b. Two copies: 805 tokens read, the password found. Ten copies: 3,829 read, found. Twelve copies: about 4,512 sent, the beginning dropped, 2,050 read, and the answer was shop.\"><text x=\"150\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ollama&#x27;s window for llama3.2:3b: 4,096 tokens</text><text x=\"140\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 copies</text><rect x=\"150\" y=\"50\" width=\"78.6\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"236.6\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read 805: PINEAPPLE</text><text x=\"140\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10 copies</text><rect x=\"150\" y=\"102\" width=\"373.9\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"531.9\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read 3,829: PINEAPPLE</text><text x=\"140\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12 copies</text><rect x=\"150\" y=\"154\" width=\"240.4\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"390.4\" y=\"154\" width=\"200.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"270.2\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dropped</text><text x=\"598.6\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">read 2,050: shop</text><path d=\"M550.0 36 L550.0 47\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M550.0 77 L550.0 99\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M550.0 129 L550.0 151\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M550.0 181 L550.0 206\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"550.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4096</text><text x=\"150\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the password was the first line; the dropped part held it</text></svg>", "caption": "The prompt and the reply share one window. The third request was cut from the front without a word, and the password at the top went with what was cut."}
```

**That is the worse of the two ways a window can be enforced.** Anthropic's API refuses a request
whose prompt and `max_tokens` do not fit, with a `400` error, before anything is generated: it
costs nothing and says exactly what is wrong. Ollama, and some other APIs and older models, cut
the input or the output instead, and the request succeeds with less than you sent. Either way,
**the check belongs in your code before the request leaves**, which is what lesson 2 section 09
builds. And where a tool shortens things quietly, a test like this one, with a fact at the start
that only survives if everything arrives, is how you find out.

## How big the real windows are

The windows of the models in lesson 2 section 04's price sheet run from 200,000 tokens to just
over a million, and the most output per reply from 64,000 to 128,000. A million tokens is several
thousand pages. It is easy to conclude from that that the limit no longer matters, and three
things say otherwise:

- **You pay for every input token on every request.** A window you fill is a bill you pay, each
  time; lesson 2 section 05 puts numbers on it.
- **A full window is slower.** The model reads all of it before writing the first token, and the
  wait before the first token grows with the prompt. On the recording machine, a request with
  1,417 new tokens to read took 47.9 seconds and the next, with 11, took 8.9; lesson 2 section 07
  has both.
- **A full window is not a well-read window.** Models are measurably worse at using information
  buried in the middle of a very long context than at the start or the end, a result first
  published as *Lost in the Middle* (Liu and others, 2023). Putting the whole repository in the
  prompt is not the same as the model having understood it. Lesson 6 retrieves the few passages
  that matter instead.
