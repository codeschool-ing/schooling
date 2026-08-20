---
title: Media queries beyond width
---

Width is the most used, and far from the only one:

```css
@media (max-height: 560px)          { }  /* on-screen keyboard open */
@media (prefers-color-scheme: dark) { }  /* system theme */
@media (prefers-reduced-motion: reduce) { }  /* reduced motion */
@media (hover: none)                { }  /* touch, no cursor */
```

The `prefers-reduced-motion` one is the most forgotten and the one that matters most to whoever needs it: there are people for whom a sliding animation causes real nausea. Respecting it means switching transitions off inside that query.

`hover: none` solves the menu that "does not open on the phone": effects hung off `:hover` do not exist on touch.
