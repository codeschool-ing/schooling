---
title: Images that do not waste bandwidth
---

Serving the same 2000px image to a phone throws away the bandwidth and the battery of whoever has least of both. `srcset` lets the browser choose:

[object Object]

`width` and `height` do not fix the size when there is CSS — they state the **aspect ratio**, and that is what stops the page from jumping when the image finishes loading. `loading="lazy"` defers whatever is off screen.

[object Object]

`alt` describes the image for whoever cannot see it. A purely decorative image takes `alt=""` — empty, not absent: that way the screen reader ignores it instead of announcing the file name.
