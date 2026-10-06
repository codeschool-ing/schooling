---
title: Measuring the choice
version: 1
---

Every strategy in this lesson has an argument for it, and arguments do not settle which one to use on
a particular corpus. A measurement does. `compare.py` cuts all thirteen documents nine ways, embeds
every chunk, and runs the 26 answerable questions of the test set against each set of chunks. A
question counts as **found** when the passage that answers it, the words recorded in `eval.jsonl`, is
inside one of the three chunks retrieved. It also counts how many tokens those three chunks would put
in the prompt.

```
ana@lab:~/rag$ python compare.py
strategy                 chunks  words  found  tokens
fixed, 30 words             227     29  17/26     108
fixed, 60 words             116     57  21/26     217
fixed, 60 + 15 overlap      150     58  24/26     219
fixed, 120 words             62    106  23/26     404
fixed, 240 words             34    194  26/26     768
sections                     92     64  25/26     260
structured, 60 words        137     43  24/26     170
structured, 120 words        99     59  25/26     237
semantic                     98     63  21/26     333
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A scatter of nine chunking strategies: retrieved tokens per question against questions whose answer was retrieved, out of 26. Fixed 30 words: 108 tokens, 17. Fixed 60: 217, 21. Fixed 60 with 15 overlapping: 219, 24. Fixed 120: 404, 23. Fixed 240: 768, 26. Sections: 260, 25. Structured 60: 170, 24. Structured 120: 237, 25. Semantic: 333, 21.\"><path d=\"M70 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 280 L70.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M225.0 280 L225.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"225.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M380.0 280 L380.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M535.0 280 L535.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"535.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">600</text><path d=\"M690.0 280 L690.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">800</text><path d=\"M65 280.0 L70 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><path d=\"M65 232.0 L70 232.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M65 184.0 L70 184.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M65 136.0 L70 136.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"136.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><path d=\"M65 88.0 L70 88.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26</text><text x=\"380.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">retrieved tokens per question, three chunks</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">questions whose answer was retrieved, of 26</text><circle cx=\"153.7\" cy=\"256.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"161.7\" y=\"268.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixed 30</text><circle cx=\"238.2\" cy=\"160.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"246.175\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixed 60</text><circle cx=\"239.7\" cy=\"88.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"247.725\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixed 60+15</text><circle cx=\"383.1\" cy=\"112.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"391.1\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixed 120</text><circle cx=\"665.2\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"657.2\" y=\"54.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixed 240</text><circle cx=\"271.5\" cy=\"64.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"279.5\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sections</text><circle cx=\"201.8\" cy=\"88.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"191.75\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">structured 60</text><circle cx=\"253.7\" cy=\"64.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"245.675\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">structured 120</text><circle cx=\"328.1\" cy=\"160.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"336.075\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">semantic</text></svg>", "caption": "Up and to the left is better: more answers found for fewer tokens. The three that follow the documents' own structure sit at the top left; fixed 240 finds everything at three times the price."}
```

## Reading the table

**The smallest chunks found the fewest answers.** Thirty-word windows found 17 of 26: each one is too
short to carry its context, and the passage that answers a question is often cut across two of them.

**The largest chunks found everything, at three times the price.** Fixed 240-word chunks found all 26,
because a chunk that big usually contains the whole section the answer is in. They put 768 tokens in
the prompt per question, against 237 for structured 120, which found 25. One more answer for 531 more
tokens on every question is a bad trade, and lesson 12 shows how much of that extra text is noise.

**Following the structure dominates.** Sections, structured 120 and structured 60 sit at the top left
of the figure: 24 or 25 found, for 170 to 260 tokens. Structured 60 found 24 with the cheapest
context of any strategy that found more than 21. Nothing the count-based strategies did, overlap
included, matched that combination.

**Overlap was worth its cost; semantic chunking was not, here.** Overlap took fixed 60 from 21 to 24
for two more tokens per question. Semantic chunking found 21, the same as fixed 60 without overlap, and
put more tokens in the prompt than either structured variant.

## What this measurement is and is not

It is a measurement on this corpus and these 26 questions, and the numbers will be different on
yours. **That is the point of running it**: the right chunk size depends on how long the documents'
paragraphs are, how specific the questions are and how many tokens a prompt can afford, and none of
those is a constant anybody can quote you.

It measures retrieval only. A found answer still has to be used by the generator, and lesson 8 measures
the answers too. And 26 questions is a small test set: one question is four percentage points, so the
difference between 24 and 25 is one question and should not decide anything by itself. The large
differences, 17 against 25, or 768 tokens against 237, are the ones to act on.

The habit worth keeping is the shape of `compare.py`: **a fixed set of questions with known answers,
run against every candidate, reporting quality and cost side by side.** Lesson 8 turns it into the
pipeline's permanent test.
