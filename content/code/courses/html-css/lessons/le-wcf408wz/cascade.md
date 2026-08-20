---
title: Cascade and inheritance are different things
---

**Cascade** is how the browser chooses between rules competing for the same element: origin, `!important`, specificity and, finally, order.

**Inheritance** is something else: some properties pass from parent to child without anyone asking. `color`, `font-family` and `line-height` inherit; `border`, `padding` and `background` do not.

The distinction matters because it explains a common mistake: setting `font-family` on the `body` works for the whole page (inheritance), but setting `border` on the `body` draws no border on any child. And there is the hybrid case of `<button>`, which does **not** inherit the font by default — hence the `font: inherit` line that shows up in almost every serious stylesheet.
