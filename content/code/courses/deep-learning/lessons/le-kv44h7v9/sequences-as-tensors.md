---
title: Sequences as tensors
version: 1
---

Everything this course has fed a network so far had a fixed size: 64 pixels, or an 8 by 8 image.
**A sentence, a recording or a week of sensor readings does not.** Its parts come in an order that
matters, and two examples of the same kind can be of any length. A review of three words and a review
of three hundred are both reviews.

A batch of sequences is a tensor with three axes: **batch, time, features**. Each sequence is one
row of the batch, each step of it is one position along time, and each step carries a vector of
features. A sound has one feature a step, its amplitude. A sentence is a run of symbols, words or
characters, and a symbol is not yet a vector at all.

Save as `~/dl/shapes.py`:

```schooling-example
{
  "language": "python",
  "file": "shapes.py",
  "parts": [
    {
      "code": "\"\"\"shapes: a batch of sequences as a tensor, and the table that turns symbols into vectors.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.manual_seed(0)\nx = torch.randint(0, 8, (4, 6))\nprint(\"symbols\", tuple(x.shape), x.dtype)\nprint(x)",
      "note": "Four sequences of six symbols each, drawn from an alphabet of eight. A symbol is a whole number that names something, a letter or a word or an event, and its size means nothing: 7 is not more than 3."
    },
    {
      "code": "embed = nn.Embedding(8, 3)\ne = embed(x)\nprint(\"embedded\", tuple(e.shape))\nprint(\"sequence 0, step 0:\", e[0, 0].detach().numpy().round(3))\nprint(\"row\", x[0, 0].item(), \"of the table:\", embed.weight[x[0, 0]].detach().numpy().round(3))",
      "note": "An embedding is a table with one row of numbers per symbol, eight rows of three here. Each symbol is replaced by its row, so the batch gains a last axis: batch, time, features. The rows are parameters, and training moves them like any weight."
    },
    {
      "code": "dense = nn.Linear(6 * 3, 10)\nprint(\"a dense layer on length 6:\", tuple(dense(e.reshape(4, -1)).shape))\ntry:\n    dense(embed(torch.randint(0, 8, (4, 9))).reshape(4, -1))\nexcept RuntimeError as err:\n    print(\"the same layer on length 9:\", str(err).split(\"\\n\")[0])",
      "note": "The obvious way to read a sequence with what lessons 9 to 13 built: flatten it and give it to a dense layer. It works for length 6 and fails for length 9, because the layer has one weight per position and there are now more positions than weights."
    }
  ]
}
```

```
PENDING shapes
```

The symbols arrive as a `(4, 6)` table of whole numbers, `int64`. **`nn.Embedding` turns each one into
a row of a learnt table**: symbol 4 became `[-0.23 -0.392 0.543]`, exactly row 4 of `embed.weight`,
and the batch became `(4, 6, 3)`. That is the batch, time, features shape every recurrent layer in
PyTorch reads. Lesson 16 takes the table apart and looks at what training writes into it; here it is
only the step that gives a symbol something to multiply.

**The last two lines are the reason this lesson exists.** A dense layer can read a sequence if the
sequence is flattened, and lesson 9's network would read these six steps as 18 numbers. Give it nine
steps and the product fails, `4x27 and 18x10`, because the layer owns one weight per position and a
longer sequence has positions it has no weights for. Padding every sequence to the longest one is a
workaround with a cost: the layer learns a separate rule for symbol 3 in position 2 and for symbol 3 in
position 5, as if they had nothing in common.

What a sequence needs is a layer whose weights belong to **the step**, not to the position. It applies
one rule at position 1, again at position 2, and so on to the end, and carries what it has seen so far
from each step to the next. That is a recurrent network, and the next section writes one.
