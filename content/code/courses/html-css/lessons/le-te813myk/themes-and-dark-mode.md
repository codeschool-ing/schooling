---
title: Themes, and the reader's dark mode
version: 1
---

Because a variable can be redefined, a whole colour scheme can be swapped by redefining a handful of them. That is how **dark mode** is built. The reader sets a preference in their operating system, and the media feature **`prefers-color-scheme`** lets a stylesheet answer it:

```css
:root {
  --color-page: #fbf8f2;
  --color-text: #1d1d1b;
  --color-accent: #2f6f4e;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-page: #161a17;
    --color-text: #e8e4dc;
    --color-accent: #8fd1ad;
  }
}

body {
  background: var(--color-page);
  color: var(--color-text);
}
a { color: var(--color-accent); }
```

Every rule in the page uses `--color-page`, `--color-text` and `--color-accent`, and none of them mentions a colour. One `@media` block redefines the three on `:root` when the reader prefers dark. `probe --dark` starts Chromium with its scheme set to dark, as the reader's system setting would:

```
ana@laptop:~/site$ probe theme.html style body background-color,color style a color axe
body  background-color: rgb(251, 248, 242)
body  color: rgb(29, 29, 27)
a  color: rgb(47, 111, 78)
axe: no violations
ana@laptop:~/site$ probe --dark theme.html style body background-color,color style a color axe
body  background-color: rgb(22, 26, 23)
body  color: rgb(232, 228, 220)
a  color: rgb(143, 209, 173)
axe: no violations
```

In the light scheme the page is `rgb(251, 248, 242)` with near-black text and the green link. In the dark scheme it is `rgb(22, 26, 23)` with light text and a **lighter** green link, `rgb(143, 209, 173)`, and axe passed both. That last part is the work in a dark theme. The green that reads well on cream, `#2f6f4e`, is far too dark to read on near-black, so the dark theme is not the light one inverted: every colour is chosen again for its own background, and checked. This repository's own interface does exactly that with its palette in both themes, and runs axe on every screen in both.

## Two details that are easy to miss

**`<meta name="color-scheme" content="light dark">`** in the page's head tells the browser the page supports both, so that the browser's own parts, the scrollbars, the form controls and the default background before the stylesheet arrives, follow the reader's scheme too. Without it a dark page can flash white while it loads.

**Name variables by role, not by colour.** `--color-text` can be dark in one theme and light in the other; `--black` cannot, and a stylesheet that says `--black: #e8e4dc` in its dark theme is one that the next person misreads. Section 08 is about naming tokens like that.

Lesson 11 is about the other preferences a reader can state, such as reduced motion, and lesson 12 uses that one.
