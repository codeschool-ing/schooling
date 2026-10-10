---
title: Cross-entropy: minus the log of the right answer
version: 1
---

A classifier's last layer produces **logits**: one score per class, any real numbers, with no promise
that they add up to anything. **Cross-entropy turns them into one number in two steps. Softmax makes
them probabilities, and the loss is minus the log of the probability given to the right class.** The
probabilities of the other classes do not appear in the loss at all. The same thing is also called log
loss and negative log-likelihood.

Save as `~/dl/xent.py`:

```schooling-example
{
  "language": "python",
  "file": "xent.py",
  "parts": [
    {
      "code": "\"\"\"xent: softmax, then minus the log of the right class, on four predictions.\"\"\"\nimport numpy as np\n\n\ndef softmax(z):\n    e = np.exp(z - z.max())\n    return e / e.sum()",
      "note": "Softmax turns any list of numbers into probabilities: exponentiate, then divide by the total. Subtracting the largest first changes nothing in the answer, and the section after next says why it is there."
    },
    {
      "code": "cases = {                          # three classes; the right answer is class 0 every time\n    \"confident, right\": [4.0, 0.0, 0.0],\n    \"unsure\":           [0.5, 0.3, 0.0],\n    \"unsure, wrong\":    [0.0, 0.5, 0.3],\n    \"confident, wrong\": [0.0, 4.0, 0.0],\n}",
      "note": "Four sets of logits, the raw scores a network's last layer produces. The right answer is class 0 in all four; what changes is how much the network believes it."
    },
    {
      "code": "for name, logits in cases.items():\n    p = softmax(np.array(logits))\n    loss = -np.log(p[0])\n    grad = p - np.array([1.0, 0.0, 0.0])\n    print(f\"{name:17s} p {np.round(p, 3)}  loss {loss:6.3f}  gradient {np.round(grad, 3)}\")",
      "note": "The loss looks only at the probability of the right class. The gradient with respect to the logits is the probabilities minus the one-hot target, the same `p - 1` that `tinynet.softmax_cross_entropy` computes."
    },
    {
      "code": "print(\"ten classes, all equal: loss\", round(float(-np.log(softmax(np.zeros(10))[0])), 3))",
      "note": "A network that knows nothing gives each of the ten digits 0.1. Its loss is the number to expect before the first step of training."
    }
  ],
  "output": "ana@vm:~/dl$ python xent.py\nconfident, right  p [0.965 0.018 0.018]  loss  0.036  gradient [-0.035  0.018  0.018]\nunsure            p [0.412 0.338 0.25 ]  loss  0.886  gradient [-0.588  0.338  0.25 ]\nunsure, wrong     p [0.25  0.412 0.338]  loss  1.386  gradient [-0.75   0.412  0.338]\nconfident, wrong  p [0.018 0.965 0.018]  loss  4.036  gradient [-0.982  0.965  0.018]\nten classes, all equal: loss 2.303"
}
```

Read the loss column from the top. Confident and right costs 0.036. Unsure, with the right class
barely ahead at 0.412, costs 0.886. Unsure and wrong costs 1.386. Confident and wrong costs 4.036,
over a hundred times the first row. The log is what does this: as the probability of the right class
falls towards zero, minus its log rises without limit, so **a confident wrong answer is the most
expensive thing a classifier can do**, and nothing caps what it costs.

**The gradient column is why this loss is used.** On the right class it is `p - 1`: -0.035 when the
network was already right, -0.982 when it was confidently wrong. The correction grows with the
mistake and does not fade as the mistake gets worse, which is the property a squared error on the
probabilities lacks; the section *MSE on a classifier* measures what that costs. Each wrong class gets
back the probability it took, as a push downwards, so in the last row class 1, which took 0.965, is
pushed down hardest.

**The last line is a number to know by heart.** A network that gives each of ten classes 0.1 has a
loss of 2.303, which is the natural log of 10. It is what a classifier of the digits should report
before it has learnt anything. A first loss far above it means the untrained network is already
confidently wrong, and its starting logits are too large.
