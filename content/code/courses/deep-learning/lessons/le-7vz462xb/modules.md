---
title: Modules, the layers that keep their own parameters
version: 1
---

In lesson 3 a layer was a class with `forward`, `backward` and its arrays, and `Net.params()`
collected the arrays for the optimiser. **An `nn.Module` is the same idea with the backward pass
taken away**, because autograd does it. What is left is a forward method and a list of parameters
that the module keeps for you, including those of every module inside it.

The network this lesson trains is one hidden layer of 32 units. Save it as `~/dl/mlp.py`, since
three programs use it:

```schooling-example
{
  "language": "python",
  "file": "mlp.py",
  "parts": [
    {
      "code": "\"\"\"mlp: the dense network this lesson trains on the digits, 64 pixels in and 10 scores out.\"\"\"\nimport torch.nn as nn\n\n\ndef make_mlp(hidden=32):\n    return nn.Sequential(nn.Linear(64, hidden), nn.ReLU(), nn.Linear(hidden, 10))",
      "note": "`nn.Sequential` runs its modules in order, the way `tinynet.Net` did in lesson 3. One hidden layer of 32 units, ReLU, and ten outputs, one score per digit. No softmax at the end: the loss applies it."
    }
  ]
}
```

Then look at it from the outside. Save as `~/dl/modules.py`:

```schooling-example
{
  "language": "python",
  "file": "modules.py",
  "parts": [
    {
      "code": "\"\"\"modules: the same network as a class, its parameters counted, and what it computes.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport tdigits\nfrom mlp import make_mlp\n\n\nclass MLP(nn.Module):\n    def __init__(self, hidden=32):\n        super().__init__()\n        self.hidden = nn.Linear(64, hidden)\n        self.out = nn.Linear(hidden, 10)\n\n    def forward(self, x):\n        return self.out(torch.relu(self.hidden(x)))",
      "note": "The longer way to write the same network, and the one any network with a branch or a skip needs. Layers assigned as attributes in `__init__` are registered as the module's children, and `forward` says what to do with them. Calling `model(x)` runs `forward`."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = make_mlp()\nprint(model)\nfor name, p in model.named_parameters():\n    print(f\"{name:9s} {str(tuple(p.shape)):9s} {p.numel():5d}\")\nprint(\"parameters:\", sum(p.numel() for p in model.parameters()))\nprint(\"as a class:\", sum(p.numel() for p in MLP().parameters()))",
      "note": "Every module knows its parameters, its children's included, and `parameters()` hands them all to an optimiser in one call. The names come from the position in the `Sequential`, or from the attribute names in the class."
    },
    {
      "code": "(x, _), _, _ = tdigits.load()\nfirst, last = model[0], model[2]\nby_hand = torch.relu(x[:5] @ first.weight.T + first.bias) @ last.weight.T + last.bias\nprint(\"output for 5 images:\", tuple(model(x[:5]).shape), \" by hand:\", torch.allclose(model(x[:5]), by_hand))",
      "note": "What a `Linear` computes, written out. PyTorch stores the weight as outputs by inputs, the transpose of lesson 1's `W`, so the product is `x @ weight.T`."
    }
  ]
}
```

```
ana@vm:~/dl$ python modules.py
Sequential(
  (0): Linear(in_features=64, out_features=32, bias=True)
  (1): ReLU()
  (2): Linear(in_features=32, out_features=10, bias=True)
)
0.weight  (32, 64)   2048
0.bias    (32,)        32
2.weight  (10, 32)    320
2.bias    (10,)        10
parameters: 2410
as a class: 2410
output for 5 images: (5, 10)  by hand: True
```

## Counting

**`sum(p.numel() for p in model.parameters())` is the line to remember**, and here it answers
2,410: 64 × 32 + 32 for the hidden layer and 32 × 10 + 10 for the output. The class version counts
the same, because it holds the same two layers under different names, `hidden` and `out` instead of
`0` and `2`. The ReLU has no parameters and gets no line.

Two things about `nn.Linear` differ from lesson 1. The weight is stored as **outputs by inputs**,
`(32, 64)`, so the layer computes `x @ weight.T + bias`, and the last line confirms that writing it
out by hand gives the same numbers. And it starts from its own random initialisation, not from
`tinynet.Linear`'s, so a PyTorch run and a NumPy run of the same shape do not start from the same
weights.

## Sequential or a class

`nn.Sequential` fits a network that is a straight line of layers, which is every network in this
lesson. **A class is needed the moment the data does not flow in one line**: two inputs, a branch
whose output is added back later, a layer used twice. Lesson 12's residual connections are the first
of those. The parameters are found the same way in both, by walking the modules assigned as
attributes, which is why a layer kept in an ordinary Python list instead is invisible to
`parameters()` and is never trained. `nn.ModuleList` is the list that registers its contents.
