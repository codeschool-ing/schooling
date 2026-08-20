---
title: CSSOM and style computation
---

The CSS goes through the same process and becomes the **CSSOM**. Then the browser combines the two trees to decide the final style of every node, resolving inheritance, specificity and order.

This is where a dispute like the one this portal ran into gets decided: a browser rule for `[hidden]` has zero specificity and loses to any class declaring `display`. None of that is visible in the CSS file — only in the computed style.

CSS **blocks rendering** on purpose: showing the page unstyled and restyling it afterwards would flash the whole screen. That is why a large stylesheet delays the first paint, and why the CSS `<link>` goes in the `<head>`.
