---
title: The slope says which way is down
version: 1
---

Standing at `w = 2` with a loss of 1.0562, there are two questions: which way to move, and how far.
**The slope of the loss at that point answers the first.** If the loss falls as `w` grows, the slope
is negative and moving right goes downhill. Its size says how steep the ground is there.

A slope can be measured without any calculus. Nudge `w` by a small amount `h` and see how far the
loss moves: that ratio is a **finite difference**. It can also be worked out. For one point the
loss is `(w*x - y)²`, which expands to `w²x² - 2wxy + y²`, and its derivative in `w` is `2wx² - 2xy`,
or `2x(w*x - y)`. The loss is the mean over the points, so its slope is the mean of theirs. Save as
`~/dl/slope.py`, which does both:

```schooling-example
{
  "language": "python",
  "file": "slope.py",
  "parts": [
    {
      "code": "# slope.py: the slope of the loss at w, measured two ways and worked out\nimport numpy as np\n\nfrom points import x, y"
    },
    {
      "code": "def loss(w):\n    return np.mean((w * x - y) ** 2)",
      "note": "The loss of `loss.py`, as a function of the weight: one number in, one number out."
    },
    {
      "code": "def slope(w):\n    return np.mean(2 * x * (w * x - y))",
      "note": "The derivative worked out above, 2x(wx - y) for each point, averaged over the ten points because the loss is their average."
    },
    {
      "code": "h = 0.001\nfor w in [0.0, 2.0, 3.0, 4.0]:\n    one_sided = (loss(w + h) - loss(w)) / h\n    centred = (loss(w + h) - loss(w - h)) / (2 * h)\n    print(f\"w {w}   one-sided {one_sided:+.6f}   centred {centred:+.6f}   formula {slope(w):+.6f}\")",
      "note": "Two measurements and the formula at four weights. The one-sided difference nudges `w` up only; the centred one nudges it both ways and divides by the distance between the two."
    }
  ]
}
```

```
ana@vm:~/dl$ python slope.py
w 0.0   one-sided -2.637415   centred -2.637800   formula -2.637800
w 2.0   one-sided -1.097415   centred -1.097800   formula -1.097800
w 3.0   one-sided -0.327415   centred -0.327800   formula -0.327800
w 4.0   one-sided +0.442585   centred +0.442200   formula +0.442200
```

**The centred measurement and the formula agree to every digit printed.** The one-sided one is off
by the same 0.000385 at every weight, because it measures the slope halfway between `w` and `w + h`
rather than at `w`. Lesson 3 uses the centred version to check the slopes of a whole network, which
is why the difference is worth seeing once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" aria-label=\"A curve of the loss against the weight from 0 to 5: a parabola falling from 4.79 at w = 0 to a bottom of 0.274 at w = 3.43 and rising to 1.23 at w = 5. Six dots mark the weights loss.py printed. A tangent at w = 0 slopes down steeply, a tangent at w = 4 slopes gently up, and at the bottom the curve is flat.\"><path d=\"M70 280 L600 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"176.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"282.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"388.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"494.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"600.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"56\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"56\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"56\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"56\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"56\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"56\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"335.0\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the weight w</text><text x=\"60\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the loss</text><path d=\"M70.0 40.4 L75.3 47.0 L80.6 53.4 L85.9 59.8 L91.2 66.0 L96.5 72.2 L101.8 78.2 L107.1 84.2 L112.4 90.1 L117.7 95.9 L123.0 101.5 L128.3 107.1 L133.6 112.6 L138.9 118.0 L144.2 123.3 L149.5 128.5 L154.8 133.6 L160.1 138.6 L165.4 143.5 L170.7 148.3 L176.0 153.0 L181.3 157.7 L186.6 162.2 L191.9 166.6 L197.2 171.0 L202.5 175.2 L207.8 179.3 L213.1 183.4 L218.4 187.3 L223.7 191.2 L229.0 194.9 L234.3 198.6 L239.6 202.2 L244.9 205.6 L250.2 209.0 L255.5 212.3 L260.8 215.4 L266.1 218.5 L271.4 221.5 L276.7 224.4 L282.0 227.2 L287.3 229.9 L292.6 232.5 L297.9 235.0 L303.2 237.4 L308.5 239.7 L313.8 241.9 L319.1 244.0 L324.4 246.1 L329.7 248.0 L335.0 249.8 L340.3 251.6 L345.6 253.2 L350.9 254.7 L356.2 256.2 L361.5 257.5 L366.8 258.8 L372.1 259.9 L377.4 261.0 L382.7 262.0 L388.0 262.8 L393.3 263.6 L398.6 264.3 L403.9 264.9 L409.2 265.3 L414.5 265.7 L419.8 266.0 L425.1 266.2 L430.4 266.3 L435.7 266.3 L441.0 266.2 L446.3 266.0 L451.6 265.7 L456.9 265.4 L462.2 264.9 L467.5 264.3 L472.8 263.6 L478.1 262.9 L483.4 262.0 L488.7 261.0 L494.0 260.0 L499.3 258.8 L504.6 257.6 L509.9 256.2 L515.2 254.8 L520.5 253.2 L525.8 251.6 L531.1 249.9 L536.4 248.0 L541.7 246.1 L547.0 244.1 L552.3 242.0 L557.6 239.8 L562.9 237.5 L568.2 235.1 L573.5 232.6 L578.8 230.0 L584.1 227.3 L589.4 224.5 L594.7 221.6 L600.0 218.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"40.41\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"176.0\" cy=\"153.05\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"282.0\" cy=\"227.19\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"388.0\" cy=\"262.83\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"494.0\" cy=\"259.97\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"600.0\" cy=\"218.61\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><path d=\"M70.0 40.409999999999854 L149.5 139.32749999999984\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M409.2 277.6579999999999 L578.8 242.28199999999987\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"88.0\" y=\"44.409999999999854\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">slope -2.64 at w = 0</text><text x=\"499.3\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">slope +0.44 at w = 4</text><path d=\"M504.6 193.0 L494.0 251.96999999999986\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"433.12420000000003\" cy=\"266.3187285674999\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"419.8\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">bottom: slope 0</text><path d=\"M409.2 193.0 L433.12420000000003 258.3187285674999\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"186.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the six weights of loss.py</text><path d=\"M184.0 114.0 L178.0 147.05\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "The loss of one weight is a parabola. The dashed lines are its slope at two weights; at the bottom the slope is zero."}
```

**Read the signs.** At 0, 2 and 3 the slope is negative, so the loss falls as `w` grows; at 4 it is
positive, so the bottom lies below 4. The size shrinks as the bottom nears, from -2.637800 at 0 to
-0.327800 at 3, and at the bottom it is zero. That is what a bottom is: the place where the ground
is flat.

**The formula is what training uses, and the measurement is how you check it.** A measurement costs
two forward passes for each weight, so a network with a million weights would need two million
passes for one set of slopes. A formula gives every slope from one pass forward and one pass back,
and lesson 3 shows how to get it for a network of any depth.
