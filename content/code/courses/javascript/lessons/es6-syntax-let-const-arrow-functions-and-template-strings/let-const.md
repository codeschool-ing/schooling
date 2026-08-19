---
title: let and const: the end of var
---

`var` has two properties nobody asked for: it leaks out of the block it was declared in, and it can be redeclared without complaint. `let` and `const` do neither, and that is why `var` no longer shows up in new code.

[object Object]

The practical rule: **`const` by default, `let` when the value really is going to change, `var` never.** Starting from `const` makes the compiler warn you when you reassign by accident — and most of the reassignments we write without thinking are accidents.
