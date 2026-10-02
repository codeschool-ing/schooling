---
title: Tokens, not words
version: 1
---

Every length setting a model offers counts tokens, and **a token is not a word**. `prompt-engineering`
introduced tokens in its lesson 3 and the output limit in its lesson 15. This lesson takes the limit
again on purpose, with a narrower question: what a cut does to an answer that a program has to read.

The harness counts with `pl tokens`, which takes a file, or `-` for whatever is piped into it:

```
ana@lab:~/triage$ pl tokens prompts/v4-only-json.txt
84 tokens, 59 words, 362 characters
ana@lab:~/triage$ echo 'They were charged twice for order 4471.' | pl tokens -
8 tokens, 7 words, 40 characters
ana@lab:~/triage$ echo '{"summary": "They were charged twice for order 4471."}' | pl tokens -
16 tokens, 8 words, 55 characters
```

In the lab, a run of letters or digits is one token and every punctuation mark is another. The
sentence is seven words and eight tokens, because the full stop counts. Put it inside one JSON field
and it doubles to sixteen: the two braces, the colon and the four quotation marks are a token each,
and so is the field's name.

**A real tokenizer splits differently, and a provider charges by its own count.** Common words tend
to be one token, rare or long words are split into pieces, and punctuation is often merged with what
stands next to it. So the lab's counts are nobody's bill. What carries over is the proportion this
lesson is about: in a JSON answer, a large share of what the model writes is structure.

## Where the tokens of an answer go

Here is one reply from the prompt that asks for the JSON object and nothing else:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t01
│ {
│   "category": "billing",
│   "urgency": "high",
│   "summary": "They were charged twice for order 4471."
│ }
stop: end, tokens in 93, out 32
```

`out 32` is the length of that reply in the lab's tokens. The summary, the part a person reads, is
eight of them. Everything else is the frame: field names, labels and punctuation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The 32 tokens of one reply, in order. 19 are JSON punctuation, 5 are field names and labels, 8 are the summary. A cap of 30 falls after the summary&#x27;s full stop, so the closing quote and brace are never written.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">One reply, 32 tokens, in the order they are written</text><rect x=\"24\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"44\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"64\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"84\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"104\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"124\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"144\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"164\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"184\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"204\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"224\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"244\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"264\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"284\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"304\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"324\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"344\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"364\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"384\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"404\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"424\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"444\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"464\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"484\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"504\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"524\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"544\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"564\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"584\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"604\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"624\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"644\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"32.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"212.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10</text><text x=\"412.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">20</text><text x=\"612.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M622.5 46 L622.5 114\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"616.5\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">max_tokens=30</text><text x=\"628.5\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">never written</text><rect x=\"24\" y=\"154\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"42\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">JSON punctuation: 19</text><rect x=\"254\" y=\"154\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"272\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">field names and labels: 5</text><rect x=\"484\" y=\"154\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"502\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the summary: 8</text></svg>", "caption": "The reply to t01, token by token as the lab counts them. More than half of it is punctuation, and a cap of 30 removes the two tokens that close it."}
```

That proportion decides two things in the rest of this lesson. **A cap chosen by thinking about how
long a summary should be will be too small**, because the summary is a quarter of the reply. And
asking for a shorter summary moves the total less than you would expect, because the frame does not
shrink when the sentence does.
