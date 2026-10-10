---
title: Four curves that went wrong, recognised by shape
version: 1
---

When a run disappoints, the reflex is to change something and run again: more epochs, another rate,
a bigger network. **The curve usually says which of those is the right change**, and each common
failure draws a different shape. This section makes four of them on purpose, from four changes to
the run of the last section, so you can recognise them on a run that was not meant to fail.

Save this as `~/dl/four.py`. The case to run is named on the command line:

```schooling-example
{
  "language": "python",
  "file": "four.py",
  "parts": [
    {
      "code": "\"\"\"four: four runs that each go wrong in a different way. Name the case on the command line.\"\"\"\nimport sys\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\n(x, y), val, _ = digits.load()\n\n\ndef make(hidden):\n    rng = np.random.default_rng(0)\n    return Net(Linear(64, hidden, rng), ReLU(), Linear(hidden, 10, rng))",
      "note": "The same network as the rest of the lesson, with the width of the hidden layer as an argument."
    },
    {
      "code": "case = sys.argv[1]\nif case == \"small\":\n    net = make(2)\n    fit(net, SGD(net.params(), 0.1), (x, y), val, epochs=40, every=4)",
      "note": "Two hidden units instead of 64. Every image has to pass through two numbers on its way to ten classes."
    },
    {
      "code": "elif case == \"few\":\n    net = make(64)\n    fit(net, SGD(net.params(), 0.5), (x[:150], y[:150]), val, epochs=150, every=10)",
      "note": "The full network on only 150 of the 1,077 training images, for 150 epochs. The validation set is the usual 360."
    },
    {
      "code": "elif case == \"fast\":\n    net = make(64)\n    fit(net, SGD(net.params(), 1.5), (x, y), val, epochs=30, every=2)",
      "note": "Everything as usual except the rate: 1.5, fifteen times the 0.1 that works."
    },
    {
      "code": "elif case == \"shuffled\":\n    order = np.random.default_rng(1).permutation(len(y))\n    net = make(64)\n    fit(net, SGD(net.params(), 0.1), (x, y[order]), val, epochs=80, every=8)",
      "note": "A bug planted on purpose: the labels are shuffled and the images are not, so each image now carries some other image's label. The validation set is left correct."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 470\" role=\"img\" aria-label=\"Four small plots of training and validation loss against epoch, from the four runs of four.py. Two hidden units: both losses high and close together, still falling slowly, 1.03 and 1.08 at epoch 40. 150 training images: training loss falls to 0.003 while validation loss stops at about 0.23 and creeps up, a wide gap. Rate 1.5: both losses fall for four epochs, jump up at epoch 6 and then sit flat at about 2.31. Labels shuffled: training loss falls slowly from 2.26 to 1.91 while validation loss rises from 2.32 to 2.53.\"><text x=\"190.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">two hidden units</text><path d=\"M70 190 L350 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 190 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">150 training images</text><path d=\"M410 190 L690 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 190 L410 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"190.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rate 1.5</text><path d=\"M70 405 L350 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 405 L70 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">labels shuffled</text><path d=\"M410 405 L690 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 405 L410 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 452 L226 452\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"232\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">train loss</text><path d=\"M400 452 L426 452\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"432\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">val loss</text></svg>", "caption": "The four runs of `four.py`, each drawn from its own printed lines, each on its own vertical scale. The shape is what tells them apart."}
```

## Too small: both lines high, and close together

```
PENDING small
```

After 40 epochs the training loss is **1.0290 and the validation loss 1.0825**, and accuracy is
0.608, where the 64-unit network passed 0.93 in ten epochs. The two lines are close, so the network
does about as badly on images it has trained on as on new ones. **That is underfitting**: the model
cannot represent the task, and two numbers in the middle of the network cannot carry what ten
digits need. Both losses are still drifting down, but slowly, and more epochs at this pace would
take a very long time to get anywhere. The fix is capacity, a wider or deeper network, before more
training.

## Too few images: the lines part company

```
PENDING few
```

**The training loss goes to 0.0034** while the validation loss stops at 0.2317 at epoch 40 and then
creeps up, to 0.2423 by epoch 150. Validation accuracy sits between 0.919 and 0.928 from epoch 20
onwards. With only 150 images the network learns them almost perfectly and learns nothing more that
transfers. **That is overfitting**: a gap that keeps widening, with the validation loss turning
upwards.

The accuracy did not fall while the loss rose, and that is worth reading carefully. Accuracy only
asks whether the right digit scored highest. The loss also asks how sure the network was, and a
network that keeps training on 150 images becomes more and more confident, including on the
validation images it gets wrong. **A rising validation loss under a flat accuracy is a network
growing overconfident**, and it is the earlier warning of the two. The cures are lesson 7's subject.

## A rate too high: down, a jump, then flat

```
PENDING fast
```

For four epochs this run learns: the validation accuracy reaches 0.578. At epoch 6 the training loss
jumps to 2.3233, and from epoch 12 both losses sit **flat, between 2.30 and 2.34**. That level is not
arbitrary. A network that gives each of the ten classes the same probability has a cross-entropy of
−ln(1/10) = ln 10 ≈ 2.303, the loss of knowing nothing, as lesson 4 worked out. One step was large
enough to throw the weights somewhere they never came back from, and from epoch 8 on the validation
accuracy stays between 0.086 and 0.117, which is chance.

**A curve that falls and then jumps is a rate too high.** Lower the rate, or add the warm-up of
lesson 5, before touching anything else.

## A bug: training improves and validation does not

```
PENDING shuffled
```

**The training loss falls, slowly and steadily, from 2.2636 to 1.9098**, so the loop is doing
something. The validation loss rises from 2.3225 to 2.5312, and the validation accuracy stays
between 0.086 and 0.125 for the whole run. With the labels shuffled, there is nothing to learn about
digits. The network is memorising which arbitrary label goes with which image, which a network with
over 4,000 weights can do for 1,077 images given time, and that memory is useless on images it has
not seen.

**Validation accuracy at chance while the training loss falls points at the data, not at the
model.** The labels, the order of a split, a preprocessing step applied to one set and not the other:
these produce this shape, and no change of rate or network fixes them. The first thing to check is a
handful of images printed beside their labels, as lesson 1's `look.py` did.

## The four, side by side

| shape | what it is | first thing to change |
| --- | --- | --- |
| both losses high, close together, slow | underfitting | the size of the network |
| train loss near zero, val loss turning up | overfitting | the data or the regularisation (lesson 7) |
| falls, jumps up, then flat near 2.30 | a rate too high | the rate, or a warm-up |
| train loss falls, val accuracy at 0.1 | a bug in the data | the labels and the pipeline |
