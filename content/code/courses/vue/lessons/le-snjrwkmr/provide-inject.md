---
title: provide and inject
version: 1
---

**A component can `provide` a value under a key, and any component below it, at any depth, can
`inject` it by that key.** The components in between neither receive it nor pass it on. It is the same
tree as before, with the unit sent past the middle instead of through it.

The keys go in a module of their own, for a reason the section on keys, later in this lesson, gives:

```javascript
// src/demos/keys.js: the keys this sandbox provides values under.
export const unitKey = Symbol('unit')
export const plannerKey = Symbol('planner')
```

```html
<!-- src/demos/InjectLeaf.vue -->
<script setup>
import { inject } from 'vue'
import { unitKey } from './keys.js'

defineProps({ minutes: Number })
const unit = inject(unitKey)
</script>

<template>
  <li>{{ unit === 'hours' ? minutes / 60 : minutes }} {{ unit }}</li>
</template>
```

```html
<!-- src/demos/InjectMiddle.vue -->
<script setup>
import InjectLeaf from './InjectLeaf.vue'

defineProps({ sessions: Array })
</script>

<template>
  <ul>
    <InjectLeaf v-for="s in sessions" :key="s.id" :minutes="s.minutes" />
  </ul>
</template>
```

```html
<!-- src/demos/ProvideInject.vue -->
<script setup>
import { provide } from 'vue'
import InjectMiddle from './InjectMiddle.vue'
import { unitKey } from './keys.js'

provide(unitKey, 'hours')

const sessions = [
  { id: 's2', minutes: 45 },
  { id: 's4', minutes: 60 },
]
</script>

<template>
  <InjectMiddle :sessions="sessions" />
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ProvideInject'
[vite] connecting...
[vite] connected.
== the text of #app
0.75 hours
1 hours
```

The same page as the drilled version, and **`InjectMiddle` no longer mentions a unit at all.** The
parent called `provide(unitKey, 'hours')` during its setup, and each leaf called `inject(unitKey)`
during its own and got `'hours'`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two trees of the same three levels. On the left, prop drilling: the parent passes unit to the middle component as a prop, and the middle passes it on to each leaf, though it never uses it. On the right, provide and inject: the parent provides unit under a key, the middle component is not involved, and each leaf injects the value directly.\"><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">props, level by level</text><rect x=\"110\" y=\"30\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">parent</text><rect x=\"110\" y=\"105\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">middle</text><rect x=\"40\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">leaf</text><rect x=\"210\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">leaf</text><line x1=\"180\" y1=\"66\" x2=\"180\" y2=\"103\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"180\" y1=\"141\" x2=\"100\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"180\" y1=\"141\" x2=\"270\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"188\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:unit</text><text x=\"90\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:unit</text><text x=\"272\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:unit</text><rect x=\"470\" y=\"30\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">parent</text><rect x=\"470\" y=\"105\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">middle</text><rect x=\"400\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">leaf</text><rect x=\"570\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">leaf</text><line x1=\"540\" y1=\"66\" x2=\"540\" y2=\"103\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"141\" x2=\"460\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"141\" x2=\"630\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><path d=\"M468,50 C370,90 400,150 440,178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></path><path d=\"M612,50 C710,90 680,150 640,178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></path><text x=\"540\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">provide(unitKey, 'hours')</text><text x=\"540\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">inject(unitKey)</text></svg>", "caption": "With provide, the middle component no longer carries a value it does not use. It also no longer shows, anywhere, that its children need one."}
```

## How a leaf finds the value

Each component's provided values sit on top of its parent's, like a stack of transparent sheets. An
`inject` looks at the nearest ancestor that provided that key and takes its value; a component further
up providing the same key is hidden by the nearer one. That makes provide a way to **override for a
subtree**: the whole planner could provide `'minutes'`, and one panel inside it provide `'hours'` for
its own children only.

Two rules come with it, and both are about timing:

- **`provide` and `inject` are called during setup**, at the top level of `<script setup>`, like
  `watch` in lesson 4. Called later, in a click handler or a `.then()`, there is no component being
  set up to attach them to, and Vue warns.
- **A value is found only by components *below* the provider.** A sibling, or the provider's own parent,
  cannot inject it. Data that the whole application needs is provided by the root component, `App`, or
  by the application itself in `main.js` with `app.provide(key, value)`, which is how libraries such as
  the router in lesson 12 make themselves available everywhere.
