---
title: box-sizing, and the first line of every stylesheet
---

By default, `width` measures only the content. So a box declared at 200px plus padding and border occupies **more** than 200px:

[object Object]

That turns any layout into mental arithmetic. The fix is one line, and it opens practically every modern stylesheet:

[object Object]

With `border-box`, `width: 200px` means 200px on screen, with the padding and border **inside**. It is the behaviour everybody expected from the start.
