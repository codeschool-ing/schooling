---
title: Specificity: the sum that decides who wins
---

When two rules reach the same element and declare the same property, the more specific one wins. Specificity is a trio of numbers — **(ids, classes, elements)** — compared from left to right:

```css
p                 /* (0,0,1) */
.warning          /* (0,1,0)  beats p */
nav a.active      /* (0,1,2) */
#top              /* (1,0,0)  beats everything above */
```

The first number crushes the others: **one id beats any number of classes**. That is why styling by id ends up forcing the next person to use `!important` — and once `!important` gets into a file, it spreads.

A specificity tie is broken by order: the last rule written wins.
