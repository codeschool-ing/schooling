---
title: Checking the gradients
version: 1
---

A mistake in a backward pass does not crash anything. **It returns arrays of the right shape,
filled with plausible numbers, and training carries on with them**, with nothing on the screen to
say that they are wrong. The forward pass can be checked against what the network predicts. The
backward pass can only be checked against the definition of a slope, which is lesson 2's nudge.

So the slow method from the first section is kept, as a test. Move one weight up by a tiny `h`,
then down, measure the loss each time, and divide the difference by `2h`. Do it for every weight
and compare with what `backward` produced. The comparison is a **relative error**, the difference
divided by the size of the two numbers, because a gap of 0.001 is nothing on a gradient of 50 and
everything on a gradient of 0.001. Save as `~/dl/gradcheck.py`:

```schooling-example
{
  "language": "python",
  "file": "gradcheck.py",
  "parts": [
    {
      "code": "\"\"\"gradcheck: tinynet's backward against finite differences, on eight digits.\"\"\"\nimport numpy as np\n\nimport digits\nimport tinynet\n\n(x_train, y_train), _, _ = digits.load()\ny = y_train[:8]",
      "note": "Eight training images are enough. The check is about the arithmetic, not about learning anything."
    },
    {
      "code": "def build(dtype):\n    \"\"\"A 64-16-10 network whose weights and gradients are kept in the given precision.\"\"\"\n    rng = np.random.default_rng(0)\n    net = tinynet.Net(tinynet.Linear(64, 16, rng), tinynet.ReLU(), tinynet.Linear(16, 10, rng))\n    for layer in net.layers[::2]:\n        for k in layer.params:\n            setattr(layer, k, getattr(layer, k).astype(dtype))\n            setattr(layer, \"d\" + k, np.zeros_like(getattr(layer, k)))\n    return net",
      "note": "`tinynet` trains in `float32`. This makes the same network in another precision by replacing each array and its gradient. The seed is the same, so both precisions start from the same weights."
    },
    {
      "code": "def compare(net, x):\n    \"\"\"The relative error between backward's gradient and a finite difference, for every weight.\"\"\"\n    _, grad = tinynet.softmax_cross_entropy(net.forward(x), y)\n    net.backward(grad)\n    errors = []\n    for value, analytic in net.params():\n        for i in np.ndindex(value.shape):\n            old = value[i]\n            value[i] = old + 1e-5\n            up = tinynet.softmax_cross_entropy(net.forward(x), y)[0]\n            value[i] = old - 1e-5\n            down = tinynet.softmax_cross_entropy(net.forward(x), y)[0]\n            value[i] = old\n            numeric = (up - down) / 2e-5\n            errors.append(abs(analytic[i] - numeric) / max(abs(analytic[i]) + abs(numeric), 1e-12))\n    return np.array(errors)",
      "note": "One backward pass gives every gradient. Then each of the 1,210 weights is moved up and down by 0.00001, and the change in the loss is measured. The error is relative: a difference of 0.001 means nothing on a gradient of 50 and everything on a gradient of 0.001."
    },
    {
      "code": "def report(label, errors):\n    print(f\"{label:32s} worst {errors.max():.1e}, above 1e-4: {(errors > 1e-4).sum()} of {errors.size}\")\n\n\nfor dtype in (np.float64, np.float32):\n    report(f\"{dtype.__name__}, tinynet as written\", compare(build(dtype), x_train[:8].astype(dtype)))",
      "note": "The same check in both precisions, on the code exactly as `tinynet.py` has it."
    },
    {
      "code": "tinynet.ReLU.backward = lambda self, grad: grad\nreport(\"float64, ReLU backward forgotten\", compare(build(np.float64), x_train[:8].astype(np.float64)))",
      "note": "A bug planted on purpose: a ReLU whose backward forgets the mask and passes every gradient through. The forward pass is untouched, so the loss is exactly what it was."
    }
  ]
}
```

```
ana@vm:~/dl$ python gradcheck.py
float64, tinynet as written      worst 1.8e-08, above 1e-4: 0 of 1210
float32, tinynet as written      worst 1.0e+00, above 1e-4: 663 of 1210
float64, ReLU backward forgotten worst 1.0e+00, above 1e-4: 704 of 1210
```

**In float64, the worst of the 1,210 weights disagrees by 1.8e-08**, and none is above 1e-4.
`tinynet`'s backward pass is right. A common rule of thumb reads a relative error around 1e-7 or
below as correct and anything above 1e-4 as a bug.

**In float32, the same correct code fails the check on 663 weights.** The fault is in the check,
not the code. A nudge of 0.00001 changes the loss in its seventh or eighth digit, and float32 keeps
only about seven, so the finite difference is mostly rounding. **With the bug planted, float64
reports 704 weights wrong**, the ones whose gradient had to pass through a ReLU that should have
stopped it. In float32 the broken code and the correct one look equally broken, which is why the
check is always run in float64. Training then goes back to float32, where the rounding is too small
to matter.

Three habits make the check worth running:

- **Keep it small.** A few images and a few units. It does two forward passes per weight, 2,420 for this
  network, where the backward pass did one.
- **Run it before training, not during.** It tests code, so it runs once whenever a layer's backward pass
  is written or changed. Lessons 7 and 8 write new layers for `tinynet`, and this is how to test
  them.
- **Watch the kinks.** ReLU has no slope at exactly zero. A weight whose nudge pushes some sum across
  zero can disagree legitimately, and a single bad entry there is not a bug. None did here.
