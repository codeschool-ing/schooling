---
title: One token at a time
version: 1
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

## A model you can see inside

The models you will call through an API have billions of parameters and cannot be inspected in
any useful way. The lab has one small enough to read. **`tinylm` is a table of which token
followed which**, counted over 78,351 tokens of the documentation that ships inside Python's
standard library. It predicts the next token from the last two, and it is a real language model
in the sense that matters here: same input, same kind of output.

Ask it what follows `Return the`:

```
ana@dev:~/shop$ python lab/next.py "Return the"
context used: 2 tokens
  5.0%  ' message'
  4.1%  ' number'
  4.1%  ' current'
  3.3%  ' string'
  3.3%  ' object'
```

That is a probability distribution. The five most likely tokens add up to under 20%; the rest is
spread thinly over every other token the model has seen after those two. Notice the space at the
start of each one: `' message'` is a single token that includes its leading space, which lesson 1
section 03 comes back to.

Change the context and the distribution changes with it:

```
ana@dev:~/shop$ python lab/next.py "Return the number of"
context used: 2 tokens
  7.5%  ' data'
  7.5%  ' context'
  7.5%  ' lines'
  7.5%  ' threads'
  3.8%  ' types'
ana@dev:~/shop$ python lab/next.py "If the file does not"
context used: 2 tokens
 11.5%  ' have'
  7.7%  ' add'
  7.7%  ' check'
  7.7%  ' exist'
  7.7%  ' close'
```

`context used: 2 tokens` is the whole of this model's memory. After `If the file does not`, it
only ever saw `does not`, so `exist` (the word any reader expects) ranks fourth, level with
`add` and `close`. A large model computes the same kind of distribution, over a vocabulary of
about 200,000 tokens, but it looks at **everything in its context window**: hundreds of
thousands of tokens on current models, against two here. That difference is what makes one of
them useful and the other a toy. The output has the same shape in both.

## The loop, and how it goes wrong

Generation repeats the step. This run always takes the single most likely token, which is called
**greedy decoding**:

```
ana@dev:~/shop$ python lab/generate.py "Return the" --tokens 40 --temperature 0
Return the message's header by summing up all threads started from the
        the type of the
        the type of the
        the type of the
        the type of the
        the type
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The generation loop with tinylm&#x27;s real numbers. The context Return the goes into the model, which gives every possible next token a probability: message 5.0%, number 4.1%, current 4.1%, string 3.3%, object 3.3%, and the rest spread thinly. One token is picked, message, appended to the context, and the loop asks again.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">context</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the</text><path d=\"M172 100 L218 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"222\" y=\"70\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"282.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads all of it</text><path d=\"M344 100 L380 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"384\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">next-token distribution</text><text x=\"398\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; message&#x27;</text><rect x=\"478\" y=\"58\" width=\"70.0\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"554.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.0%</text><text x=\"398\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; number&#x27;</text><rect x=\"478\" y=\"80\" width=\"57.39999999999999\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"541.4\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.1%</text><text x=\"398\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; current&#x27;</text><rect x=\"478\" y=\"102\" width=\"57.39999999999999\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"541.4\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.1%</text><text x=\"398\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; string&#x27;</text><rect x=\"478\" y=\"124\" width=\"46.199999999999996\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.2\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.3%</text><text x=\"398\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&#x27; object&#x27;</text><rect x=\"478\" y=\"146\" width=\"46.199999999999996\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.2\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.3%</text><text x=\"484\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… and every other token</text><path d=\"M586 100 L604 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"608\" y=\"70\" width=\"96\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pick one</text><text x=\"656.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&#x27; message&#x27;</text><path d=\"M656 132 L656 240 L95 240 L95 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"376\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">append it, and ask again</text><text x=\"95\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Return the message</text></svg>", "caption": "One step of generation, with the numbers `tinylm` printed for `Return the`. A reply is this step repeated until a stop condition."}
```

**It falls into a loop and stays there.** Once `the type of the` has been written, the last two
tokens are `of the`, the most likely continuation of those is the same as last time, and nothing
in a greedy loop ever chooses differently. Large models repeat themselves under greedy decoding
too, less often and over longer stretches, and the providers' defaults pick at random from the
distribution rather than always taking the top. Lesson 1 section 04 shows how that choice is
controlled.

## What follows from the loop

Four facts about every model you will call come straight from this, and each has a lesson:

- **Output is produced one token at a time**, so a long answer takes longer than a short one,
  in proportion. Lesson 9 shows the tokens to the user as they arrive instead of making them
  wait for the last.
- **You pay per token**, in and out, because tokens are what the model processes. Lesson 2 does
  the arithmetic.
- **The model sees only its context.** It has no memory between requests and no view of your
  files unless they are in the request. Lesson 1 section 06 shows what a conversation really
  sends.
- **Nothing in the loop checks facts.** The next token is the likely one, and likely is not the
  same as true. Lesson 1 section 07 shows the small model doing it, and lesson 11 deals with it
  in production.
