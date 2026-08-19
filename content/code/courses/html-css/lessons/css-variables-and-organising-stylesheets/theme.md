---
title: Light and dark themes with one switch
---

Because variables inherit, swapping a whole theme is redeclaring them in a scope above:

[object Object]

The rest of the stylesheet never mentions a theme colour: it reads `var(--background)` and does not know two exist. Swapping the theme becomes adding an attribute on `<html>` — one line of JavaScript, without rewriting a single rule. It is exactly how the portal and the vitrine do it.
