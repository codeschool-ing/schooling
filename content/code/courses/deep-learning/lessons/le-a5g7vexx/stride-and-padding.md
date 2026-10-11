---
title: Stride and padding, and the size of what comes out
version: 1
---

The size of a convolution's output is not something to discover by running the network and reading
the error. **It is arithmetic, and it depends on three settings.** The kernel size `k` is how wide the
window is. The stride `s` is how far it moves each step. The padding `p` is how many rings of zeros
are added around the image before it starts. For an image `n` pixels wide:

```
out = (n + 2p - k) // s + 1
```

`//` divides and rounds down. The program below builds a real `nn.Conv2d` for seven settings, runs it
on an 8 by 8 image, and prints the formula's answer beside the shape PyTorch returned. Save it as
`~/dl/shapes.py`:

```schooling-example
{
  "language": "python",
  "file": "shapes.py",
  "parts": [
    {
      "code": "\"\"\"shapes: what kernel size, stride and padding do to the size of an 8x8 image.\"\"\"\nimport torch\nimport torch.nn as nn\n\nx = torch.zeros(1, 1, 8, 8)",
      "note": "One image, one channel, 8 by 8. The values do not matter here, only the shape that comes out."
    },
    {
      "code": "print(\"kernel  stride  padding  formula  nn.Conv2d output\")\nfor k, s, p in [(3, 1, 0), (3, 1, 1), (5, 1, 0), (5, 1, 2), (3, 2, 1), (3, 2, 0), (2, 2, 0)]:\n    conv = nn.Conv2d(1, 4, kernel_size=k, stride=s, padding=p)\n    formula = (8 + 2 * p - k) // s + 1\n    print(f\"{k:6d}  {s:6d}  {p:7d}  {formula:7d}  {tuple(conv(x).shape)}\")",
      "note": "Seven settings, each built as a real layer with 4 filters and run on the image. The `formula` column is computed by hand beside it; `//` is division rounded down."
    }
  ]
}
```

```
ana@vm:~/dl$ python shapes.py
kernel  stride  padding  formula  nn.Conv2d output
     3       1        0        6  (1, 4, 6, 6)
     3       1        1        8  (1, 4, 8, 8)
     5       1        0        4  (1, 4, 4, 4)
     5       1        2        8  (1, 4, 8, 8)
     3       2        1        4  (1, 4, 4, 4)
     3       2        0        3  (1, 4, 3, 3)
     2       2        0        4  (1, 4, 4, 4)
```

The formula and the layer agree on every line. Read them in pairs:

- **Padding keeps the size.** A 3 by 3 filter with no padding gives 6, as in the last section; with
  one ring of zeros it gives 8 again. A 5 by 5 filter needs two rings. Padding `p = (k - 1) / 2`, with
  stride 1, gives an output the size of the input, which is how the network in this lesson keeps its
  maps at 8 by 8.
- **Stride shrinks it.** With stride 2 the window stands on every other pixel, and 8 becomes 4.
- **Rounding down drops pixels.** Kernel 3, stride 2 and no padding gives 3: the window stands at
  columns 0, 2 and 4, and a fourth step would need columns 6 to 8, which do not exist. **Column 7 is
  never read.** Nothing warns you; a shape that comes out one smaller than expected is the sign.

**The shape has four numbers, in a fixed order**: batch, channels, height, width. The batch is 1
because one image went in. The channels are 4 because each layer was built with 4 filters, and each
filter makes a map of its own. That is why `filter.py` reshaped its image to `(1, 1, 8, 8)` before
handing it to PyTorch: one image, one channel, and the grid.
