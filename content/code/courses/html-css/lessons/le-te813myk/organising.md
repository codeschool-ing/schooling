---
title: Organising without turning it into archaeology
---

A stylesheet that grows without order becomes a file nobody dares delete anything from. Three habits hold that back:

- **A predictable order in the file**: reset, variables, base, components, utilities, media queries. A new rule has an obvious place to go.
- **Low, flat specificity**: a simple class, with almost no nesting. A four-level selector forces the next one to have five.
- **Name it for what the thing is, not for what it looks like**: `.warning` survives the decision to make the warning blue; `.red-text` does not.

If an `!important` has shown up, the cause was almost always an over-specific selector further back. The fix is to lower that one's specificity, not to raise this one's.
