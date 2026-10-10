---
title: Yes or no, and several labels at once
version: 1
---

Softmax answers *which one of these classes?*, and its probabilities add up to 1 by construction:
raising one lowers the others. **Not every question has exactly one answer.** A yes-or-no question
has two, and a photograph can show a dog, a ball and grass at the same time.

**For a yes-or-no question, one output, a sigmoid and binary cross-entropy.** The sigmoid of lesson 1
turns the single logit into `p`, the probability of yes. The loss is `-log p` when the answer is yes
and `-log(1 - p)` when it is no. It is the cross-entropy of the previous sections with two classes,
written with one output instead of two.

**For several labels at once, one such output per label, each judged on its own.** The program below
asks three questions about every digit: is it even, is it above 4, and does it have a closed loop,
which 0, 6, 8 and 9 do. Save as `~/dl/multilabel.py`:

```schooling-example
{
  "language": "python",
  "file": "multilabel.py",
  "parts": [
    {
      "code": "\"\"\"multilabel: three yes-or-no questions about every digit, answered at once.\"\"\"\nimport numpy as np\n\nimport digits\nfrom tinynet import Linear, ReLU, Net\n\nQUESTIONS = (\"even\", \"above 4\", \"has a loop\")\n\n\ndef answers(y):\n    \"\"\"Three 0-or-1 targets per image: one column per question.\"\"\"\n    return np.stack([y % 2 == 0, y > 4, np.isin(y, [0, 6, 8, 9])], axis=1).astype(np.float32)",
      "note": "The labels are built from the digit: an 8 is even, above 4 and has a loop, so its target is `[1, 1, 1]`, and a 3 is `[0, 0, 0]`. Nothing says an image has exactly one yes."
    },
    {
      "code": "def sigmoid_bce(logits, t):\n    \"\"\"Binary cross-entropy on every output, from logits; its mean and its gradient.\"\"\"\n    p = 1 / (1 + np.exp(-logits))\n    loss = np.maximum(logits, 0) - logits * t + np.log1p(np.exp(-np.abs(logits)))\n    return loss.mean(), (p - t) / t.size",
      "note": "Each output gets its own sigmoid and its own `-log p` or `-log(1 - p)`. The loss line is that formula rearranged so that `exp` only ever sees a negative number, the same trick as the previous section. The gradient is again `p - t`."
    },
    {
      "code": "(x, y), (xv, yv), _ = digits.load()\nt, tv = answers(y), answers(yv)\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 32, rng), ReLU(), Linear(32, 3, rng))\nfor epoch in range(30):\n    order = rng.permutation(len(y))\n    for start in range(0, len(y), 32):\n        idx = order[start:start + 32]\n        loss, grad = sigmoid_bce(net.forward(x[idx]), t[idx])\n        net.backward(grad)\n        for p, g in net.params():\n            p -= 0.5 * g",
      "note": "The plain training loop of lesson 3, with three outputs instead of ten and the new loss in place of `softmax_cross_entropy`. Nothing else about the network changes."
    },
    {
      "code": "p = 1 / (1 + np.exp(-net.forward(xv).astype(np.float64)))\nprint(\"val loss\", round(float(sigmoid_bce(net.forward(xv), tv)[0]), 4))\nfor j, q in enumerate(QUESTIONS):\n    print(f\"{q:10s} val accuracy {((p[:, j] > 0.5) == tv[:, j]).mean():.3f}\")\nfor digit in (3, 8):\n    i = int(np.argmax(yv == digit))\n    print(f\"a {digit}:\", dict(zip(QUESTIONS, np.round(p[i], 3).tolist())), \" sum\", round(p[i].sum(), 3))",
      "note": "Each output is read on its own, as yes above 0.5. The last lines show two validation images and what their three probabilities add up to."
    }
  ],
  "output": "ana@vm:~/dl$ python multilabel.py\nval loss 0.1042\neven       val accuracy 0.956\nabove 4    val accuracy 0.969\nhas a loop val accuracy 0.964\na 3: {'even': 0.0, 'above 4': 0.0, 'has a loop': 0.0}  sum 0.0\na 8: {'even': 0.957, 'above 4': 0.979, 'has a loop': 0.76}  sum 2.697"
}
```

Each question is answered correctly for between 95.6% and 96.9% of the validation images. The two
digits at the end show what a softmax could not have said. The 3 gets almost nothing for all three
questions, and its outputs add up to 0.0. The 8 gets three yeses, adding up to 2.697. **Neither sum
is a mistake: the outputs are independent probabilities, and their total means nothing.**

Two details carry over from cross-entropy. **The gradient is again `p - t`**, because the slope of
the log cancels the slope of the sigmoid exactly as it cancels the softmax's. And the loss line never
takes the exponential of a positive number, which is the previous section's trick rearranged for a
sigmoid. PyTorch packages both as `BCEWithLogitsLoss`, which takes logits for the same reason its
cross-entropy does.

The 0.5 that turns a probability into a yes is a choice rather than part of the loss. When one label
is rare, a lower threshold for that label, chosen on the validation set, finds more of it at the
price of more false alarms. That trade belongs to the metric, which is the subject of the last
section.
