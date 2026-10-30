---
title: React in five minutes, for this course
version: 1
---

**React Native is React, so its screens are React components.** If you already write React, this
section is a reminder. If the framework you know is Angular, Vue or Svelte, the ideas are ones you know
under other names, and this is enough of React's spelling to read and write the planner's screens. It is not a React course: the four ideas below are the ones lessons 7 to 9 use.

**A component is a function that returns what to draw.** The returned thing is JSX, which looks like
markup and is JavaScript: each tag is a call that creates an element.

```tsx
function Total({ done, planned }: { done: number; planned: number }) {
  return <Text>This week: {done} of {planned} minutes done</Text>;
}
```

**Props are a component's arguments.** `Total` above receives `done` and `planned`, and `<Total done={75}
planned={125} />` draws it. Curly braces put a JavaScript value inside JSX, in a prop or in the text.

**State is a value a component remembers between draws.** `useState` gives the current value and a
function to replace it; replacing it draws the component again with the new value:

```tsx
const [open, setOpen] = useState<string | null>(null);
// later, in a press handler:
setOpen("statistics");
```

**React draws from state, so you never change the screen directly.** Where lesson 1's `main.ts` called
`draw()` after every change, a React component sets its state, and React works out what to redraw. The
plan itself is never edited in place: `markDone` returns a new plan, as it always has in `planner.ts`,
and `setPlan(markDone(plan, id))` hands it to React. **That is why the planner's rules move across
unchanged**: they were already written the way React wants them, as functions that take a plan and
return a new one.

*These two snippets are illustrations, not a program to run; the next section's `App.tsx` is the whole
program, and it uses all four ideas.*
