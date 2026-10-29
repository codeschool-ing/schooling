---
title: When a watcher is the wrong tool
version: 1
---

**The most common misuse of a watcher is keeping one piece of state in step with another, which is
what a computed is for.** It looks reasonable: when the sessions change, recompute the total and store
it. It has two defects, and this demo shows both at once.

```html
<!-- src/demos/SyncedByWatch.vue -->
<script setup>
import { ref, watch } from 'vue'

const sessions = ref([
  { course: 'statistics', minutes: 45 },
  { course: 'spanish', minutes: 30 },
])

// The wrong tool: a second piece of state, kept in step by hand.
const total = ref(0)
watch(sessions, (list) => {
  total.value = list.reduce((sum, s) => sum + s.minutes, 0)
  console.log(`watcher set total to ${total.value}`)
})

function shown() {
  console.log(`render shows total = ${total.value}`)
  return total.value
}
function addGuitar() {
  sessions.value.push({ course: 'guitar', minutes: 20 })
}
function replaceAll() {
  sessions.value = [...sessions.value, { course: 'guitar', minutes: 20 }]
}
</script>

<template>
  <p>Planned: {{ shown() }} minutes</p>
  <button id="push" @click="addGuitar">Add guitar (push)</button>
  <button id="replace" @click="replaceAll">Add guitar (replace)</button>
</template>
```

Click the first button, then the second:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SyncedByWatch' --do 'click #push' --do 'click #replace'
[vite] connecting...
[vite] connected.
render shows total = 0
-- click #push
-- click #replace
watcher set total to 115
render shows total = 115
== the text of #app
Planned: 115 minutes

Add guitar (push)Add guitar (replace)
```

**The first render said 0.** The watcher runs only when its source changes, not when it is created, so
until something changed, `total` held its starting value while the page showed two sessions. The
correct number existed nowhere.

**Then `push` changed nothing at all.** No `watcher set total` line follows it. A watcher on a ref fires
when `.value` is replaced, and `push` adds an item to the array that is already there. The total was
now wrong by 20 minutes, silently. Only the second button, which built a new array and assigned it,
woke the watcher, and the total finally caught up with both additions at once: 115.

Both defects have fixes, `{ immediate: true }` and `{ deep: true }`, which lesson 4 explains. But
**each fix answers a symptom of having a second copy of the value**. With a computed there is nothing
to keep in step:

```javascript
const total = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0))
```

It is correct on the first render, because it is worked out the first time it is read. It notices the
`push`, because the `reduce` read every item through the proxy. And it can never be out of date,
because there is no stored copy to be out of date.

## The rule of thumb

| you want | use |
|---|---|
| a value that follows from other values | `computed` |
| to **do** something when a value changes: save it, fetch something, call a library, move focus | a watcher, lesson 4 |

A watcher is for side effects, things that reach outside the component's own state. If the body of
your watcher only assigns to another ref, it was a computed all along.
