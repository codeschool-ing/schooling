---
title: Where the fallback goes
version: 1
---

**A `Suspense` boundary works like an error boundary, for waiting instead of failing.** When anything
inside it is not ready, React draws its `fallback` in place of all of its children, and when
everything is ready, the children replace the fallback. Where you put it decides how much of the
screen gives way to the fallback.

```schooling-figure
{"svg": "<svg data-fig=\"suspend\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of opening a course. The click sets openId; React renders the lazy CourseScreen, whose code is not there, so it suspends and the nearest Suspense draws its fallback, Loading the course. The file arrives; React renders again, and the course screen replaces the fallback.\"><rect x=\"10\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">click</text><text x=\"75.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">setOpenId</text><line x1=\"141\" y1=\"67\" x2=\"151\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"151.0,67.0 143.5,70.2 143.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"152\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"217.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lazy part</text><text x=\"217.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">not loaded</text><line x1=\"283\" y1=\"67\" x2=\"293\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"293.0,67.0 285.5,70.2 285.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"294\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fallback</text><text x=\"359.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Loading the course…</text><line x1=\"425\" y1=\"67\" x2=\"435\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"435.0,67.0 427.5,70.2 427.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"436\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"501.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET</text><text x=\"501.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseScreen-…js</text><line x1=\"567\" y1=\"67\" x2=\"577\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"577.0,67.0 569.5,70.2 569.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"578\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">render again</text><text x=\"643.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the course</text><line x1=\"152\" y1=\"120\" x2=\"566\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"359\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the student sees the fallback</text><text x=\"643\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the screen</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an error on the way goes past Suspense, to the nearest error boundary</text></svg>", "caption": "Not ready means the nearest Suspense draws its fallback until it is."}
```

Placing one is a question of what the student should see while they wait:

| where `Suspense` goes | what the student sees while the code loads |
|---|---|
| around the whole app, in `main.tsx` | the planner disappears, every time any lazy part loads |
| inside `<main>`, around the course screen | only the content changes; the planner's page stays |
| one around each of several lazy parts | each part appears as soon as its own code arrives |
| one around several lazy parts together | one fallback, until all of them have arrived |

The last two rows are a real choice. Several boundaries show content sooner, but the screen fills in
piece by piece and things move as each piece arrives. One boundary for several parts waits for the
slowest of them and then shows everything at once. Neither is wrong; it depends on whether the parts
make sense on their own.

Splitting has a cost of its own, and **a lazy part is a request, with a wait, that a bundled part does
not have**. The useful places to cut are the ones a lot of users never reach or reach later:

- **Screens**, especially in an app with routes, where most visits see two or three of them. Lesson 17
  splits by route.
- **Heavy things used in one place**: a form library, a chart, a rich text editor.
- **Not small components on the first screen**. They are needed at once, and loading them separately
  only adds a request before the page is complete.

**`Suspense` waits for more than code.** Anything that *suspends* triggers it, and in React 19 three
kinds of things do:

| what suspends | where it comes from |
|---|---|
| a `lazy` component whose code has not arrived | React itself, this lesson |
| `use(promise)` on a promise that has not settled | React 19's `use`, the same function that reads a context |
| a data hook built for it, such as TanStack Query's `useSuspenseQuery` | the library |

A fetch in a `useEffect`, as in lesson 5, does not suspend: the component renders, shows its own
loading state, and renders again when the data arrives. That is why the planner still draws *Loading
the planner…* from `status` rather than from a `Suspense` fallback. Moving it would mean
`useSuspenseQuery`, and then the failed state would have to come from an error boundary too, with a
way to reset the query on a retry; lesson 15, where the data is loaded on the server, is where
`Suspense` and data meet properly.
