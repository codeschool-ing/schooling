---
title: Trigger, render, commit
version: 1
---

**React updates the screen in three steps, and only the last one touches the page.** Most surprises
about React come from merging them into one, so they are worth naming before looking at any output.

```schooling-figure
{"svg": "<svg data-fig=\"three-steps\" viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Three boxes in a row. Trigger: the first render, or a state setter being called. Render: React calls the components and collects a new tree, with nothing on the page changed. Commit: React compares the new tree with the last one and changes the page only where they differ. The page is touched only in the third box.\"><text x=\"120\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">1 · trigger</text><rect x=\"20\" y=\"44\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">first render, or</text><text x=\"120\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setMonday(…)</text><line x1=\"222\" y1=\"84\" x2=\"258\" y2=\"84\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,84.0 250.5,87.2 250.5,80.8\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">2 · render</text><rect x=\"260\" y=\"44\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">call App, then its</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">children, down the tree</text><line x1=\"462\" y1=\"84\" x2=\"498\" y2=\"84\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"498.0,84.0 490.5,87.2 490.5,80.8\" fill=\"var(--wire)\"></polygon><text x=\"600\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">3 · commit</text><rect x=\"500\" y=\"44\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">compare with last tree,</text><text x=\"600\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">change only the difference</text><line x1=\"20\" y1=\"150\" x2=\"460\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"240\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing on the page changes</text><line x1=\"500\" y1=\"150\" x2=\"700\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"600\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the page changes here</text></svg>", "caption": "Only the commit touches the page. Everything before it can be repeated or thrown away."}
```

1. **Trigger.** Something asks for a new screen. There are only two things that do: the first
   render, which `createRoot(…).render(<App />)` in `main.tsx` starts, and a state setter such as
   `setMonday` being called.
2. **Render.** React calls your components. Calling `App` produces a tree of the objects lesson 2
   looked at, and every component element in that tree is called in turn, down to the plain HTML
   elements at the bottom. **Rendering is calling functions and collecting what they return.** Nothing
   on the page has changed yet.
3. **Commit.** React compares the new tree with the one it made last time and changes the page where,
   and only where, the two differ. On the first render everything is new, so everything is added.

The browser then paints, which is its business and not React's.

Two consequences follow, and the next sections show both happening.

**A render can be thrown away.** Because step 2 changes nothing, React is free to call your
components when it likes, more than once if it likes, and to discard the result. That is why lesson 2
insisted a component must not change anything outside itself: a component that wrote to a variable,
or to the data it was given, would do it on every call, including the calls whose result never
reached the screen.

**A render is not an update to the page.** A component can be called and produce exactly what it
produced last time, and then the commit has nothing to do. Whether that is cheap is lesson 21's
question; whether it is correct never depends on it.
