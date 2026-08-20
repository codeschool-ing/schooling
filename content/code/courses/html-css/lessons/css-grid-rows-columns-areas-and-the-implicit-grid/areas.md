---
title: Named areas: the layout drawn out
---

The most readable form of grid is to name the regions and draw them:

```css
.app {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-areas:
    "bar    bar"
    "rail   content"
    "footer footer";
}
.bar     { grid-area: bar; }
.rail    { grid-area: rail; }
.content { grid-area: content; }
.footer  { grid-area: footer; }
```

The CSS starts to **look like** the layout, and rearranging everything for a phone means rewriting the three quoted lines inside a media query — without touching a single child.
