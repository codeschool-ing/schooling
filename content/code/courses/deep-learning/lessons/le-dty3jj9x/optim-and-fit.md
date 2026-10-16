---
title: "optim.py and fit.py: three rules, and the loop that runs them"
version: 1
---

The last three sections wrote each rule for a toy of two or three numbers. A network holds arrays of
many shapes, and every NumPy lesson from here to lesson 8 trains one. **These two files are what they
train it with**: `optim.py` writes the three rules once, for any list of value and gradient pairs,
and `fit.py` is the loop that feeds them batches. Save both in `~/dl`, starting with
`~/dl/optim.py`:

```schooling-example
{
  "language": "python",
  "file": "optim.py",
  "parts": [
    {
      "code": "\"\"\"optim: three ways to turn a gradient into a step, each changing the arrays in place.\"\"\"\nimport numpy as np",
      "note": "Every optimiser here is given `net.params()`, the pairs of value and gradient from lesson 3, and changes the values in place with `-=`. Writing `p = p - ...` would make a new array and leave the network's own weights untouched."
    },
    {
      "code": "class SGD:\n    def __init__(self, params, lr):\n        self.params, self.lr = params, lr\n\n    def step(self):\n        for p, g in self.params:\n            p -= self.lr * g",
      "note": "The rule of lesson 2, for every array of the network: a step against the gradient, scaled by the rate. `lr` is an ordinary attribute, which is what lets a schedule change it between epochs."
    },
    {
      "code": "class Momentum:\n    def __init__(self, params, lr, beta=0.9):\n        self.params, self.lr, self.beta = params, lr, beta\n        self.v = [np.zeros_like(p) for p, _ in params]\n\n    def step(self):\n        for (p, g), v in zip(self.params, self.v):\n            v *= self.beta\n            v += g\n            p -= self.lr * v",
      "note": "One velocity array per parameter, of the same shape, starting at zero. Each step it keeps `beta` of itself and adds the new gradient, and the parameter moves along it. A gradient that never changes makes `v` grow towards ten times its size, 1 / (1 - 0.9)."
    },
    {
      "code": "class Adam:\n    def __init__(self, params, lr=0.001, beta1=0.9, beta2=0.999, eps=1e-8):\n        self.params, self.lr, self.b1, self.b2, self.eps = params, lr, beta1, beta2, eps\n        self.m = [np.zeros_like(p) for p, _ in params]\n        self.v = [np.zeros_like(p) for p, _ in params]\n        self.t = 0\n\n    def step(self):\n        self.t += 1\n        for (p, g), m, v in zip(self.params, self.m, self.v):\n            m *= self.b1\n            m += (1 - self.b1) * g\n            v *= self.b2\n            v += (1 - self.b2) * g * g\n            m_hat = m / (1 - self.b1 ** self.t)\n            v_hat = v / (1 - self.b2 ** self.t)\n            p -= self.lr * m_hat / (np.sqrt(v_hat) + self.eps)",
      "note": "`adam_steps.py`, for every array of a network: two running averages per parameter, both corrected by `1 - beta ** t`, and a step of `m_hat` over the square root of `v_hat`. `self.t` counts the steps, and `eps` only stops a division by zero."
    }
  ]
}
```

**The three classes share one interface**: they are built from `net.params()` and a rate, and their
`step()` uses whatever gradients the backward pass has just left in the arrays. The optimisers of
PyTorch, in lesson 9, have exactly this shape. There, gradients are added to what is already stored,
so a loop has to clear them before every backward pass. Here `Linear.backward` overwrites `dW` and
`db` with `[...] =`, which is why nothing in these files clears anything.

Then `~/dl/fit.py`:

