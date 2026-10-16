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
{"svg": "<svg viewBox=\"0 0 700 470\" role=\"img\" aria-label=\"Four small plots of training and validation loss against epoch, from the four runs of four.py. Two hidden units: both losses high and close together, still falling slowly, 1.03 and 1.08 at epoch 40. 150 training images: training loss falls to 0.003 while validation loss stops at about 0.23 and creeps up, a wide gap. Rate 1.5: both losses fall for four epochs, jump up at epoch 6 and then sit flat at about 2.31. Labels shuffled: training loss falls slowly from 2.26 to 1.91 while validation loss rises from 2.32 to 2.53.\"><text x=\"190.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">two hidden units</text><path d=\"M70 190 L350 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 190 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"64\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"64\" y=\"115.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"64\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"350\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"70\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"210.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M98.0 52.0 L126.0 70.4 L154.0 82.2 L182.0 90.4 L210.0 95.7 L238.0 100.3 L266.0 103.6 L294.0 107.4 L322.0 109.2 L350.0 112.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M98.0 53.1 L126.0 69.1 L154.0 79.9 L182.0 87.4 L210.0 93.4 L238.0 97.4 L266.0 100.0 L294.0 104.5 L322.0 105.5 L350.0 108.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"530.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">150 training images</text><path d=\"M410 190 L690 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 190 L410 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"404\" y=\"115.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.25</text><text x=\"404\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"690\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><text x=\"410\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"550.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M428.7 127.2 L447.3 172.2 L466.0 179.9 L484.7 184.0 L503.3 185.8 L522.0 186.8 L540.7 187.4 L559.3 187.8 L578.0 188.1 L596.7 188.4 L615.3 188.5 L634.0 188.6 L652.7 188.8 L671.3 188.9 L690.0 189.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M428.7 91.0 L447.3 107.9 L466.0 117.7 L484.7 120.5 L503.3 119.9 L522.0 120.3 L540.7 120.2 L559.3 119.8 L578.0 118.8 L596.7 119.3 L615.3 118.5 L634.0 118.4 L652.7 117.4 L671.3 117.1 L690.0 117.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"190.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rate 1.5</text><path d=\"M70 405 L350 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 405 L70 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"64\" y=\"405.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"64\" y=\"330.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.25</text><text x=\"64\" y=\"255.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.5</text><text x=\"350\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"70\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"210.0\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M88.7 305.2 L107.3 320.2 L126.0 265.6 L144.7 284.5 L163.3 276.6 L182.0 266.2 L200.7 266.1 L219.3 266.3 L238.0 266.1 L256.7 266.1 L275.3 266.2 L294.0 265.9 L312.7 266.1 L331.3 266.1 L350.0 266.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M88.7 305.6 L107.3 313.4 L126.0 289.6 L144.7 263.5 L163.3 258.8 L182.0 264.9 L200.7 265.4 L219.3 265.4 L238.0 265.8 L256.7 266.2 L275.3 265.8 L294.0 266.0 L312.7 266.2 L331.3 266.5 L350.0 265.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"530.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">labels shuffled</text><path d=\"M410 405 L690 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 405 L410 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404\" y=\"405.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"404\" y=\"330.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.5</text><text x=\"404\" y=\"255.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"690\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><text x=\"410\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"550.0\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M438.0 291.8 L466.0 294.1 L494.0 295.9 L522.0 298.0 L550.0 299.7 L578.0 301.5 L606.0 303.6 L634.0 305.8 L662.0 307.4 L690.0 309.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M438.0 288.9 L466.0 287.8 L494.0 286.8 L522.0 284.1 L550.0 284.7 L578.0 283.8 L606.0 282.2 L634.0 281.9 L662.0 278.7 L690.0 278.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M200 452 L226 452\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"232\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">train loss</text><path d=\"M400 452 L426 452\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"432\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">val loss</text></svg>", "caption": "The four runs of `four.py`, each drawn from its own printed lines, each on its own vertical scale. The shape is what tells them apart."}
```

## Too small: both lines high, and close together

```
ana@vm:~/dl$ python four.py small
epoch   4  train loss 1.8396  val loss 1.8257  val acc 0.372
epoch   8  train loss 1.5941  val loss 1.6126  val acc 0.428
epoch  12  train loss 1.4369  val loss 1.4674  val acc 0.467
epoch  16  train loss 1.3279  val loss 1.3680  val acc 0.475
epoch  20  train loss 1.2569  val loss 1.2886  val acc 0.494
epoch  24  train loss 1.1957  val loss 1.2352  val acc 0.531
epoch  28  train loss 1.1522  val loss 1.1995  val acc 0.558
epoch  32  train loss 1.1019  val loss 1.1399  val acc 0.586
epoch  36  train loss 1.0774  val loss 1.1270  val acc 0.619
epoch  40  train loss 1.0290  val loss 1.0825  val acc 0.608
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
ana@vm:~/dl$ python four.py few
epoch  10  train loss 0.2094  val loss 0.3300  val acc 0.911
epoch  20  train loss 0.0595  val loss 0.2738  val acc 0.928
epoch  30  train loss 0.0335  val loss 0.2409  val acc 0.928
epoch  40  train loss 0.0199  val loss 0.2317  val acc 0.922
epoch  50  train loss 0.0141  val loss 0.2338  val acc 0.925
epoch  60  train loss 0.0107  val loss 0.2323  val acc 0.922
epoch  70  train loss 0.0087  val loss 0.2327  val acc 0.922
epoch  80  train loss 0.0073  val loss 0.2341  val acc 0.922
epoch  90  train loss 0.0063  val loss 0.2372  val acc 0.922
epoch 100  train loss 0.0054  val loss 0.2358  val acc 0.922
epoch 110  train loss 0.0049  val loss 0.2385  val acc 0.922
epoch 120  train loss 0.0046  val loss 0.2386  val acc 0.925
epoch 130  train loss 0.0039  val loss 0.2421  val acc 0.922
epoch 140  train loss 0.0037  val loss 0.2431  val acc 0.922
epoch 150  train loss 0.0034  val loss 0.2423  val acc 0.919
```

**The training loss goes to 0.0034** while the validation loss stops at 0.2317 at epoch 40 and then
creeps up, to 0.2423 by epoch 150. Validation accuracy sits between 0.919 and 0.928 from epoch 20
onwards. With only 150 images the network learns them almost perfectly and learns nothing more that
transfers. **That is overfitting**: a gap that keeps widening, with the validation loss turning
upwards.

The accuracy did not fall while the loss rose, and the reason is in what each one measures. Accuracy
only asks whether the right digit scored highest. The loss also asks how sure the network was, and a
network that keeps training on 150 images becomes more and more confident, including on the
validation images it gets wrong. **A rising validation loss under a flat accuracy is a network
growing overconfident**, and it is the earlier warning of the two. The cures are lesson 7's subject.

## A rate too high: down, a jump, then flat

```
ana@vm:~/dl$ python four.py fast
epoch   2  train loss 1.6638  val loss 1.6560  val acc 0.358
epoch   4  train loss 1.4140  val loss 1.5263  val acc 0.578
epoch   6  train loss 2.3233  val loss 1.9234  val acc 0.217
epoch   8  train loss 2.0086  val loss 2.3585  val acc 0.097
epoch  10  train loss 2.1405  val loss 2.4366  val acc 0.106
epoch  12  train loss 2.3139  val loss 2.3357  val acc 0.106
epoch  14  train loss 2.3154  val loss 2.3270  val acc 0.089
epoch  16  train loss 2.3119  val loss 2.3275  val acc 0.086
epoch  18  train loss 2.3143  val loss 2.3204  val acc 0.106
epoch  20  train loss 2.3154  val loss 2.3141  val acc 0.111
epoch  22  train loss 2.3140  val loss 2.3194  val acc 0.086
epoch  24  train loss 2.3185  val loss 2.3163  val acc 0.086
epoch  26  train loss 2.3151  val loss 2.3138  val acc 0.092
epoch  28  train loss 2.3150  val loss 2.3082  val acc 0.117
epoch  30  train loss 2.3147  val loss 2.3298  val acc 0.097
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
ana@vm:~/dl$ python four.py shuffled
epoch   8  train loss 2.2636  val loss 2.3225  val acc 0.125
epoch  16  train loss 2.2190  val loss 2.3447  val acc 0.111
epoch  24  train loss 2.1814  val loss 2.3635  val acc 0.086
epoch  32  train loss 2.1396  val loss 2.4186  val acc 0.100
epoch  40  train loss 2.1054  val loss 2.4054  val acc 0.103
epoch  48  train loss 2.0694  val loss 2.4232  val acc 0.106
epoch  56  train loss 2.0277  val loss 2.4564  val acc 0.097
epoch  64  train loss 1.9849  val loss 2.4628  val acc 0.114
epoch  72  train loss 1.9513  val loss 2.5259  val acc 0.100
epoch  80  train loss 1.9098  val loss 2.5312  val acc 0.094
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
