---
title: The first training
version: 1
---

Lesson 1 ended with a two-layer network whose weights were written by hand, because nothing yet
could find them. **Now something can.** The loop below is everything training is: predict, measure
the loss and its gradient, pass it back, and move every weight a little against its own gradient.
There is no optimiser object and no framework, and every line is one you have already seen. Save
as `~/dl/train.py`:

```schooling-example
{
  "language": "python",
  "file": "train.py",
  "parts": [
    {
      "code": "\"\"\"train: tinynet learns the digits, with the plainest loop there is.\"\"\"\nimport numpy as np\n\nimport digits\nimport tinynet\n\n(x_train, y_train), (x_val, y_val), _ = digits.load()\nrng = np.random.default_rng(0)\nnet = tinynet.Net(tinynet.Linear(64, 64, rng), tinynet.ReLU(), tinynet.Linear(64, 10, rng))\nlr, batch = 0.1, 32",
      "note": "A network of 64 inputs, 64 hidden units and 10 outputs, one per digit. The rate is 0.1, and the gradient is computed on 32 images at a time; lessons 5 and 6 are about those two numbers."
    },
    {
      "code": "for epoch in range(1, 21):\n    order = rng.permutation(len(y_train))\n    total = 0.0\n    for start in range(0, len(order), batch):\n        rows = order[start:start + batch]\n        loss, grad = tinynet.softmax_cross_entropy(net.forward(x_train[rows]), y_train[rows])\n        net.backward(grad)\n        for value, gradient in net.params():\n            value -= lr * gradient\n        total += loss * len(rows)\n    accuracy = (net.forward(x_val).argmax(axis=1) == y_val).mean()\n    print(f\"epoch {epoch:2d}  train loss {total / len(y_train):.4f}  val accuracy {accuracy:.3f}\")",
      "note": "Each epoch shuffles the training set and walks it 32 images at a time. Each batch is a forward pass, the loss and its gradient, a backward pass, and a step. `value -= lr * gradient` changes the arrays inside the layers, in place. After the epoch, the network predicts the 360 validation images, and the largest of the ten outputs is its answer."
    }
  ]
}
```

```
ana@vm:~/dl$ python train.py
epoch  1  train loss 1.8299  val accuracy 0.714
epoch  2  train loss 1.0593  val accuracy 0.864
epoch  3  train loss 0.6628  val accuracy 0.858
epoch  4  train loss 0.4799  val accuracy 0.917
epoch  5  train loss 0.3816  val accuracy 0.914
epoch  6  train loss 0.3263  val accuracy 0.925
epoch  7  train loss 0.2856  val accuracy 0.925
epoch  8  train loss 0.2565  val accuracy 0.936
epoch  9  train loss 0.2317  val accuracy 0.928
epoch 10  train loss 0.2127  val accuracy 0.939
epoch 11  train loss 0.1972  val accuracy 0.944
epoch 12  train loss 0.1813  val accuracy 0.947
epoch 13  train loss 0.1715  val accuracy 0.942
epoch 14  train loss 0.1621  val accuracy 0.944
epoch 15  train loss 0.1550  val accuracy 0.950
epoch 16  train loss 0.1450  val accuracy 0.956
epoch 17  train loss 0.1413  val accuracy 0.953
epoch 18  train loss 0.1327  val accuracy 0.958
epoch 19  train loss 0.1270  val accuracy 0.956
epoch 20  train loss 0.1238  val accuracy 0.953
```

**From random weights to 0.953 of the validation digits in twenty epochs.** The first epoch already
reaches 0.714, against the 0.1 a network guessing at random would score. The training loss falls
every epoch, from 1.8299 to 0.1238. The validation accuracy mostly rises, peaks at 0.958 in epoch
18 and ends at 0.953.

Look at what did the work. The network has 64 × 64 + 64 + 64 × 10 + 10 = 4,810 numbers, and the
program never says what any of them should be. Each one was moved, 34 times an epoch, by its own
share of the blame for the loss on 32 images. **That share is the gradient, and backpropagation is
what made it cheap enough to compute 4,810 at a time.**

Three choices in this loop were made without an argument, and the next three lessons supply one:

- **the loss**, which lesson 4 explains and compares with others;
- **the rate of 0.1 and the plain step**, which lesson 5 replaces with better ones and shows how to
  choose;
- **the batch of 32 and the twenty epochs**, which lesson 6 measures, along with how to read a
  validation curve that goes down as well as up, as this one did from epoch 2 to epoch 3.

The test set has not been touched, and it will not be until a lesson has a final model to report.
