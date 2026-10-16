---
title: Batch normalisation, written for tinynet
version: 1
---

In 2015 Sergey Ioffe and Christian Szegedy took standardisation inside the network. **At a layer,
take the sums the batch produced, and for each unit subtract their mean and divide by their standard
deviation, measured over that batch.** They argued it fixed what they called internal covariate
shift: each layer's inputs keep changing as the layers before it learn. A 2018 paper by Santurkar
and colleagues found that explanation weak and traced the benefit to a smoother loss, on which larger
steps are safe. The effect is not in dispute, and the next section measures it.

The layer does four things to each feature, which is one column of the batch:

1. it measures the column's mean and variance over the rows of the batch;
2. it subtracts the mean and divides by the standard deviation, giving `xhat`, with mean 0 and
   variance 1;
3. it multiplies by a learnt `gamma` and adds a learnt `beta`, one of each per feature;
4. during training, it keeps running averages of the mean and variance for later.

**Step 3 gives back what step 2 took.** A column forced to mean 0 and variance 1 has lost options:
a ReLU after it would cut about half of every column, always. With `gamma` and `beta` the network can learn
any mean and spread for each unit, and the spread is now a parameter the network chose rather than
an accident of the weights before it. Step 4 exists because a prediction made after training may
arrive alone, with no batch to measure. Save as `~/dl/batchnorm.py`:

```schooling-example
{
  "language": "python",
  "file": "batchnorm.py",
  "parts": [
    {
      "code": "\"\"\"batchnorm: batch normalisation, as a layer tinynet can stack.\"\"\"\nimport numpy as np\n\n\nclass BatchNorm:\n    \"\"\"Each feature to mean 0 and variance 1 over the batch, then scaled by gamma and shifted by beta.\"\"\"\n    params = (\"gamma\", \"beta\")\n\n    def __init__(self, n, momentum=0.1, eps=1e-5):\n        self.gamma = np.ones(n, dtype=np.float32)\n        self.beta = np.zeros(n, dtype=np.float32)\n        self.dgamma = np.zeros_like(self.gamma)\n        self.dbeta = np.zeros_like(self.beta)",
      "note": "Two parameters per feature, named in `params` the way `Linear` names `W` and `b`, so `Net.params()` hands them to the optimiser with their gradients. They start at 1 and 0, which leaves the normalised value untouched."
    },
    {
      "code": "        self.running_mean = np.zeros(n, dtype=np.float32)\n        self.running_var = np.ones(n, dtype=np.float32)\n        self.momentum, self.eps = momentum, eps\n        self.training = True",
      "note": "The running statistics are not parameters: no gradient moves them. They are averages kept for later, when there is no batch to measure. `training` is the flag `Net.mode` sets on every layer."
    },
    {
      "code": "    def forward(self, x):\n        if self.training:\n            mean, var = x.mean(axis=0), x.var(axis=0)\n            m = self.momentum\n            self.running_mean = (1 - m) * self.running_mean + m * mean\n            self.running_var = (1 - m) * self.running_var + m * var",
      "note": "In training, the mean and variance of each column, over the rows of this batch. Each batch also moves the running averages 10% of the way towards what it measured, which is what `momentum=0.1` means in PyTorch too."
    },
    {
      "code": "        else:\n            mean, var = self.running_mean, self.running_var\n        self.std = np.sqrt(var + self.eps)\n        self.xhat = (x - mean) / self.std\n        return self.gamma * self.xhat + self.beta",
      "note": "In evaluation, the stored averages stand in for the batch. `eps` keeps a column with no spread from dividing by zero. Then every feature is scaled and shifted by its own `gamma` and `beta`, so the network can learn any mean and spread it needs."
    },
    {
      "code": "    def backward(self, grad):\n        self.dgamma[...] = (grad * self.xhat).sum(axis=0)\n        self.dbeta[...] = grad.sum(axis=0)\n        g = grad * self.gamma\n        return (g - g.mean(axis=0) - self.xhat * (g * self.xhat).mean(axis=0)) / self.std",
      "note": "`gamma` and `beta` get the same gradients a weight and a bias get. The input's gradient has two extra terms because every row's mean and variance came from all the rows: moving one input moves the statistics every other output was divided by."
    }
  ]
}
```

