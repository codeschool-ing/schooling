---
title: deep, immediate and once
version: 1
---

**By default a watcher on a ref is shallow, lazy and permanent**: it notices only when `.value` is
replaced, it does not run until the first change, and it keeps running until the component goes
away. Three options change each of those, and it is worth seeing all five watchers below answer the
same three clicks.

```html
<!-- src/demos/DeepAndOnce.vue -->
<script setup>
import { ref, reactive, watch } from 'vue'

const sessions = ref([{ course: 'statistics', minutes: 45 }])
const plan = reactive({ sessions: [{ course: 'statistics', minutes: 45 }] })

watch(sessions, () => console.log('shallow: the ref was replaced'))
watch(sessions, () => console.log('deep: something inside changed'), { deep: true })
watch(plan, () => console.log('a reactive object: something inside changed'))
watch(sessions, () => console.log('immediate: runs at once, and on every change'), { immediate: true })
watch(sessions, () => console.log('once: the first change, and never again'), { once: true, deep: true })

function push() {
  sessions.value.push({ course: 'guitar', minutes: 20 })
  plan.sessions.push({ course: 'guitar', minutes: 20 })
}
function replace() {
  sessions.value = [...sessions.value]
}
</script>

<template>
  <button id="push" @click="push">Push a session</button>
  <button id="replace" @click="replace">Replace the list</button>
</template>
```

Push, then replace, then push again:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=DeepAndOnce' --do 'click #push' --do 'click #replace' --do 'click #push' --text -
[vite] connecting...
[vite] connected.
immediate: runs at once, and on every change
-- click #push
deep: something inside changed
once: the first change, and never again
a reactive object: something inside changed
-- click #replace
shallow: the ref was replaced
deep: something inside changed
immediate: runs at once, and on every change
-- click #push
deep: something inside changed
a reactive object: something inside changed
```

Read it by watcher:

| watcher | when the page opened | first push | replace | second push |
|---|---|---|---|---|
| plain, on the ref | | | fired | |
| `deep: true` | | fired | fired | fired |
| on a `reactive` object | | fired | | fired |
| `immediate: true` | fired | | fired | |
| `once: true` (and deep) | | fired | | |

**A plain watcher missed both pushes.** `push` changes the array that is already in `.value`; nothing
was replaced. That is lesson 3's synced-total bug, from the watcher's side.

**`deep: true` saw everything**, because Vue walks the whole value and records a read of every
property inside it, so a change anywhere is a change to the source. **A `reactive` object is watched
deeply without asking**, for the same reason: there is no `.value` to be replaced, only properties.
Notice that the reactive watcher did not fire on `replace`, which changed only the ref.

**`immediate: true` ran once at once**, before any change, and then like a plain watcher. It is for a
watcher whose job also needs doing at the start: fetch the data for the course you opened, and again
when you open another.

**`once: true` ran at the first change and never again.** Vue 3.4 added it; before that you stopped
the watcher by hand, as the stopping section of this lesson shows.

## What deep costs

To notice a change anywhere, a deep watcher reads everything, on every change: every session, every
field of every session. For six sessions that is nothing. For a list of ten thousand rows with nested
objects it is a walk of the whole tree each time one checkbox is ticked. Two cheaper habits get the
same result:

- **Replace instead of mutating**, as the planner's rules already do: `toggleDone` returns a new array,
  so a plain watcher on the ref fires, and nothing has to be walked.
- **Watch the one thing you need**, with a getter: `watch(() => sessions.value.length, …)` fires when
  the count changes and reads nothing else.

`deep` also accepts a number since Vue 3.5, `{ deep: 1 }`, for "the array and its items, but not
inside the items".
