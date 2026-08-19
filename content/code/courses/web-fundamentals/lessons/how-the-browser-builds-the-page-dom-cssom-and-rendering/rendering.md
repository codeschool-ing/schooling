---
title: Layout, paint and composition
---

With the style resolved, three steps remain: **layout** computes the position and size of every box, **paint** draws the pixels, and **composition** puts the layers together on screen.

The cost of each is very different, and that is what separates a smooth animation from a stuttering one. Changing `width` or `top` redoes the layout of everything around it. Changing `background-color` only repaints. Changing `transform` or `opacity` touches only composition, which the graphics card does on its own.

Hence the most profitable practical rule in front-end work: **animate `transform` and `opacity`**, not `left`, `top` or `width`.
