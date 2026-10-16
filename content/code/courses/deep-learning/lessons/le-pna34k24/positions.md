---
title: "Positions: attention cannot see order"
version: 1
---

It is natural to assume that attention reads a sequence from left to right, as the LSTM of lesson 14
did. **It does not read it in any order at all.** Nothing in `softmax(Q @ K.T / sqrt(d)) @ V` knows which
row is first: every token is compared with every other one, and the comparison is the same wherever the
two sit. Shuffle the tokens and each one meets the same others with the same scores. Save as
`~/dl/positions.py`:

```schooling-example
{
  "language": "python",
  "file": "positions.py",
  "parts": [
    {
      "code": "\"\"\"positions: attention cannot see order until each token is told where it stands.\"\"\"\nimport math\n\nimport torch\nimport torch.nn as nn\n\ntorch.set_printoptions(precision=3, sci_mode=False)\ntorch.set_grad_enabled(False)\ntorch.manual_seed(0)\nd = 16\nmha = nn.MultiheadAttention(d, 4, batch_first=True)\nx = torch.randn(1, 5, d)\norder = torch.tensor([4, 2, 0, 3, 1])",
      "note": "One attention layer of 16 features and four heads, five random tokens, and an order to shuffle them into."
    },
    {
      "code": "def attend(x):\n    return mha(x, x, x)[0]",
      "note": "Self-attention: the same tokens supply the queries, the keys and the values."
    },
    {
      "code": "out, shuffled = attend(x), attend(x[:, order])\nprint(\"shuffle the input, and the output is the same rows shuffled:\", torch.allclose(shuffled, out[:, order], atol=1e-6))",
      "note": "Attention on the tokens as they are and on the same tokens shuffled. If attention saw order, the second output would be something new."
    },
    {
      "code": "def sinusoids(length, d):\n    \"\"\"The 2017 encoding: sines and cosines whose wavelength grows along the features.\"\"\"\n    pos = torch.arange(length).float()[:, None]\n    rate = torch.exp(-math.log(10000.0) * torch.arange(0, d, 2).float() / d)\n    pe = torch.zeros(length, d)\n    pe[:, 0::2], pe[:, 1::2] = torch.sin(pos * rate), torch.cos(pos * rate)\n    return pe",
      "note": "The encoding of the 2017 paper. Each pair of features is a sine and a cosine of the position, and each pair turns at its own rate, the first fastest. No parameters: it is computed, for any position."
    },
    {
      "code": "pe = sinusoids(50, d)\nprint(\"positions 0 to 3, first four features\\n\", pe[:4, :4])\nprint(\"similarity of positions 0 and 3:\", round((pe[0] @ pe[3]).item(), 3),\n      \"  10 and 13:\", round((pe[10] @ pe[13]).item(), 3), \"  27 and 30:\", round((pe[27] @ pe[30]).item(), 3))",
      "note": "The first rows, and the dot product of three pairs of positions that are each three apart."
    },
    {
      "code": "placed = x + pe[:5]\nout, shuffled = attend(placed), attend(x[:, order] + pe[:5])\nprint(\"with positions added, still the same rows shuffled:\", torch.allclose(shuffled, out[:, order], atol=1e-6))",
      "note": "Each token gets its position's vector added before attention, and the shuffle is tried again. A shuffled token now carries a different position."
    },
    {
      "code": "learnt = nn.Embedding(50, d)\nprint(\"learnt positions:\", tuple(learnt.weight.shape))\ntry:\n    learnt(torch.arange(60))\nexcept IndexError as e:\n    print(\"a sequence of 60:\", type(e).__name__, e)",
      "note": "The other way: a learnt table with one row per position, trained like any embedding. It has rows for 50 positions, and a sequence of 60 asks for ten that do not exist."
    }
  ]
}
```

```
ana@vm:~/dl$ python positions.py
shuffle the input, and the output is the same rows shuffled: True
positions 0 to 3, first four features
 tensor([[ 0.000,  1.000,  0.000,  1.000],
        [ 0.841,  0.540,  0.311,  0.950],
        [ 0.909, -0.416,  0.591,  0.807],
        [ 0.141, -0.990,  0.813,  0.583]])
similarity of positions 0 and 3: 5.543   10 and 13: 5.543   27 and 30: 5.543
with positions added, still the same rows shuffled: False
learnt positions: (50, 16)
a sequence of 60: IndexError index out of range in self
```

**The first line is the problem.** Shuffled into a new order, the five tokens produced exactly the same
five outputs, shuffled the same way. To attention, a sequence is a set: "the dog bit the man" and "the man
bit the dog" are the same five words. For the recall task of lesson 14 it is fatal, because "the first
symbol" is a position, and a model that cannot see positions has no way to tell which one it is.

The fix is to add, to each token's vector, **a vector that depends only on where the token stands.** The
2017 paper computed it with sines and cosines of the position at different rates. Position 0 starts
`[0, 1, 0, 1]`, and each later row turns every pair of features a little further, the first pair
fastest. The three similarities show the useful property: positions 0 and 3, 10 and 13, and 27 and 30
all gave 5.543. **The dot product of two positions depends only on how far apart they are**, so "three
tokens back" looks the same everywhere in the sequence, and attention can learn it as one rule.

With the positions added, the shuffled tokens no longer give the shuffled output: `False`. A token moved
to another place now carries another position, and it is a different vector.

The other way is **a learnt table with one row per position**, an `nn.Embedding` indexed by the position
instead of the symbol. GPT-2 used one, with 1,024 rows. It costs parameters and has a hard edge: the
table built here has 50 rows, and a sequence of 60 asked for positions it does not have, which raised
`IndexError`. Sinusoids can be computed for any position, but a model trained on sequences of 50 has
still never seen what position 60 looks like, so neither choice makes a model work past its training
length for free.

Many recent models use a third kind, rotary position embeddings (RoPE), from Jianlin Su and colleagues in
2021. They rotate each query and key by an angle that grows with the position, so that a score depends on
the distance between two tokens directly. Llama models use it. It is not built in this lesson. The model
at the end of this lesson uses a learnt table of 50 rows, since 50 is the longest sequence the recall
task asks for.
