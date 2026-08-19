---
title: Template strings
---

Backticks instead of quotes, `${}` to interpolate, and a line break counts literally. Concatenation with `+` disappears, which is where the missing spaces are born.

[object Object]

Interpolation accepts **any expression**, not just a variable — a function call, a ternary, an operation. What it must not receive is user text destined to become HTML: that is where interpolation turns into the hole, and it is why this portal has an `esc()` in `app/text.js`.
