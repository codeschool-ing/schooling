---
title: Configuration is where the design system lives
---

The classes come out of a configurable scale. Customising the scale is what stops Tailwind from being a pile of magic values:

```css
@theme {
  --color-brand: #5b8cff;
  --spacing-section: 4.5rem;
}
/* bg-brand, text-brand, p-section… now exist */
```

Once that is done, `bg-brand` is the brand colour everywhere, and changing it means editing one line. It is the same role the CSS variables of lesson 09 play — the difference is that here the scale also generates the classes.
