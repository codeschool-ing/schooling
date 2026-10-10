---
title: Pretraining a body worth borrowing
version: 1
---

Augmentation stretches the data you have. **Transfer learning borrows from data you do not have**:
a network trained on one task already holds filters that respond to strokes, corners and loops,
and a second task that needs the same parts can start from them. The usual picture is a network
trained on millions of photographs, lent to somebody with a few hundred; the last section of this
lesson shows that version, which this lab cannot download.

This course makes its own instead. **The digits 0 to 4 play the large old task, and the digits 5
to 9 the small new one.** A network trained on the first five classes has never seen a 7, so
whatever it brings to the second five has to be something general about handwriting. Save as
`~/dl/pretrain.py`:

```schooling-example
{
  "language": "python",
  "file": "pretrain.py",
  "parts": [
    {
      "code": "\"\"\"pretrain: a CNN trained on the digits 0 to 4 only, saved as base.pt.\"\"\"\nimport torch\n\nimport cnn\nimport loop\nimport tdigits",
      "note": "The CNN from the `cnn.py` of lesson 11, the loop from the `loop.py` of lesson 9, and the digits as images from `tdigits.py`."
    },
    {
      "code": "def first_five(x, y):\n    \"\"\"Only the images labelled 0 to 4, so the labels are still 0 to 4.\"\"\"\n    keep = y < 5\n    return x[keep], y[keep]\n\n\ntrain, val, _ = tdigits.load(images=True)\ntrain, val = first_five(*train), first_five(*val)\nprint(\"train\", len(train[1]), \"images, val\", len(val[1]), \"images, labels\", sorted(set(train[1].tolist())))",
      "note": "Half the classes, from both the training and the validation split. The test split stays unread, as it has since lesson 1. The digits 5 to 9 are held back for the next section, where they are the new task."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = cnn.make_cnn(5)\nopt = torch.optim.Adam(model.parameters(), lr=1e-3)\nloop.fit(model, opt, train, val, epochs=20, every=5)",
      "note": "Five outputs, one per class. The seed fixes the starting weights and `loop.fit` fixes the order of the batches, so the same machine writes the same file every time."
    },
    {
      "code": "torch.save(model.state_dict(), \"base.pt\")\nprint(\"saved base.pt:\", sum(p.numel() for p in model.parameters()), \"parameters\")",
      "note": "The `state_dict`, as lesson 9 saved one: the tensors by name, not the code. Whoever loads it builds `cnn.make_cnn(5)` first and pours the numbers in."
    }
  ]
}
```

```
PENDING pretrain
```

528 training images and 180 for validation, labelled 0 to 4. After 20 epochs the network is right
on 0.989 of the validation images, and it was already at 0.967 after 5. The program writes the
weights to `base.pt`, and `ls` shows the file:

```
PENDING pretrain
```

The file holds the 37,957 parameters of `cnn.make_cnn(5)`, as a `state_dict`. **Keep it**: the
next section borrows from it, and so does lesson 17.

## What a body and a head are

A classifier is two parts with different jobs. **The body turns an image into features**: here the
two convolutions, the pooling and the first linear layer, ending in 64 numbers per image. **The
head turns features into the classes of one task**: here the last `Linear(64, 5)`, with one
output per digit from 0 to 4. The head is what knows the task's labels. The body, ideally, only
knows what images of this kind are made of.

That is the whole idea of transfer learning: keep the body, throw the head away, and train a new
head for the new labels. Whether the body really only knows *what digits are made of*, or knows
*what 0 to 4 look like*, is a question the next section answers with a run.
