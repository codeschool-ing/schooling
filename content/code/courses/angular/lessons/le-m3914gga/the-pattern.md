---
title: The planner's store, as a pattern
version: 1
---

**Since lesson 11 the planner has kept its state in a service of signals, and the shape it settled
into has a name in every state library: data flows one way.** A component reads signals; when
something happens it calls a method; the method changes the state; the signals that depend on the
state follow; the template draws them again. Nothing writes the state but the store's own methods,
and nothing reads it but through what the store hands out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A loop of four boxes, the data flowing one way around it. A component&#x27;s template reads signals. An event in the component calls a method of the store. The method replaces the store&#x27;s private state. The computed signals that depend on the state follow, and the template reads them again.\"><rect x=\"40\" y=\"40\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">component</text><text x=\"150\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">template reads signals</text><rect x=\"460\" y=\"40\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">method</text><text x=\"570\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toggle(), add()</text><rect x=\"460\" y=\"150\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">state</text><text x=\"570\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">private data</text><rect x=\"40\" y=\"150\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">computed</text><text x=\"150\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sessions(), weekTotals()</text><line x1=\"262\" y1=\"65\" x2=\"456\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"456.0,65.0 448.6,68.1 448.6,61.9\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">an event calls</text><line x1=\"570\" y1=\"92\" x2=\"570\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"570.0,146.0 566.9,138.6 573.1,138.6\" fill=\"var(--wire)\"></polygon><text x=\"578\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replaces</text><line x1=\"456\" y1=\"175\" x2=\"264\" y2=\"175\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"264.0,175.0 271.4,171.9 271.4,178.1\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">follow</text><line x1=\"150\" y1=\"148\" x2=\"150\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,94.0 153.1,101.4 146.9,101.4\" fill=\"var(--wire)\"></polygon><text x=\"158\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read again</text><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nothing else writes the state</text></svg>", "caption": "Data flows one way: events become method calls, methods replace the state, and what depends on it follows."}
```

Each part of `PlannerStore` has the name the libraries give it:

| in `PlannerStore` | the general name | what makes it work |
|---|---|---|
| `private readonly data` | the **state** | one place, private, so nothing else writes it |
| `courses`, `sessions`, `weekTotals` | **selectors** | `computed`, read-only, recomputed only when the state changes |
| `minutesThisWeek(courseId)` | a selector with an argument | a method reading signals, tracked wherever it is called |
| `toggle`, `add` | **actions**, and the code that handles them | a named way in, the only one, which also talks to the server |
| `saveError` | state about the state | a signal like the rest |

**Two rules make it hold.** State is replaced, never changed in place, as lesson 6 said and lesson 19's
pure pipes confirmed: `update` returns a new object, so every `computed` and every `OnPush` component
sees a new value. And a component never keeps a copy: it reads the store's signal where it needs it,
so there is nothing to fall out of step, which is the defect lesson 11 removed.

Not all state belongs in a store. The value of a form while it is being typed belongs to the form; whether a
panel is open belongs to the component that draws it. A store is for state that more than one place
reads, or that must outlive the component showing it. The next section adds one such thing.
