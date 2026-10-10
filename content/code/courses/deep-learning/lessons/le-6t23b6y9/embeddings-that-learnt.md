---
title: Embeddings that learnt something
version: 1
---

Nobody tells a model that Monday and Friday are both days. **It is given one task, to guess a missing
token from the tokens around it, and the table of embeddings is adjusted by backpropagation like any
other weight.** Tokens that keep turning up in the same company end up with similar rows, because
similar rows are the cheapest way to make the same guesses about them. That idea, that a word is
known by the words around it, is older than neural networks; word2vec made it famous in 2013.

The model below is as small as that idea allows: an embedding table of 500 rows of 8, an average,
and one linear layer that scores all 500 tokens. Save it as `~/dl/near.py`, beside `corpus.txt` and
`tok.json`:

```schooling-example
{
  "language": "python",
  "file": "near.py",
  "parts": [
    {
      "code": "\"\"\"near: a small model learns a vector per token from the corpus, and the neighbours that come out.\"\"\"\nfrom collections import Counter\n\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\nfrom tokenizers import Tokenizer\n\ntok = Tokenizer.from_file(\"tok.json\")\nids = tok.encode(open(\"corpus.txt\").read()).ids\nV, DIM, WINDOW = tok.get_vocab_size(), 8, 2\nx = torch.tensor([ids[i - WINDOW:i] + ids[i + 1:i + WINDOW + 1] for i in range(WINDOW, len(ids) - WINDOW)])\ny = torch.tensor(ids[WINDOW:len(ids) - WINDOW])\nprint(\"examples:\", len(y), \" context:\", tuple(x.shape))",
      "note": "Every token, with the two on each side of it as its context. The model's task is to guess the middle token from those four."
    },
    {
      "code": "class Guess(nn.Module):\n    def __init__(self):\n        super().__init__()\n        self.emb = nn.Embedding(V, DIM)\n        self.out = nn.Linear(DIM, V)\n\n    def forward(self, context):\n        return self.out(self.emb(context).mean(dim=1))",
      "note": "Look up the four context vectors, average them, and score every token of the vocabulary with one linear layer. The average throws the order away on purpose: this model learns only which tokens keep company."
    },
    {
      "code": "seen = Counter(ids)\npieces = [tok.decode([i]) for i in range(V)]\nwords = [i for i, p in enumerate(pieces) if seen[i] >= 3 and p[:1] == \" \" and p[1:].isalpha() and len(p) > 3]",
      "note": "The candidates for a neighbour: whole words, with their leading space, seen at least three times. Without this, fragments and bytes nobody wrote would crowd the list."
    },
    {
      "code": "def nearest(model, word, k=3):\n    table = F.normalize(model.emb.weight.detach()[words], dim=1)\n    q = words.index(tok.encode(word).ids[0])\n    sims = table @ table[q]\n    sims[q] = -1\n    best = sims.topk(k)\n    return \"  \".join(f\"{pieces[words[j]].strip()} {s:.2f}\"\n                     for s, j in zip(best.values.tolist(), best.indices.tolist()))",
      "note": "Cosine similarity: both vectors scaled to length 1, then a dot product. 1 is the same direction and 0 is unrelated. The word itself is set aside."
    },
    {
      "code": "QUERIES = [\" Monday\", \" baker\", \" pears\", \" red\", \" goat\"]\ntorch.manual_seed(0)\nmodel = Guess()\nprint(\"candidates:\", len(words))\nfor w in QUERIES:\n    print(f\"untrained {w.strip():7s}\", nearest(model, w))",
      "note": "The neighbours before any training, from random vectors. This is the baseline the trained ones have to beat."
    },
    {
      "code": "opt = torch.optim.Adam(model.parameters(), lr=0.01)\nfor epoch in range(1, 301):\n    loss = F.cross_entropy(model(x), y)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\n    if epoch % 100 == 0:\n        print(f\"epoch {epoch}: loss {loss.item():.3f}\")\nfor w in QUERIES:\n    print(f\"trained   {w.strip():7s}\", nearest(model, w))",
      "note": "Full-batch training: every example at every step, with Adam from lesson 5. Then the same five questions again."
    }
  ]
}
```

```
PENDING near
```

The 998 examples are the corpus's tokens minus the two
at each end, and each has four tokens of context. Of the 500 tokens, 57 qualify as candidates: whole
words seen at least three times.

## Before: a baseline, not a finding

**Read the untrained block first, because it is what a cosine looks like when it means nothing.**
` baker` sits at 0.89 from ` rains`, and ` Monday` at 0.82 from ` said`. In eight dimensions, two
random vectors land close together often enough that the best of 56 will usually look like a
match. A similarity number on its own proves nothing; it has to beat what chance gives at the same
size.

## After 300 epochs

Each epoch is one step, with the whole corpus as the batch. The loss falls from 3.270 at epoch 100 to
1.353 at epoch 300, and the neighbours change:

| query | nearest after training | the pattern |
| --- | --- | --- |
| Monday | Saturday 0.81, Friday 0.79 | days of the market |
| baker | potter 0.95, miller 0.94 | the trades |
| goat | dog 0.91, cat 0.88 | the animals |
| pears | sleeps 0.80, plums 0.76, cherries 0.70 | fruit, with an intruder first |
| red | all 0.86, sheep 0.83 | nothing |

**Four of the five came out as categories the corpus never named.** The model found them because those
words fill the same slots: `On ___ the`, `the ___ sells`, `The ___ eats`. The trades are the clearest,
because the corpus names them most: `baker` fifteen times. `pears` found two other fruits, behind a word that
has nothing to do with fruit.

`red` failed, and it is worth being plain about why. **It appears three times, in three different
frames**: `apples are red,`, `cherries are red,` and `the wheel red.`. `Monday` appears five times,
four of them straight after `on`, the slot every other day of the week fills. Three examples that disagree about the company a word keeps are
not enough for its row to settle anywhere. A language model's table is trained the same way on
billions of tokens, and that is the whole difference between these neighbours and the ones a real
model gives.

This model is not good for anything else. Its guesses are only the pretext: the table is what was
wanted, and a language model gets its table as a by-product of the same kind of guessing.
