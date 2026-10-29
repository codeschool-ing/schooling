---
title: Two rules, and nothing else
version: 1
---

**Hooks are the functions whose names start with `use`**: `useState`, `useEffect`, and the ones
lesson 7 adds and teaches you to write. They come with two rules, and React's documentation states
them in a sentence each:

1. **Call hooks at the top level of a component**, never inside a condition, a loop, a nested
   function, or after an early `return`.
2. **Call hooks only from React components or from other hooks**, never from an ordinary function, a
   class, or an event handler.

That is all of it. Everything else people call a rule of hooks is one of these two, or a consequence
of the dependency array from lesson 5.

The rules look arbitrary until you know what React does with a hook call, and then they look
inevitable. The next section shows the mechanism. The three after it break the first rule in the
planner, in the two ways it is usually broken, and see what each costs: one crashes the app on its
first load, and one does nothing visible at all and quietly throws away what the user chose. The
second is the worse of the two. The last section is about a mistake that breaks neither rule and is the
commonest hook bug there is.

The second rule is shorter to explain. A hook works by attaching state to the component React is
rendering at that moment. Outside a render, there is no such component, so a hook called from a click
handler or a utility function has nothing to attach to; React throws an error that says so the first
time it happens. A custom hook, a function named `useSomething` that calls hooks, is allowed because
it is only ever called during a component's render, and its name is how both React's tools and the
next person know that.
