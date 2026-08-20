---
title: Animations, and what each property costs
---

For something that happens on its own, `@keyframes` describes the path:

```css
@keyframes appear {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: none; }
}

.panel { animation: appear .3s ease both; }
```

Note what is being animated, and it is the most profitable rule in this whole lesson: **animate `transform` and `opacity`.** They touch only composition, which the graphics card does on its own. Animating `width`, `top` or `margin` redoes the layout of everything around it on every frame, and that is what stutters on a phone.

And respect whoever asked for less motion:

```css
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; transition: none !important; }
}
```
