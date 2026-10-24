---
title: When the callback runs
version: 1
---

**A watcher's callback does not run at the moment the value changes.** Like a render, it is queued
(lesson 2), and the `flush` option says where in the queue it goes: before the component redraws,
after it, or at once, on every single write.

```html
<!-- src/demos/FlushTiming.vue -->
<script setup>
import { ref, watch } from 'vue'

const count = ref(0)
const page = () => document.querySelector('output').textContent

watch(count, (n) => console.log(`pre:  count ${n}, page says ${page()}`))
watch(count, (n) => console.log(`post: count ${n}, page says ${page()}`), { flush: 'post' })
watch(count, (n) => console.log(`sync: count ${n}, page says ${page()}`), { flush: 'sync' })

function addTwo() {
  count.value++
  count.value++
}
</script>

<template>
  <output>{{ count }}</output>
  <button @click="addTwo">Add two</button>
</template>
```

One click, two increments:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FlushTiming' --do 'click button' --text -
[vite] connecting...
[vite] connected.
-- click button
sync: count 1, page says 0
sync: count 2, page says 0
pre:  count 2, page says 0
post: count 2, page says 2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"One click on Add two, in time order from left to right. The click writes count twice. The sync watcher runs at each write, seeing count 1 and then count 2, and the page saying 0 both times. When the click&#x27;s code has finished, the queue runs: the pre watcher, once, with count 2 and the page still saying 0; then the redraw, after which the output says 2; then the post watcher, once, with count 2 and the page saying 2.\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the click</text><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">watchers</text><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;output&gt;</text><rect x=\"100\" y=\"45\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"157\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">count.value++</text><line x1=\"157\" y1=\"77\" x2=\"157\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"157.0,108.0 153.9,100.6 160.1,100.6\" fill=\"var(--wire)\"></polygon><rect x=\"222\" y=\"45\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"279\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">count.value++</text><line x1=\"279\" y1=\"77\" x2=\"279\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"279.0,108.0 275.9,100.6 282.1,100.6\" fill=\"var(--wire)\"></polygon><rect x=\"100\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"157\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">sync</text><text x=\"157\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 1, page says 0</text><rect x=\"222\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"279\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">sync</text><text x=\"279\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 2, page says 0</text><rect x=\"344\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"401\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">pre</text><text x=\"401\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 2, page says 0</text><rect x=\"466\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"523\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">redraw</text><rect x=\"588\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">post</text><text x=\"645\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 2, page says 2</text><line x1=\"344\" y1=\"96\" x2=\"702\" y2=\"96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"523\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">queued: run after the click's code</text><rect x=\"100\" y=\"182\" width=\"362\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"281\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><rect x=\"466\" y=\"182\" width=\"236\" height=\"28\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"584\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><line x1=\"100\" y1=\"226\" x2=\"702\" y2=\"226\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"702.0,226.0 694.6,229.1 694.6,222.9\" fill=\"var(--wire)\"></polygon></svg>", "caption": "sync runs at every write; pre and post run once, on either side of the redraw."}
```

| `flush` | ran | saw the page say | use it for |
|---|---|---|---|
| `'sync'` | twice, once per write, at the moment of writing | 0 | almost nothing; see below |
| `'pre'`, the default | once, with the final value, **before** the redraw | 0 | work that only needs the values, which is most of it |
| `'post'` | once, **after** the redraw | 2 | work that needs the page as the change left it: measuring, scrolling, focusing |

`'pre'` is the default because most watchers do not touch the page, and running them before the
redraw lets them change state that the same redraw will then show, in one pass instead of two.

**`'post'` is for reading the DOM.** A watcher that scrolls a list to the session just added needs that
session's element to exist, and it exists only after the redraw. `watchPostEffect` is `watchEffect`
with `flush: 'post'` already set.

**`'sync'` gives up the batching** that the queue exists for. It ran twice for two writes, and a loop
of a hundred writes would run it a hundred times. It is for the rare watcher that must see every
intermediate value, such as a log of every change; it is never the fix for a watcher that "runs too
late", which is a `'post'` problem or a `computed` problem.
