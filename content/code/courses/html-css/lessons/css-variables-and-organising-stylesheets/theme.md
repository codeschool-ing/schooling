---
title: Light and dark themes with one switch
---

Because variables inherit, swapping a whole theme is redeclaring them in a scope above:

```css
:root {
  --background: #0a0e14;
  --text: #e8e6df;
}

html[data-theme="light"] {
  --background: #f2f4f9;
  --text: #1a1f28;
}

body { background: var(--background); color: var(--text); }
```

The rest of the stylesheet never mentions a theme colour: it reads `var(--background)` and does not know two exist. Swapping the theme becomes adding an attribute on `<html>` — one line of JavaScript, without rewriting a single rule. It is exactly how the portal and the vitrine do it.
