---
title: Why a store
version: 1
---

**A store is state that lives outside every component, with one copy for the whole application, that
any component can read and change through the store's own functions.** Lesson 10 ended on the reason the
planner needs one: a composable makes fresh state each time it is called, so two pages calling
`usePlannerData()` would hold two lists of sessions. And lesson 12's guard had to fetch the courses a
second time, because a guard is not a component and cannot inject what `App` provides.

**Pinia** is Vue's store library, written by a member of the Vue team and recommended by the Vue
documentation. It replaced Vuex, which you will meet in older code. Install it in the sandbox first,
pinned:

```
ana@dev:~/vue/sandbox$ npm install --save-exact pinia@4.1.0

added 8 packages, and audited 47 packages in 1s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

A store, like the router, is installed into the application, so the sandbox's `main.js` gains one
`use`:

```javascript
// src/main.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'

// Every file in src/demos is a demo, and ?demo=NAME picks one.
const demos = import.meta.glob('./demos/*.vue')
const name = new URLSearchParams(location.search).get('demo')
const load = demos[`./demos/${name}.vue`]

if (load) {
  // Each demo gets a store container of its own, from lesson 13 on.
  load().then((module) => createApp(module.default).use(createPinia()).mount('#app'))
} else {
  document.querySelector('#app').textContent = `No demo called ${name}. There are: ${Object.keys(demos).join(', ')}`
}
```

`createPinia()` makes the container that holds every store's state. Each demo gets its own, so that one
demo's state does not leak into the next.

## The same counter, twice

A tally of minutes, written as lesson 10's composable and as a store, side by side:

```javascript
// src/demos/tally.js: the same minutes counter, as a composable and as a store.
import { ref } from 'vue'
import { defineStore } from 'pinia'

export function useTally() {
  const minutes = ref(0)
  const add = (m) => (minutes.value += m)
  return { minutes, add }
}

export const useTallyStore = defineStore('tally', () => {
  const minutes = ref(0)
  const add = (m) => (minutes.value += m)
  return { minutes, add }
})
```

The two definitions differ by one line: the store's function is passed to `defineStore('tally', …)`
instead of being exported as it is. A box that uses both, and a demo with two boxes:

```html
<!-- src/demos/TallyBox.vue -->
<script setup>
import { useTally, useTallyStore } from './tally.js'

const { name } = defineProps({ name: String })
const own = useTally()
const shared = useTallyStore()
</script>

<template>
  <p :id="name">{{ name }}: composable {{ own.minutes }}, store {{ shared.minutes }}</p>
  <button :id="`add-${name}`" @click="own.add(15), shared.add(15)">Add 15 here</button>
</template>
```

```html
<!-- src/demos/WhyAStore.vue -->
<script setup>
import TallyBox from './TallyBox.vue'
</script>

<template>
  <TallyBox name="week" />
  <TallyBox name="course" />
</template>
```

Add 15 twice in the first box and once in the second:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=WhyAStore' --do 'click #add-week' --do 'click #add-week' --do 'click #add-course'
[vite] connecting...
[vite] connected.
-- click #add-week
-- click #add-week
-- click #add-course
== the text of #app
week: composable 30, store 45

Add 15 here

course: composable 15, store 45

Add 15 here
```

**The composables counted apart, 30 and 15; the store counted once, 45, and both boxes show it.**
`useTally()` ran its function in each box and made two `minutes` refs. `useTallyStore()` ran its function
the first time it was called, kept the result in the Pinia container under the id `'tally'`, and handed
the same store to every later caller.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Before and after the store. Before: App owns the data and provides it to the views; the router&#x27;s guard is outside the component tree, so it fetches courses.json itself, a second request. After: the planner store owns the data, inside Pinia&#x27;s container; App, the views, the session rows and the guard all call usePlannerStore and reach the same store, and courses.json is fetched once.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">lesson 12: provide</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">lesson 13: one store</text><rect x=\"100\" y=\"34\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">App</text><rect x=\"30\" y=\"104\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HomeView</text><line x1=\"170\" y1=\"70\" x2=\"95\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,102.0 100.6,96.2 103.0,102.0\" fill=\"var(--wire)\"></polygon><rect x=\"190\" y=\"104\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseView</text><line x1=\"170\" y1=\"70\" x2=\"255\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"255.0,102.0 247.0,102.3 249.2,96.5\" fill=\"var(--wire)\"></polygon><text x=\"170\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provide</text><rect x=\"30\" y=\"168\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">beforeEnter</text><rect x=\"200\" y=\"168\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"265\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">courses.json</text><line x1=\"162\" y1=\"183\" x2=\"198\" y2=\"183\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,183.0 190.6,186.1 190.6,179.9\" fill=\"var(--amber)\"></polygon><text x=\"180\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a second request</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><rect x=\"470\" y=\"100\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">usePlannerStore</text><rect x=\"395\" y=\"25\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">App</text><line x1=\"450\" y1=\"56\" x2=\"545\" y2=\"98\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,98.0 537.0,97.9 539.5,92.2\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"600\" y=\"25\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HomeView</text><line x1=\"655\" y1=\"56\" x2=\"545\" y2=\"98\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,98.0 550.8,92.5 553.0,98.3\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"395\" y=\"175\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SessionRow</text><line x1=\"450\" y1=\"174\" x2=\"545\" y2=\"142\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,142.0 539.0,147.3 537.0,141.4\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"600\" y=\"175\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">beforeEnter</text><line x1=\"655\" y1=\"174\" x2=\"545\" y2=\"142\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,142.0 552.9,141.1 551.2,147.0\" fill=\"var(--phosphor-dim)\"></polygon></svg>", "caption": "A store is reached by import, so a guard reaches it as easily as a component does."}
```

## What a store adds to a shared ref

A `ref` exported from a module, like lesson 4's `clock.js`, is also one copy for everybody. What Pinia
adds is what makes shared state manageable once an application has a few people working on it:

- **one container per application**, so server rendering (lesson 19) and tests (lesson 21) start each run
  with fresh state instead of whatever the last one left in a module;
- **a name and a shape**: every store has an id, its state, its getters and its actions, so everybody
  knows where a change can come from;
- **the developer tools**: the Vue extension shows every store, its state, and a timeline of every
  change;
- **hooks into every change**, `$subscribe` and `$onAction`, the fifth section of this lesson.
