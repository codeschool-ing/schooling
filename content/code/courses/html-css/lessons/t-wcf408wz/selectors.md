---
title: The vocabulary of selectors
---

A selector is the question "which elements?". The forms that solve almost everything:

```css
.card            { }   /* class */
#top             { }   /* id */
nav a            { }   /* descendant: every `a` inside nav */
nav > a          { }   /* direct child */
li + li          { }   /* immediately following sibling */
a[href^="http"]  { }   /* attribute starting with */
li:nth-child(2n) { }   /* pseudo-class */
```

In practice, **a class solves 90% of cases**, and it is what you should prefer. An id is unique per page and, as the next section shows, carries a weight in specificity that gets in the way more than it helps.
