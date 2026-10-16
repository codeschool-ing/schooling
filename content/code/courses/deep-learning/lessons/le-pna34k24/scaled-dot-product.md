---
title: Scaled dot-product attention, by hand
version: 1
---

The 2017 paper that introduced the transformer, "Attention Is All You Need" by Ashish Vaswani and seven colleagues, most of them at Google,
writes the whole mechanism as one formula:

```
attention(Q, K, V) = softmax(Q @ K.T / sqrt(d)) @ V
```

**Every token is a query and every token is a key, so all the lookups of the previous section happen in
one matrix product.** `Q @ K.T` is a table with a row per query and a column per key. The softmax runs along
each row, and multiplying by `V` mixes the values with each row's weights. `d` is the width of a query.
The program does it for four tokens, by hand and then with PyTorch's function. Save as
`~/dl/attention.py`:

```schooling-example
{
  "language": "python",
  "file": "attention.py",
  "parts": [
    {
      "code": "\"\"\"attention: scaled dot-product attention by hand on four tokens, then against PyTorch's.\"\"\"\nimport math\n\nimport torch\nimport torch.nn.functional as F\n\ntorch.set_printoptions(precision=3, sci_mode=False)\ntorch.manual_seed(0)\nd = 8\nq, k, v = torch.randn(4, d), torch.randn(4, d), torch.randn(4, d)",
      "note": "Four tokens, already projected: a query, a key and a value of 8 numbers for each. Random, so that nothing about the arithmetic depends on a lucky choice."
    },
    {
      "code": "scores = q @ k.T / math.sqrt(d)\nprint(\"scores, one row per query, one column per key\\n\", scores)\nweights = torch.softmax(scores, dim=-1)\nprint(\"weights, each row sums to 1\\n\", weights)\nout = weights @ v\nprint(\"output\", tuple(out.shape), \" first row\", out[0, :4])",
      "note": "The whole mechanism in three lines. `q @ k.T` scores every query against every key at once, a 4 by 4 table. The softmax runs along each row, so each token's weights sum to 1, and `weights @ v` mixes the values with them."
    },
    {
      "code": "ref = F.scaled_dot_product_attention(q[None], k[None], v[None])[0]\nprint(\"largest difference from PyTorch's:\", f\"{(out - ref).abs().max().item():.1e}\")",
      "note": "PyTorch's own function, given the same tensors with a batch axis added in front. It divides by the square root of `d` too, by default."
    },
    {
      "code": "print(\"\\n   d   spread of q.k   spread / sqrt(d)   largest weight raw   scaled\")\nfor d in (4, 64, 512):\n    q, k = torch.randn(2000, 16, d), torch.randn(2000, 16, d)\n    raw = (q[:, :1] @ k.transpose(1, 2))[:, 0]\n    top_raw = torch.softmax(raw, dim=-1).max(dim=-1).values.mean()\n    top_scaled = torch.softmax(raw / math.sqrt(d), dim=-1).max(dim=-1).values.mean()\n    print(f\"{d:4d}   {raw.std():12.2f}   {raw.std() / math.sqrt(d):16.2f}   {top_raw:18.3f}   {top_scaled:6.3f}\")",
      "note": "Why the division. For three widths, 2,000 random queries are scored against 16 random keys each. The spread of the raw scores, how much the largest weight takes without the division, and how much it takes with it."
    }
  ]
}
```

```
ana@vm:~/dl$ python attention.py
scores, one row per query, one column per key
 tensor([[-0.005,  1.806, -0.139, -1.336],
        [ 0.164,  0.193, -0.249,  0.338],
        [ 0.488, -2.487, -0.098,  0.802],
        [ 0.239,  1.360, -0.446, -0.815]])
weights, each row sums to 1
 tensor([[0.121, 0.741, 0.106, 0.032],
        [0.258, 0.265, 0.171, 0.307],
        [0.336, 0.017, 0.187, 0.460],
        [0.203, 0.623, 0.102, 0.071]])
output (4, 8)  first row tensor([-1.294, -0.149, -0.370, -0.216])
largest difference from PyTorch's: 1.2e-07
```

Read the tables row by row. **Row 1 is the first token's query against all four keys.** It scored 1.806
against key 2 and less than 0.5 against the others, so the softmax gave key 2 a weight of 0.741 and the
first token's output is mostly value 2. Row 2 is nearly flat, 0.258, 0.265, 0.171 and 0.307: that query
matches no key much better than the others, and its output is close to the plain average of the four
values. Each output row is a new vector of 8 for its token, built from the values of all the tokens, its
own included.

The hand-written version agrees with `F.scaled_dot_product_attention` to 1.2e-07, which is float32
rounding. **For four tokens the weights are a 4 by 4 table; for n tokens they are n by n**, so a sequence
twice as long has four times as many weights to compute. Lesson 16 comes back to what that costs when the
tokens are a text.

```
   d   spread of q.k   spread / sqrt(d)   largest weight raw   scaled
   4           2.01               1.00                0.421    0.234
  64           7.95               0.99                0.844    0.246
 512          22.59               1.00                0.948    0.246
```

**The division by √d is there because of the last table.** A dot product of two vectors of `d` random
numbers, each with a spread of 1, has a spread of about √d. The program measured 2.01, 7.95 and 22.59 for
widths 4, 64 and 512, whose square roots are 2, 8 and 22.6. Divided by √d, the spreads were 1.00, 0.99 and
1.00.

Without the division, a wide query produces large scores, and large scores make a sharp softmax, as the
×20 line of the previous section did. At width 512 the largest of 16 weights took 0.948 on average,
**before any training had decided which key deserved it.** A weight that close to 1 also passes back
very little gradient: the slope of a softmax weight `w` with respect to its own score is `w * (1 - w)`,
which is 0.049 at 0.948 against 0.185 at 0.246. With the division, the largest weight was 0.246 at
widths 64 and 512, and 0.234 at width 4: the starting point no longer depends on how wide the model is.
