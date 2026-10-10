---
title: Pooling, which keeps the strongest answer
version: 1
---

After a convolution comes, often, a layer that throws most of its output away on purpose. **Pooling
cuts each map into small blocks and keeps one number per block**: the largest, for max pooling, or the
mean, for average pooling. With 2 by 2 blocks the height and the width halve, and three numbers in
four are gone. Save as `~/dl/pool.py`:

```schooling-example
{
  "language": "python",
  "file": "pool.py",
  "parts": [
    {
      "code": "\"\"\"pool: max and average pooling on a 4x4 map, and what a one-pixel shift does.\"\"\"\nimport torch\nimport torch.nn as nn\n\nm = torch.tensor([[1., 3., 0., 2.],\n                  [4., 2., 1., 0.],\n                  [0., 1., 5., 6.],\n                  [2., 0., 7., 1.]]).reshape(1, 1, 4, 4)\nprint(\"max:\\n\", nn.MaxPool2d(2)(m).reshape(2, 2))\nprint(\"average:\\n\", nn.AvgPool2d(2)(m).reshape(2, 2))\nprint(\"parameters in MaxPool2d(2):\", len(list(nn.MaxPool2d(2).parameters())))",
      "note": "A 4 by 4 map, as a convolution would hand it on, cut into four 2 by 2 blocks. Max pooling keeps the largest number of each block, average pooling their mean."
    },
    {
      "code": "dot = torch.zeros(1, 1, 4, 4)\ndot[0, 0, 1, 0] = 1.0\nfor shift in (0, 1, 2):\n    moved = torch.roll(dot, shifts=shift, dims=3)\n    print(f\"dot moved {shift} right -> pooled\", nn.MaxPool2d(2)(moved).flatten().tolist())",
      "note": "A single bright point, moved along its row by 0, 1 and 2 pixels, and what max pooling makes of each position."
    }
  ]
}
```

```
ana@vm:~/dl$ python pool.py
max:
 tensor([[4., 2.],
        [2., 7.]])
average:
 tensor([[2.5000, 0.7500],
        [0.7500, 4.7500]])
parameters in MaxPool2d(2): 0
dot moved 0 right -> pooled [1.0, 0.0, 0.0, 0.0]
dot moved 1 right -> pooled [1.0, 0.0, 0.0, 0.0]
dot moved 2 right -> pooled [0.0, 1.0, 0.0, 0.0]
```

The top-left block holds 1, 3, 4 and 2, so max pooling keeps 4 and average pooling keeps 2.5. **A
pooling layer has nothing to learn**: zero parameters, the same fixed rule everywhere.

The reason to want it is in the last three lines. The bright point moved one pixel to the right and
the pooled output did not change, because it stayed inside the same 2 by 2 block. Moved two pixels,
it crossed into the next block and the output moved with it. **Max pooling asks whether a feature
appeared somewhere in the block, not exactly where.** A stroke drawn one pixel to the left by a
different hand gives the same answer, and that is worth more than the precise position for telling a
6 from a 5.

The other reason is cost. Every layer after the pooling works on a quarter of the numbers. In the
network of this lesson the pooling turns 32 maps of 8 by 8 into 32 maps of 4 by 4, and the dense
layer that follows reads 512 numbers instead of 2,048.

Max pooling is not the only way to shrink a map. A convolution with stride 2, from the last section,
halves it too, and learns how while doing it; many recent architectures use that instead, and lesson
12's ResNet uses both.
