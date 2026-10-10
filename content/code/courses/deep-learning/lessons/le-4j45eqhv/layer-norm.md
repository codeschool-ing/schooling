---
title: Layer normalisation, along the other axis
version: 1
---

Layer normalisation is often described as batch norm for small batches. **It is better seen as the
same arithmetic on the other axis.** Batch norm takes one feature and normalises it across the
examples of a batch. Layer norm takes one example and normalises it across its own features. The
mean and variance it uses come from a single row, so the other rows never enter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" aria-label=\"Two copies of a batch drawn as a grid, four examples in rows by six features in columns. On the left, batch norm: a highlighted column, meaning each feature is normalised with statistics taken down the column, across the examples. On the right, layer norm: a highlighted row, meaning each example is normalised with statistics taken along its own row, across its features.\"><text x=\"192\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">batch norm</text><text x=\"192\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">features →</text><text x=\"76\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">examples</text><rect x=\"84\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"84\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"84\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"84\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"192\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one mean and variance per feature,</text><text x=\"192\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">over the batch</text><text x=\"508\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">layer norm</text><text x=\"508\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">features →</text><text x=\"392\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">examples</text><rect x=\"400\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"400\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"400\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"400\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"508\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one mean and variance per example,</text><text x=\"508\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">over its features</text></svg>", "caption": "The same arithmetic on the two axes of a batch. Batch norm needs the other examples; layer norm needs only the one in front of it."}
```

Jimmy Ba, Jamie Kiros and Geoffrey Hinton proposed it in 2016. The class is batch norm with the axis
turned, and with the parts that existed only because of the batch removed. Save as
`~/dl/layernorm.py`:

```schooling-example
{
  "language": "python",
  "file": "layernorm.py",
  "parts": [
    {
      "code": "\"\"\"layernorm: layer normalisation, the same arithmetic along the other axis.\"\"\"\nimport numpy as np\n\n\nclass LayerNorm:\n    \"\"\"Each example to mean 0 and variance 1 over its own features, then gamma and beta.\"\"\"\n    params = (\"gamma\", \"beta\")\n\n    def __init__(self, n, eps=1e-5):\n        self.gamma = np.ones(n, dtype=np.float32)\n        self.beta = np.zeros(n, dtype=np.float32)\n        self.dgamma = np.zeros_like(self.gamma)\n        self.dbeta = np.zeros_like(self.beta)\n        self.eps = eps",
      "note": "The same `gamma` and `beta`, one per feature. What is missing is the point: no running statistics, no momentum, and no `training` flag, because nothing here depends on the batch."
    },
    {
      "code": "    def forward(self, x):\n        mean = x.mean(axis=1, keepdims=True)\n        var = x.var(axis=1, keepdims=True)\n        self.std = np.sqrt(var + self.eps)\n        self.xhat = (x - mean) / self.std\n        return self.gamma * self.xhat + self.beta",
      "note": "`axis=1` where `BatchNorm` has `axis=0`: the mean and variance of each row, over its own features. `keepdims=True` keeps them as a column, so they subtract from every feature of their own row."
    },
    {
      "code": "    def backward(self, grad):\n        self.dgamma[...] = (grad * self.xhat).sum(axis=0)\n        self.dbeta[...] = grad.sum(axis=0)\n        g = grad * self.gamma\n        return (g - g.mean(axis=1, keepdims=True)\n                - self.xhat * (g * self.xhat).mean(axis=1, keepdims=True)) / self.std",
      "note": "The backward of `BatchNorm` with the axis turned: the extra terms now run along a row, because a row's features shared a mean and a variance. `gamma` and `beta` still sum over the batch, since every example used them."
    }
  ]
}
```

`checknorm.py` from the batch norm section takes the layer and the axis as arguments, so the same
check runs on this one from the command line:

```
ana@vm:~/dl$ python -c "from checknorm import check; from layernorm import LayerNorm; check(LayerNorm(5), axis=1)"
x     mean [3.08 3.26 1.25 2.94 3.73 2.28 2.75 3.74]  std [0.77 1.95 1.69 1.32 1.44 0.9  1.04 1.48]
xhat  mean [0. 0. 0. 0. 0. 0. 0. 0.]  std [1. 1. 1. 1. 1. 1. 1. 1.]
relative error of the input gradient: 1.6e-10
```

Each of the eight rows now has mean 0 and standard deviation 1, and the backward pass agrees with
the measured slope to 1.6e-10. **The difference that matters shows when one example is on its own.**
Save as `~/dl/alone.py`:

```schooling-example
{
  "language": "python",
  "file": "alone.py",
  "parts": [
    {
      "code": "\"\"\"alone: one image's features, normalised inside a batch of four and on their own.\"\"\"\nimport numpy as np\n\nimport digits\nfrom batchnorm import BatchNorm\nfrom layernorm import LayerNorm\n\n_, (x, _), _ = digits.load()\nh = x[:4] @ np.random.default_rng(0).normal(0, 0.5, (64, 6))\nprint(\"first image's six features:\", np.round(h[0], 2))",
      "note": "Four validation images through a random layer of six units: six features each, the kind of thing a normalising layer receives."
    },
    {
      "code": "for layer in (BatchNorm(6), LayerNorm(6)):\n    in_batch = layer.forward(h)[0]\n    alone = layer.forward(h[:1])[0]\n    print(f\"\\n{type(layer).__name__}\")\n    print(\"  in a batch of four:\", np.round(in_batch, 2) + 0)\n    print(\"  on its own:        \", np.round(alone, 2) + 0)",
      "note": "The first image's output twice from each layer: once with the other three images beside it, and once alone. Both layers are in their training behaviour, which for `LayerNorm` is the only one it has."
    }
  ]
}
```

```
ana@vm:~/dl$ python alone.py
first image's six features: [ 2.16  2.48 -0.03 -2.   -3.61  0.23]

