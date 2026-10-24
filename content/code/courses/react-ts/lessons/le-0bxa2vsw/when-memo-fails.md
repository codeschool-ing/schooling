---
title: When memo does nothing
version: 1
---

**`memo` is only as good as the props it is handed.** One prop that is new on every render, and the
comparison fails every time: React does the comparison, then the render anyway, and the memo has cost
something and saved nothing. The easiest way to get there is an arrow function written inline:

```
ana@dev:~/planner$ sed -i 's|onToggle={toggleDone} />}|onToggle={(id) => toggleDone(id)} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={(id) => toggleDone(id)} />}
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
drawn: row s1 (update)
drawn: row s2 (update)
ana@dev:~/planner$ sed -i 's|onToggle={(id) => toggleDone(id)} />}|onToggle={toggleDone} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
```

`(id) => toggleDone(id)` does the same thing as `toggleDone`, and it is a **new function on every
render**, so `onToggle` changed every time and both rows were drawn after the click, as if `memo` were
not there. The last `sed` put the stable function back.

Which values keep their identity from one render to the next decides whether `memo` can work:

| a prop that is | the same on the next render? | to make it the same |
|---|---|---|
| a string, a number, a boolean | yes, if the value is | nothing to do |
| an object from React Query's cache | yes, where its data did not change | nothing to do |
| a setter from `useState`, or `mutate` | yes, always | nothing to do |
| an object or array built while rendering | no | `useMemo`, lesson 7 |
| a function written while rendering | no | `useCallback`, lesson 7 |
| JSX passed as `children` | no | rarely worth it |

This is why lesson 7 said `useMemo` and `useCallback` matter where identity matters: **their real job
is to feed `memo`**, or a dependency array. A `useCallback` on a function passed to a component that is
not memoised buys nothing at all.

And it is why adding `memo` by reflex is a mistake. Every memoised component is a comparison on every
render and a set of props that must stay stable for as long as the code lives, which the next person to
add an inline arrow will not know. The next section is the alternative.
