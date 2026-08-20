---
title: Where the CSS and the JavaScript go
---

The stylesheet goes in the `<head>`, and the script goes at the end of the `<body>` or with `defer`:

```html
<head>
  <link rel="stylesheet" href="style.css" />
  <script src="app.js" defer></script>
</head>
```

Both places come from the same reasoning, with opposite results. **CSS blocks rendering on purpose** — showing the page unstyled and restyling it afterwards would flash the whole screen — so the sooner it starts downloading, the better.

**An ordinary script blocks the DOM being built**, because it may alter the tree under construction. That is why a `<script>` at the top of the `<head>` without `defer` is the classic recipe for a blank page. With `defer` it downloads in parallel and executes after the HTML is built, preserving the order between scripts.
