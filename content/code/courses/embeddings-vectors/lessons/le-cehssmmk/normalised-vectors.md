---
title: Vectors that are not normalised
version: 1
---

all-MiniLM-L6-v2 divides every vector by its length before returning it, so its vectors are
**normalised**: length 1, every one. That is a choice, not a law, and a model that skips it brings
the trap from *The dot product, by hand* back into a real search.

WordLlama skips it by default. Lesson 1 passed `norm=True` to WordLlama on purpose; `lengths.py`
leaves it out:

```schooling-example
{
  "language": "python",
  "file": "lengths.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\nW = wl.embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Embed the 40 articles with WordLlama, without `norm=True`, so each vector keeps the length the model gave it."
    },
    {
      "code": "for text in [\"refund\", \"When your refund arrives\"]:\n    print(f\"{np.linalg.norm(wl.embed(text)[0]):.3f}  {text!r}\")\nn = np.linalg.norm(W, axis=1)\nprint(f\"articles: shortest {n.min():.3f}, longest {n.max():.3f}\")",
      "note": "The length of one word's vector, of a title's, and the range across the articles."
    },
    {
      "code": "q = wl.embed(\"discount for a classroom set\")[0]\nraw = W @ q\ncos = raw / (n * np.linalg.norm(q))\nfor i in [ids.index(\"h37\"), ids.index(\"h05\")]:\n    print(f\"{ids[i]}  raw {raw[i]:.3f}  length {n[i]:.3f}  cosine {cos[i]:.3f}  {help[i]['title']}\")",
      "note": "One question scored two ways against two articles: the raw dot product, and the cosine, which divides both lengths out."
    },
    {
      "code": "Wn = W / n[:, None]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nfor query in queries:\n    q = wl.embed(query[\"text\"])[0]\n    by_raw, by_cos = ids[np.argmax(W @ q)], ids[np.argmax(Wn @ q)]\n    if by_raw != by_cos:\n        print(f\"{query['id']}  raw {by_raw}  cosine {by_cos}  relevant {' '.join(query['relevant'])}\")",
      "note": "For each of the 24 questions, the article ranked first by the raw dot product and by the cosine. Print the questions where they differ, with the article the course marked as the answer."
    }
  ]
}
```

```
ana@lab:~/emb$ python lengths.py
9.104  'refund'
3.945  'When your refund arrives'
articles: shortest 1.212, longest 2.280
h37  raw 1.707  length 1.905  cosine 0.212  Audiobooks
h05  raw 1.554  length 1.490  cosine 0.247  Orders for schools and libraries
q08  raw h12  cosine h10  relevant h10
q12  raw h10  cosine h07  relevant h07
q15  raw h32  cosine h36  relevant h36
q16  raw h20  cosine h21  relevant h21
q21  raw h37  cosine h05  relevant h05
```

## Length is not meaning

**The word *refund* alone has a vector of length 9.104; the title *When your refund arrives* has
3.945, and the 40 articles range from 1.212 to 2.280.** WordLlama averages the fixed vectors of a
text's tokens, and an average of arrows pointing in many directions is shorter than the arrows
themselves. One word is not averaged with anything, so it stays long. The length records how much
the tokens of a text disagree with each other, and that is not what a search is asking about.

The dot product counts it anyway. Asked *discount for a classroom set*, the raw dot product puts
**Audiobooks** first, 1.707 against 1.554 for **Orders for schools and libraries**, the article that
actually offers 15% off to schools. Audiobooks wins on length, 1.905 against 1.490. Divide the
lengths out and the order flips: cosine 0.212 for Audiobooks and 0.247 for the schools article.

Over the 24 questions, the article ranked first changed for five of them, and **in all five the
cosine's choice is the article the course marked as the answer**. The length carried nothing
the question asked about, only how much each text's tokens disagree.

## Normalise once, when you write

The fix is one line, and the place it goes matters more than the line:

`V = V / np.linalg.norm(V, axis=1, keepdims=True)`

Do it **when the vectors are stored**, and do the same to each query before comparing. After that
every stored vector has length 1, the plain dot product is the cosine, and every tool downstream can
use the cheapest comparison there is. Forgetting it is silent: the search still returns five
articles, they are just ranked partly by an accident of averaging. Lesson 7 meets the same rule
from the other side, when a provider's vector is cut short and its length is no longer 1.

Keep the raw vectors only when a model's documentation says the length carries something, which a
few models trained with the dot product do. For a model that says nothing, or says to use cosine,
normalise.
