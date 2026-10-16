---
title: Training mode and evaluation mode
version: 1
---

The batch norm layer behaves one way in training and another in evaluation, and **the classic bug
is predicting with the network still in training mode**. Lesson 5's `fit.evaluate` switches the mode
for you, so every validation number in this course so far was honest. A program that serves a model,
and predicts one image at a time as requests arrive, has nobody to switch it unless you write the
line. Save as `~/dl/predict.py`:

```schooling-example
{
  "language": "python",
  "file": "predict.py",
  "parts": [
    {
      "code": "\"\"\"predict: single images through a network with batch norm, in both modes.\"\"\"\nimport numpy as np\n\nimport digits\nfrom batchnorm import BatchNorm\nfrom fit import evaluate, fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 64, rng), BatchNorm(64), ReLU(), Linear(64, 10, rng))\nfit(net, SGD(net.params(), 0.1), train, val, epochs=10, every=10)\nx, y = val",
      "note": "A small network with one batch norm layer, trained for ten epochs. `fit` evaluates with `evaluate`, which switches the network to evaluation mode and back, so the accuracy it prints is the honest one."
    },
    {
      "code": "def one_at_a_time(training):\n    net.mode(training)\n    for i in range(5):\n        logits = net.forward(x[i:i + 1])\n        print(f\"  label {y[i]}  predicted {logits.argmax()}  first logits {np.round(logits[0, :3], 2)}\")",
      "note": "What a program serving the model does: one image arrives, and it is predicted on its own. `x[i:i + 1]` keeps the batch shape, one row of 64."
    },
    {
      "code": "bn = net.layers[1]\nprint(\"running variance, first three features:\", np.round(bn.running_var[:3], 4))\nprint(\"evaluation mode, one image per batch:\")\none_at_a_time(False)\nprint(\"training mode, one image per batch:\")\none_at_a_time(True)\nprint(\"running variance, first three features:\", np.round(bn.running_var[:3], 4))\nprint(\"val loss and accuracy now:\", np.round(evaluate(net, *val), 3))",
      "note": "The same five images twice, first in the right mode and then in the wrong one. The running variance and the validation score are printed again afterwards, to see whether the wrong mode left anything behind."
    }
  ]
}
```

```
ana@vm:~/dl$ python predict.py
epoch  10  train loss 0.1144  val loss 0.1380  val acc 0.953
running variance, first three features: [0.1114 0.1146 0.1297]
evaluation mode, one image per batch:
  label 4  predicted 4  first logits [-2.31  1.26 -2.72]
  label 3  predicted 3  first logits [-1.96  0.94  2.3 ]
  label 0  predicted 0  first logits [ 8.08 -4.02  0.83]
  label 0  predicted 0  first logits [ 7.43 -3.98 -0.93]
  label 3  predicted 3  first logits [-1.69 -0.37  3.39]
training mode, one image per batch:
  label 4  predicted 8  first logits [-0.35  0.27 -0.11]
  label 3  predicted 8  first logits [-0.35  0.27 -0.11]
  label 0  predicted 8  first logits [-0.35  0.27 -0.11]
  label 0  predicted 8  first logits [-0.35  0.27 -0.11]
  label 3  predicted 8  first logits [-0.35  0.27 -0.11]
running variance, first three features: [0.0658 0.0677 0.0766]
val loss and accuracy now: [0.166 0.939]
```

**In evaluation mode the five images come out right**: 4, 3, 0, 0 and 3. In training mode every
one of them is an 8, with the same three logits to the last digit, `[-0.35 0.27 -0.11]`. The reason is
arithmetic. A batch of one image has that image as its mean and 0 as its variance, so `xhat` is 0 for
every feature and the layer outputs `beta`, the same vector whatever the image. Everything after it
then computes the same answer.

**The second harm is quieter, and it outlives the call.** In training mode the layer also updates its
running averages, and a batch of one has a variance of 0. Each of the five calls moved the running
variance 10% of the way towards zero, so the first feature's fell from 0.1114 to 0.0658. Nobody
trained the network, and its validation loss rose from 0.138 to 0.166 and its accuracy fell from
0.953 to 0.939. Five predictions did that. A server answering thousands in training mode would erase
the statistics completely.

Three habits prevent it:

- switch to evaluation mode before any prediction, validation included, and back to training mode
  before the next step, as `fit.evaluate` does;
- in PyTorch the switch is `model.eval()` and `model.train()`, and lesson 9 meets the same bug there;
- **suspect the mode when an answer depends on what else is in the batch**. A model whose prediction
  for one image changes when the images around it change is measuring the batch, which only training
  mode does.

The same flag switches lesson 7's dropout off, so a network with either layer has two behaviours, and
only one of them is meant for predictions.
