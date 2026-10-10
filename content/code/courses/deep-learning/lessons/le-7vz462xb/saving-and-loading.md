---
title: Saving and loading a state dict
version: 1
---

`train.py` ended with `torch.save(model.state_dict(), "mlp.pt")`. **A state dict is the model's
numbers by name, and nothing else**: not the class, not the order of the layers, not the
activations. Reading them back therefore takes the code that builds the network first. Save as
`~/dl/load.py`:

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "\"\"\"load: the trained weights read back into a fresh network, and checked.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\n_, val, _ = tdigits.load()\nstate = torch.load(\"mlp.pt\")\nfor name, tensor in state.items():\n    print(f\"{name:9s} {tuple(tensor.shape)}\")",
      "note": "A state dict is an ordinary dictionary from parameter names to tensors. It holds the numbers and not the code: nothing in it says that `0` is a `Linear` or that a ReLU sits between the layers."
    },
    {
      "code": "torch.manual_seed(1)\nmodel = make_mlp()\nprint(\"fresh:   val loss %.4f  val acc %.3f\" % loop.evaluate(model, *val))\nmodel.load_state_dict(state)\nprint(\"loaded:  val loss %.4f  val acc %.3f\" % loop.evaluate(model, *val))",
      "note": "The code builds the network, with random weights, and `load_state_dict` copies the saved numbers into it by name. The validation figures should be the ones the last epoch of `train.py` printed."
    },
    {
      "code": "try:\n    make_mlp(hidden=64).load_state_dict(state)\nexcept RuntimeError as e:\n    print(str(e).split(\"\\n\")[0])\n    print(str(e).split(\"\\n\")[1].strip())",
      "note": "Code that builds a different network refuses the file, and says which tensor did not fit."
    }
  ]
}
```

```
PENDING load
```

The file is 11,829 bytes, the 2,410 numbers at four bytes each plus the names and the format's own
bookkeeping. The fresh network, with random weights, scores 0.097, about one in ten, which is
guessing among ten digits. After `load_state_dict` it scores 0.950 with a loss of 0.1461, the same
two numbers as the last line of `train.py`. **Checking that a loaded model reproduces a number it
had before saving is the test that the right weights went into the right code.**

The last two lines are what happens when they did not. A network built with 64 hidden units has a
`0.weight` of `[64, 64]`, the file has `[32, 64]`, and `load_state_dict` refuses rather than loading
half of it. That strictness is why the state dict, and not the whole model, is the thing to save.

## Why not save the whole model

`torch.save(model)` also works, and it stores the model by pickling it, which records a reference to
the class by its module and name, `mlp` and `make_mlp`'s `Sequential` here, and not the class's code.
A rename or a move of that code breaks every file saved that way. Loading a pickle also runs code
chosen by whoever wrote the file, which is why `torch.load` now defaults to `weights_only=True` and
accepts only tensors and plain containers, a state dict among them.

## Resuming training

The weights are enough to predict. To continue training where a run stopped, the optimiser has a
`state_dict()` too, and it matters for Adam, whose two running averages per parameter (lesson 5)
would otherwise restart from zero. A checkpoint is then one dictionary holding both state dicts and
the epoch number, saved with the same `torch.save`.
