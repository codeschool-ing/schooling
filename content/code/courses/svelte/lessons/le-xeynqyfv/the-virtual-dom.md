---
title: What a virtual DOM is, and why Svelte has none
version: 1
---

**A virtual DOM is a copy of the page kept in JavaScript, made again after every change and compared
with the copy before it.** React builds one, and so does Vue. When something changes, the framework
calls your component function again, gets back a fresh description of what the page should look
like, compares it with the previous description, and applies only the differences to the real page.
That comparison is called **diffing**, and the step that applies its result is called **patching**.

It is a good design, and the reason for it is worth understanding before looking at what Svelte
does instead. Changing the real DOM is slow compared with changing a JavaScript object, and writing
code that changes exactly the right nodes by hand is hard. The virtual DOM lets you write the page as
if you rebuilt all of it on every change, and makes that affordable by touching the real page only
where the two descriptions differ.

## The same counter, written for React

This is lesson 1's `Counter` as a React component. It is here to be read, not run; lesson 20 builds
the planner's equivalent in all three of the other frameworks.

```jsx
// Counter.jsx, in React: not part of the planner.
import { useState } from "react";

export default function Counter() {
  const [minutes, setMinutes] = useState(0);
  return (
    <>
      <button onClick={() => setMinutes(minutes + 30)}>Add 30 minutes</button>
      <p>{minutes} minutes this week</p>
    </>
  );
}
```

Read it as React reads it. `Counter` is a function that **returns a description** of a button and
a paragraph. When the button is pressed, `setMinutes` asks React to **call `Counter` again**. The new
call returns a new description, with `30` where `0` was. React compares the two, finds that one piece
of text differs, and changes that text on the page.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two ways one press of the button reaches the page. Above, React: setMinutes asks React to call Counter again, which returns a new description of the button and the paragraph; React compares it with the previous description, finds one text that differs, and patches that text on the page. Below, Svelte: the click sets the signal minutes, the signal tells the one effect that read it, and the effect sets the text of the paragraph. Both end with one text node changed; only React built and compared two descriptions to get there.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">React</text><rect x=\"20\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">setMinutes(30)</text><line x1=\"144\" y1=\"58\" x2=\"160\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,58.0 152.6,61.1 152.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"160\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Counter() again</text><line x1=\"284\" y1=\"58\" x2=\"300\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,58.0 292.6,61.1 292.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"300\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new description</text><line x1=\"424\" y1=\"58\" x2=\"440\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"440.0,58.0 432.6,61.1 432.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"440\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"502\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">diff with the old</text><line x1=\"564\" y1=\"58\" x2=\"580\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"580.0,58.0 572.6,61.1 572.6,54.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"580\" y=\"36\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">patch 1 text</text><rect x=\"160\" y=\"92\" width=\"404\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"362\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">work done in the browser to find the change</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Svelte</text><rect x=\"20\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes += 30</text><line x1=\"144\" y1=\"198\" x2=\"160\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,198.0 152.6,201.1 152.6,194.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"160\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">signal minutes</text><line x1=\"284\" y1=\"198\" x2=\"300\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,198.0 292.6,201.1 292.6,194.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"300\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">its one reader</text><line x1=\"424\" y1=\"198\" x2=\"440\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"440.0,198.0 432.6,201.1 432.6,194.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"440\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">set 1 text</text><rect x=\"580\" y=\"176\" width=\"124\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;p&gt;30 …&lt;/p&gt;</text><line x1=\"564\" y1=\"198\" x2=\"578\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,198.0 570.6,201.1 570.6,194.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"642\" y1=\"80\" x2=\"642\" y2=\"174\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"362\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">worked out once, by the compiler, before anybody visited</text></svg>", "caption": "Both reach the same single change. React compares two descriptions to find it; Svelte's effect already knew."}
```

## What Svelte does instead

Lesson 1's compiled `Counter` had none of those steps. There was no second call to the component
and no description to compare. There was **one effect that sets one text node**, and it runs when
`minutes` changes, because it read `minutes` the last time it ran.

**The work a virtual DOM does at runtime, Svelte's compiler does once, at build time.** It reads the
markup, sees that `{minutes}` sits inside the `<p>`, and writes code that updates that node and
nothing else. The question "what could this change affect?" is answered by the compiler, from the
source, instead of by a diff, on every change, in the visitor's browser.

That has a cost, and it is honest to name it. Svelte's components only work because a compiler
rewrote them, so Svelte syntax is not JavaScript and tools have to understand it. React components
are ordinary functions that any JavaScript tool can read. Lesson 20 comes back to what each choice
costs over the life of a project.

## The word "reactivity"

Every framework uses it, and it means something narrower than it sounds: **when a value changes,
whatever depends on it updates by itself.** The frameworks differ in how they find out what depends
on what. React re-runs the component and compares the output. Svelte tracks it with **signals**: values
that record who read them, so that a change can go straight to the readers. Vue, Angular and Solid
use signals too, and Vue still diffs a virtual DOM for the components its signals mark as changed,
which lesson 20 sets beside Svelte's approach. The section after next draws that record for the counter.
