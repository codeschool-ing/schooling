---
title: The normal flow, and leaving it a little
---

By default every element is `position: static`: it stays where the flow put it, and `top`/`left` do nothing.

`position: relative` keeps the element in the flow — **its space stays reserved** — and shifts only the drawing. That is why it is almost never used to move things: it is used to become the **anchor** of an `absolute` child, which is the next section's subject.
