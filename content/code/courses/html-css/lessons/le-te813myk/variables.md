---
title: Custom properties
---

CSS variables are declared with two hyphens and read with `var()`:

```css
:root {
  --blue: #5b8cff;
  --space: 16px;
}

.button {
  background: var(--blue);
  padding: var(--space);
}
```

The difference from a preprocessor's variables is decisive: these **exist in the browser**. They inherit, they can be swapped inside a selector, they respond to a media query and they are readable and writable from JavaScript at run time. A Sass variable disappears at compile time; this one is still there.
