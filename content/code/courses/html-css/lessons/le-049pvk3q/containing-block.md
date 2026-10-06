---
title: The containing block
version: 1
---

Lesson 6 said that a percentage width is a share of the **containing block**, and that for most elements that is the parent. The badge in the last section showed the exception that matters. Which box a box is measured from depends on its own `position`:

- **`static` and `relative`**: the content area of the nearest ancestor that is a block, which in practice is the parent.
- **`absolute`**: the **padding box of the nearest positioned ancestor**, meaning the nearest ancestor whose `position` is anything other than `static`. If there is none, the initial containing block, which is the size of the window at the top of the page.
- **`fixed`**: the window, the viewport, section 06.
- **`sticky`**: it is in the flow like a relative box, and sticks within its nearest scrolling ancestor, section 07.

"Positioned" means `relative`, `absolute`, `fixed` or `sticky`. That is why `position: relative` with no offsets is so common: it changes nothing about the box itself and makes it the reference for everything absolute inside it.

Two details follow from "padding box". An absolute child at `top: 0; left: 0` sits inside the parent's border, at the corner of its padding. And `width: 100%` on it is the parent's width including padding, not just the content area, which is different from what a child in the flow gets.

## Three other things make a containing block

A `transform` on an ancestor, lesson 12, a `filter` and a few rarer properties also make it the containing block for absolute and even for fixed descendants. That is a surprise worth knowing about once: a "fixed" header inside a transformed element scrolls with that element instead of staying on the screen. When a positioned box is measured from somewhere unexpected, look up the tree for a `position`, a `transform` or a `filter`, in that order. DevTools helps: in the Elements panel, an element's **containing block** is not shown directly, but hovering each ancestor in turn and comparing its box with where your element sits finds it within a minute.
