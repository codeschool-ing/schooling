---
title: What re-renders, and why all of it
version: 1
---

**When a component's state changes, React renders that component and every component below it.**
Not the ones whose props changed: all of them. The way to see it is to make each component say when
it is called. This file is temporary, for this lesson only; save it as `src/rendered.ts`:

```typescript
// For lesson 3 only: each component calls this while it renders, and the
// console says who rendered, in order.
export function rendered(name: string) {
  console.log(`render ${name}`)
}
```

Then a call to it at the top of each of the six components. Two `sed` commands do it in one go, the
first importing the function and the second adding a line after each `function` line:

```
ana@dev:~/planner$ sed -i '1i import { rendered } from "./rendered"' src/App.tsx src/WeekNav.tsx src/WeekSummary.tsx src/CourseList.tsx src/CourseCard.tsx src/Card.tsx
ana@dev:~/planner$ sed -i 's/^\(export \)\?function \([A-Za-z]*\)(\(.*\)) {$/&\n  rendered('"'"'\2'"'"')/' src/App.tsx src/WeekNav.tsx src/WeekSummary.tsx src/CourseList.tsx src/CourseCard.tsx src/Card.tsx
ana@dev:~/planner$ grep -n "rendered(" src/*.tsx
src/App.tsx:10:  rendered('App')
src/Card.tsx:10:  rendered('Card')
src/CourseCard.tsx:12:  rendered('CourseCard')
src/CourseList.tsx:11:  rendered('CourseList')
src/WeekNav.tsx:10:  rendered('WeekNav')
src/WeekSummary.tsx:11:  rendered('WeekSummary')
```

## The first render

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet
render App
render App
render WeekNav
render WeekNav
render WeekSummary
render WeekSummary
render CourseList
render CourseList
render CourseCard
render CourseCard
render Card
render Card
render CourseCard
render CourseCard
render Card
render Card
render CourseCard
render CourseCard
render Card
render Card
```

Read it as the order in which React called your functions: `App` first, then its children from top
to bottom, then theirs. `CourseList` renders before any `CourseCard`, and each `CourseCard` before its
`Card`. **Every line appears twice**, and that is `<StrictMode>` in `main.tsx`; the next section takes
it out to show the difference, and explains why it is there.

## After a click

With `StrictMode` gone, so that each call is printed once, this is the whole page loading and then
"Next week" being pressed:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week'
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
-- click button Next week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
```

The click changed one value, `monday`, in `App`. **React called every component again.** `WeekNav`
received the same function and a new Monday; `WeekSummary` and `CourseList` received a new array of
sessions; every `CourseCard` received a new filtered array; every `Card` received the same title and
a new paragraph. Not one of them was skipped, and none could have been: React does not compare props
before rendering a child unless you ask it to, which is `memo`, and lesson 21's subject.

```schooling-figure
{"svg": "<svg data-fig=\"cascade\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The planner's tree with App's state changed. Every component under App is drawn highlighted, because every one of them rendered again: WeekNav, WeekSummary, CourseList, the three CourseCards and the three Cards. A note says ten calls for one changed value.\"><rect x=\"290\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"23.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">App</text><text x=\"360.0\" y=\"36.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">monday ← changed</text><rect x=\"70\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">WeekNav</text><line x1=\"360\" y1=\"46\" x2=\"145\" y2=\"86\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"145.0,86.0 151.8,81.5 153.0,87.8\" fill=\"var(--amber)\"></polygon><rect x=\"250\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">WeekSummary</text><line x1=\"360\" y1=\"46\" x2=\"325\" y2=\"86\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"325.0,86.0 327.5,78.2 332.3,82.5\" fill=\"var(--amber)\"></polygon><rect x=\"470\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseList</text><line x1=\"360\" y1=\"46\" x2=\"545\" y2=\"86\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,86.0 537.0,87.5 538.3,81.3\" fill=\"var(--amber)\"></polygon><rect x=\"330\" y=\"150\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseCard</text><line x1=\"545\" y1=\"114\" x2=\"385\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"385.0,150.0 391.6,145.2 393.0,151.5\" fill=\"var(--amber)\"></polygon><rect x=\"350\" y=\"206\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Card</text><line x1=\"385\" y1=\"176\" x2=\"385\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"385.0,206.0 381.8,198.5 388.2,198.5\" fill=\"var(--amber)\"></polygon><rect x=\"460\" y=\"150\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseCard</text><line x1=\"545\" y1=\"114\" x2=\"515\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"515.0,150.0 517.3,142.2 522.3,146.3\" fill=\"var(--amber)\"></polygon><rect x=\"480\" y=\"206\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Card</text><line x1=\"515\" y1=\"176\" x2=\"515\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"515.0,206.0 511.8,198.5 518.2,198.5\" fill=\"var(--amber)\"></polygon><rect x=\"590\" y=\"150\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseCard</text><line x1=\"545\" y1=\"114\" x2=\"645\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"645.0,150.0 636.9,150.5 639.0,144.4\" fill=\"var(--amber)\"></polygon><rect x=\"610\" y=\"206\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Card</text><line x1=\"645\" y1=\"176\" x2=\"645\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"645.0,206.0 641.8,198.5 648.2,198.5\" fill=\"var(--amber)\"></polygon><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 value changed,</text><text x=\"30\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">10 components called</text></svg>", "caption": "A state change in App renders App and everything below it."}
```

The rule has a useful edge. **A component above the one whose state changed is not rendered.** If
`WeekNav` kept the week in its own state, a click would render `WeekNav` alone and the summary would
never hear about it. That is why the state lives in `App`: the components that read it are below it,
and lesson 4 makes this placement a rule with a name.
