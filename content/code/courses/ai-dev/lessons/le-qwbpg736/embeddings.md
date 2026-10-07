---
title: Meaning as a position
version: 2
---

Before a model can do anything with a token, it turns it into a list of numbers, a **vector**.
Those vectors are learnt during training so that tokens used in similar ways end up close
together, and that closeness is the closest thing a model has to meaning. The same idea, applied
to a whole sentence instead of one token, gives an **embedding**: one vector per text, made by a
model trained for exactly that, so that texts about the same thing land near each other.

You will use embeddings directly, without any generation at all, to search documents by what
they say rather than by the words they share. Lesson 6 builds that. This section is about what
the numbers are and what they cannot do.

## A text becomes 256 numbers

The embedding model you installed with the libraries is **WordLlama**, a small model that runs on
a laptop's processor in milliseconds. The first time it is loaded it downloads one small file, its
tokenizer's settings, and keeps it. It turns any text into 256 numbers:

```
ana@dev:~/shop$ python -c 'from wordllama import WordLlama; v = WordLlama.load().embed(["the cart total is wrong"]); print(v.shape, v.dtype); print(v[0][:6].round(3))'
(1, 256) float32
[-0.189 -0.251 -0.139  0.108  0.091 -0.229]
```

No single number means anything on its own. What means something is **the direction the whole
vector points in**, compared with another one. The usual comparison is **cosine similarity**: 1
when two vectors point the same way, 0 when they are unrelated, and below 0 when they point
apart.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three embeddings drawn as arrows from one point. The query, the cart total is wrong, points right. The cart page loads slowly points 58 degrees away, a cosine of 0.529. Our office opens at nine points 92 degrees away, a cosine of minus 0.028.\"><defs><marker id=\"an-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M150 260 L380.0 260.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><path d=\"M150 260 L271.7 64.8\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><path d=\"M150 260 L143.6 30.1\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><circle cx=\"150\" cy=\"260\" r=\"3\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"388.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">query</text><text x=\"388.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">the cart total is wrong</text><text x=\"281.7\" y=\"58.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">the cart page loads slowly</text><text x=\"281.7\" y=\"74.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">close: cosine 0.529</text><text x=\"153.6\" y=\"24.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">our office opens at nine</text><text x=\"153.6\" y=\"40.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">unrelated: cosine −0.028</text><path d=\"M210 260 A60 60 0 0 0 181.7 209.1\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M190 260 A40 40 0 0 0 148.9 220.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Similarity is the angle between two vectors. These angles are the real cosines from the capture below, drawn in two dimensions; WordLlama's vectors have 256."}
```

## Asking which sentences are close

`~/shop/scratch/similar.py` embeds a query and a few candidate texts, and lists the candidates by
cosine similarity to the query:

```python
import sys

import numpy as np
from wordllama import WordLlama

wl = WordLlama.load()
query, *texts = [line.strip() for line in sys.stdin if line.strip()]
vectors = wl.embed([query] + texts, norm=True)
scores = vectors[1:] @ vectors[0]
print(f"query: {query}")
for i in np.argsort(-scores):
    print(f"  {scores[i]:+.3f}  {texts[i]}")
```

Here is a support question against four sentences, two of which are the same complaint in other
words:

```
ana@dev:~/shop$ printf "%s\n" "the cart total is wrong" "checkout adds up the order incorrectly" "the sum shown at checkout is too high" "the cart page loads slowly" "our office opens at nine" | python scratch/similar.py
query: the cart total is wrong
  +0.529  the cart page loads slowly
  +0.347  checkout adds up the order incorrectly
  +0.178  the sum shown at checkout is too high
  -0.028  our office opens at nine
```

The unrelated sentence comes last, as it should. **But the winner is wrong.** A slow page is a
different problem from a wrong total, and it ranks first because it shares the words `the cart`.
WordLlama is small and leans heavily on the words themselves; the two rephrasings share almost
no words with the query and lose to a sentence that does. Larger embedding models, the ones the
providers sell, are much better at paraphrase. They still make this kind of mistake, less often,
and no score tells you when they have.

The second limit shows up even in good models:

```
ana@dev:~/shop$ printf "%s\n" "the coupon was accepted" "the coupon was not accepted" "the coupon was refused" "the voucher was accepted" | python scratch/similar.py
query: the coupon was accepted
  +0.964  the coupon was not accepted
  +0.664  the coupon was refused
  +0.271  the voucher was accepted
```

**The opposite statement is the closest match, at 0.964.** An embedding places a text by its
subject, and *was accepted* and *was not accepted* are about the same subject. Embeddings answer
"is this about the same thing?", not "does this say the same thing?". A search built on them finds
the passage about refunds. Reading it to see whether refunds are allowed is the generating
model's job, or yours.

## What to take from these numbers

- **A similarity score is a ranking, not a verdict.** 0.529 here does not mean "53% the same";
  scores from different models are not even on the same scale. Compare scores only with other
  scores from the same model.
- **Test an embedding model on your own material** before you trust it, with a handful of
  queries whose right answers you know. Lesson 6 does that and turns it into a number.
- **Exact identifiers are a weak spot.** An error code or a product reference is a string to be
  matched, not a meaning to be approximated; lesson 6 adds keyword search for exactly that case.
