---
title: Providing something that changes
version: 1
---

**`provide` hands over whatever it is given, once.** Give it a plain value and the injectors get that
value forever; give it a ref and they get the ref, and follow it as it changes. So a value that
changes is provided as a ref or a `computed`, never as `.value`, for the same reason lesson 2 gave for
passing a ref into a function.

That raises the question lesson 6 answered for props: if a child holds the parent's ref, can it write
to it? It can, unless the provider prevents it. This demo prevents it, and shows both what the child
may do and what it may not:

```html
<!-- src/demos/TotalBadge.vue -->
<script setup>
import { inject } from 'vue'
import { plannerKey } from './keys.js'

const { total, addFive } = inject(plannerKey)

function cheat() {
  total.value = 999
}
</script>

<template>
  <p id="badge">Total: {{ total }} minutes</p>
  <button id="add" @click="addFive">Add five</button>
  <button id="cheat" @click="cheat">Write to it directly</button>
</template>
```

```html
<!-- src/demos/ReactiveProvide.vue -->
<script setup>
import { ref, readonly, provide } from 'vue'
import TotalBadge from './TotalBadge.vue'
import { plannerKey } from './keys.js'

const total = ref(75)

provide(plannerKey, {
  total: readonly(total),
  addFive: () => {
    total.value += 5
  },
})
</script>

<template>
  <TotalBadge />
  <p id="owner">The provider has {{ total }}</p>
</template>
```

Add five, then try to write 999:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProvide' --do 'click #add' --do 'click #cheat'
[vite] connecting...
[vite] connected.
-- click #add
-- click #cheat
[warn] [Vue warn] Set operation on key "value" failed: target is readonly. RefImpl
== the text of #app
Total: 80 minutes

Add fiveWrite to it directly

The provider has 80
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The ReactiveProvide demo. On the left, the provider owns total, a ref that starts at 75. In the middle, what it provides under plannerKey: readonly of total, and the function addFive. On the right, TotalBadge injects both and shows Total: 80 minutes. Clicking Add five calls addFive, and the provider changes its own ref, from 75 to 80, which both show. Writing total.value equals 999 from the badge is refused, because what it holds is a read-only view of the ref.\"><rect x=\"20\" y=\"50\" width=\"180\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ReactiveProvide.vue</text><text x=\"110\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total = ref(75)</text><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">75, then 80</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">plannerKey</text><rect x=\"285\" y=\"70\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">readonly(total)</text><rect x=\"285\" y=\"112\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">addFive</text><rect x=\"520\" y=\"50\" width=\"180\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">TotalBadge.vue</text><text x=\"610\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Total: 80 minutes</text><line x1=\"202\" y1=\"96\" x2=\"266\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"266.0,96.0 258.6,99.1 258.6,92.9\" fill=\"var(--wire)\"></polygon><text x=\"234\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provide</text><line x1=\"452\" y1=\"96\" x2=\"516\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"516.0,96.0 508.6,99.1 508.6,92.9\" fill=\"var(--wire)\"></polygon><text x=\"484\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inject</text><path d=\"M 570 142 V 196 H 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"110\" y1=\"196\" x2=\"110\" y2=\"144\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"110.0,144.0 113.1,151.4 106.9,151.4\" fill=\"var(--phosphor)\"></polygon><text x=\"340\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Add five: the owner changes its own ref</text><text x=\"620\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">total.value = 999</text><text x=\"620\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused: a read-only view</text></svg>", "caption": "Provide the state read-only and the ways to change it as functions."}
```

**`Add five` worked, and both the badge and the provider show 80.** The badge called the function the
provider handed it, and the provider changed its own ref. **Writing 999 was refused** with a warning,
because the badge was given `readonly(total)`: a read-only view of the same ref, which follows every
change and accepts none.

## The pattern

Provide **the state read-only, and the operations on it as functions.** It is the props-and-emits
contract of lesson 6, stretched across the layers in between: the injector reads what it is given, and
asks for changes through functions the owner wrote. The owner keeps a single place where its state
changes, which is what makes it possible to find out later why it changed.

| provide | the injector can |
|---|---|
| `'hours'`, a plain value | read it, once; it will never change |
| `total`, a ref | read it and follow it, *and write to it*, unnoticed by the owner |
| `readonly(total)` | read it and follow it; a write is refused |
| `readonly(total)` and `addFive` | read it, follow it, and ask the owner to change it |

`readonly` works on a ref, a `reactive` object or a `computed`; a `computed` with no setter is already
read-only, which is why the planner can provide its `titles` as they are, later in this lesson.
