---
title: Aligning and distributing
---

Centring in both directions, once a puzzle, is three lines today. Rather than showing the three on their own, it is worth reading a whole navigation bar — which is where these properties really turn up — with the explanation of each piece beside it:

```schooling-example
{
  "language": "css",
  "file": "bar.css",
  "parts": [
    {
      "code": ".bar {\n  display: flex;",
      "note": "From here on the direct children of `.bar` are flex items. Nothing happens to the grandchildren — flex applies one level only."
    },
    {
      "code": "  align-items: center;",
      "note": "Aligns on the **cross** axis. With `flex-direction: row` (the default), the cross axis is the vertical one: this is what puts the logo and the links at the same height even though they are different sizes."
    },
    {
      "code": "  gap: 24px;",
      "note": "The space between the items. `gap` leaves nothing over at the ends, does not collapse, and does away with the `:last-child { margin: 0 }` every old stylesheet carries."
    },
    {
      "code": "  padding: 0 32px;\n}",
      "note": "The bar's inner space. Note that it is NOT `gap`: one is the frame, the other is the distance between the items."
    },
    {
      "code": ".bar .menu {\n  margin-left: auto;\n}",
      "note": "The most useful trick in flexbox. `margin: auto` eats all the free space on that side, so this item — and everything after it — is pushed to the right. It does what `justify-content: space-between` would do, but for ONE item, and without touching the rest."
    },
    {
      "code": ".bar .title {\n  min-width: 0;\n}",
      "note": "The most mysterious and most useful line. A flex item does not shrink below its own content by default, and a long title bursts the bar instead of getting an ellipsis. `min-width: 0` gives the permission to shrink back."
    }
  ],
  "output": "┌──────────────────────────────────────────────┐\n│ ◐ codeschool.ing   Tracks           Sign in  │\n└──────────────────────────────────────────────┘\n  └ logo and title             └ pushed by margin-left:auto"
}
```

On the main axis, the values you use are `flex-start`, `center`, `flex-end`, `space-between` (the ends flush against the edges, equal space between the items) and `space-evenly` (equal space everywhere, edges included).
