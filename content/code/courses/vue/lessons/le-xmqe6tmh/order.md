---
title: Parents and children, in order
version: 1
---

**A parent's setup runs before its children exist, and its `onMounted` runs after all of them are on
the page.** Removal mirrors it: the parent is told first that it is leaving, and is the last to be gone.
That order decides what a parent may assume about its children, and the other way round.

One component that logs its moments, used three times, as a parent with two children in its slot:

```html
<!-- src/demos/Child.vue -->
<script setup>
import { onBeforeMount, onMounted, onBeforeUnmount, onUnmounted } from 'vue'

const { name } = defineProps({ name: String })
console.log(`${name}: setup`)
onBeforeMount(() => console.log(`${name}: beforeMount`))
onMounted(() => console.log(`${name}: mounted`))
onBeforeUnmount(() => console.log(`${name}: beforeUnmount`))
onUnmounted(() => console.log(`${name}: unmounted`))
</script>

<template>
  <p>{{ name }}</p>
  <slot />
</template>
```

```html
<!-- src/demos/Order.vue -->
<script setup>
import { ref } from 'vue'
import Child from './Child.vue'

const shown = ref(true)
</script>

<template>
  <Child v-if="shown" name="parent">
    <Child name="first child" />
    <Child name="second child" />
  </Child>
  <button @click="shown = false">Remove all three</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Order' --do 'click button' --text -
[vite] connecting...
[vite] connected.
parent: setup
parent: beforeMount
first child: setup
first child: beforeMount
second child: setup
second child: beforeMount
first child: mounted
second child: mounted
parent: mounted
-- click button
parent: beforeUnmount
first child: beforeUnmount
second child: beforeUnmount
first child: unmounted
second child: unmounted
parent: unmounted
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Time runs left to right. Three rows: parent, first child, second child. The parent&#x27;s setup and beforeMount come first; then each child&#x27;s setup and beforeMount; then the first child&#x27;s mounted, the second child&#x27;s mounted, and last the parent&#x27;s mounted. Creation goes down the tree and mounting comes back up.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parent</text><line x1=\"130\" y1=\"50\" x2=\"705\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">first child</text><line x1=\"130\" y1=\"110\" x2=\"705\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">second child</text><line x1=\"130\" y1=\"170\" x2=\"705\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><rect x=\"135\" y=\"37\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"164.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">setup</text><rect x=\"198\" y=\"37\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"227.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">before…</text><line x1=\"193\" y1=\"50\" x2=\"198\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"261\" y=\"97\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">setup</text><line x1=\"256\" y1=\"50\" x2=\"261\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"324\" y=\"97\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"353.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">before…</text><line x1=\"319\" y1=\"110\" x2=\"324\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"387\" y=\"157\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">setup</text><line x1=\"382\" y1=\"110\" x2=\"387\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"450\" y=\"157\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"479.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">before…</text><line x1=\"445\" y1=\"170\" x2=\"450\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"513\" y=\"97\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">mounted</text><line x1=\"508\" y1=\"170\" x2=\"513\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"576\" y=\"157\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">mounted</text><line x1=\"571\" y1=\"110\" x2=\"576\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"639\" y=\"37\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">mounted</text><line x1=\"634\" y1=\"170\" x2=\"639\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><text x=\"260\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">created, going down</text><text x=\"600\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mounted, coming back up</text></svg>", "caption": "A parent is mounted last, so its onMounted can count on every child being on the page."}
```

**Creation goes down, and mounting comes back up.** The parent's setup and `beforeMount` run first;
then each child is created and prepared in turn; then the children are mounted, first to last, and only
then the parent. A parent's `onMounted` can therefore count on every child being on the page and
having run its own `onMounted`. A child's `onMounted` can count on the page, because Vue runs the
mounted hooks only once the whole tree has been inserted, but not on anything the parent does in its
own `onMounted`, which has not run yet.

**Removal starts at the top and finishes at the top.** `beforeUnmount` runs parent first, then
children; `unmounted` runs children first, then the parent. So in its own `onUnmounted`, a parent knows
its children have already finished cleaning up after themselves.

## What this means in practice

- **Do not reach into a child from the parent's setup.** It does not exist yet. A template ref to a
  child component, section 04, is `null` until the parent's `onMounted`.
- **Do not make a child depend on something its parent sets up in `onMounted`.** The child's
  `onMounted` runs first and will not find it. Provide the thing during the parent's setup instead, as
  lesson 8 did, and it is there before any child is created.
- **Clean up in the component that started the work.** Each component's `onUnmounted` runs for it,
  whatever its parent does, so a timer belongs to the component that started it.
