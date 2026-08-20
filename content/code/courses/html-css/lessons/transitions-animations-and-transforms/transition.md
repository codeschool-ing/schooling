---
title: Transition: smoothing a change
---

`transition` interpolates between two values when the property changes:

```css
.button {
  background: var(--blue);
  transition: background .2s ease, transform .2s ease;
}
.button:hover {
  transform: translateY(-2px);
}
```

The transition is declared on the **normal** state, not on the `:hover` — that way it applies on the way in and on the way out. Declared only on the `:hover`, the effect eases in and snaps out.

Avoid `transition: all`. It starts animating properties you did not know had changed, and it is a silent source of jank.
