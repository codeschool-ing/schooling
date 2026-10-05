---
title: Diversity
version: 1
---

A list of the five nearest books is five answers to one question, and books that all sit close to
one point cannot be far from each other. A reader who sees five nearly identical suggestions has
really been offered one. The author cap of the previous section is a rule for one
kind of sameness. **Maximal Marginal Relevance**, MMR, is a general one: pick the books one at a
time, and make each new pick pay for how much it resembles the picks already made.

## The rule

At each step, every remaining book gets a value:

```localised
value = lambda * similarity to the reader - (1 - lambda) * highest similarity to any book already picked
```

The book with the highest value is picked, and the step repeats until the list is full. `lambda`,
written λ from here on, is a dial between 0 and 1. At 1, the second term vanishes and MMR is the
plain ranking. As it falls, resemblance to what is already on the list costs more, and a book that brings something
new can overtake one that is slightly closer to the reader.

```schooling-example
{
  "language": "python",
  "file": "mmr.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom books import B, books, readers, row\n\nr = readers[\"r02\"]\nv = B[[row[i] for i in r[\"finished\"]]].mean(axis=0)\nv /= np.linalg.norm(v)\npool = [i for i in range(len(books)) if books[i][\"id\"] not in r[\"finished\"]]",
      "note": "Caio's vector, and the pool of books he has not finished."
    },
    {
      "code": "def mmr(v, pool, k, lam):\n    chosen, pool = [], list(pool)\n    while pool and len(chosen) < k:\n        def value(i):\n            like = max((B[i] @ B[j] for j in chosen), default=0.0)\n            return lam * (B[i] @ v) - (1 - lam) * like\n        best = max(pool, key=value)\n        chosen.append(best)\n        pool.remove(best)\n    return chosen",
      "note": "At every step, each remaining book's value is its similarity to the reader, weighted by `lam`, minus its highest similarity to a book already chosen, weighted by `1 - lam`. The best is chosen and leaves the pool."
    },
    {
      "code": "for lam in (1.0, 0.7, 0.6, 0.5):\n    print(f\"lambda {lam}\")\n    for i in mmr(v, pool, 5, lam):\n        print(f\"  {B[i] @ v:.3f}  {books[i]['id']}  {books[i]['genre']:15} {books[i]['title']}  ({books[i]['author']})\")",
      "note": "The same reader at four settings of the dial. The score printed is the plain similarity to Caio, so the lists can be compared."
    }
  ]
}
```

```
ana@lab:~/emb$ python mmr.py
lambda 1.0
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.400  b18  science fiction The Invisible Man  (H. G. Wells)
lambda 0.7
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.400  b18  science fiction The Invisible Man  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
lambda 0.6
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.303  b51  non-fiction     The Art of War  (Sun Tzu)
lambda 0.5
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.176  b06  romance         Persuasion  (Jane Austen)
  0.303  b51  non-fiction     The Art of War  (Sun Tzu)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
```

## Reading the four lists

**At λ = 1.0 the list is the ranking from `reader.py`**, which is the check that the code is right.
At 0.7 two books swap places and nothing else changes: Caio's candidates are already varied enough
that a small penalty finds nothing worth replacing.

At 0.6 *The Invisible Man* leaves, and **The Art of War** comes in at 0.303, a book about strategy
for a reader of science fiction. At 0.5 the second place goes to **Persuasion**, a romance, at
0.176, the furthest from Caio of anything on any of the four lists. That is MMR doing what it was
told: Persuasion resembles nothing already picked, and at that setting being different counts as
much as being relevant.

**The dial has no correct setting, and this catalogue shows why it has to be measured.** Between 0.7
and 0.5 the list goes from barely changed to absurd in two steps. Where the useful middle sits
depends on how similar the candidates are to each other, which depends on the catalogue and the
model. In a catalogue holding forty editions of one classic, the penalty would bite at a far higher
λ than here. The way to choose is the usual one: try a few settings, and measure what readers do with the lists.

## What MMR does not see

*Around the World in Eighty Days* stayed on every list, beside *Journey to the Centre of the Earth*,
both by Verne. MMR compares the vectors, and the vectors were made from titles and blurbs; the
author's name was never embedded, so to MMR two books by one author are only as similar as their
stories. Sameness that lives in the metadata is caught by a rule on the metadata, which is why the
author cap and MMR are used together rather than one instead of the other.

MMR also appears outside recommendations. A search that returns five chunks of the same paragraph
is wasting four places, and the same rule can keep the passages handed to a language model, the
subject of `rag`, from repeating each other.
