---
title: What it changes about how you think
version: 1
---

**Without a virtual DOM, a component is set up once and then left alone, and the code you write is
the code that runs.** Most of what feels different about Svelte, coming from React or from tutorials
written for it, follows from that one fact. This section gathers the consequences in one place, so
that each later lesson can point back to it.

## What you stop doing

| in React you would… | in Svelte… | because |
|---|---|---|
| wrap a function in `useCallback` so a child does not re-render | write the function | the script runs once, so the function is the same object for the component's life |
| wrap a calculation in `useMemo` | write `$derived(…)`, lesson 3 | a derived value recalculates when something it read changes, and not otherwise |
| keep hooks at the top, never inside an `if` | use runes where they make sense | a rune is a compiler instruction, not a call React counts in order |
| copy an array to change it: `[...list, item]` | `list.push(item)` | `$state` arrays and objects are deep, lesson 3; changing them in place is tracked |
| reach for a state library for anything shared | a `.svelte.js` module or context, lessons 10 and 11 | signals work outside components too |

None of the left-hand column is wrong in React. Each is the price of the component function running
on every change, and Svelte does not charge it.

## What you still have to do

**Keys in lists still matter.** When a list is reordered, Svelte has to decide which existing element
becomes which, and without a key it matches them by position. Lesson 8 shows the wrong row keeping a
half-typed input because of it.

**Effects still need care.** An effect that sets a value it also reads can run itself in a loop, and
Svelte stops it with an error rather than letting it spin. Lesson 3's rule for effects is the
practical one: most things that feel like an effect are a derived value or an event handler instead.

**Reactivity lives in the variable, so moving the value out breaks it.** `let { minutes } = counter`
copies the number once, exactly like the `hours` that stayed at zero in "The script runs once".
Lesson 3 shows the forms that keep the connection: reading `counter.minutes` where it is needed, or
`$derived`.

## What you gain, and what you give up

You gain small components and a small runtime, because the compiler worked out ahead of time what
each change affects. You gain code that looks like plain JavaScript, `minutes += 30`, even though the
compiler rewrote it.

You give up the ability to read a component as ordinary JavaScript. A `.svelte` file only means what
it means after the compiler has read it, so an editor, a linter or a test runner has to know Svelte to
help you, and every one this course uses does. And you give up the largest ecosystem: React has more
components, more examples and more job listings, which lesson 20 weighs honestly against everything
above.
