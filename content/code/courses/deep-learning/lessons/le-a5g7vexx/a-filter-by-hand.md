---
title: A filter, slid by hand
version: 1
---

Lesson 9's network reads a digit as 64 numbers in a row, and the order of that row means nothing to
it. **Shuffle the pixels of every image in the same fixed way and a dense layer can learn exactly as
well**, because the shuffle only reorders the rows of its weight matrix. Nothing in it knows that
pixel 3 sits next to pixel 4, or that pixel 11 is just below pixel 3. Whatever it learns about
strokes and corners it has to learn from the data, separately for every place on the grid.

A convolution starts from the opposite assumption: **what matters in a picture is a small
neighbourhood, and the same thing can turn up anywhere.** It takes a filter, also called a kernel, of
3 by 3 weights, lays it on a 3 by 3 patch of the image, multiplies the nine pairs and adds them up.
That sum is one number of the output. Then the filter moves one pixel and does it again, with the
same nine weights, until it has visited every place it fits.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"On the left, the 8 by 8 digit with its ink values. A 3 by 3 window over its top-left corner is outlined, and a second window one column to the right is dashed. In the middle, the filter: minus one, zero and plus one in each row. On the right, the 6 by 6 output, where the first window gave 21 and the second gave 32.\"><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">PENDING</text></svg>", "caption": "The filter sits on a 3 by 3 patch, multiplies, adds, and writes one number. One column to the right, it does it again. Thirty-six positions fit, so the output is 6 by 6."}
```

The program below does it with two loops, on the first training digit. It needs the `digits.py` from
lesson 1 beside it. Save it as `~/dl/filter.py`:

```schooling-example
{
  "language": "python",
  "file": "filter.py",
  "parts": [
    {
      "code": "\"\"\"filter: a 3x3 edge filter slid over one digit, by hand.\"\"\"\nimport numpy as np\n\nimport digits\n\n(x, y), _, _ = digits.load()\nimage = (x[0] * 16).reshape(8, 8).astype(int)\nprint(\"label\", y[0])\nprint(image)",
      "note": "The first training image, the one lesson 1 drew in characters, back on its 0 to 16 scale so every number below is a whole one."
    },
    {
      "code": "kernel = np.array([[-1, 0, 1],\n                   [-1, 0, 1],\n                   [-1, 0, 1]])",
      "note": "The filter: nine weights. It adds the column on its right and subtracts the column on its left, so it answers how much the ink grows from left to right."
    },
    {
      "code": "out = np.zeros((6, 6), dtype=int)\nfor i in range(6):\n    for j in range(6):\n        out[i, j] = (image[i:i + 3, j:j + 3] * kernel).sum()\nprint(out)",
      "note": "The whole of convolution. Cut the 3x3 patch at row `i`, column `j`, multiply it by the filter element by element, add the nine products. A 3-pixel window fits in 6 places across 8 pixels, so the answer is 6 by 6."
    },
    {
      "code": "import torch\nimport torch.nn.functional as F\n\nt = F.conv2d(torch.tensor(image, dtype=torch.float32).reshape(1, 1, 8, 8),\n             torch.tensor(kernel, dtype=torch.float32).reshape(1, 1, 3, 3))\nprint(\"PyTorch agrees:\", bool((t.reshape(6, 6).int().numpy() == out).all()))",
      "note": "The same image and filter through PyTorch's own function. It wants four dimensions for each, which the next section explains, and returns the same 36 numbers."
    }
  ]
}
```

```
PENDING filter
```

The digit is a 6: a stroke down columns 2 and 3, and a loop at the bottom. **The filter subtracts the
column on its left from the column on its right**, so it is positive where ink starts and negative
where ink ends, reading left to right. The first column of the output, 21 to 48, is the left edge of
that stroke; the third, -5 to -34, is its right edge. Where the patch is blank, or evenly inked, the
two sides cancel and the answer is near zero. Nine weights found a vertical edge at every height of
the image, and they would find one in any other column too.

**The output is 6 by 6, not 8 by 8**, because a 3-pixel window has 6 places to stand across 8
pixels. The next section says how to keep the size, and how to shrink it on purpose.

The last line checks the loops against PyTorch's `F.conv2d`, and the 36 numbers agree. One detail
of the name: in mathematics a convolution flips the filter before sliding it, and what the loops do,
without a flip, is called cross-correlation. Deep learning libraries compute the second and call it
convolution. Since the network learns its filters, a flipped filter is simply learnt the other way
round, and nothing else changes.
