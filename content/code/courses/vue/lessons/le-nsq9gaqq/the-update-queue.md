---
title: The update queue, and nextTick
version: 1
---

**Changing a ref does not redraw the page at once.** Vue notes which renders need to run again,
puts them in a queue, and runs the queue once your code has finished, in what JavaScript calls a
microtask. So three changes in a row cause one redraw, not three, and the page you read in the same
function still shows the old value.

```html
<!-- src/demos/UpdateQueue.vue -->
<script setup>
import { ref, nextTick } from 'vue'

const count = ref(0)

function shown() {
  console.log(`render with count = ${count.value}`)
  return count.value
}

async function addThree() {
  count.value++
  count.value++
  count.value++
  const onPage = document.querySelector('output').textContent
  console.log(`count is ${count.value}, the page still says ${onPage}`)
  await nextTick()
  console.log(`after nextTick the page says ${document.querySelector('output').textContent}`)
}
</script>

<template>
  <output>{{ shown() }}</output>
  <button @click="addThree">Add three</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=UpdateQueue' --do 'click button'
[vite] connecting...
[vite] connected.
render with count = 0
-- click button
count is 3, the page still says 0
render with count = 3
after nextTick the page says 3
== the text of #app
3Add three
```

The order of the lines is the lesson:

1. `render with count = 0` is the first draw.
2. After three increments, **`count` is 3 and the `<output>` still says 0**. The value changed; the
   page has not been redrawn yet.
3. **`render with count = 3` appears once**, not three times. The three writes queued one redraw, and
   it ran with the final value.
4. `await nextTick()` waited for that redraw, and after it the page says 3.

`javascript` lesson 13, on the event loop, described microtasks: work that runs after the current task
and before the browser does anything else. Vue's queue is one of them. **`nextTick()` returns a
promise that resolves after the queue has run**, so the code after `await nextTick()` sees the page
as the change left it.

## When you need it

Rarely, and almost always to touch the DOM directly after a change: to focus a field that a change
has just made appear, to measure an element's new size, to scroll a list to an item that was just
added. Lesson 9 does the first one with a template ref.

If you find yourself reaching for `nextTick` to make a *value* correct, the value is being computed
in the wrong place. Values belong in `computed`, which is never stale; `nextTick` is only about the
page catching up.
