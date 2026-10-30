---
title: What context costs
version: 1
---

**When a provider's value changes, every component that reads that context renders again**, whatever
part of the value it uses. Context has no way to say "this component only needs `status`". The
planner's value is the object `usePlanner` returns: when a session is ticked, `sessions` changes, a
new object is made, and both `App` and `CourseScreen` render again. That is correct here, because both
use the sessions. It stops being free when one context carries many unrelated values and many
components read it.

```schooling-figure
{"svg": "<svg data-fig=\"context-cost\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"PlannerProvider holds one value with status, courses, sessions and toggleDone. App reads status, courses and sessions; CourseScreen reads sessions and toggleDone. When sessions change, a new value is made and both readers render again. A store with selectors lets each reader subscribe to its own slice.\"><rect x=\"200\" y=\"14\" width=\"320\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">PlannerProvider</text><text x=\"360.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">{ status, courses, sessions, toggleDone }</text><rect x=\"60\" y=\"140\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">App</text><text x=\"170.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">status · courses · sessions</text><rect x=\"440\" y=\"140\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">CourseScreen</text><text x=\"550.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sessions · toggleDone</text><line x1=\"300\" y1=\"70\" x2=\"170\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"170.0,140.0 175.1,133.6 178.1,139.3\" fill=\"var(--amber)\"></polygon><line x1=\"420\" y1=\"70\" x2=\"550\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"550.0,140.0 541.9,139.3 544.9,133.6\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sessions changed: both render</text><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">with a store, each reader subscribes to its own slice</text></svg>", "caption": "Context has one value; every reader renders when it changes."}
```

Three habits keep context cheap:

- **One context per concern.** The signed-in user, the theme and the planner's data change at
  different rates and are read by different components. Three small contexts beat one large one,
  because a change to the theme does not render everything that reads the user.
- **A stable value.** A provider that builds its value as a new object on every one of its own renders
  makes every reader render with it. `PlannerProvider` renders only when the planner's state changes,
  so its object is new only when something in it is; a provider that also re-rendered for other
  reasons would wrap the value in `useMemo`.
- **Context for values that change rarely.** A context that changes on every keystroke renders all its
  readers on every keystroke. That is where the libraries in the next three sections earn their place:
  each lets a component subscribe to one slice of a shared value and render only when that slice
  changes.

Context is also not a state manager. It moves a value; the state itself is still a `useState` in
`usePlanner`. Every library below is, at heart, a store that lives outside React with a hook that
subscribes to it, which is how they manage to re-render only the components whose slice changed.
