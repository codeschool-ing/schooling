---
title: The perceptron, and the line it cannot bend
version: 1
---

The picture most people arrive with is a brain: neurons, synapses, something that thinks. **The
thing on the screen is arithmetic.** A unit multiplies each input by a weight, adds the products and
a bias, and applies a fixed function to the result. The biology gave it the name and almost nothing
else.

The first unit that learned its own weights was Frank Rosenblatt's perceptron, in 1958. Its
function is a step: answer 1 if the sum is above zero, and 0 otherwise. Its learning rule fits in
three lines, and the program below runs it on two truth tables. Save it as `~/dl/perceptron.py`:

```schooling-example
{
  "language": "python",
  "file": "perceptron.py",
  "parts": [
    {
      "code": "\"\"\"perceptron: Rosenblatt's learning rule on two tiny truth tables.\"\"\"\nimport numpy as np\n\nX = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])\nTABLES = {\"AND\": np.array([0, 0, 0, 1]), \"XOR\": np.array([0, 1, 1, 0])}",
      "note": "Four inputs, and two answers to learn from them. AND is 1 only when both inputs are 1; XOR is 1 when exactly one of them is."
    },
    {
      "code": "for name, y in TABLES.items():\n    w, b = np.zeros(2), 0.0\n    for epoch in range(1, 21):\n        mistakes = 0\n        for x, target in zip(X, y):\n            out = 1 if x @ w + b > 0 else 0",
      "note": "The unit: multiply each input by its weight, add the bias, and answer 1 if the sum is above zero. An epoch is one pass over the four examples, and the program allows twenty."
    },
    {
      "code": "            if out != target:\n                w += (target - out) * x\n                b += target - out\n                mistakes += 1\n        if mistakes == 0:\n            break",
      "note": "The learning rule. On a mistake, `target - out` is +1 or -1, and the weights move towards the input when the answer should have been 1 and away from it when it should have been 0. A correct answer changes nothing."
    },
    {
      "code": "    state = \"learnt\" if mistakes == 0 else \"still wrong\"\n    outputs = [1 if x @ w + b > 0 else 0 for x in X]\n    print(f\"{name}: {state} after {epoch} epochs, w={w} b={b}, \"\n          f\"outputs {outputs}, wanted {y.tolist()}\")"
    }
  ]
}
```

```
ana@vm:~/dl$ python perceptron.py
AND: learnt after 6 epochs, w=[2. 1.] b=-2.0, outputs [0, 0, 0, 1], wanted [0, 0, 0, 1]
XOR: still wrong after 20 epochs, w=[-1.  0.] b=1.0, outputs [1, 1, 0, 0], wanted [0, 1, 1, 0]
```

**AND was learnt in six passes**, with weights 2 and 1 and a bias of -2: the sum passes zero only
when both inputs are 1. **XOR was still wrong after twenty**, and it would still be wrong after two
thousand. The rule is not slow on XOR. It cannot finish.

## Why it cannot

The sum `w1·x1 + w2·x2 + b` is zero along a straight line in the plane of the two inputs. Everything
on one side of it gets a 1, everything on the other a 0. So a single unit can only ever answer
questions whose 1s and 0s a straight line can separate.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 270\" role=\"img\" aria-label=\"Two plots of the four inputs. For AND only (1,1) is a 1, and a straight line cuts it off from the three 0s. For XOR, (0,1) and (1,0) are 1s on one diagonal and (0,0) and (1,1) are 0s on the other, and no straight line puts the two 1s on one side and the two 0s on the other.\"><text x=\"160\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">AND</text><path d=\"M70 200 L270 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 200 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"230\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"50\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"50\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"278\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x1</text><text x=\"70\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x2</text><circle cx=\"70\" cy=\"200\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"70\" cy=\"60\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"230\" cy=\"200\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"230\" cy=\"60\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><path d=\"M120 40 L270 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"170\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">one line separates the 1 from the 0s</text><text x=\"480\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">XOR</text><path d=\"M390 200 L590 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M390 200 L390 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"390\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"550\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"370\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"370\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"598\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x1</text><text x=\"390\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x2</text><circle cx=\"390\" cy=\"200\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"390\" cy=\"60\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"550\" cy=\"200\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"550\" cy=\"60\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><path d=\"M420 40 L560 185\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"565\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"var(--amber)\">?</text><text x=\"490\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">no single line separates them</text></svg>", "caption": "AND can be drawn with one straight line through the input space, and XOR cannot. A single unit draws exactly one line."}
```

AND passes that test. XOR fails it: its 1s sit on one diagonal and its 0s on the other, and every
line that puts both 1s on one side takes a 0 with them. In 1969 Minsky and Papert's book
*Perceptrons* proved this and more about what single layers cannot compute, and interest in the
field fell away for more than a decade.

**The way out was known even then: more than one layer.** What was missing was a rule to train
them, because the perceptron's rule needs to know what each unit should have answered, and a unit in
the middle of a network has no target of its own. Lesson 3 is that rule. The last section of this
lesson shows the two-layer answer to XOR with its weights written by hand, which proves the
arrangement can do it before any rule learns it.
