---
title: storeToRefs, and the destructuring trap again
version: 1
---

**A store is a reactive object, so destructuring it hands out plain values that never change.**
`const { done } = store` reads `store.done` once. To take pieces out of a store and keep them reactive,
`storeToRefs(store)` returns a ref for every piece of state and every getter, and those can be
destructured safely.

```html
<!-- src/demos/LostRefs.vue -->
<script setup>
import { storeToRefs } from 'pinia'
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()
const { done } = store
const { done: doneRef, planned } = storeToRefs(store)
const { toggle } = store
</script>

<template>
  <p id="plain">Destructured: {{ done }}</p>
  <p id="refs">With storeToRefs: {{ doneRef }} of {{ planned }}</p>
  <button @click="toggle('s4')">Toggle s4</button>
</template>
```

Toggle the session that is not done:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LostRefs' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
Destructured: 45

With storeToRefs: 105 of 105

Toggle s4
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"The LostRefs demo. On the left, the sessions store, a reactive object, with done going from 45 to 105 when s4 is toggled, planned at 105, and the action toggle. On the right, three ways of taking pieces out of it. const done equals store reads done once and is a plain copy: it stays at 45. storeToRefs of store gives a ref for done and planned, which follows the store: 105 of 105. const toggle equals store takes the action straight from the store: a function, the same forever, and its button worked.\"><rect x=\"20\" y=\"30\" width=\"200\" height=\"156\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">useSessionsStore()</text><text x=\"120\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">done: 45 → 105</text><text x=\"120\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planned: 105</text><text x=\"120\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">toggle()</text><rect x=\"280\" y=\"40\" width=\"220\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">const { done } = store</text><line x1=\"222\" y1=\"57\" x2=\"276\" y2=\"57\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"276.0,57.0 268.6,60.1 268.6,53.9\" fill=\"var(--amber)\"></polygon><text x=\"512\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a copy: stays at 45</text><rect x=\"280\" y=\"95\" width=\"220\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">storeToRefs(store)</text><line x1=\"222\" y1=\"112\" x2=\"276\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"276.0,112.0 268.6,115.1 268.6,108.9\" fill=\"var(--phosphor)\"></polygon><text x=\"512\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">refs: 105 of 105</text><rect x=\"280\" y=\"150\" width=\"220\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">const { toggle } = store</text><line x1=\"222\" y1=\"167\" x2=\"276\" y2=\"167\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"276.0,167.0 268.6,170.1 268.6,163.9\" fill=\"var(--phosphor)\"></polygon><text x=\"512\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a function: the same forever</text></svg>", "caption": "State and getters go through storeToRefs; actions come straight from the store."}
```

**The destructured `done` stayed at 45; the one from `storeToRefs` moved to 105.** It is lesson 2's
first trap, in a new place, and the reason the planner's views write their first two lines the way they
do:

```javascript
const planner = usePlannerStore()
const { sessions } = storeToRefs(planner)
const { toggle } = planner
```

## Why actions come straight from the store

`storeToRefs` skips actions, because an action is a function and a function needs no ref: it is the
same function forever, and calling it always works on the current state. So **state and getters go
through `storeToRefs`, and actions are destructured from the store itself**, as `toggle` is above. The
demo does the same with `toggle`, and its button worked.

## Or do not destructure

`planner.sessions` in the template, and `planner.toggle(id)` in the script, need no `storeToRefs` at
all: reading through the store is always reactive. `App.vue` in the last section of this lesson writes
`planner.error` and `planner.courses.length` in its template and destructures nothing. Destructure when a
view uses a piece often enough that `planner.` everywhere would be noise, and then use `storeToRefs`.
