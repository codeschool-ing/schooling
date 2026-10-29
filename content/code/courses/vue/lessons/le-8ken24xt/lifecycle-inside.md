---
title: Hooks inside a composable
version: 1
---

**A composable can call `onMounted` and `onUnmounted`, and they attach to the component that called the
composable.** That is what lets a composable start something and clean up after itself, with the
calling component none the wiser. It is also the source of the one rule a composable cannot break: it
must be called while a component is being set up.

```javascript
// src/demos/useTicker.js: a timer that belongs to whichever component calls it.
import { ref, onMounted, onUnmounted } from 'vue'

export function useTicker(name) {
  const ticks = ref(0)
  let timer
  onMounted(() => {
    timer = setInterval(() => ticks.value++, 100)
    console.log(`${name}: started`)
  })
  onUnmounted(() => {
    clearInterval(timer)
    console.log(`${name}: stopped after ${ticks.value} ticks`)
  })
  return ticks
}
```

A component that uses it, and a parent with two of them and a button that calls the composable at the
wrong moment:

```html
<!-- src/demos/TickerUser.vue -->
<script setup>
import { useTicker } from './useTicker.js'

const { name } = defineProps({ name: String })
const ticks = useTicker(name)
</script>

<template>
  <p>{{ name }}: {{ ticks }}</p>
</template>
```

```html
<!-- src/demos/LifecycleInside.vue -->
<script setup>
import { ref } from 'vue'
import TickerUser from './TickerUser.vue'
import { useTicker } from './useTicker.js'

const shown = ref(true)

function tooLate() {
  useTicker('called from a click')
}
</script>

<template>
  <template v-if="shown">
    <TickerUser name="first" />
    <TickerUser name="second" />
  </template>
  <button id="remove" @click="shown = false">Remove both</button>
  <button id="late" @click="tooLate">Call the composable from a click</button>
</template>
```

Let them tick, remove them, and then press the second button:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LifecycleInside' --do 'wait 300' --do 'click #remove' --do 'click #late' --text -
[vite] connecting...
[vite] connected.
first: started
second: started
-- wait 300
-- click #remove
first: stopped after 9 ticks
second: stopped after 9 ticks
-- click #late
[warn] [Vue warn]: onMounted is called when there is no active component instance to be associated with. Lifecycle injection APIs can only be used during execution of setup(). If you are using async setup(), make sure to register lifecycle hooks before the first await statement.
[warn] [Vue warn]: onUnmounted is called when there is no active component instance to be associated with. Lifecycle injection APIs can only be used during execution of setup(). If you are using async setup(), make sure to register lifecycle hooks before the first await statement.
```

**Each component got its own timer, started when it was mounted and stopped when it was removed**, and
neither `TickerUser` contains a line about timers. The hooks inside `useTicker` were registered while
`TickerUser` was being set up, so Vue attached them to that `TickerUser`.

**Called from a click, the same composable could attach its hooks to nothing**, and Vue said so twice,
once per hook: `no active component instance to be associated with`. The timer it meant to start never
started, because `onMounted` never ran. The warning is explicit about why, and mentions the other way
to get here: a hand-written `async setup()` function that calls the composable after an `await`.
`<script setup>` is spared that one, because its compiler puts the component back after a top-level
`await`; lesson 15 meets that compiler at work.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two cases. Above: TickerUser&#x27;s setup calls useTicker, which calls onMounted and onUnmounted while TickerUser is the component being set up, so both hooks are attached to TickerUser and run when it is mounted and removed. Below: a click handler calls useTicker after setup is over; no component is being set up, so the hooks attach to nothing, Vue warns, and the timer never starts.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">during setup: the hooks find their component</text><rect x=\"40\" y=\"46\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">TickerUser</text><rect x=\"250\" y=\"46\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">useTicker()</text><rect x=\"460\" y=\"46\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onMounted</text><text x=\"570\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onUnmounted</text><line x1=\"192\" y1=\"68\" x2=\"248\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,68.0 240.6,71.1 240.6,64.9\" fill=\"var(--wire)\"></polygon><line x1=\"402\" y1=\"68\" x2=\"458\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"458.0,68.0 450.6,71.1 450.6,64.9\" fill=\"var(--wire)\"></polygon><path d=\"M570,44 C560,26 140,26 120,44\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"124\" y1=\"40\" x2=\"120\" y2=\"45\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"120.0,45.0 122.2,37.3 127.0,41.2\" fill=\"var(--phosphor)\"></polygon><rect x=\"20\" y=\"130\" width=\"680\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">from a click: nobody is being set up</text><rect x=\"40\" y=\"160\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">@click</text><rect x=\"250\" y=\"160\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">useTicker()</text><rect x=\"460\" y=\"160\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"570\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">onMounted</text><text x=\"570\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">[Vue warn]: no instance</text><line x1=\"192\" y1=\"182\" x2=\"248\" y2=\"182\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,182.0 240.6,185.1 240.6,178.9\" fill=\"var(--wire)\"></polygon><line x1=\"402\" y1=\"182\" x2=\"458\" y2=\"182\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"458.0,182.0 450.6,185.1 450.6,178.9\" fill=\"var(--wire)\"></polygon></svg>", "caption": "A composable's hooks belong to whichever component is being set up when it is called, and to nothing if none is."}
```

## The rule, and how to keep it

**Call composables at the top level of `<script setup>`.** Not in a handler, not in a
`setTimeout`, not in a `.then()`. When something needs to happen later, call the composable during
setup and have it return a function that does the later part, as `useWeek` returns `next`.

React has a rule that sounds the same and is not: the next section is the comparison.
