---
title: "Query, key and value: a lookup that can be trained"
version: 1
---

Attention is usually explained with a picture of a person reading a sentence and focusing on the
words that matter. **What it computes is plainer than that: a dictionary lookup made soft.** A Python
dictionary takes a key, finds the one entry that matches it exactly, and returns that entry's value.
Attention takes a query, scores it against every key, and returns a mixture of every value, weighted by
how well each key matched.

The words come from that picture. The **query** is what a token is looking for, the **key** is what a
token offers to be found by, and the **value** is what it hands over when it is found. The program below
does the lookup both ways on four entries, with keys and values written by hand. Save as
`~/dl/qkv.py`:

```schooling-example
{
  "language": "python",
  "file": "qkv.py",
  "parts": [
    {
      "code": "\"\"\"qkv: a dictionary lookup, made soft, and the three projections that feed it.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.set_printoptions(precision=3, sci_mode=False)\nkeys = torch.tensor([[1., 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])\nvalues = torch.tensor([[10.], [20.], [30.], [40.]])\nquery = torch.tensor([0., 0.9, 0.3, 0.])\nprint(\"hard lookup:\", values[(keys @ query).argmax()].item())",
      "note": "Four keys, each pointing in its own direction, and a value for each. The query leans mostly towards the second key and a little towards the third. A dictionary would take the best match and return its value, 20, and nothing else."
    },
    {
      "code": "scores = keys @ query\nweights = torch.softmax(scores, dim=0)\nprint(\"scores \", scores)\nprint(\"weights\", weights, \" sum\", round(weights.sum().item(), 3))\nprint(\"soft lookup:\", round((weights @ values).item(), 2))",
      "note": "The soft version scores every key by its dot product with the query, turns the scores into weights with a softmax, and returns the weighted sum of all the values."
    },
    {
      "code": "for sharpness in (1, 5, 20):\n    w = torch.softmax(sharpness * scores, dim=0)\n    print(f\"scores x{sharpness:<2d}  weights {w}  result {(w @ values).item():.2f}\")",
      "note": "The same scores multiplied by 5 and by 20 before the softmax. Larger scores make the weights more lopsided, and the soft lookup slides towards the hard one."
    },
    {
      "code": "q = query.clone().requires_grad_()\n(torch.softmax(keys @ q, dim=0) @ values).sum().backward()\nprint(\"gradient of the soft lookup with respect to the query:\", q.grad)",
      "note": "The soft lookup has a gradient with respect to the query, so training can move the query towards the key it should have matched. The hard one has none: `argmax` returns an index."
    },
    {
      "code": "torch.manual_seed(0)\ntokens = torch.randn(4, 16)\nto_q, to_k, to_v = nn.Linear(16, 16), nn.Linear(16, 16), nn.Linear(16, 16)\nq, k, v = to_q(tokens), to_k(tokens), to_v(tokens)\nprint(\"tokens\", tuple(tokens.shape), \" q\", tuple(q.shape), \" k\", tuple(k.shape), \" v\", tuple(v.shape))",
      "note": "In a network nobody writes the keys. Each token's vector goes through three learnt layers of its own, one making the query, one the key and one the value. Here the four tokens are random vectors of 16; lesson 16 is about where real ones come from."
    }
  ]
}
```

```
ana@vm:~/dl$ python qkv.py
hard lookup: 20.0
scores  tensor([0.000, 0.900, 0.300, 0.000])
weights tensor([0.172, 0.423, 0.232, 0.172])  sum 1.0
soft lookup: 24.04
scores x1   weights tensor([0.172, 0.423, 0.232, 0.172])  result 24.04
scores x5   weights tensor([0.010, 0.933, 0.046, 0.010])  result 20.57
scores x20  weights tensor([0.000, 1.000, 0.000, 0.000])  result 20.00
gradient of the soft lookup with respect to the query: tensor([-2.418, -1.713,  1.384,  2.746])
tokens (4, 16)  q (4, 16)  k (4, 16)  v (4, 16)
```

**The hard lookup returned 20 and the soft one 24.04.** The query scored 0.9 against the second key and
0.3 against the third, and the softmax turned the four scores into weights of 0.172, 0.423, 0.232 and
0.172, which add up to 1. The result is those weights times 10, 20, 30 and 40: mostly the second value,
pulled down a little by the first and further up by the third and the fourth. The first and the fourth
matched nothing and still received 0.172 each. A softmax of finite scores never gives a weight of exactly 0.

**The size of the scores decides how hard the lookup is.** Multiplied by 5, the same scores put 0.933 on
the second key and the result fell to 20.57. Multiplied by 20, the weights printed as 1.000 on one key and 0.000 on
the rest, and the soft lookup returned 20.00, the hard one's answer. The next section shows that this
scale is set by the width of the vectors, and why it has to be corrected for.

Why not use the hard lookup, then? **Because it cannot be trained.** The gradient of the soft lookup with
respect to the query is `[-2.418, -1.713, 1.384, 2.746]`: it says that moving the query towards the third
and fourth keys would raise the result, and by how much. `argmax` returns a position, and a small change
to the query changes nothing at all until the winner jumps from one key to another. Backpropagation,
lesson 3's subject, needs a slope, and only the soft version has one. That is how a network learns where
to look.

In a real network nobody writes the keys. Each token arrives as a vector, and **three learnt linear
layers turn the same vector into a query, a key and a value**: three different vectors, because what a
token looks for is not the same as what it offers. The last lines did that for four random tokens of 16
numbers, and each of `q`, `k` and `v` came out `(4, 16)`, one row per token. In a model, those rows come
from an embedding: lesson 16 is about how a symbol becomes a vector, and here `nn.Embedding` is enough,
as in lesson 14.
