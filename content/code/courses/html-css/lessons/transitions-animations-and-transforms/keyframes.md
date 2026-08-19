---
title: Animations, and what each property costs
---

For something that happens on its own, `@keyframes` describes the path:

[object Object]

Note what is being animated, and it is the most profitable rule in this whole lesson: **animate `transform` and `opacity`.** They touch only composition, which the graphics card does on its own. Animating `width`, `top` or `margin` redoes the layout of everything around it on every frame, and that is what stutters on a phone.

And respect whoever asked for less motion:

[object Object]
