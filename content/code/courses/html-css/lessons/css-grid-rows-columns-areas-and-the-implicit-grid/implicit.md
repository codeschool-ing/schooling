---
title: The implicit grid and grids that adjust themselves
---

If you declare two columns and six items arrive, the grid creates new rows on its own: that is the **implicit grid**, controlled by `grid-auto-rows`.

The most profitable combination in modern CSS makes a responsive grid **with no media query at all**:

```css
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 12px;
}
```

It reads: as many columns as fit, each at least 220px and sharing the rest equally. The grid rearranges itself at any width.

`auto-fill` keeps the empty columns reserved; `auto-fit` collapses them, making the existing items stretch to fill. With few items on a wide screen, the choice between the two is very visible.
