---
title: A spacing scale on a grid
version: 1
---

**Spacing tokens are multiples of one unit, so that every gap in the product is one of a few sizes.**
The planner's unit is a quarter of a rem, four pixels by default, and it has eight steps:

```
ana@dev:~/planner$ grep space src/tokens.css
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.25rem;
  --space-6: 1.5rem;
  --space-7: 1.75rem;
  --space-8: 2rem;
```

Four pixels is the grid most design systems use, because it divides the common screen sizes evenly and
is small enough to fine-tune a dense control without inventing a value. Some systems use eight and halve
it where needed; the choice matters less than having one.

## What the tokens replace

The planner's stylesheet from lesson 1 had `margin: 2rem auto`, `padding: 0 1rem`, `gap: 1rem` and
`margin: 0.25rem 0`. Each of those was somebody's eye on the day. As tokens they become `--space-8`,
`--space-4`, `--space-4` and `--space-1`, and three things follow:

- **a reviewer can see a wrong value.** `padding: 13px` in a pull request stands out among `var(--space-…)`;
  `13px` among other pixel values does not.
- **the steps relate.** A card's inner padding at `--space-4` and the gap between cards at `--space-6`
  read as a rhythm, because they share a unit.
- **density can change in one place.** A compact mode for a dense table is a different unit for that
  part of the page, and every gap inside it follows.

## Where the scale stops

Not every length is spacing. A component's own dimensions, a column's maximum width (`40rem` in the
planner), a border's thickness: those are separate tokens or plain values, and forcing them onto the
spacing scale produces a `--space-160` that nobody can explain. Spacing tokens are for the space
**between** and **inside** things, which is most of the lengths in a stylesheet and not all of them.
