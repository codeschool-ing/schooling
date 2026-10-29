---
title: watch, and what it can watch
version: 1
---

**A watcher runs a function of yours when a reactive value changes, and it exists for side effects:
work that reaches outside the component's own state.** Saving to storage, fetching data, calling a
library that is not Vue, moving the focus. Lesson 3 drew the line: a value that follows from other
values is a `computed`; an action that follows from a change is a watcher.

`watch(source, callback)` takes the thing to watch and the function to call. The callback receives the
new value and the old one. What counts as a source is narrower than "anything", and the three shapes it
accepts cover almost every case:

```html
<!-- src/demos/WatchSources.vue -->
<script setup>
import { ref, watch } from 'vue'

const minutes = ref(30)
const course = ref('spanish')

// A ref: the callback gets the new value and the old one.
watch(minutes, (now, before) => console.log(`minutes: ${before} -> ${now}`))

// A getter: anything computed from reactive values.
watch(
  () => minutes.value >= 60,
  (long) => console.log(`at least an hour: ${long}`),
)

// An array of sources: fires when any of them changes.
watch([course, minutes], ([c, m]) => console.log(`now ${c} for ${m} minutes`))

function longer() {
  minutes.value += 15
}
</script>

<template>
  <p>{{ course }}, {{ minutes }} minutes</p>
  <button id="longer" @click="longer">15 more</button>
  <button id="guitar" @click="course = 'guitar'">Guitar</button>
</template>
```

Start the sandbox in a second terminal, and click `15 more` twice, then `Guitar`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=WatchSources' --do 'click #longer' --do 'click #longer' --do 'click #guitar' --text -
[vite] connecting...
[vite] connected.
-- click #longer
minutes: 30 -> 45
now spanish for 45 minutes
-- click #longer
minutes: 45 -> 60
at least an hour: true
now spanish for 60 minutes
-- click #guitar
now guitar for 60 minutes
```

`--text -` tells `look` to print no text at the end, because here only the console matters.

## The three shapes

- **A ref.** `watch(minutes, …)` fires when `minutes.value` is replaced, and hands over `now` and
  `before`: 30 → 45, then 45 → 60. Pass the ref itself, never `minutes.value`: that is the number 30,
  and a number cannot be watched. Vue warns if you try.
- **A getter**, a function returning a value worked out from reactive state. Vue runs it, records
  what it read, and calls your callback **only when its result changes**. That is why `at least an
  hour` printed once, at 60, and not at 45: the getter returned `false` both times before.
- **An array of sources**, for "when any of these changes". The callback receives an array of new
  values in the same order. `Guitar` changed only `course`, and the third watcher fired with both
  values.

The getter is the one to reach for when the thing you care about is a property: `watch(() =>
props.courseId, …)` in lesson 6, or `watch(() => route.params.id, …)` in lesson 12. Writing
`watch(route.params.id, …)` instead passes a string, which is the same mistake as `minutes.value`.

## What the callback should not do

The callback runs after the change, outside any render. It may assign to refs, and that is allowed;
but if all it does is assign a value worked out from the source, you have rebuilt the synced-total
demo of lesson 3, with both of its defects. **Ask what the callback does that the screen cannot see.**
If the answer is nothing, it is a computed.
