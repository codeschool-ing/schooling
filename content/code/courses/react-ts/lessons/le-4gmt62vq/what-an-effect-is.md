---
title: An effect keeps something outside React in step
version: 1
---

**A component's render must not change anything outside itself. An effect is where you do it
anyway, on purpose, after the render has reached the page.** The browser tab's title, a connection
to a server, a listener on the window, a timer: none of them is part of the tree React draws, and
an effect is how a component keeps one of them in step with what it renders.

The shape is always the same:

```tsx
useEffect(() => {
  // runs after React has committed this render to the page
  return () => {
    // runs before the effect runs again, and when the component goes away
  }
}, [dependencies])
```

Three parts, and this lesson takes them in turn: **the function**, which does the work; **the
cleanup** it may return, which undoes it; and **the dependency array**, which says when the work has
to be done again.

```schooling-figure
{"svg": "<svg data-fig=\"timeline\" viewBox=\"0 0 720 225\" role=\"img\" aria-label=\"A timeline of two renders. Render 1, commit 1, then effect 1 runs. Later monday changes: render 2, commit 2, then cleanup 1 runs with render 1's values, and only then effect 2. The page has already changed before each effect runs.\"><line x1=\"20\" y1=\"120\" x2=\"700\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"20\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 1</text><rect x=\"110\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">commit 1</text><rect x=\"200\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">effect 1</text><rect x=\"350\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 2</text><rect x=\"440\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">commit 2</text><rect x=\"530\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cleanup 1</text><rect x=\"620\" y=\"104\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">effect 2</text><text x=\"320\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">monday changes</text><line x1=\"320\" y1=\"150\" x2=\"320\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"320.0,124.0 323.2,131.5 316.8,131.5\" fill=\"var(--paper-dim)\"></polygon><path d=\"M 240 104 C 300 40 520 40 570 104\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><polygon points=\"570.0,104.0 562.7,100.3 567.7,96.2\" fill=\"var(--amber)\"></polygon><text x=\"405\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">undoes what effect 1 started</text><text x=\"150\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the page shows render 1</text><line x1=\"110\" y1=\"198\" x2=\"340\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"560\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the page shows render 2</text><line x1=\"440\" y1=\"198\" x2=\"700\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line></svg>", "caption": "An effect runs after its commit; its cleanup runs before the next one."}
```

Two things in that picture matter more than the rest:

- **An effect runs after the commit.** The page already shows the new render when the effect starts,
  so an effect never delays what the user sees, and it can read the page as it now is.
- **The cleanup runs before the next effect**, with the values of its own render. Whatever an effect
  started, its own cleanup stops: the listener it added, the request it is waiting for.

## What an effect is not

The word suggests "something that happens because of something else", and that is the most common
misuse: an effect that watches one piece of state to set another. Lesson 4 already named the right
tool for that, which is computing the value while rendering, and the section "You might not need an
effect" lists the other cases. **The test is whether there is something outside React to keep in
step.** If the answer is no, it is not an effect.

The planner has three things outside React that it needs to keep in step: the data on the server,
the tab's title, and the keyboard. The next three sections do them in that order.
