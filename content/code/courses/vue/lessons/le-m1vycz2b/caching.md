---
title: The cache, and when it is emptied
version: 1
---

**A computed runs its function lazily and caches the result.** Lazily: not when its inputs change, but
the next time somebody reads it. Cached: until one of the reactive values it read during its last run
changes, every read returns the stored result without running anything.

That is two claims, and both can be seen:

```html
<!-- src/demos/LazyComputed.vue -->
<script setup>
import { ref, computed } from 'vue'

const minutes = ref(90)
const showHours = ref(false)

const hours = computed(() => {
  console.log(`computing hours from ${minutes.value}`)
  return minutes.value / 60
})

function change() {
  minutes.value += 30
  minutes.value += 30
  console.log('two changes made')
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <p v-if="showHours">{{ hours }} hours</p>
  <button id="change" @click="change">Add an hour</button>
  <button id="show" @click="showHours = true">Show hours</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LazyComputed' --do 'click #change' --do 'click #show' --do 'click #change'
[vite] connecting...
[vite] connected.
-- click #change
two changes made
-- click #show
computing hours from 150
-- click #change
two changes made
computing hours from 210
== the text of #app
210 minutes

3.5 hours

Add an hourShow hours
```

Step by step:

1. **Nothing was computed when the page opened.** `hours` is only shown under `v-if="showHours"`, which
   is false, so nobody read it, so its function never ran.
2. The first click changed `minutes` twice. Still nothing: a computed nobody reads is never worked out.
3. **`Show hours` read it for the first time**, and it was computed once, from 150, the value at that
   moment.
4. The second click on `Add an hour` added another hour in two steps, and `hours` was computed **once**,
from
   210. The two writes marked it stale; the redraw read it once.

## How it knows what it depends on

There is no list of dependencies to write, and that is not magic. While the function runs, Vue
records every reactive value it reads, exactly as it does for a render (lesson 2). **The dependencies
are whatever the last run read.** A computed with a condition in it depends on different things at
different times:

```javascript
const label = computed(() => (showHours.value ? `${hours.value} hours` : `${minutes.value} minutes`))
```

While `showHours` is false, `label` depends on `showHours` and `minutes`, and changing `hours` does not
recompute it. That is correct, since `hours` was not used, and it is also why a computed must read its
inputs *every time it runs*. A value read once into a variable outside the function, and used inside
it, is a copy, and the computed will never notice it change.

## What it costs

A computed holds its last result and the list of what it read. That is a small object per computed, and
the work of checking whether it is stale is cheaper than redoing almost any calculation. **There is no
reason to avoid `computed` for small things**; the reason to use it is not speed but correctness, and
speed comes along.

One case is worth knowing: a computed that returns a **new object** every time, like the planner's
per-course totals (section 07 of this lesson), makes everything that reads it redraw whenever it is
recomputed, even when the numbers inside came out the same. Vue 3.4 and later compare the old and new
results and skip the redraw for an unchanged number or string; for a new object they cannot know
without looking inside, and they do not look.
