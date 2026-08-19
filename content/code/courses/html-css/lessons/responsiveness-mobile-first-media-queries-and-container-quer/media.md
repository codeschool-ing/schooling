---
title: Media queries beyond width
---

Width is the most used, and far from the only one:

[object Object]

The `prefers-reduced-motion` one is the most forgotten and the one that matters most to whoever needs it: there are people for whom a sliding animation causes real nausea. Respecting it means switching transitions off inside that query.

`hover: none` solves the menu that "does not open on the phone": effects hung off `:hover` do not exist on touch.
