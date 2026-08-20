---
title: absolute and the positioning context
---

`position: absolute` takes the element out of the flow: its space stops existing and the neighbours close up as if it were not there. It positions itself relative to the **nearest positioned ancestor** — any one that is not `static`.

```css
.card       { position: relative; }
.card .badge {
  position: absolute;
  top: 8px;
  right: 8px;
}
```

It is the most used pattern in all of CSS: the parent becomes `relative` purely to serve as a reference, and the child hangs off its corner. **Forgetting the `relative` on the parent** is the classic defect — the badge climbs to the corner of the page, because with no positioned ancestor the reference becomes the window.
