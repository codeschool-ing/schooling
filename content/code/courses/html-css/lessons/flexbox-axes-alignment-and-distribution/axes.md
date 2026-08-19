---
title: Everything depends on the main axis
---

Flexbox arranges the children along **one** axis. `flex-direction` picks which:

[object Object]

Understanding that settles the confusion that slows learners down most: `justify-content` acts on the **main axis** and `align-items` on the **cross** one. Since the default is `row`, `justify-content` looks "horizontal" and `align-items` looks "vertical" — until somebody writes `flex-direction: column`, and the two swap meaning.

The right question is never "how do I centre horizontally?", it is "what is my main axis?".

[object Object]
