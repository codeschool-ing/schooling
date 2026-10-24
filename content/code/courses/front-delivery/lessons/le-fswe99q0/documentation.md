---
title: Documentation that cannot fall behind
version: 1
---

**The most useful documentation of a component is generated from the component and its stories,
because that is the only kind that changes when they do.** A wiki page describing the session row is
correct on the day it is written and wrong the first time somebody adds an argument and forgets the wiki.

`tags: ["autodocs"]` in `preview.ts` gives every component a **Docs** page, built from three things that
already exist:

- **the stories**, each drawn live on the page, one under the other, so the page shows every state the
  stories cover;
- **the arguments**, as a table with their types and defaults, and the same controls as the canvas;
- **the comments**: the JSDoc comment above `sessionRow` in `components.ts` becomes the component's
  description, and a JSDoc comment above a story's export becomes that story's.

None of it is written twice. A new argument appears in the table the next time Storybook reads the file; a
new story appears on the page.

## Prose that is not generated

Some documentation is not about one component: when to use a row and when a card, how the spacing scale is
meant to be used, what the tokens are called. Storybook takes those as **MDX** files, Markdown that can
embed stories and blocks of Storybook's own, and lists them in the sidebar beside the components. A
design system's front page, its token reference and its contribution guide are usually MDX pages.

The rule from the last lesson applies here too: **prose that restates a value goes stale.** An MDX page
that says "the accent is green" is wrong the day the brand changes; one that embeds the colour from the
tokens is not. Write the reasons in prose and let the values come from the code.

## Who reads it

The audience is wider than developers. A designer checks that the component matches the design in every
state; a product manager sees what exists before asking for something new; a tester finds the states to
try. That is why the next section publishes it: **a workshop only on your computer is a workshop for one
person**.
