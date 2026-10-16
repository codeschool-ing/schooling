---
title: Several heads, for the same weights
version: 1
---

One attention gives each token one set of weights: one way of looking at the rest of the sequence. A
token often needs several at once. A verb may need its subject, the word just before it and the end of
the sentence, and one softmax has to share a single total of 1 among all of them. **Multi-head attention
cuts the features into groups and runs a separate attention in each one.** With 16 features and 4
heads, each head gets 4 features of the query, the key and the value, computes its own weights, and the
four results are put side by side again.

The program writes that out and compares it with `nn.MultiheadAttention`, using the layer's own
weights. Save as `~/dl/heads.py`:

```schooling-example
{
  "language": "python",
  "file": "heads.py",
  "parts": [
    {
      "code": "\"\"\"heads: four heads of attention written out, against nn.MultiheadAttention with the same weights.\"\"\"\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\ntorch.set_printoptions(precision=3, sci_mode=False)\ntorch.set_grad_enabled(False)\ntorch.manual_seed(0)\nd, heads = 16, 4\nmha = nn.MultiheadAttention(d, heads, batch_first=True)\none = nn.MultiheadAttention(d, 1, batch_first=True)\nprint(\"parameters, 4 heads:\", sum(p.numel() for p in mha.parameters()),\n      \" 1 head:\", sum(p.numel() for p in one.parameters()))\nprint(\"in_proj\", tuple(mha.in_proj_weight.shape), \" out_proj\", tuple(mha.out_proj.weight.shape))",
      "note": "A layer of four heads and a layer of one, both 16 wide. Nothing here is trained, so gradients are switched off. `in_proj_weight` is the query, key and value matrices stacked into one; `out_proj` mixes the heads back together."
    },
    {
      "code": "def split(t):\n    \"\"\"(batch, time, d) to (batch, head, time, d / heads): each head gets its own slice of the features.\"\"\"\n    return t.view(1, 5, heads, d // heads).transpose(1, 2)",
      "note": "A head is a slice of the features. `view` cuts the 16 into 4 groups of 4, and `transpose` moves the head axis in front of time, so every head becomes a separate batch of its own small attention."
    },
    {
      "code": "x = torch.randn(1, 5, d)\nq, k, v = F.linear(x, mha.in_proj_weight, mha.in_proj_bias).chunk(3, dim=-1)\nq, k, v = split(q), split(k), split(v)\nprint(\"q for all heads\", tuple(q.shape))",
      "note": "Five tokens through the layer's own projection, using its weights directly, then split into the four heads."
    },
    {
      "code": "weights = torch.softmax(q @ k.transpose(-2, -1) / (d // heads) ** 0.5, dim=-1)\njoined = (weights @ v).transpose(1, 2).reshape(1, 5, d)\nout = mha.out_proj(joined)",
      "note": "Attention in every head at once, scaled by the square root of the head's width, 4, not of the layer's. The four results are put side by side again, back to 16 features, and `out_proj` mixes them."
    },
    {
      "code": "ref, ref_weights = mha(x, x, x, average_attn_weights=False)\nprint(\"largest difference from nn.MultiheadAttention: output\", f\"{(out - ref).abs().max().item():.1e}\",\n      \" weights\", f\"{(weights - ref_weights).abs().max().item():.1e}\")\nfor h in range(heads):\n    print(f\"head {h}: where token 5 looks\", weights[0, h, 4])",
      "note": "The layer run normally, asked for each head's weights separately, against the version written out. Then where the fifth token looks, head by head."
    }
  ]
}
```

```
ana@vm:~/dl$ python heads.py
parameters, 4 heads: 1088  1 head: 1088
in_proj (48, 16)  out_proj (16, 16)
q for all heads (1, 4, 5, 4)
largest difference from nn.MultiheadAttention: output 0.0e+00  weights 0.0e+00
head 0: where token 5 looks tensor([0.282, 0.175, 0.172, 0.127, 0.245])
head 1: where token 5 looks tensor([0.137, 0.103, 0.529, 0.163, 0.069])
head 2: where token 5 looks tensor([0.136, 0.201, 0.206, 0.248, 0.209])
head 3: where token 5 looks tensor([0.178, 0.105, 0.330, 0.263, 0.123])
```

**Four heads cost exactly what one head costs: 1,088 parameters.** The query, key and value matrices are
16 by 16 whichever way they are cut, stored together as one `(48, 16)` matrix, and `out_proj` is the
fourth, 16 by 16. Four matrices of `d` by `d` and four bias vectors of `d` give `4 * 16 * 16 + 4 * 16`, the
1,088 the program counted. Heads do not add weights. They divide the same projection into independent pieces,
each with its own softmax.

The version written out agrees with PyTorch's to `0.0e+00`, in the output and in the weights, because it
is the same arithmetic in the same order. Each head scales by the square root of its own width, 4, since
that is the width of the vectors it multiplies.

**The last four lines show the point of having heads.** The fifth token, looking from the same input,
puts 0.529 of its weight on token 3 in head 1, and spreads it between 0.136 and 0.248 in head 2. The
weights here are random, so these patterns mean nothing yet. In a trained model they do. In 2019 Kevin Clark and colleagues
read the heads of a trained BERT: some attended to the previous token, some to the separator that ends
each sentence, and some linked a verb to its object.
