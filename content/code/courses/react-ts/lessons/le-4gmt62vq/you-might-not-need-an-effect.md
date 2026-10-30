---
title: You might not need an effect
version: 1
---

**Most effects in code that has problems should not be effects.** React's own documentation has a page
with this title, and its argument is the one lessons 4 and 5 have been building: an effect is for
keeping something outside React in step, and most of what people write effects for is inside React
already.

Each row below is a pattern that works, in the sense that the screen ends up right, and costs an
extra render, a flash of the wrong value, or a bug that waits for the day two updates arrive
together:

| what you want | written as an effect | what to write instead |
|---|---|---|
| a value computed from props or state | an effect that sets a second piece of state | compute it while rendering, as `WeekSummary` does |
| something to happen when a button is pressed | state set by the button, and an effect that watches it | do it in the click handler |
| a form reset when the user picks another record | an effect that clears the fields when the id changes | `key={id}` on the form, from lesson 3 |
| data from the server | an effect with `fetch`, `ignore` and three states | an effect is right, and a library is better: lesson 11 |
| a list sorted or filtered | an effect that writes the sorted list into state | sort while rendering; lesson 7 caches it if it is slow |

The first row is the commonest, so here is its shape, as it is usually written:

```tsx
const [thisWeek, setThisWeek] = useState<Session[]>([])
useEffect(() => {
  setThisWeek(sessions.filter((s) => inWeek(s.date, monday)))
}, [sessions, monday])
```

It renders the component with an empty `thisWeek`, commits that to the page, runs the effect, sets
state, and renders again with the right list. Two renders where one would do, and the first one shows
nothing. The line `App` already has, `const thisWeek = sessions.filter(…)`, does it in one render and
cannot go stale.

**The planner's three effects pass the test**: the server, the tab's title and the window's keyboard
are all outside React. Everything else in it is computed while rendering, and that is not an accident
of a small app. It is the shape a React component should have whatever its size.
