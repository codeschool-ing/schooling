---
title: What runs again when something changes
version: 1
---

**The four cards draw the same page and update it in two different ways.** The `console.log` lines
said which:

| | the component's code ran | then, for one tick |
| --- | --- | --- |
| Angular | once, the constructor | the signal, its two `computed`s, and the bindings that read them |
| React | once per drawing | the whole function, again; React compares what it returned with the last time |
| Vue | once, the setup | the `ref`, its two `computed`s, and the parts of the template that read them |
| Svelte | once, the script | the `$state`, its two `$derived`s, and the code the compiler wrote for the paragraph |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two diagrams side by side. On the left, tracked reads, as Angular, Vue and Svelte do it: a tick changes the state, an arrow goes to the two derived values that read it, and from them to the one paragraph that reads those; the heading and the rest are untouched. On the right, React: a tick changes the state, the whole component function runs again, its result is compared with the last one, and the difference is written to the page.\"><text x=\"175\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Angular, Vue, Svelte: tracked reads</text><text x=\"545\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">React: run again, compare</text><line x1=\"360\" y1=\"14\" x2=\"360\" y2=\"236\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"115\" y=\"44\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">state</text><rect x=\"40\" y=\"110\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planned</text><rect x=\"190\" y=\"110\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done</text><line x1=\"160\" y1=\"80\" x2=\"110\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"110.0,106.0 115.1,99.8 118.0,105.4\" fill=\"var(--wire)\"></polygon><line x1=\"190\" y1=\"80\" x2=\"240\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"240.0,106.0 232.0,105.4 234.9,99.8\" fill=\"var(--wire)\"></polygon><rect x=\"100\" y=\"176\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the paragraph</text><line x1=\"100\" y1=\"146\" x2=\"150\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,172.0 142.0,171.4 144.9,165.8\" fill=\"var(--wire)\"></polygon><line x1=\"250\" y1=\"146\" x2=\"200\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"200.0,172.0 205.1,165.8 208.0,171.4\" fill=\"var(--wire)\"></polygon><text x=\"175\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the heading is not touched</text><rect x=\"430\" y=\"44\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">state</text><rect x=\"430\" y=\"98\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the whole function runs</text><rect x=\"430\" y=\"152\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">compared with the last result</text><rect x=\"430\" y=\"206\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the difference is written</text><line x1=\"545\" y1=\"74\" x2=\"545\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,96.0 541.9,88.6 548.1,88.6\" fill=\"var(--wire)\"></polygon><line x1=\"545\" y1=\"128\" x2=\"545\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,150.0 541.9,142.6 548.1,142.6\" fill=\"var(--wire)\"></polygon><line x1=\"545\" y1=\"182\" x2=\"545\" y2=\"204\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,204.0 541.9,196.6 548.1,196.6\" fill=\"var(--wire)\"></polygon></svg>", "caption": "The same tick, two ways to find what changed: follow who read the value, or run the component again and compare."}
```

**Three of the four track reads.** A signal in Angular, a ref in Vue and a rune in Svelte all know
who read them, so a change reaches exactly those readers and nothing else. That is lesson 6 and lesson 7 of this course, and it is the same idea under three names. Vue has had it from the start, Svelte has had runes since version 5, and Angular moved to it with signals, which is why the planner could drop zone.js.

**React re-runs and compares.** A change of state runs the component's function again, the whole of
it, and React compares the new result with the old to find what to change in the page. Nothing is
tracked; everything is recomputed, and the comparison keeps the page cheap to update. The totals in
the React card are plain arithmetic in the function, done again on every drawing. In a larger
component, React offers `useMemo` to keep a value until what it depends on changes; the `react-ts`
course teaches it in its lesson 7, and its lesson 3 is this whole question, what actually re-renders.

Neither way is wrong, and the difference shows in what you have to think about. In Angular, Vue and
Svelte, the question is **what reads what**: a value read outside a reactive context, or a `computed`
that reads something it should not, behaves surprisingly. In React the question is **what runs
again**: an object made inside the function is a new object on every drawing, and a component that
passes one to a child makes the child draw again too.

## The same ideas, four spellings

| idea | Angular | React | Vue | Svelte |
| --- | --- | --- | --- | --- |
| state | `signal()` | `useState()` | `ref()` | `$state()` |
| derived | `computed()` | a `const`, or `useMemo()` | `computed()` | `$derived()` |
| side effect | `effect()` | `useEffect()` | `watch()`, `watchEffect()` | `$effect()` |
| loop in the template | `@for` with `track` | `map()` with `key` | `v-for` with `:key` | `{#each}` with a key |
| condition | `@if` | `&&` or `? :` | `v-if` | `{#if}` |
| an input from a parent | `input()` | a property of `props` | `defineProps()` | `$props()` |
| a value back to the parent | `output()` | a function passed as a prop | `defineEmits()` | a function passed as a prop |
| two-way binding to a field | `[(ngModel)]`, `[formField]` | `value` and `onChange` | `v-model` | `bind:value` |

A student of this course reads most of the other three's code already. What changes is the
spelling, and in React, the model of what runs.