BatchNorm
  in a batch of four: [ 0.03  0.84 -0.24  0.49 -1.41 -0.05]
  on its own:         [0. 0. 0. 0. 0. 0.]

LayerNorm
  in a batch of four: [ 1.06  1.21  0.04 -0.87 -1.62  0.17]
  on its own:         [ 1.06  1.21  0.04 -0.87 -1.62  0.17]
```

**Batch norm gives the first image a different output depending on its company**, and alone it gives
zeros, the failure of the previous section. Layer norm gives the same six numbers either way, so it
needs no running averages, no mode, and no batch. On the ten-layer network of this lesson it is a
weaker stabiliser than batch norm:

```
ana@vm:~/dl$ python deep.py layer
normalisation: layer, 43,530 parameters
val accuracy  epoch:    1      5     10     15     20
rate 0.03              0.664  0.925  0.939  0.950  0.956   train loss 0.013
rate 0.1               0.436  0.797  0.803  0.914  0.975   train loss 0.035
rate 0.3               0.106  0.419  0.800  0.833  0.903   train loss 0.316
rate 1.0               0.097  0.106  0.100  0.100  0.111   train loss 2.310
```

It trains at 0.1 and 0.3, where the network without normalisation did not, and ends at 0.975 and
0.903. At 1.0 it fails, where batch norm reached 0.961. **For a stack of fully connected layers over
images, batch norm is the stronger choice. Layer norm is the one that still works where a batch is
not a sensible thing to measure**, and sequence models are that case for three reasons:

- the examples of a batch are sentences of different lengths, padded to the longest, so the
  statistics of a feature over the batch would mix real words with padding;
- a model that writes text produces one token at a time for one user, which is a batch of one at
  every step;
- the same layer normalises each word's vector the same way in training and in use, so there is no
  mode to forget.

The transformer block of lesson 15 puts a layer norm before its attention and before its feed-forward
part. Many recent language models use a variant called RMSNorm, which skips subtracting the mean and
divides by the root of the mean square alone.
