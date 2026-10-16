---
title: What deep learning is for
version: 1
---

After three sections where the network lost, the opposite question deserves the same care: **where
does a network win, and why there?** The answer is in what a column means. In a table, a column is a
feature somebody chose, and it means the same thing in every row. In an image, pixel 27 is ink in
one digit and background in the next, and what matters is the arrangement of many pixels, wherever
it sits. Somebody has to turn that arrangement into features. **A network learns those features
itself**, and that is the work a tree on raw pixels cannot do.

The digits are a small test of that, because at 8 by 8 they are nearly a table: 64 numbers, few
enough that boosting can treat each pixel as a column. The program below trains logistic regression,
boosting and lesson 11's CNN once, on the digits as they are, then asks all three about the
validation digits moved one pixel to each side. It needs the `cnn.py`, `tdigits.py`, `loop.py` and
`digits.py` that `small.py` used. Save it as `~/dl/moved.py`:

```schooling-example
{
  "language": "python",
  "file": "moved.py",
  "parts": [
    {
      "code": "\"\"\"moved: three models trained on the digits, then shown the same validation digits moved by one pixel.\"\"\"\nimport torch\nfrom sklearn.ensemble import HistGradientBoostingClassifier\nfrom sklearn.linear_model import LogisticRegression\nfrom threadpoolctl import threadpool_limits\n\nimport cnn\nimport loop\nimport tdigits\n\ntorch.set_num_threads(1)\nthreadpool_limits(1)\n\n(x, y), (vx, vy), _ = tdigits.load()"
    },
    {
      "code": "def move(images, right):\n    \"\"\"Every 8x8 image shifted `right` pixels sideways, the column that comes in left blank.\"\"\"\n    grid = images.reshape(-1, 8, 8)\n    out = torch.zeros_like(grid)\n    if right > 0:\n        out[:, :, right:] = grid[:, :, :-right]\n    elif right < 0:\n        out[:, :, :right] = grid[:, :, -right:]\n    else:\n        out = grid\n    return out.reshape(-1, 64)",
      "note": "The same digit, one column to the right or to the left. A person reads it exactly as before; to a model that learnt one weight or one split per pixel, every input number has changed."
    },
    {
      "code": "logistic = LogisticRegression(max_iter=5000).fit(x.numpy(), y.numpy())\nboosting = HistGradientBoostingClassifier(random_state=0).fit(x.numpy(), y.numpy())\ntorch.manual_seed(0)\nnet = cnn.make_cnn()\nloop.fit(net, torch.optim.SGD(net.parameters(), lr=0.1), (x.reshape(-1, 1, 8, 8), y),\n         (vx.reshape(-1, 1, 8, 8), vy), epochs=30, every=10**9)",
      "note": "All three are trained once, on the digits as they are. The CNN with lesson 11's recipe, so it is lesson 11's network again."
    },
    {
      "code": "for right in (0, 1, -1):\n    v = move(vx, right)\n    print(f\"moved {right:+d}:  logistic {logistic.score(v.numpy(), vy.numpy()):.3f}  \"\n          f\"boosting {boosting.score(v.numpy(), vy.numpy()):.3f}  \"\n          f\"CNN {loop.evaluate(net, v.reshape(-1, 1, 8, 8), vy)[1]:.3f}\")",
      "note": "Nothing is retrained: the same three models are asked about the validation digits in place, then moved one pixel each way."
    }
  ]
}
```

```
ana@vm:~/dl$ python moved.py
moved +0:  logistic 0.967  boosting 0.978  CNN 0.978
moved +1:  logistic 0.381  boosting 0.425  CNN 0.706
moved -1:  logistic 0.400  boosting 0.442  CNN 0.683
```

**On the digits in place, boosting ties the CNN at 0.978.** On images this small, the network has no
advantage to show. Moving the digits by one pixel changes that completely. Logistic regression falls
to 0.381 and 0.400, boosting to 0.425 and 0.442, and the CNN keeps 0.706 and 0.683.

The two tabular models learnt a weight or a split per pixel position, so to them a shifted digit is a
different table. The CNN's filters are the same nine weights at every place (lesson 11), so a stroke
it learnt to find in column 3 is found in column 4 as well, and its pooling forgives a little more.
**That is a feature learnt from the structure of the input, not from a column**, and it is why it
dropped less. It did drop: one pooling layer is not full invariance, and lesson 7's augmentation, by
showing it shifted digits in training, is the usual way to close the rest.

Scale that up and you have the case for deep learning. A photograph is 150,528 numbers, a second of
audio is tens of thousands, a sentence is a sequence of tokens (lesson 16), and in none of them does
a single raw number mean anything a tree could split on. **Where the features have to be learnt
from raw, structured input, networks have no serious rival**, and pretrained ones (lessons 13 and 17)
bring that to problems with little data too.

The two meet often. A table with a column of free text or a photo per row is common. A sound arrangement lets a network
turn the text or the photo into a vector of numbers, an embedding, and hands that to boosting as more
columns beside the others. Each model then does what it is good at.
