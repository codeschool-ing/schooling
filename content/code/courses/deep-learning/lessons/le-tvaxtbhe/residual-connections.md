---
title: Residual connections, and the gradient they let through
version: 1
---

The argument in the last section was that extra layers could always learn to pass their input
through unchanged. **That turns out to be hard for a stack of convolutions to learn**: the identity
is one exact setting of thousands of weights, and nothing in training aims at it. Kaiming He and his
colleagues changed the question in 2015. Instead of asking a block for its output, ask it for **a
correction to its input**, and add the input back:

```
output = relu(x + f(x))
```

If the convolutions learn nothing useful, `f(x)` can sit near zero and the block passes `x` through,
which is the easy setting to find. If they learn something, it is added to what was already there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"A residual block drawn left to right. The input x enters, goes through a 3 by 3 convolution, a ReLU and a second 3 by 3 convolution, which together give f(x). A second line carries x around them unchanged. The two meet at a plus sign, and a ReLU follows. A note says that if the convolutions learn nothing, f(x) is zero and the block passes x through.\"><text x=\"30\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">x</text><path d=\"M42 130 L90 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M82.6 133.1 L90 130 L82.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"90\" y=\"110\" width=\"100\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">conv 3x3</text><rect x=\"230\" y=\"110\" width=\"80\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ReLU</text><rect x=\"350\" y=\"110\" width=\"100\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">conv 3x3</text><path d=\"M190 130 L230 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M222.6 133.1 L230 130 L222.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M310 130 L350 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.6 133.1 L350 130 L342.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 130 L506 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M498.6 133.1 L506 130 L498.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"520\" cy=\"130\" r=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"520\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">+</text><path d=\"M534 130 L574 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M566.6 133.1 L574 130 L566.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"574\" y=\"110\" width=\"80\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"614\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ReLU</text><path d=\"M654 130 L684 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M676.6 133.1 L684 130 L676.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">plain path: f(x)</text><path d=\"M60 130 L60 50 L520 50 L520 108\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520 100 L520 116\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M516.9 108.6 L520 116 L523.1 108.6\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"290\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">the skip: x unchanged</text><text x=\"350\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">If the convolutions learn nothing, f(x) is 0 and the block passes x through.</text></svg>", "caption": "A residual block: two convolutions compute a correction, and the input is added back to it."}
```

In code it is one line. Add this class to the end of `~/dl/deep.py`:

```schooling-example
{
  "language": "python",
  "file": "deep.py",
  "parts": [
    {
      "code": "class Residual(Plain):\n    \"\"\"The same two convolutions, with the input added back before the last ReLU.\"\"\"\n\n    def forward(self, x):\n        return self.relu(x + self.conv2(self.relu(self.conv1(x))))",
      "note": "Add this to the end of `deep.py`. It inherits the two convolutions from `Plain`, so it has exactly the same parameters, and changes one line: `x +` before the second ReLU. Nothing is learnt by the skip itself."
    }
  ]
}
```

The block has the same two convolutions and the same parameter count as `Plain`, so the comparison
is fair: the same program, the same seeds, the skip as the only change.

```
ana@vm:~/dl$ python depth.py Residual
epoch  20  train loss 0.2515  val loss 0.2521  val acc 0.925
4 layers, 4970 parameters
  train loss by epoch: 2.31 2.28 2.18 1.85 1.49 1.18 0.96 0.83 0.67 0.62 0.51 0.46 0.40 0.34 0.33 0.28 0.30 0.26 0.26 0.25
epoch  20  train loss 0.0671  val loss 0.1190  val acc 0.956
8 layers, 14250 parameters
  train loss by epoch: 2.31 2.21 1.90 1.70 1.45 1.13 0.81 0.56 0.40 0.44 0.34 0.24 0.19 0.17 0.16 0.16 0.11 0.09 0.13 0.07
epoch  20  train loss 0.0369  val loss 0.0952  val acc 0.964
12 layers, 23530 parameters
  train loss by epoch: 2.32 2.30 2.10 1.42 0.96 0.61 0.42 0.36 0.25 0.23 0.21 0.22 0.15 0.07 0.09 0.12 0.10 0.12 0.12 0.04
epoch  20  train loss 0.0851  val loss 0.1853  val acc 0.942
20 layers, 42090 parameters
  train loss by epoch: 2.31 2.27 2.15 1.82 1.63 1.27 1.02 0.65 0.47 0.36 0.25 0.21 0.15 0.19 0.16 0.24 0.15 0.13 0.10 0.09
```

**With the skips, every depth trains.** The 12-layer residual network ends at a training loss of
0.04 and a validation accuracy of 0.964, the best of the eight runs. The 20-layer one, which as a
plain network sat at 2.30 for twenty epochs, ends at 0.09 and 0.942. It is not better than the
12-layer one on 1,077 images and twenty epochs, and the skips do not promise that; they promise that
adding layers no longer stops training. The parameter counts are the same as the plain ones, line
for line.

The reason is in the gradient. Before any training, give both 20-layer networks one batch, run one
backward pass, and measure the gradient that reaches each block. Save as `~/dl/grads.py`:

```schooling-example
{
  "language": "python",
  "file": "grads.py",
  "parts": [
    {
      "code": "\"\"\"grads: how much gradient reaches each block of a 20-layer network, before any training.\"\"\"\nimport torch\nimport torch.nn.functional as F\n\nimport deep\nimport tdigits\n\n(x, y), _, _ = tdigits.load(images=True)"
    },
    {
      "code": "for block in (deep.Plain, deep.Residual):\n    torch.manual_seed(0)\n    model = deep.make(20, block)\n    F.cross_entropy(model(x[:32]), y[:32]).backward()",
      "note": "Both networks start from the same seed, so their weights are identical; only the forward pass differs. One batch of 32, one backward pass, no step."
    },
    {
      "code": "    norms = [m.conv1.weight.grad.norm().item() for m in model if isinstance(m, deep.Plain)]\n    print(f\"{block.__name__:8s} block 1 to 9:\", \" \".join(f\"{n:.0e}\" for n in norms))",
      "note": "The size of the gradient on the first convolution of each of the nine blocks, from the input end to the output end. `Residual` is a subclass of `Plain`, so the same test finds the blocks of both."
    }
  ]
}
```

```
ana@vm:~/dl$ python grads.py
Plain    block 1 to 9: 2e-09 2e-09 3e-08 1e-07 1e-06 7e-06 5e-05 6e-04 4e-03
Residual block 1 to 9: 2e-02 5e-02 7e-02 5e-02 7e-02 9e-02 7e-02 1e-01 6e-02
```

**In the plain network the gradient shrinks at almost every block on the way back**, by three to
fifteen times at most of them, and the first block gets a gradient more than a million times smaller than
the last one. Its weights barely
move, the blocks after it are reading what is close to noise, and the whole stack stalls: lesson 3's
vanishing gradients, at work in a real network. In the residual network every block gets a gradient
of the same size. The addition copies the gradient of the output straight to the input, because
the derivative of `x + f(x)` with respect to `x` is 1 plus whatever `f` contributes, so there is
always a path back along which nothing is multiplied away.

That is the whole of ResNet's change. The rest of the architecture is VGG's stacks of 3x3
convolutions with batch normalisation, and the next section takes torchvision's version apart.
