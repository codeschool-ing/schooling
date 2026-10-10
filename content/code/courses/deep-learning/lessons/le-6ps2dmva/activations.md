---
title: Activation functions, at seven points
version: 1
---

The function a unit applies to its sum is its **activation**. The perceptron used a step. Almost
nothing uses one now, and the reason is the subject of the next two lessons: training adjusts each
weight according to how much a small change in it would change the output, and a step's output does
not change at all under a small change, except at the one point where it jumps.

Four functions, evaluated at the same seven inputs. Save as `~/dl/activations.py`:

```python
# activations.py: four functions a unit can apply to its sum, at the same seven points
import numpy as np

z = np.array([-3.0, -1.0, -0.1, 0.0, 0.1, 1.0, 3.0])
functions = {
    "step":    (z > 0).astype(float),
    "sigmoid": 1 / (1 + np.exp(-z)),
    "tanh":    np.tanh(z),
    "relu":    np.maximum(0, z),
}
print("z       " + " ".join(f"{v:6.1f}" for v in z))
for name, out in functions.items():
    print(f"{name:7s} " + " ".join(f"{v:6.3f}" for v in out))
```

```
ana@vm:~/dl$ python activations.py
z         -3.0   -1.0   -0.1    0.0    0.1    1.0    3.0
step     0.000  0.000  0.000  0.000  1.000  1.000  1.000
sigmoid  0.047  0.269  0.475  0.500  0.525  0.731  0.953
tanh    -0.995 -0.762 -0.100  0.000  0.100  0.762  0.995
relu     0.000  0.000  0.000  0.000  0.100  1.000  3.000
```

Read the table by column, as a unit would see it.

| | what it does | where you meet it |
| --- | --- | --- |
| **step** | jumps from 0 to 1 at zero; between -0.1 and 0.1 it says nothing about the 0.2 of difference | the perceptron, and history |
| **sigmoid** | squeezes any sum into 0 to 1, passing 0.5 at zero; at 3 it is already 0.953, and further out it barely moves | the last layer of a yes-or-no classifier, read as a probability |
| **tanh** | the same S shape, between -1 and 1 and centred on zero | inside recurrent networks, lesson 14 |
| **ReLU** | zero for anything negative, the input itself for anything positive | between the layers of nearly every network since about 2012 |

**The flat ends of sigmoid and tanh are the problem they carry.** Where the curve is flat, a change
in the sum changes nothing in the output, and lesson 3 measures what that does to a deep network:
the signal that trains the first layers shrinks every time it passes one, until the first layers
stop learning. ReLU has no flat end on the positive side. It is also the cheapest function a
processor can compute, which matters when it runs billions of times.

Its own weakness is the other side. A unit whose sum is negative for every input outputs zero for
everything, receives no signal to change, and stays that way: a *dead* unit. Variants such as Leaky
ReLU and GELU give the negative side a small slope instead of none. GELU is the one inside the
transformers of lesson 15.

**Why bother with a function at all?** The section after next answers it with a measurement: without
one, any number of layers is exactly one layer.
