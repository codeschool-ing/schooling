---
title: "The block: attention, an MLP, and two shortcuts"
version: 1
---

Attention moves information between tokens, and that is all it does. Each output is a weighted average
of values, so on its own it can mix what the tokens carry but not transform it much. **A transformer block pairs it with a small MLP that works on each token separately.** Both halves
are wrapped in two devices this course has already met: a layer norm before each half (lesson 8) and a residual connection
around it (lesson 12). In code, a block is two lines:

```
x = x + attention(norm1(x))
x = x + mlp(norm2(x))
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"A transformer block drawn left to right. The tokens go through a layer norm and attention, and the input is added back around both. Then a second layer norm and an MLP from 32 to 128 and back to 32, and the input to that half is added back around it. Attention holds 4,224 parameters and moves information between tokens; the MLP holds 8,352 and works on each token alone.\"><text x=\"6\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens in</text><path d=\"M20 130 L70 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M62.6 133.1 L70 130 L62.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"70\" y=\"108\" width=\"80\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">layer norm</text><path d=\"M150 130 L180 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M172.6 133.1 L180 130 L172.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"180\" y=\"100\" width=\"110\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"235\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">attention</text><text x=\"235\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4 heads</text><text x=\"235\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4,224</text><text x=\"235\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">between tokens</text><path d=\"M290 130 L322 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M314.6 133.1 L322 130 L314.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"334\" cy=\"130\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><text x=\"334\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">+</text><path d=\"M55 130 L55 60 L334 60 L334 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M334 108 L334 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M330.9 110.6 L334 118 L337.1 110.6\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M346 130 L376 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M368.6 133.1 L376 130 L368.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"376\" y=\"108\" width=\"80\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"416\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">layer norm</text><path d=\"M456 130 L486 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M478.6 133.1 L486 130 L478.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"486\" y=\"100\" width=\"110\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"541\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">MLP</text><text x=\"541\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">32 → 128 → 32</text><text x=\"541\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8,352</text><text x=\"541\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each token alone</text><path d=\"M596 130 L628 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M620.6 133.1 L628 130 L620.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"640\" cy=\"130\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><text x=\"640\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">+</text><path d=\"M362 130 L362 60 L640 60 L640 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M640 108 L640 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M636.9 110.6 L640 118 L643.1 110.6\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M652 130 L690 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M682.6 133.1 L690 130 L682.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"668\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens out</text></svg>", "caption": "One block with the layer norm first: attention lets the tokens exchange information, the MLP works on each one alone, and each half adds its input back."}
```

A transformer is that block stacked: the output of one is the input of the next, the same shape all the
way up. PyTorch has it as `nn.TransformerEncoderLayer`. The program builds one and then rebuilds its
forward pass from its own parts, to show the two lines are all there is. Save as `~/dl/block.py`:

