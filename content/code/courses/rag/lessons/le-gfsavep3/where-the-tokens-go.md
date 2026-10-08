---
title: Where the tokens go
version: 2
---

Lesson 12 split one prompt into its parts. `split.py` does the same for the whole week, from the
counts `priced.py` saved:

```schooling-example
{
  "language": "python",
  "file": "split.py",
  "parts": [
    {
      "code": "import json\n\ncosts = json.load(open(\"costs.json\"))\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]\nanswered = [costs[q[\"text\"]] for q in LOG if costs[q[\"text\"]][\"input\"]]\ntotal = sum(c[\"input\"] + c[\"output\"] for c in answered)\nfor part in (\"instructions\", \"sources\", \"output\"):\n    n = sum(c[part] for c in answered)\n    print(f\"{part:13} {n:6} tokens  {n / total:4.0%}\")\nrest = sum(c[\"input\"] - c[\"instructions\"] - c[\"sources\"] for c in answered)\nprint(f\"{'question etc':13} {rest:6} tokens  {rest / total:4.0%}\")",
      "note": "Where the tokens of the answered questions went: the instructions, the sources, the reply, and the rest of the prompt."
    }
  ]
}
```

```
ana@vm:~/rag$ python split.py
instructions   34506 tokens   19%
sources       104725 tokens   57%
output         26677 tokens   15%
question etc   16580 tokens    9%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"One bar split by where the week&#x27;s tokens went: sources 57%, instructions 19%, output 15%, the question and the rest 9%, of 182,488 tokens over 486 model calls.\"><rect x=\"20.0\" y=\"40\" width=\"128.6\" height=\"40\" fill=\"var(--wire)\"></rect><rect x=\"148.6\" y=\"40\" width=\"390.2\" height=\"40\" fill=\"var(--phosphor)\"></rect><rect x=\"538.8\" y=\"40\" width=\"99.4\" height=\"40\" fill=\"var(--amber)\"></rect><rect x=\"638.2\" y=\"40\" width=\"61.8\" height=\"40\" fill=\"var(--paper-dim)\"></rect><rect x=\"20\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--wire)\"></rect><text x=\"38\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instructions 19%</text><rect x=\"176\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"194\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sources 57%</text><rect x=\"297\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"315\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">output 15%</text><rect x=\"411\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"429\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">question and the rest 9%</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">182,488 tokens over the week's 486 model calls</text></svg>", "caption": "The sources are most of the bill, which is why lesson 12's packing is a cost decision as well as a quality one. The instructions are the same 71 tokens on every call: nearly a fifth of everything, paid 486 times."}
```

**The sources are 57% of the week**, 104,725 tokens of retrieved text and headers. That makes lesson
12's packing a cost decision as well as a quality one: its budget took a fifth off each prompt, and nearly
all of it came out of this line.

**The instructions are 19%**, and they are the strangest line on the bill: the same 71 tokens, lesson
7's system prompt, sent 486 times. Nothing about them changes between calls. That is what the last
technique in this lesson, prompt caching, is for, though, as the section on it shows, 71 tokens is far
too short a prefix for any provider's cache.

The output is 15%. It is short because the replies are short, and it is also the one part the
pipeline controls only indirectly, through the instructions and a `max_tokens` limit. Lesson 9's budget
reserved room for it; this week shows it was never close.
