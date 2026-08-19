---
title: Transforms
---

`transform` moves, rotates, scales and skews without taking the element out of the flow: **its space stays reserved** where it always was, and nothing around it moves.

[object Object]

The order of the functions matters: rotating and then translating is not the same as translating and then rotating, because each one operates in the coordinate system the previous one left behind.
