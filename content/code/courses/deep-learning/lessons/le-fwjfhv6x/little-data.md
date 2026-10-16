---
title: Little data
version: 1
---

The digits are where networks have done well in this course: lesson 11's CNN reached 0.978 on the
validation set. **That was with 1,077 training images.** The question this section asks is what
happens to the ranking when there are far fewer, which is the normal case for a new problem: a
company starting to label its own documents has twenty of them, not a thousand.

The program trains three models with 2, 5 and 20 images of each digit, and then with all 1,077:
logistic regression, lesson 9's MLP from its `mlp.py`, and lesson 11's CNN from `cnn.py`. It needs
those two files, the `tdigits.py` and `loop.py` from lesson 9 and the `digits.py` from lesson 1
beside it. Save it as `~/dl/small.py`:

```schooling-example
{
  "language": "python",
  "file": "small.py",
  "parts": [
    {
      "code": "\"\"\"small: logistic regression, lesson 9's MLP and lesson 11's CNN, given 2, 5, 20 or all the images of each digit.\"\"\"\nimport torch\nfrom sklearn.linear_model import LogisticRegression\nfrom threadpoolctl import threadpool_limits\n\nimport cnn\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\ntorch.set_num_threads(1)\nthreadpool_limits(1)\n\n(x, y), val, _ = tdigits.load()\nval_images = (val[0].reshape(-1, 1, 8, 8), val[1])",
      "note": "The validation set is always the full 360 images, so every row of the table is judged on the same exam. Only the training set shrinks."
    },
    {
      "code": "def first(per_class):\n    \"\"\"The first `per_class` training images of each digit, or all of them.\"\"\"\n    if per_class is None:\n        return torch.arange(len(y))\n    return torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(10)])",
      "note": "The same number of each digit, so a small set never lacks a class by bad luck. `None` means the whole 1,077."
    },
    {
      "code": "def net(make, xs, ys, v, steps=1020):\n    torch.manual_seed(0)\n    model = make()\n    batches = -(-len(ys) // 32)\n    loop.fit(model, torch.optim.SGD(model.parameters(), lr=0.1), (xs, ys), v,\n             epochs=steps // batches, every=10**9)\n    return loop.evaluate(model, *v)[1]",
      "note": "Lesson 9's recipe, SGD at 0.1 in batches of 32, and the same number of steps whatever the size: 1,077 images are 34 batches, and 30 epochs of them are 1,020 steps. Twenty images make one batch, so they get 1,020 epochs, and no network loses for having been stopped early."
    },
    {
      "code": "print(\"images   logistic   MLP     CNN\")\nfor per_class in (2, 5, 20, None):\n    i = first(per_class)\n    xs, ys = x[i], y[i]\n    logistic = LogisticRegression(max_iter=5000).fit(xs.numpy(), ys.numpy())\n    lr_acc = logistic.score(val[0].numpy(), val[1].numpy())\n    mlp_acc = net(make_mlp, xs, ys, val)\n    cnn_acc = net(cnn.make_cnn, xs.reshape(-1, 1, 8, 8), ys, val_images)\n    print(f\"{len(ys):6d}   {lr_acc:.3f}      {mlp_acc:.3f}   {cnn_acc:.3f}\")",
      "note": "The same images go to all three. The CNN receives them as 1 by 8 by 8 grids, the other two as rows of 64."
    }
  ]
}
```

```
ana@vm:~/dl$ python small.py
images   logistic   MLP     CNN
    20   0.764      0.761   0.717
    50   0.861      0.842   0.786
   200   0.922      0.922   0.928
  1077   0.967      0.950   0.978
```

The last row is a check: 0.950 and 0.978 are lesson 9's and lesson 11's results, from the same
recipe and the same seed. The rows above it are the finding.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 340\" role=\"img\" aria-label=\"Validation accuracy against the number of training images, 20, 50, 200 and 1,077, for three models. Logistic regression is ahead at 20 and 50 images. The CNN is last at 20 and 50 and first at 200 and 1,077. The MLP sits close to logistic regression throughout and ends below it.\"><path d=\"M90 290 L530 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 290 L90 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 290.0 L530 290.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M90 206.6666666666666 L530 206.6666666666666\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"206.6666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M90 123.33333333333331 L530 123.33333333333331\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"123.33333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.9</text><path d=\"M90 40.0 L530 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><text x=\"90.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"188.84219987169183\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50</text><text x=\"338.38467537239444\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><text x=\"520.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1,077</text><text x=\"305.0\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">training images (log scale)</text><text x=\"80\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">validation accuracy</text><path d=\"M90.0 236.7 L188.8 155.8 L338.4 105.0 L520.0 67.5\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"90.0\" cy=\"236.66666666666663\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"188.84219987169183\" cy=\"155.83333333333331\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"338.38467537239444\" cy=\"104.99999999999994\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"520.0\" cy=\"67.50000000000003\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"538\" y=\"67.50000000000003\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">logistic</text><path d=\"M90.0 239.2 L188.8 171.7 L338.4 105.0 L520.0 81.7\" stroke=\"var(--paper-dim)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"239.16666666666663\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><circle cx=\"188.84219987169183\" cy=\"171.66666666666669\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><circle cx=\"338.38467537239444\" cy=\"104.99999999999994\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><circle cx=\"520.0\" cy=\"81.66666666666669\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><text x=\"538\" y=\"93.66666666666669\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">MLP</text><path d=\"M90.0 275.8 L188.8 218.3 L338.4 100.0 L520.0 58.3\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"275.8333333333333\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"188.84219987169183\" cy=\"218.33333333333326\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"338.38467537239444\" cy=\"99.99999999999994\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"520.0\" cy=\"58.33333333333334\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"538\" y=\"46.33333333333334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">CNN</text></svg>", "caption": "The same three models at four sizes of training set, drawn from the printed accuracies. The lines cross between 50 and 200 images."}
```

**With 20 images, the CNN is last, 4.7 points behind logistic regression**, and with 50 it is 7.5
points behind. At 200 it is ahead, by 0.006, which is two images of the 360, and with all 1,077 it
leads by 1.1 points. The lines cross somewhere between 50 and 200 images.

The reason is the number of things each model has to learn. Logistic regression on 64 pixels and 10
classes has 650 weights; the CNN has 38,282. Twenty images cannot pin down 38,282 numbers, and with
1,020 steps on the same twenty the CNN has every chance to memorise them, which is lesson 7's
subject. **A model with more parameters needs more data before its extra capacity is
worth anything**, and before that point the simpler model is not a compromise, it is the better
model.

The MLP is worth a look as well. It never beats logistic regression on these digits: 0.761 against
0.764, 0.842 against 0.861, a tie at 200, and 0.950 against 0.967 with everything. A hidden layer of
32 units gave it more to learn and nothing it could use.

Deep learning's own answer to little data is not to train from nothing. Lesson 13 trained a body on
other digits and gave the new task only a new head, and lesson 17 fine-tuned it. **With a model
pretrained on a large set, a network can learn from twenty examples**, because most of what it needs
was learnt somewhere else. Without one, as here, twenty examples go to the model with the fewest
numbers to fit.
