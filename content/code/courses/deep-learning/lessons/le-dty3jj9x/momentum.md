---
title: Momentum, in a long narrow valley
version: 1
---

The loss of a network, drawn over its weights, is not a round bowl. Some directions are steep and
some are nearly flat, and they sit side by side. **That shape, more than the noise, is what slows
plain gradient descent down**, and the clearest place to see it is in two dimensions, where every
step can be printed. Save as `~/dl/bowl.py`:

```schooling-example
{
  "language": "python",
  "file": "bowl.py",
  "parts": [
    {
      "code": "\"\"\"bowl: plain gradient descent and momentum in a long, narrow valley.\"\"\"\nimport numpy as np\n\nCURVE = np.array([1.0, 100.0])     # gentle along x, a hundred times steeper along y",
      "note": "A valley with two directions: along `x` the floor slopes gently, across it along `y` the walls are a hundred times steeper. Networks have thousands of directions, and the steep and the gentle ones are mixed in the same way."
    },
    {
      "code": "def gradient(p):\n    \"\"\"The slope of 0.5 * (x**2 + 100 * y**2), whose lowest point is (0, 0).\"\"\"\n    return CURVE * p",
      "note": "The slope of that valley, worked out by hand: the derivative of `0.5 * x**2` is `x`, and of `0.5 * 100 * y**2` it is `100 * y`."
    },
    {
      "code": "def descend(lr, beta, steps=40):\n    p, v = np.array([-10.0, 1.0]), np.zeros(2)\n    path = [p.copy()]\n    for _ in range(steps):\n        v = beta * v + gradient(p)\n        p = p - lr * v\n        path.append(p.copy())\n    return path",
      "note": "One function for both methods. `v` is the velocity: each step it keeps `beta` of its old value and adds the new gradient, and the point moves along `v`. With `beta=0.0` the old value is thrown away and this is plain gradient descent."
    },
    {
      "code": "plain = descend(lr=0.019, beta=0.0)\nheavy = descend(lr=0.019, beta=0.9)\nprint(\"step   plain x  plain y   momentum x  momentum y\")\nfor t, (a, b) in enumerate(zip(plain, heavy)):\n    print(f\"{t:4d}  {a[0]:8.3f} {a[1]:8.3f}   {b[0]:10.3f} {b[1]:11.3f}\")\nprint(f\"distance from (0, 0) after 40 steps: plain {np.linalg.norm(plain[-1]):.3f}, \"\n      f\"momentum {np.linalg.norm(heavy[-1]):.3f}\")",
      "note": "The same start, the same rate and the same 40 steps for both. Only `beta` differs."
    }
  ]
}
```

```
PENDING bowl
```

Read the plain columns first. **Across the valley, `y` flips sign at every step**: 1, -0.9, 0.81,
-0.729. Each step multiplies it by 1 − 100 × 0.019, which is −0.9. **Along the valley, `x` crawls**:
each step multiplies it by 1 − 0.019, and after 40 steps it is still at -4.643.

The obvious cure, a larger rate, is not available. At 0.021 the factor across the valley would be
1 − 2.1 = −1.1, and every bounce would be bigger than the one before. **The steepest direction sets
the highest rate the whole descent can use**, and the gentle direction has to live with it.

Momentum keeps a velocity. Along `x` the gradient points the same way at every step, so the velocity
builds up: by step 14 momentum is at -0.229, where plain descent is at -7.645.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"The long narrow valley seen from above, with x from -10 to 3 across and y from -1 to 1 up the page, stretched so the zigzag shows. Plain gradient descent starts at (-10, 1), bounces from one wall to the other with shrinking jumps and after 40 steps has only reached x = -4.6. Momentum starts at the same point, rushes along the valley, overshoots the lowest point to x = 2.8, swings back and ends near it, still rocking across the valley.\"><rect x=\"40\" y=\"30\" width=\"620\" height=\"200\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M40 105.5 L660 105.5\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 154.5 L660 154.5\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 80.9 L660 80.9\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 179.1 L660 179.1\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 48.2 L660 48.2\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 211.8 L660 211.8\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"62.14285714285714\" cy=\"48.18181818181819\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"72.14285714285714\" y=\"46.18181818181819\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">start</text><circle cx=\"505.0\" cy=\"130.0\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"505.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">lowest point</text><path d=\"M505.0 136.0 L505.0 232\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M60 272 L90 272\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"98\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">plain gradient descent, rate 0.019</text><path d=\"M390 272 L420 272\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"428\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">momentum 0.9, same rate</text></svg>", "caption": "Forty steps at the same rate. Plain descent spends them bouncing between the walls; momentum spends them travelling along the floor, and pays with an overshoot."}
```

**It is not free, and the table says what it costs.** A ball rolling down this valley does not stop
at the bottom: momentum overshoots to 2.842 at step 23 and has to roll back. Nor did it calm the
zigzag. Across the valley it swings at half the frequency and dies away more slowly, 0.122 at step 40
against plain descent's 0.015. All of its gain is along the floor, and along the floor it is large:
0.316 from the lowest point after 40 steps, against 4.643.

`beta` is how much of the velocity survives each step. At 0 nothing survives and the method is plain
descent; close to 1 the ball hardly brakes. 0.9 is the value almost everybody uses. In a network the
same thing happens in thousands of directions at once, and the velocity has one more use there: it
is an average over recent batches, so it smooths the batch noise of the last section too.

This form, `v = beta * v + g` and a step of `lr * v`, is the one PyTorch's own SGD uses when it is
given a `momentum`. Nesterov's variant, which takes the gradient at the point the velocity is about
to carry the weights to, is one more argument there, `nesterov=True`.
