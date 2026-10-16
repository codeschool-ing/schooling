---
title: Choosing the loss, and why the metric is a different number
version: 1
---

**The loss follows from the question the output answers, and the question also fixes the last
layer.** The two are chosen together, because the losses that work best take raw scores and apply the
squashing function themselves.

| the output answers | last layer | loss | in PyTorch (lesson 9) |
| --- | --- | --- | --- |
| a number, ordinary noise | one linear output, no activation | MSE | `nn.MSELoss` |
| a number, with outliers to ignore | one linear output, no activation | Huber, or MAE | `nn.HuberLoss`, `nn.L1Loss` |
| one class out of several | one logit per class, no softmax in the model | cross-entropy, softmax inside | `nn.CrossEntropyLoss` |
| yes or no | one logit | binary cross-entropy, sigmoid inside | `nn.BCEWithLogitsLoss` |
| several yes-or-no labels at once | one logit per label | binary cross-entropy per label | `nn.BCEWithLogitsLoss` |

## The metric is not the loss

A loss has to be something gradient descent can follow: smooth, with a slope everywhere. **Accuracy
has no useful slope.** It is a step, like the perceptron's in lesson 1: a small change in a weight
changes no prediction, so its gradient is zero almost everywhere. So training follows a loss, and the
model is judged by a metric, and the two can disagree. Save as `~/dl/metric.py`:

```python
# metric.py: three models on the same five yes-or-no questions, scored two ways
import numpy as np

models = {                          # the probability each model gave the right answer
    "A": [0.60, 0.60, 0.60, 0.60, 0.40],
    "B": [0.99, 0.99, 0.99, 0.99, 0.001],
    "C": [0.90, 0.90, 0.45, 0.45, 0.45],
}
for name, p_right in models.items():
    p = np.array(p_right)
    print(f"model {name}  accuracy {(p > 0.5).mean():.1f}   cross-entropy {-np.log(p).mean():.3f}")
```

```
ana@vm:~/dl$ python metric.py
model A  accuracy 0.8   cross-entropy 0.592
model B  accuracy 0.8   cross-entropy 1.390
model C  accuracy 0.4   cross-entropy 0.521
```

A and B both get four of five right. **B's loss is more than twice A's because of one answer**: it
gave the right class 0.001 on the fifth question, and cross-entropy punishes a confident mistake
without limit. C has the lowest loss of the three and the lowest accuracy, 0.4. It is never very
wrong and is wrong often. Ranked by loss, the order is C, A, B; ranked by accuracy, C comes last.

**Train on the loss, choose on the metric.** The metric is whatever the problem is judged by:
accuracy for the digits, recall when missing a rare case is what hurts, mean minutes late for
deliveries. When two models disagree on the validation set, the metric decides which one ships. The
loss says whether training is going well, and lesson 6 reads its curves. A validation loss that rises
while accuracy holds steady is usually a model growing confidently wrong on a few images, which is
model B's shape.
