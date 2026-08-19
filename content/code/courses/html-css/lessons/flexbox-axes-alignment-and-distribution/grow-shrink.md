---
title: Growing, shrinking and the basis
---

The `flex` property is a shorthand for three things: how much the item may grow, how much it may shrink, and what size it starts from.

[object Object]

The difference between `flex: 1` and `flex: 1 1 auto` trips a lot of people up: with a basis of `0`, the items all end up the same size; with a basis of `auto`, each one's content matters, and an item with a long text ends up larger than the others.

And a flex item **does not shrink below its content** by default, which makes a long text burst the container. The cure is `min-width: 0` on the item — the most mysterious and most useful line in flexbox.
