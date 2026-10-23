---
title: When the callback runs
version: 1
---

**A watcher's callback does not run at the moment the value changes.** Like a render, it is queued
(lesson 2), and the `flush` option says where in the queue it goes: before the component redraws,
after it, or at once, on every single write.

```html
<!-- src/demos/FlushTiming.vue -->
<script setup>
import { ref, watch } from 'vue'

const count = ref(0)
const page = () => document.querySelector('output').textContent

watch(count, (n) => console.log(`pre:  count ${n}, page says ${page()}`))
watch(count, (n) => console.log(`post: count ${n}, page says ${page()}`), { flush: 'post' })
watch(count, (n) => console.log(`sync: count ${n}, page says ${page()}`), { flush: 'sync' })

function addTwo() {
  count.value++
  count.value++
}
</script>

<template>
  <output>{{ count }}</output>
  <button @click="addTwo">Add two</button>
</template>
```

One click, two increments:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FlushTiming' --do 'click button' --text -
[vite] connecting...
[vite] connected.
-- click button
sync: count 1, page says 0
sync: count 2, page says 0
pre:  count 2, page says 0
post: count 2, page says 2
```

| `flush` | ran | saw the page say | use it for |
|---|---|---|---|
| `'sync'` | twice, once per write, at the moment of writing | 0 | almost nothing; see below |
| `'pre'`, the default | once, with the final value, **before** the redraw | 0 | work that only needs the values, which is most of it |
| `'post'` | once, **after** the redraw | 2 | work that needs the page as the change left it: measuring, scrolling, focusing |

`'pre'` is the default because most watchers do not touch the page, and running them before the
redraw lets them change state that the same redraw will then show, in one pass instead of two.

**`'post'` is for reading the DOM.** A watcher that scrolls a list to the session just added needs that
session's element to exist, and it exists only after the redraw. `watchPostEffect` is `watchEffect`
with `flush: 'post'` already set.

**`'sync'` gives up the batching** that the queue exists for. It ran twice for two writes, and a loop
of a hundred writes would run it a hundred times. It is for the rare watcher that must see every
intermediate value, such as a log of every change; it is never the fix for a watcher that "runs too
late", which is a `'post'` problem or a `computed` problem.
