---
title: One token at a time
version: 2
---

A language model does one thing, over and over: **given the text so far, it gives every possible
next token a probability.** Generating a reply is a loop around that single step: pick a token,
append it to the text, and ask again. The fluent paragraphs, the working code and the confident
wrong answers all come out of the same loop. Most of what this course teaches you to manage
(cost, limits, streaming, hallucination) is a consequence of it.

::: track ai
You took this mechanism apart in `ai-models`, layer by layer. This lesson is the short version a
developer works from, and lessons 6 and 7 compress `rag` and `agents-mcp` the same way. Read those
three for the code around the model, which is what the earlier courses left for this one, and skim
the explanations you already have.
:::

::: track *
You do not need the mathematics of a neural network to work with one, any more than you need a
compiler's internals to write a program. You do need the loop, because every limit you will hit
in this course is a property of it.
:::

## Asking the model for one step

The APIs of the big providers return the finished text and hide the step. Ollama will show it:
asked for one token, it can also return the five candidates it rated highest and the probability
of each, as a logarithm. `~/shop/scratch/next.py` asks for exactly that and prints the
probabilities as percentages:

```python
import json
import math
import sys
import urllib.request

# Ollama's own API rather than an SDK: it can return the probabilities the model
# gave each candidate for the next token, which no provider's API shows.
body = {"model": "llama3.2:3b", "prompt": sys.argv[1], "raw": True, "stream": False,
        "logprobs": True, "top_logprobs": 5, "options": {"num_predict": 1}}
request = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode())
step = json.load(urllib.request.urlopen(request))["logprobs"][0]
for candidate in step["top_logprobs"]:
    print(f"{math.exp(candidate['logprob']):6.1%}  {candidate['token']!r}")
```

`"raw": True` sends the text exactly as written. Without it, Ollama wraps the text in the
template of a chat, and the model answers it instead of continuing it. Ask what follows
`Return the`:

```
ana@dev:~/shop$ python scratch/next.py "Return the"
  7.6%  ' sum'
  5.5%  ' number'
  2.5%  ' first'
  2.4%  ' value'
  2.1%  ' count'
```

That is a probability distribution, and these are its five largest entries. Together they come to
about a fifth; the rest is spread thinly over the 128,000 or so other tokens in this model's
vocabulary. Notice the space at the start of each one: `' sum'` is a single token that includes its
leading space, which section 07 comes back to.

**Nothing has been drawn at random yet**, so your numbers will be close to these. Not identical:
between two runs on the recording machine they moved by up to three points, which section 08
comes back to. Change the context and the distribution changes
with it:

```
ana@dev:~/shop$ python scratch/next.py "Return the number of"
 24.4%  ' elements'
  5.1%  ' nodes'
  4.6%  ' unique'
  4.1%  ' ways'
  3.4%  ' days'
ana@dev:~/shop$ python scratch/next.py "If the file does not"
 72.3%  ' exist'
 10.4%  ' have'
  7.4%  ' contain'
  1.2%  ' already'
  0.7%  ' open'
```

After `If the file does not`, one continuation takes almost three quarters of the probability,
because the model read the whole sentence and `exist` is what that sentence nearly always says
next. After `Return the`, nothing is that clear, and the model spreads its bets. **Both are the
same kind of output**: a score for every token, computed from everything in the context. A model
with a window of a few thousand tokens and one with a million produce exactly this; the larger
window only changes how much text the scores are computed from.

## The loop, and what it writes

Generation repeats the step. `~/shop/scratch/generate.py` asks Ollama to run the whole loop for a
number of tokens, with the settings of the draw that section 08 is about:

```python
import argparse
import json
import urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("prompt")
ap.add_argument("--tokens", type=int, default=20)
ap.add_argument("--temperature", type=float, default=0.8)
ap.add_argument("--top-p", type=float, default=1.0)
ap.add_argument("--seed", type=int, default=1)
a = ap.parse_args()

# "raw" sends the text as it is, so the model continues it rather than replying to it.
body = {"model": "llama3.2:3b", "prompt": a.prompt, "raw": True, "stream": False,
        "options": {"num_predict": a.tokens, "temperature": a.temperature,
                    "top_p": a.top_p, "top_k": 0, "seed": a.seed}}
request = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode())
print(a.prompt + json.load(urllib.request.urlopen(request))["response"])
```

With the temperature at 0, every step takes the single most likely token, which is called
**greedy decoding**:

```
ana@dev:~/shop$ python scratch/generate.py "Return the" --tokens 40 --temperature 0
Return the sum of all the elements in the list.

## Step 1: Define the problem
We need to write a function that takes a list of numbers as input and returns the sum of all the elements
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The generation loop with llama3.2:3b&#x27;s real numbers. The context Return the goes into the model, which gives every possible next token a probability: sum 7.6%, number 5.5%, first 2.5%, value 2.4%, count 2.1%, and the rest spread thinly. One token is picked, sum, appended to the context, and the loop asks again.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">context</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the</text><path d=\"M172 100 L218 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"222\" y=\"70\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"282.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads all of it</text><path d=\"M344 100 L380 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"384\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">next-token distribution</text><text x=\"398\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; sum&#x27;</text><rect x=\"478\" y=\"58\" width=\"76.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7.6%</text><text x=\"398\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; number&#x27;</text><rect x=\"478\" y=\"80\" width=\"55.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"539.0\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.5%</text><text x=\"398\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; first&#x27;</text><rect x=\"478\" y=\"102\" width=\"25.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"509.0\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.5%</text><text x=\"398\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; value&#x27;</text><rect x=\"478\" y=\"124\" width=\"24.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"508.0\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.4%</text><text x=\"398\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; count&#x27;</text><rect x=\"478\" y=\"146\" width=\"21.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.1%</text><text x=\"484\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… and every other token</text><path d=\"M586 100 L604 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"608\" y=\"70\" width=\"96\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pick one</text><text x=\"656.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&#x27; sum&#x27;</text><path d=\"M656 132 L656 240 L95 240 L95 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"376\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">append it, and ask again</text><text x=\"95\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the sum</text></svg>", "caption": "One step of generation, with the numbers `llama3.2:3b` gave for `Return the`. A reply is this step repeated until a stop condition."}
```

**Nothing in that text was asked for.** `Return the` became a coding exercise with a numbered
step and a heading in Markdown, because text that starts that way, in what the model was trained
on, often goes on that way. It stopped mid-sentence because it was allowed forty tokens and used
them all. The model did not decide to write an exercise; at each step, one more token of an
exercise was the likeliest thing to come next.

## What follows from the loop

Four facts about every model you will call come straight from this, and each has a lesson:

- **Output is produced one token at a time**, so a long answer takes longer than a short one,
  in proportion. Lesson 9 shows the tokens to the user as they arrive instead of making them
  wait for the last.
- **You pay per token**, in and out, because tokens are what the model processes. Lesson 2 does
  the arithmetic.
- **The model sees only its context.** It has no memory between requests and no view of your
  files unless they are in the request. Section 10 shows what a conversation really sends.
- **Nothing in the loop checks facts.** The next token is the likely one, and likely is not the
  same as true. Section 11 shows this model doing it, and lesson 11 deals with it in production.
