---
title: A computed changes nothing
version: 1
---

**A computed's function must only read and return.** It must not change reactive state, start a
request, write to storage or touch the page, because you do not decide when it runs: Vue does, lazily,
whenever somebody reads it after a change, and possibly never. Anything a computed does besides
returning a value happens at a moment nobody chose.

The dangerous case is the one that does not look like a change at all:

```html
<!-- src/demos/SortInPlace.vue -->
<script setup>
import { ref, computed } from 'vue'

const sessions = ref([
  { date: '2026-10-23', minutes: 40 },
  { date: '2026-10-19', minutes: 45 },
  { date: '2026-10-21', minutes: 60 },
])

// Wrong: sort() rearranges the array it is called on.
const byDateWrong = computed(() => sessions.value.sort((a, b) => a.date.localeCompare(b.date)))
// Right: toSorted() returns a sorted copy and leaves the original alone.
const byDate = computed(() => sessions.value.toSorted((a, b) => a.date.localeCompare(b.date)))

const first = sessions.value[0].date
</script>

<template>
  <p id="order">The data, as it was written: {{ sessions.map((s) => s.date).join(', ') }}</p>
  <p id="sorted">Sorted: {{ byDate.map((s) => s.date).join(', ') }}</p>
  <p id="wrong">Sorted with sort(): {{ byDateWrong.map((s) => s.date).join(', ') }}</p>
  <p>The first one written was {{ first }}.</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SortInPlace'
[vite] connecting...
[vite] connected.
== the text of #app
The data, as it was written: 2026-10-19, 2026-10-21, 2026-10-23

Sorted: 2026-10-19, 2026-10-21, 2026-10-23

Sorted with sort(): 2026-10-19, 2026-10-21, 2026-10-23

The first one written was 2026-10-23.
```

The first line was supposed to show the data in the order it was written, 23, 19, 21. **It shows them
sorted**, and the last line confirms that the first session written was the 23rd. `Array.prototype.sort`
rearranges the array it is called on and returns that same array, so `byDateWrong` sorted
`sessions.value` itself, through the proxy, the first time it ran. Every other reader of `sessions` got
the sorted order from then on.

Nothing warned. The page looks correct, because sorted is what you wanted to see. The damage is
elsewhere: a list the student arranged by hand comes back in a different order, a session's index no
longer points at the same session, and the bug appears in a part of the planner that never mentioned
sorting.

**`toSorted()` returns a sorted copy** and leaves the array alone, and so do `toReversed()` and
`toSpliced()`. They are in every browser since 2023 and in Node 20 and later. Where you cannot use
them, copy first: `[...sessions.value].sort(…)`. The methods that change an array in place, `sort`,
`reverse`, `splice`, `push`, `pop`, `shift`, `unshift` and `fill`, have no business inside a computed.

## No requests either

A computed is synchronous: it returns a value, and an `async` function returns a promise.

```html
<!-- src/demos/AsyncComputed.vue -->
<script setup>
import { computed } from 'vue'

const status = computed(async () => {
  const response = await fetch('/courses.json')
  return response.status
})
</script>

<template>
  <p>The request answered {{ status }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=AsyncComputed'
[vite] connecting...
[vite] connected.
== the text of #app
The request answered "[object Promise]"
```

**The value of the computed is the promise**, not what the promise will hold, and the template printed
it the only way it can print an object: `"[object Promise]"`, quotes included. The request did run, and
its answer went nowhere. Fetching is a side effect that takes time, and its place is a watcher (lesson
4) or a composable that wraps one (lesson 10).

## The test

Can you call the function ten times in a row, or not at all, and have the page be the same? If yes, it
belongs in a computed. If calling it changes anything, it does not.
