---
title: Counting the work
version: 1
---

A model is described by its number of parameters, so the number of parameters is the usual first guess
at what it costs to train. **The parameter count measures memory, not work.** What a processor spends
its time on is arithmetic, and one parameter can take part in one multiplication per example or in
hundreds of them.

PyTorch can count the arithmetic for you. The program below counts it for lesson 9's MLP and lesson
11's CNN, per example, for the forward pass alone and for a whole training step, and then times a
training step of each. It needs the `digits.py` from lesson 1, the `tdigits.py` and `mlp.py` from lesson
9 and the `cnn.py` from lesson 11 beside it. Save it as `~/dl/work.py`:

```schooling-example
{
  "language": "python",
  "file": "work.py",
  "parts": [
    {
      "code": "\"\"\"work: parameters, arithmetic per example, and time, for lesson 9's MLP and lesson 11's CNN.\"\"\"\nimport time\n\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.flop_counter import FlopCounterMode\n\nimport cnn\nimport tdigits\nfrom mlp import make_mlp",
      "note": "`FlopCounterMode` is PyTorch's own counter: while it is active, it adds up the floating-point operations of every matrix product and convolution that runs. It counts a multiplication and an addition as two."
    },
    {
      "code": "def flops(step):\n    \"\"\"Floating-point operations PyTorch counts while `step` runs.\"\"\"\n    with FlopCounterMode(display=False) as counter:\n        step()\n    return counter.get_total_flops()\n\n\ndef ms_per_batch(model, x, y, repeat=20):\n    \"\"\"The fastest of `repeat` training steps on one batch, in milliseconds.\"\"\"\n    best = float(\"inf\")\n    for _ in range(repeat):\n        start = time.perf_counter()\n        F.cross_entropy(model(x), y).backward()\n        best = min(best, time.perf_counter() - start)\n    return best * 1000",
      "note": "The fastest of twenty runs, because anything else running on the machine can only make a step slower, never faster. A step here is the forward pass, the loss and the backward pass; the optimiser's update is left out, since it is one subtraction per parameter."
    },
    {
      "code": "measured = {}\nfor name, make, images in ((\"MLP\", make_mlp, False), (\"CNN\", cnn.make_cnn, True)):\n    torch.manual_seed(0)\n    model = make()\n    (x, y), _, _ = tdigits.load(images=images)\n    xb, yb = x[:32], y[:32]\n    n = sum(p.numel() for p in model.parameters())\n    forward = flops(lambda: model(xb)) / 32\n    train = flops(lambda: F.cross_entropy(model(xb), yb).backward()) / 32\n    ms = ms_per_batch(model, xb, yb)\n    print(f\"{name}: {n} parameters\")\n    print(f\"  forward {forward:,.0f} FLOPs per example, {forward / n:.1f} per parameter\")\n    print(f\"  training step {train:,.0f} per example, {train / forward:.2f} times the forward, {train / n:.1f} per parameter\")\n    print(f\"  30 epochs of 1,077 images: {30 * 1077 * train / 1e9:.2f} GFLOPs\")\n    print(f\"  {ms:.2f} ms per batch of 32, {32 * train / ms / 1e6:.2f} GFLOP/s\")\n    measured[name] = (train, ms)\n\n(mlp_flops, mlp_ms), (cnn_flops, cnn_ms) = measured[\"MLP\"], measured[\"CNN\"]\nprint(f\"CNN against MLP: {cnn_flops / mlp_flops:.0f} times the arithmetic, {cnn_ms / mlp_ms:.1f} times the time\")",
      "note": "Both networks see the same batch of 32 digits, flat for the MLP and as 1 by 8 by 8 grids for the CNN. Each count is divided by 32 to give a cost per example. The last two lines put the CNN's arithmetic and its time over the MLP's."
    }
  ]
}
```

```
PENDING work
```

**The MLP does 2.0 floating-point operations per parameter in the forward pass.** Each weight multiplies
one input, and the product is added to a sum: one multiplication and one addition, once per example. The
biases are a handful of additions, which the counter leaves out.

**The CNN does 17.6 per parameter**, because a weight of a convolution is not used once. A filter slides over
all 64 positions of the 8 by 8 map, and padding keeps every map at 8 by 8, so each weight of the two
convolutions multiplies 64 times per image. Lesson 11 found the CNN has nearly sixteen times the MLP's
parameters. In arithmetic per training step it does 198 times as much.

## Forward, then backward at twice the price

**A training step costs about three forward passes.** The backward pass of a layer computes two
products, each about as large as its forward one: the gradient of the loss with respect to the layer's
weights, and the gradient with respect to the layer's input, which the layer below needs. The CNN's step
is 2.97 times its forward pass. The MLP's is 2.14 times, because its first layer reads the image, and
nothing needs a gradient for the image, so that layer's second product is skipped.

That gives the rule used to estimate what a large model will cost before anybody trains it. **Training
takes about 6 × N × D operations**: 2 per parameter forward and 4 backward, for N parameters and D
examples seen. For a language model D counts tokens, and each weight is used once per token, which is
the case the rule was made for. The MLP sits under it, at 4.2 per parameter, for the reason just given.
The CNN breaks it at 52.4 per parameter, because a convolution reuses its weights across positions. The
rule is about dense layers, and a model built of something else needs its arithmetic counted.

## Time does not follow the arithmetic, at this size

The milliseconds are the course machine's, measured while other programs were sharing its four
processors. Yours will differ, so **compare the ratios.** The CNN did 198 times the MLP's arithmetic and
took TIMERATIO times as long.

The reason is what happens around the arithmetic. Every step pays fixed costs whatever the size of the
matrices: Python calls each layer, PyTorch checks shapes, picks a routine and allocates the outputs.
**For the MLP almost the whole step is that overhead**, which is why its operations per second come out
so low next to the CNN's. The arithmetic predicts the time only once each step has enough of it to
keep the processor busy: larger layers, larger images, larger batches.

A graphics card makes this sharper. Its arithmetic is many times faster than a processor's and the
overhead per step is not, so a model as small as these leaves the card waiting most of the time. That
was not run for this course, which has no graphics card, but it is the reason a small model on an
expensive card is money spent on waiting. Lesson 10 measured the other kind of waiting, for data.
