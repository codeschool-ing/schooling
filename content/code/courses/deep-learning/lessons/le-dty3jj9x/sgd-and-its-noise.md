---
title: Stochastic gradient descent, and the noise it runs on
version: 1
---

Lesson 2 computed the gradient over every training point before it took a single step. **On a real
data set nobody does that.** A network learning from a million images would wait for a million
forward and backward passes to move once. Stochastic gradient descent, SGD for short, takes a small
random batch instead, computes the gradient on that batch alone and steps. The batch's gradient is an
estimate of the whole set's, and this section measures how good an estimate it is.

Save the program as `~/dl/noise.py`, beside the `digits.py` from lesson 1 and the `tinynet.py` from
lesson 3:

```schooling-example
{
  "language": "python",
  "file": "noise.py",
  "parts": [
    {
      "code": "\"\"\"noise: how far one batch's gradient is from the gradient of the whole training set.\"\"\"\nimport numpy as np\n\nimport digits\nfrom tinynet import Linear, ReLU, Net, softmax_cross_entropy\n\n(x, y), _, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))",
      "note": "The network every program of this lesson trains: 64 pixels in, 32 hidden units with ReLU, 10 scores out, built from the `tinynet.py` of lesson 3 with a fixed seed."
    },
    {
      "code": "def gradient(idx):\n    \"\"\"The loss on the images in idx, and every gradient flattened into one vector.\"\"\"\n    loss, grad = softmax_cross_entropy(net.forward(x[idx]), y[idx])\n    net.backward(grad)\n    return loss, np.concatenate([g.ravel() for _, g in net.params()])",
      "note": "One forward and one backward pass over the images in `idx`. `net.params()` hands back each weight array with its gradient, and the gradients are laid end to end as one long vector, so that two of them can be compared with a single number."
    },
    {
      "code": "full_loss, full = gradient(np.arange(len(y)))\nprint(f\"whole set: loss {full_loss:.4f}  gradient length {np.linalg.norm(full):.4f}\")",
      "note": "The exact gradient: all 1,077 training images in one pass. This is what gradient descent in lesson 2 followed, and what nobody computes for a real data set."
    },
    {
      "code": "order = rng.permutation(len(y))\ncosines, batches, sizes = [], [], []\nfor start in range(0, len(y), 32):\n    idx = order[start:start + 32]\n    loss, g = gradient(idx)\n    cosines.append(g @ full / (np.linalg.norm(g) * np.linalg.norm(full)))\n    batches.append(g)\n    sizes.append(len(idx))\n    if start < 5 * 32:\n        print(f\"batch {start // 32 + 1}: loss {loss:.4f}  length {np.linalg.norm(g):.4f}  \"\n              f\"cosine with the whole {cosines[-1]:.3f}\")\nprint(f\"{len(cosines)} batches: cosine from {min(cosines):.3f} to {max(cosines):.3f}\")",
      "note": "The same images cut into batches of 32, in a shuffled order. The cosine is 1 when a batch's gradient points exactly where the whole one does, 0 when it is at right angles and negative when it points uphill."
    },
    {
      "code": "mean = np.average(batches, axis=0, weights=sizes)\nprint(\"weighted mean of the batch gradients equals the whole:\", np.allclose(mean, full, atol=1e-6))",
      "note": "Each batch's gradient is a mean over its images, so the batches' gradients, weighted by how many images each holds, average back to the whole set's gradient. The last batch has 21 images, which is why the weights are needed."
    }
  ]
}
```

```
ana@vm:~/dl$ python noise.py
whole set: loss 2.3051  gradient length 0.6619
batch 1: loss 2.3243  length 1.1441  cosine with the whole 0.771
batch 2: loss 2.2481  length 0.9592  cosine with the whole 0.743
batch 3: loss 2.2744  length 0.8638  cosine with the whole 0.354
batch 4: loss 2.2323  length 0.7266  cosine with the whole 0.572
batch 5: loss 2.3406  length 1.0045  cosine with the whole 0.740
34 batches: cosine from 0.354 to 0.868
weighted mean of the batch gradients equals the whole: True
```

**No batch agrees with the whole set, and every batch roughly agrees.** The cosines run from 0.354
to 0.868, which is an angle of about 69 degrees at the worst and 30 at the best. All 34 are
positive, and that is what matters: a small step against any of these gradients lowers the loss of
the whole set as well, even against batch 3's, which is a poor estimate and still points downhill.

The batch gradients are also longer than the exact one, between 0.7266 and 1.1441 in the five printed
against 0.6619. The extra length is noise. Inside a batch of 32 the ways its images disagree with the
other 1,045 do not cancel, and they add a part that points nowhere in particular.

**The last line is why the method works at all.** Weighted by their sizes, the 34 batch gradients
average back to the whole set's gradient exactly. Each step is wrong in its own direction, the
errors have no favourite direction, and over many steps they cancel, leaving the descent lesson 2
did. Statisticians call such an estimate unbiased.

So the trade is **many cheap, noisy steps instead of few exact ones**: one pass over the 1,077
images buys a single exact step, or 34 steps with batches of 32. Two consequences of the noise come
back in this lesson:

- **The loss of a batch moves even when the network does not.** The five batches above were measured
  with the same weights and still gave losses from 2.2323 to 2.3406. A curve of batch losses wobbles
  for that reason alone.
- **The noise does not shrink near the bottom.** The exact gradient gets smaller as the weights
  approach a minimum, and the disagreement between batches does not, so at a fixed rate the weights
  keep jittering around the minimum instead of settling in it. The schedules at the end of this lesson
  exist for that.

How large a batch should be is lesson 6's subject. This lesson keeps it at 32.
