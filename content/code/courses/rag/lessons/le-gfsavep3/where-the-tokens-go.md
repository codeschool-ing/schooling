---
title: Where the tokens go
version: 1
---

Lesson 12 split one prompt into its parts. `split.py` does the same for the whole week, from the
counts `priced.py` saved:

```
ana@lab:~/rag$ python split.py
instructions   34506 tokens   21%
sources       104725 tokens   62%
output         22563 tokens   13%
question etc    5888 tokens    4%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"One bar split by where the week&#x27;s tokens went: sources 62%, instructions 21%, output 13%, the question and the rest 4%, of 167,682 tokens over 486 model calls.\"><rect x=\"20.0\" y=\"40\" width=\"139.9\" height=\"40\" fill=\"var(--wire)\"></rect><rect x=\"159.9\" y=\"40\" width=\"424.7\" height=\"40\" fill=\"var(--phosphor)\"></rect><rect x=\"584.6\" y=\"40\" width=\"91.5\" height=\"40\" fill=\"var(--amber)\"></rect><rect x=\"676.1\" y=\"40\" width=\"23.9\" height=\"40\" fill=\"var(--paper-dim)\"></rect><rect x=\"20\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--wire)\"></rect><text x=\"38\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instructions 21%</text><rect x=\"176\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"194\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sources 62%</text><rect x=\"297\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"315\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">output 13%</text><rect x=\"411\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"429\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">question and the rest 4%</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">167,682 tokens over the week's 486 model calls</text></svg>", "caption": "The sources are most of the bill, which is why lesson 12's packing is a cost decision as well as a quality one. The instructions are the same 71 tokens on every call: a fifth of everything, paid 486 times."}
```

**The sources are 62% of the week**, 104,725 tokens of retrieved text and headers. That makes lesson
12's packing a cost decision as well as a quality one: its budget took a fifth off each prompt, and nearly
all of it came out of this line.

**The instructions are 21%**, and they are the strangest line on the bill: the same 71 tokens, lesson
7's system prompt, sent 486 times. Nothing about them changes between calls. That is what the last
technique in this lesson, prompt caching, is for, though, as the section on it shows, 71 tokens is far
too short a prefix for any provider's cache.

The output is 13%. It is short because the replies are short, and it is also the one part the
pipeline controls only indirectly, through the instructions and a `max_tokens` limit. Lesson 9's budget
reserved room for it; this week shows it was never close.