```schooling-example
{
  "language": "python",
  "file": "fit.py",
  "parts": [
    {
      "code": "\"\"\"fit: the training loop every NumPy lesson from here on runs.\"\"\"\nimport numpy as np\n\nfrom tinynet import softmax_cross_entropy",
      "note": "The loss is tinynet's softmax cross-entropy, the one lesson 4 takes apart. It returns the mean loss of a batch and the gradient that starts the backward pass."
    },
    {
      "code": "def evaluate(net, x, y):\n    \"\"\"Loss and accuracy on a whole set, with the network in evaluation mode.\"\"\"\n    net.mode(False)\n    logits = net.forward(x)\n    net.mode(True)\n    loss, _ = softmax_cross_entropy(logits, y)\n    return float(loss), float((logits.argmax(axis=1) == y).mean())",
      "note": "One forward pass over a whole set, with no backward and no step. `net.mode(False)` changes nothing for tinynet's layers; it is there for the layers lessons 7 and 8 add, which behave differently while training."
    },
    {
      "code": "def fit(net, opt, train, val, epochs, batch_size=32, seed=0, every=1):\n    \"\"\"Shuffle, cut into batches, step once per batch; report every `every` epochs.\"\"\"\n    x, y = train\n    rng = np.random.default_rng(seed)\n    history = []\n    net.mode(True)\n    for epoch in range(1, epochs + 1):\n        order = rng.permutation(len(y))\n        losses = []\n        for start in range(0, len(y), batch_size):\n            idx = order[start:start + batch_size]\n            loss, grad = softmax_cross_entropy(net.forward(x[idx]), y[idx])\n            net.backward(grad)\n            opt.step()\n            losses.append(loss)\n        val_loss, val_acc = evaluate(net, *val)\n        history.append((epoch, float(np.mean(losses)), val_loss, val_acc))\n        if epoch % every == 0:\n            print(f\"epoch {epoch:3d}  train loss {np.mean(losses):.4f}  \"\n                  f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}\")\n    return history",
      "note": "Each epoch shuffles the training set with its own seeded generator, cuts it into batches and makes one step per batch: forward, loss, backward, `opt.step()`. With 1,077 images and batches of 32 that is 34 steps, the last one on 21 images. `history` keeps one tuple per epoch, and `every` decides how often a line is printed."
    }
  ]
}
```

A short program puts the two together and trains the digits network with momentum. Save as
`~/dl/train.py`:

```schooling-example
{
  "language": "python",
  "file": "train.py",
  "parts": [
    {
      "code": "\"\"\"train: the digits network, trained by fit with an optimiser from optim.\"\"\"\nimport numpy as np\n\nimport digits\nimport optim\nfrom fit import fit\nfrom tinynet import Linear, ReLU, Net",
      "note": "The imports are the whole toolkit of the NumPy lessons: the data from lesson 1, the network from lesson 3, and the two modules of this one."
    },
    {
      "code": "train, val, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))\nopt = optim.Momentum(net.params(), lr=0.1)\nhistory = fit(net, opt, train, val, epochs=10)",
      "note": "The same network as `noise.py`, given to momentum at a rate of 0.1 for ten epochs. Swapping the optimiser is changing one name on the `opt =` line."
    }
  ]
}
```

```
ana@vm:~/dl$ python train.py
epoch   1  train loss 1.2015  val loss 0.3860  val acc 0.875
epoch   2  train loss 0.2865  val loss 0.2014  val acc 0.931
epoch   3  train loss 0.1590  val loss 0.2189  val acc 0.925
epoch   4  train loss 0.1596  val loss 0.1243  val acc 0.953
epoch   5  train loss 0.1136  val loss 0.1915  val acc 0.925
epoch   6  train loss 0.1447  val loss 0.1363  val acc 0.964
epoch   7  train loss 0.0946  val loss 0.1449  val acc 0.944
epoch   8  train loss 0.0728  val loss 0.1320  val acc 0.942
epoch   9  train loss 0.0622  val loss 0.1258  val acc 0.958
epoch  10  train loss 0.0581  val loss 0.1032  val acc 0.969
```

**Ten epochs take validation accuracy from 0.875 to 0.969**, and two things in the log are worth
reading before they surprise you.

**In the first epoch the training loss, 1.2015, is far above the validation loss, 0.3860.** That is
not a bug, and it is not the network doing better on unseen digits. The training loss is the mean of
34 batch losses taken while the weights were still changing, most of them before the network had
learnt much. The validation loss is measured once, at the end of the epoch, with the weights the
epoch finished with.

**The validation accuracy does not climb steadily.** It goes 0.931, 0.925, 0.953, 0.925, 0.964: up and
down by as much as 0.039 between neighbouring epochs. That is the noise of SGD and the swing of
momentum, seen from the outside. What a curve like this says, and when to stop, is lesson 6's
subject.
