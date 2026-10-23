---
title: Stopping a watcher
version: 1
---

**A watcher created while a component is being set up belongs to that component, and stops when the
component is removed.** A watcher created at any other time belongs to nobody, and runs until the page
is closed. That is the whole rule, and the second half is a memory leak waiting for a component that
is shown and hidden a hundred times.

The demo has a ref in a module of its own, so that it outlives any component:

```javascript
// src/demos/clock.js: one ref shared by every component that imports it.
import { ref } from 'vue'

export const tick = ref(0)
```

A component that watches it three ways:

```html
<!-- src/demos/Listener.vue -->
<script setup>
import { watch } from 'vue'
import { tick } from './clock.js'

// Created during setup: stopped when this component goes away.
watch(tick, (n) => console.log(`setup watcher saw tick ${n}`))

// Created later, after the component exists: belongs to nobody.
setTimeout(() => {
  watch(tick, (n) => console.log(`late watcher saw tick ${n}`))
}, 0)

// Created during setup and stopped by hand, after the first change.
const stop = watch(tick, (n) => {
  console.log(`stoppable watcher saw tick ${n}, and stops`)
  stop()
})
</script>

<template>
  <p>The listener is here.</p>
</template>
```

And a parent that can tick the clock and remove the listener:

```html
<!-- src/demos/StopWatching.vue -->
<script setup>
import { ref } from 'vue'
import Listener from './Listener.vue'
import { tick } from './clock.js'

const shown = ref(true)
</script>

<template>
  <Listener v-if="shown" />
  <button id="tick" @click="tick++">Tick</button>
  <button id="remove" @click="shown = false">Remove the listener</button>
</template>
```

Tick twice, remove the listener, and tick again:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=StopWatching' --do 'click #tick' --do 'click #tick' --do 'click #remove' --do 'click #tick'
[vite] connecting...
[vite] connected.
-- click #tick
late watcher saw tick 1
setup watcher saw tick 1
stoppable watcher saw tick 1, and stops
-- click #tick
late watcher saw tick 2
setup watcher saw tick 2
-- click #remove
-- click #tick
late watcher saw tick 3
== the text of #app
TickRemove the listener
```

**After the listener was removed, the late watcher still saw tick 3.** The component is gone from the
page, and a function inside it is still running on every change, holding on to everything it can
reach. The watcher created during setup stopped with the component, as it should.

## Why "during setup" decides it

`<script setup>` runs synchronously, and while it runs Vue knows which component is being set up. A
watcher created in that window is registered with that component, and removing the component stops it.
The `setTimeout` callback ran a moment later, when no component was being set up, so its watcher was
registered with nothing. The same is true of a watcher created after an `await` in setup, or inside a
`.then()`: **if you cannot see it at the top level of the script, assume it will not stop itself.**

## Stopping one by hand

`watch` and `watchEffect` both return a function that stops the watcher. The third watcher called it
from inside its own callback, after the first tick, and never ran again. Two cases need it:

- a watcher created late, as above: keep the stop function and call it when the component is removed
  (lesson 9's `onUnmounted` is where);
- a watcher that has done its job: wait for a value to appear, act once, stop. `{ once: true }` is the
  shorter way to say that, since Vue 3.4.

Vue 3.5 also lets you `pause()` and `resume()` a watcher through the same handle, for a watcher that
should sleep while, say, a panel is collapsed, without losing its place.
