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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"One click on Add three, in time order from left to right, on three rows. On the first row, the click&#x27;s code: count.value++ three times, then the log saying count is 3 and the page still says 0, then await nextTick. On the second row, Vue&#x27;s queue: the three writes queued one render, and it runs once, with count equal to 3, when the click&#x27;s code has paused at the await. Then the code resumes and the page says 3. On the third row, the output element: it says 0 until that one render, and 3 after it.\"><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">addThree()</text><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">queue</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;output&gt;</text><rect x=\"110\" y=\"40\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"127\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">++</text><line x1=\"127\" y1=\"72\" x2=\"150\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"150\" y=\"40\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"167\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">++</text><line x1=\"167\" y1=\"72\" x2=\"150\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"190\" y=\"40\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"207\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">++</text><line x1=\"207\" y1=\"72\" x2=\"150\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"100\" y=\"108\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"160\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1 render queued</text><rect x=\"230\" y=\"40\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">logs: the page still says 0</text><rect x=\"400\" y=\"40\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">await nextTick()</text><line x1=\"502\" y1=\"62\" x2=\"525\" y2=\"106\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"525.0,106.0 518.8,100.9 524.3,98.0\" fill=\"var(--phosphor)\"></polygon><rect x=\"505\" y=\"108\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">render with count = 3</text><line x1=\"627\" y1=\"110\" x2=\"640\" y2=\"74\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"640.0,74.0 640.4,82.0 634.6,79.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"628\" y=\"40\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"670\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the page says 3</text><rect x=\"100\" y=\"176\" width=\"523\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"361\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><rect x=\"627\" y=\"176\" width=\"83\" height=\"28\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><line x1=\"100\" y1=\"226\" x2=\"710\" y2=\"226\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"710.0,226.0 702.6,229.1 702.6,222.9\" fill=\"var(--wire)\"></polygon><text x=\"405\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one click, in time order</text></svg>", "caption": "Three writes queue one render; nextTick waits for it."}
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
