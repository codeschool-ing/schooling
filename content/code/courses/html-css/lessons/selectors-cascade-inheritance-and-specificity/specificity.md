---
title: Specificity: the sum that decides who wins
---

When two rules reach the same element and declare the same property, the more specific one wins. Specificity is a trio of numbers — **(ids, classes, elements)** — compared from left to right:

[object Object]

The first number crushes the others: **one id beats any number of classes**. That is why styling by id ends up forcing the next person to use `!important` — and once `!important` gets into a file, it spreads.

A specificity tie is broken by order: the last rule written wins.
