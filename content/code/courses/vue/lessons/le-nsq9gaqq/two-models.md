---
title: Two ways to know what changed
version: 1
---

**A framework has to answer one question over and over: something changed, so what on the screen
must be redrawn?** React and Vue answer it in opposite ways, and most of what feels different between
them comes from that one decision.

**React runs your component again.** A React component is a function. When its state changes, React
calls the whole function again, gets a new description of the screen, compares it with the previous
one and changes the elements that differ. React does not know which value a piece of markup used; it
finds out by running everything and comparing.

**Vue runs your component once, and remembers what each piece read.** The code in `<script setup>`
runs a single time, when the component is created. The values you want to watch are wrapped, so that
reading one is noticed and writing one is noticed. When the template renders, Vue records every
wrapped value it read. When one of those values is written later, Vue knows exactly which renders
depend on it and runs only those again.

The common wrong picture, for somebody arriving from React, is that a Vue component re-runs on every
change like a React one. It does not, and the next demo shows it.

## A sandbox for experiments

The planner is for the planner. Experiments go in a second project beside it, `~/vue/sandbox`, made
the same way and pinned to the same versions by copying the planner's `package.json` and lockfile:

```
ana@dev:~/vue$ npm create vue@3.24.0 -- --prettier --bare sandbox > /dev/null
ana@dev:~/vue$ cd sandbox
ana@dev:~/vue/sandbox$ cp ../planner/package.json ../planner/package-lock.json ../planner/vite.config.js .
ana@dev:~/vue/sandbox$ npm pkg set name=sandbox
ana@dev:~/vue/sandbox$ npm install

added 38 packages, and audited 39 packages in 1s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/sandbox$ mkdir src/demos
```

`npm install` found a lockfile and installed exactly the tree it describes, which is the point of
keeping one. Now give the sandbox a `main.js` that can show any of several small components, each a
file in `src/demos`, picked by the address:

```javascript
// src/main.js
import { createApp } from 'vue'

// Every file in src/demos is a demo, and ?demo=NAME picks one.
const demos = import.meta.glob('./demos/*.vue')
const name = new URLSearchParams(location.search).get('demo')
const load = demos[`./demos/${name}.vue`]

if (load) {
  load().then((module) => createApp(module.default).mount('#app'))
} else {
  document.querySelector('#app').textContent = `No demo called ${name}. There are: ${Object.keys(demos).join(', ')}`
}
```

`import.meta.glob` is something Vite provides, not JavaScript: it finds every file matching the
pattern when the project is built, and lesson 17 shows what it turns into. Here it means that a new
demo is a new file, and nothing else changes.

## Once, against every time

The first demo logs a line when its setup runs, and another every time its template reads `count`:

```html
<!-- src/demos/RunsOnce.vue -->
<script setup>
import { ref } from 'vue'

console.log('setup ran')
const count = ref(0)

function label() {
  console.log(`render read count = ${count.value}`)
  return `Clicked ${count.value} times`
}
</script>

<template>
  <button @click="count++">{{ label() }}</button>
</template>
```

Start the sandbox's dev server in a second terminal (`npm run dev`, inside `~/vue/sandbox`), and click
the button three times:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=RunsOnce' --do 'click button' --do 'click button' --do 'click button'
[vite] connecting...
[vite] connected.
setup ran
render read count = 0
-- click button
render read count = 1
-- click button
render read count = 2
-- click button
render read count = 3
== the text of #app
Clicked 3 times
```

**`setup ran` appears once. The render runs four times**: once to draw the page, then once per click.
The function `label()` is called again because the template calls it, and the template runs again
because it read `count`, which changed. Nothing else in the component runs again. In React, the
equivalent of `console.log('setup ran')` would be printed four times, because the whole function is
the render.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two rows, each showing a component over three clicks. In React, every click runs the whole component function again, then compares the new description with the old one and patches the page. In Vue, the setup runs once at the start; every click writes a ref, and only the render that read it runs again and patches the page.\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">React</text><rect x=\"100\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"155.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ compare</text><line x1=\"230\" y1=\"30\" x2=\"230\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"230\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">click</text><rect x=\"250\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"305.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ compare</text><line x1=\"380\" y1=\"30\" x2=\"380\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"380\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">click</text><rect x=\"400\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"455.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ compare</text><line x1=\"530\" y1=\"30\" x2=\"530\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">click</text><rect x=\"550\" y=\"44\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">component()</text><text x=\"605.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ compare</text><text x=\"100\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">runs again on a change: the whole function</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Vue</text><rect x=\"100\" y=\"154\" width=\"70\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">setup</text><rect x=\"180\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"218.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><line x1=\"281\" y1=\"140\" x2=\"281\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"281\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">click</text><rect x=\"306\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"344.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><line x1=\"407\" y1=\"140\" x2=\"407\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"407\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">click</text><rect x=\"432\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><line x1=\"533\" y1=\"140\" x2=\"533\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"533\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">click</text><rect x=\"558\" y=\"154\" width=\"76\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"596.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">render()</text><text x=\"100\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">runs again on a change: the render that read it</text></svg>", "caption": "React finds out what changed by running everything again. Vue already knows, because every read of a ref was recorded."}
```

## What each model costs

| | React | Vue |
|---|---|---|
| what runs again on a change | the whole component function | only the renders and effects that read the value |
| how a value is declared | `useState`, called on every render, in the same order | `ref` or `reactive`, called once |
| where it goes wrong | work in the function body repeated on every render; stale values captured by closures | a value that stops being tracked, because it was unwrapped too early (section 05 of this lesson) |
| what you write to say "this depends on that" | dependency arrays, by hand | nothing; reading it is the declaration |

Neither is free. React's model is simple to state and makes you think about what runs on every
render. Vue's model makes the common case automatic, and its traps all have the same shape: **a value
read from outside the wrapper is a plain value, and plain values are not watched.** The rest of this
lesson is about the wrapper.