```schooling-example
{
  "language": "python",
  "file": "block.py",
  "parts": [
    {
      "code": "\"\"\"block: one transformer block written as two lines, against nn.TransformerEncoderLayer.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.set_grad_enabled(False)\ntorch.manual_seed(0)\nd = 32\nlayer = nn.TransformerEncoderLayer(d, nhead=4, dim_feedforward=4 * d, dropout=0.1,\n                                   activation=\"gelu\", batch_first=True, norm_first=True)\nlayer.eval()",
      "note": "PyTorch's block, 32 wide, 4 heads, an MLP four times wider, GELU, and its default dropout of 0.1. `norm_first=True` puts each layer norm before its sub-layer, as GPT-2 and most later models do. `eval()` switches the dropout off."
    },
    {
      "code": "def mlp(x):\n    return layer.linear2(layer.activation(layer.linear1(x)))",
      "note": "The MLP, built from the layer's own parts: a linear layer out to 128, GELU, and a linear layer back to 32. It sees one token at a time."
    },
    {
      "code": "def block(x):\n    n = layer.norm1(x)\n    x = x + layer.self_attn(n, n, n)[0]\n    return x + mlp(layer.norm2(x))",
      "note": "The block. Normalise, attend, add the input back; normalise, run the MLP, add back again. The two additions are residual connections."
    },
    {
      "code": "x = torch.randn(2, 7, d)\nprint(\"input\", tuple(x.shape), \" output\", tuple(layer(x).shape))\nprint(\"largest difference from the layer:\", f\"{(block(x) - layer(x)).abs().max().item():.1e}\")",
      "note": "Two sequences of seven tokens through the layer and through the two lines above, compared."
    },
    {
      "code": "for name, part in ((\"attention\", layer.self_attn), (\"mlp\", nn.ModuleList([layer.linear1, layer.linear2])),\n                   (\"two layer norms\", nn.ModuleList([layer.norm1, layer.norm2]))):\n    print(f\"{name:16s} {sum(p.numel() for p in part.parameters()):6,d}\")\nprint(f\"{'the block':16s} {sum(p.numel() for p in layer.parameters()):6,d}\")\nprint(\"by hand:\", 4 * d * d + 4 * d, \"+\", 2 * 4 * d * d + 4 * d + d, \"+\", 4 * d)",
      "note": "Where the parameters are, counted off the tensors and then by hand: four 32 by 32 projections with biases, two 32 by 128 matrices with biases, and a gamma and a beta per feature in each norm."
    },
    {
      "code": "big = nn.TransformerEncoderLayer(768, nhead=12, dim_feedforward=3072, batch_first=True)\nper_block = sum(p.numel() for p in big.parameters())\nprint(f\"one block 768 wide: {per_block:,} parameters\")\nprint(f\"twelve blocks, 50,257 tokens, 1,024 positions, a last norm: {12 * per_block + (50257 + 1024) * 768 + 2 * 768:,}\")",
      "note": "The same block at GPT-2's published width, 768, with 12 heads and an MLP of 3,072, built in memory with random weights. Then the whole model: twelve blocks, a row per token for its 50,257 tokens and its 1,024 positions, and one last norm."
    }
  ]
}
```

```
ana@vm:~/dl$ python block.py
input (2, 7, 32)  output (2, 7, 32)
largest difference from the layer: 0.0e+00
attention         4,224
mlp               8,352
two layer norms     128
the block        12,704
by hand: 4224 + 8352 + 128
one block 768 wide: 7,087,872 parameters
twelve blocks, 50,257 tokens, 1,024 positions, a last norm: 124,439,808
```

**The two lines agree with the layer to `0.0e+00`.** Nothing else happens inside it, apart from dropout,
which the layer applies after the attention and inside the MLP while training, at 0.1 by default.
Lesson 7 introduced it; `eval()` turns it off, which is why the comparison was made after it. The MLP is
the one of lesson 9 with GELU, the activation lesson 1 named, in place of ReLU, and four times as wide as
the block inside, which is the 2017 paper's ratio.

The counts show where a transformer keeps its weights:

| part | parameters | by hand |
| --- | --- | --- |
| attention | 4,224 | four 32 × 32 matrices and their biases |
| MLP | 8,352 | 32 × 128 and 128 × 32, with biases |
| two layer norms | 128 | a gamma and a beta for each of 32 features, twice |
| the block | 12,704 | |

**Two thirds of the block is the MLP**, and that ratio does not depend on the width: attention grows
as 4·d² and the MLP as 8·d². At GPT-2's published width of 768 the same block has 7,087,872
parameters. Twelve of them, with a row of 768 for each of its 50,257 tokens and 1,024 positions and one
last layer norm, make 124,439,808: the smallest GPT-2, from 2019,
which OpenAI first announced as 117M and later relabelled 124M. That is arithmetic
on shapes built in memory; nothing was downloaded.

**Where the norm goes is a choice with a history.** The 2017 paper normalised after each addition,
which PyTorch keeps as its default, `norm_first=False`. GPT-2 moved the norm to the start of each half,
as here, so that the residual path runs from the first block to the last with nothing on it but
additions. Ruibin Xiong and colleagues showed in 2020 that this arrangement can be trained without the
warm-up the original needed, the warm-up of lesson 5. Most models since put the norm first.
