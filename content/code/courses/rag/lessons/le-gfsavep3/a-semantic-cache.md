---
title: A semantic cache
version: 1
---

A semantic cache matches questions by meaning: it embeds each new question, finds the nearest stored
one, and serves that answer if the similarity is above a threshold. "how long does a refund take" and
"refund timing after return" are one question, and an exact cache stores two answers for them.

`semantic.py` replays the week through a semantic cache at six thresholds, and uses the topic each
question was generated from to count the hits that served an answer to a different question:

```
ana@lab:~/rag$ python semantic.py
threshold  misses  hits  wrong
     0.95      38   462      0
     0.90      35   465      0
     0.85      32   468      0
     0.80      27   473      0
     0.75      24   476     25
     0.70      21   479     25
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Bars for six thresholds of a semantic cache over the week&#x27;s 500 questions. Model calls fall from 38 at 0.95 to 27 at 0.80 with no wrong answers; at 0.75 calls fall to 24 and 25 answers are wrong; at 0.70, 21 calls and 25 wrong.\"><path d=\"M70 240 L540 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 240 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M65 240.0 L70 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 190.0 L70 190.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M65 140.0 L70 140.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M65 90.0 L70 90.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><rect x=\"88.0\" y=\"50.0\" width=\"20\" height=\"190.0\" fill=\"var(--phosphor)\"></rect><text x=\"110.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.95</text><rect x=\"166.0\" y=\"65.0\" width=\"20\" height=\"175.0\" fill=\"var(--phosphor)\"></rect><text x=\"188.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.90</text><rect x=\"244.0\" y=\"80.0\" width=\"20\" height=\"160.0\" fill=\"var(--phosphor)\"></rect><text x=\"266.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.85</text><rect x=\"322.0\" y=\"105.0\" width=\"20\" height=\"135.0\" fill=\"var(--phosphor)\"></rect><text x=\"344.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.80</text><rect x=\"400.0\" y=\"120.0\" width=\"20\" height=\"120.0\" fill=\"var(--phosphor)\"></rect><rect x=\"424.0\" y=\"115.0\" width=\"20\" height=\"125.0\" fill=\"var(--amber)\"></rect><text x=\"422.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.75</text><rect x=\"478.0\" y=\"135.0\" width=\"20\" height=\"105.0\" fill=\"var(--phosphor)\"></rect><rect x=\"502.0\" y=\"115.0\" width=\"20\" height=\"125.0\" fill=\"var(--amber)\"></rect><text x=\"500.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.70</text><text x=\"305.0\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">similarity threshold of the cache</text><rect x=\"566\" y=\"54\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"584\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">model calls</text><rect x=\"566\" y=\"78\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"584\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">wrong answers</text></svg>", "caption": "Lowering the threshold saves calls slowly and then breaks at once: from 0.80 to 0.75 the cache saves three more calls and serves 25 customers the answer to a different question."}
```

From 0.95 down to 0.80, **the misses fall from 38 to 27 with no wrong answers**: eleven model calls
saved over the exact cache. At **0.75, three more calls are saved and 25 answers are wrong**, all of
them a customer asking about one kind of cancellation and served the answer about the other:

```
ana@lab:~/rag$ python near.py
0.867  'Can I cancel a pre-order?'  'Can I cancel my order?'
0.872  'how do I cancel a pre-order'  'how do I cancel an order'
0.774  'how long does a refund take'  'refund timing after return'
```

"Can I cancel a pre-order?" and "Can I cancel my order?" are 0.867 similar, closer than two honest
phrasings of the refund question at 0.774, and they have different answers. **Similarity between
questions measures how alike their words and topics are, not whether they have the same answer.** A
threshold high enough to keep the two cancellations apart is too high to merge the refund phrasings,
and that conflict is in the questions, not in the model.

Three consequences for anyone adding one:

- **The threshold is chosen on a labelled log**, the way lesson 8 chose the floor, and checked on
  questions it was not chosen on. The 0.80 that works here is a number about these forty phrasings.
- **The margin is thin and invisible.** Between 0.80 and 0.75 nothing degraded gradually; it broke. A
  cache that serves wrong answers produces no error and no complaint until a customer acts on one.
- **The gain is the difference from the exact cache**, eleven calls of 486 here, not the difference
  from no cache. Most of what a semantic cache seems to save, an exact cache already saves without any
  wrong answers.
