---
title: Which unit for what
---

Each unit answers a different question, and choosing the wrong one is the source of half the accessibility problems in typography.

- **`px`** — absolute. Good for borders and shadows, where the value really is physical.
- **`rem`** — a multiple of the root font size. It is the default for typography and spacing, because it **respects whoever enlarged the font in the browser**. Text sized in `px` ignores that preference.
- **`em`** — a multiple of the element's own font size. Useful for spacing that should follow the text, but careful: it compounds in nested elements.
- **`%`** — relative to the container. Width.
- **`vw` / `vh`** — relative to the window. Good for full screens; on a phone, prefer `svh`/`dvh`, which cope with the browser bar appearing and disappearing.

The practical rule that settles almost everything: **`rem` for text and space, `%` or `fr` for width, `px` only for fine detail.**