The backward pass is the part people copy without reading. **In a normal layer each output depends
on its own row; here every output in a column also depends on every other row**, through the mean and
the variance they all shared. That is where the two subtracted terms come from. A formula like this
is checked rather than trusted, with the finite differences of lesson 3. Save as `~/dl/checknorm.py`:

```schooling-example
{
  "language": "python",
  "file": "checknorm.py",
  "parts": [
    {
      "code": "\"\"\"checknorm: a normalising layer's backward, against the slope measured by nudging.\"\"\"\nimport numpy as np\n\nfrom batchnorm import BatchNorm\n\n\ndef check(layer, axis):\n    rng = np.random.default_rng(0)\n    x = rng.normal(3, 2, (8, 5))\n    layer.gamma[...] = rng.normal(1, 0.3, 5)\n    layer.beta[...] = rng.normal(0, 0.3, 5)\n    w = rng.normal(0, 1, (8, 5))",
      "note": "A batch of 8 rows and 5 features, centred on 3 rather than 0 so there is something to normalise. `gamma` and `beta` get random values, because at 1 and 0 a mistake involving them would not show."
    },
    {
      "code": "    def loss(x):\n        return (layer.forward(x) * w).sum()\n\n    loss(x)\n    dx = layer.backward(w)",
      "note": "A made-up loss: each output times a fixed random weight, added up. Its gradient with respect to the outputs is `w` itself, so `backward(w)` gives the gradient of this loss with respect to `x`."
    },
    {
      "code": "    print(\"x     mean\", np.round(x.mean(axis=axis), 2), \" std\", np.round(x.std(axis=axis), 2))\n    xhat = layer.xhat\n    print(\"xhat  mean\", np.round(xhat.mean(axis=axis), 2) + 0, \" std\", np.round(xhat.std(axis=axis), 2))",
      "note": "The statistics before and after normalising, along the axis the layer works on. `+ 0` turns a printed `-0.` into `0.`."
    },
    {
      "code": "    numeric = np.zeros_like(x)\n    for i in np.ndindex(x.shape):\n        up, down = x.copy(), x.copy()\n        up[i] += 1e-5\n        down[i] -= 1e-5\n        numeric[i] = (loss(up) - loss(down)) / 2e-5\n    error = np.abs(dx - numeric).max() / np.abs(numeric).max()\n    print(f\"relative error of the input gradient: {error:.1e}\")\n\n\nif __name__ == \"__main__\":\n    check(BatchNorm(5), axis=0)",
      "note": "Lesson 3's gradient check: nudge each of the 40 inputs up and down, and measure how much the loss moved. The `if` runs the check only when the file is run, not when another program imports `check` from it."
    }
  ]
}
```

```
ana@vm:~/dl$ python checknorm.py
x     mean [2.61 3.11 2.27 3.2  3.21]  std [0.98 1.56 1.88 0.97 1.95]
xhat  mean [0. 0. 0. 0. 0.]  std [1. 1. 1. 1. 1.]
relative error of the input gradient: 8.6e-11
```

The five columns of `x` had means between 2.27 and 3.21 and standard deviations between 0.97 and
1.95. After the layer, every column of `xhat` has mean 0 and standard deviation 1. **The backward
pass agrees with the measured slope to a relative error of 8.6e-11**, which is about as close as
nudging by 1e-5 in float64 can measure.

**The layer goes between a `Linear` and its activation**: `Linear`, then `BatchNorm`, then `ReLU`,
which is where the original paper put it. In that place the `Linear` layer's bias does nothing.
Subtracting the batch mean removes any constant added just before, and `beta` does the bias's job
after it. tinynet's `Linear` always has a bias, and here it costs 64 numbers that never move the
result. PyTorch's `nn.Linear` takes
`bias=False` for exactly this case.

One property explains most of what the layer does for training. **Multiply a unit's weights by any
positive number and its sums, their mean and their standard deviation all grow by that number, so
`xhat` does not change at all.** Whatever a large step does to the scale of the weights before a
batch norm layer, the layers after it see the same scale.
