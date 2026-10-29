---
title: Reactivity, compared
version: 1
---

**The four cards draw the same page, and they disagree about one question: when the state changes,
what runs again?** The `console.log` lines answered it:

| | the code that runs once | at a tick, what runs again |
| --- | --- | --- |
| Vue | `<script setup>`, once per component | the two `computed`s, and the parts of the template that read them |
| React | nothing: the component is a function | the whole function, and React compares what it returns with the last time |
| Angular | the constructor, once | the `computed`s, and the bindings that read the signals |
| Svelte | the `<script>`, once | the `$derived`s, and the generated code that writes the text |

**Three of the four track dependencies.** Vue, Angular and Svelte each notice, while a computed or a
template runs, which pieces of state it read, and when one of those changes they rerun exactly what
read it. Vue does it with the proxies of lesson 2, Angular with signals, Svelte with signals too, made
by its compiler from the runes. **React does not track anything**: a change of state means the
component runs again, all of it, and React works out what is different in what it returned. That is
why React needs the new list from `setSessions` to see a change, why its derived values are plain
variables recomputed on every run, and why `useMemo` and `useCallback` exist, to keep some work from
being redone. It is also why React's model is the easiest of the four to state, a function from state
to page, and a lot of people prefer it for that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"What runs again when a session is ticked, in the four cards. In Vue, Angular and Svelte, the state is connected to the two totals that read it, and the totals to the text that shows them; the tick reruns those two totals and that text, and the setup, the constructor or the script does not run again. In React, the tick calls the whole component function again, which recomputes both totals and returns the whole card, and React compares it with the card it returned before.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Vue, Angular, Svelte: tracked</text><rect x=\"30\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sessions</text><rect x=\"200\" y=\"100\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">planned</text><line x1=\"150\" y1=\"60\" x2=\"198\" y2=\"116\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,116.0 190.8,112.4 195.6,108.4\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"150\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">done</text><line x1=\"150\" y1=\"60\" x2=\"198\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,166.0 192.1,160.6 197.8,158.0\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"190\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setup: once</text><rect x=\"200\" y=\"200\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the total's text</text><line x1=\"312\" y1=\"116\" x2=\"330\" y2=\"116\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"312\" y1=\"166\" x2=\"330\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"330\" y1=\"116\" x2=\"330\" y2=\"216\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"330\" y1=\"216\" x2=\"312\" y2=\"216\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"312.0,216.0 319.4,212.9 319.4,219.1\" fill=\"var(--wire)\"></polygon><line x1=\"360\" y1=\"15\" x2=\"360\" y2=\"240\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">React: the function runs again</text><rect x=\"400\" y=\"40\" width=\"280\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">WeekCard()</text><text x=\"540\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState(start)</text><text x=\"540\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planned = ...</text><text x=\"540\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done = ...</text><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">return &lt;section&gt;...&lt;/section&gt;</text><rect x=\"400\" y=\"200\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">compared with the last card</text><line x1=\"540\" y1=\"192\" x2=\"540\" y2=\"198\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line></svg>", "caption": "Three of the four rerun what read the state; React reruns the component."}
```

## The same ideas, in four spellings

| | Vue | React | Angular | Svelte |
| --- | --- | --- | --- | --- |
| state | `ref([...])` | `useState([...])` | `signal([...])` | `$state([...])` |
| read it | `sessions.value` | `sessions` | `sessions()` | `sessions` |
| change it | `s.done = true` | `setSessions(newList)` | `sessions.update(...)` | `s.done = true` |
| derived | `computed(...)` | a `const` in the function | `computed(...)` | `$derived(...)` |
| a list | `v-for`, `:key` | `.map()`, `key` | `@for`, `track` | `{#each}`, `(id)` |
| two-way field | `v-model` | `checked` and `onChange` | `[checked]` and `(change)`, or `[(ngModel)]` | `bind:checked` |

**Changing it is where they split in two.** Vue and Svelte let you change a field inside the state,
and they see it; React and Angular's signals want a new value, so the list is copied with one session
changed, which is lesson 3's `toggleDone` and the reason it returned a new list. Code written in that
style moves between all four.

## What each costs

The size of each project on disk, and of the JavaScript each build sends:

```
ana@dev:~/vue/compare$ du -sh vue/node_modules react/node_modules angular/node_modules svelte/node_modules
110M	vue/node_modules
134M	react/node_modules
360M	angular/node_modules
112M	svelte/node_modules
```

```
ana@dev:~/vue/compare$ (cd vue && npm run build 2>&1 | grep -E "\.js|\.css")
dist/assets/index-A9ehZFq6.js  64.64 kB │ gzip: 25.49 kB
ana@dev:~/vue/compare$ (cd react && npm run build 2>&1 | grep -E "\.js|\.css")
dist/assets/index-B22AcDMe.js  220.16 kB │ gzip: 68.86 kB
ana@dev:~/vue/compare$ (cd angular && npx ng build 2>&1 | grep -E "^(main|styles|Initial)")
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-COB43VF2.js    | main          | 107.08 kB |                32.40 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes
ana@dev:~/vue/compare$ (cd svelte && npm run build 2>&1 | grep -E "\.js|\.css")
dist/assets/index-CROVg5r1.js  33.74 kB │ gzip: 13.37 kB
```

**Compressed, Svelte's card is 13 kB, Vue's 25, Angular's 32 and React's 69.** For a card, most of
each number is the framework itself, so the gaps are largest here and shrink as an application grows
and its own code takes over. Svelte's is smallest because a compiler sends only the code a page uses;
React's is largest because `react-dom` carries the whole of React's machinery for comparing what a
function returned. None of the four is too big for the planner, and `front-performance` lesson 2 is
the place where such numbers are measured on real pages. Angular's `node_modules` is the largest
because the platform comes with the CLI, a test setup and a compiler of its own.
