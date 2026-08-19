---
title: Mobile first is about what the default is
---

Mobile first is not "start by designing the phone": it is **writing the phone's CSS with no media query at all**, and using media queries only to add what larger screens allow.

[object Object]

The order matters more than it looks. Written the other way round — desktop first, with `max-width` — the phone has to **undo** rules, and undoing costs more lines and more specificity than adding. On top of that, the weakest device ends up downloading and applying the CSS it will not use.
