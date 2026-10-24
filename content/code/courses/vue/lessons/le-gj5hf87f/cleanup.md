---
title: Cleaning up after a watcher
version: 1
---

**A watcher that starts something slow must be able to cancel it when the next change arrives, or the
older answer can land after the newer one and win.** This is the most common real bug in watchers,
because it never shows on a fast machine with a fast network, and it shows on a phone on a train.

The demo has a pretend server in which statistics answers in 600 milliseconds and everything else in
100. Two watchers ask it for notes whenever the course changes; one cleans up and one does not:

```html
<!-- src/demos/StaleAnswer.vue -->
<script setup>
import { ref, watch, onWatcherCleanup } from 'vue'

// A pretend server: statistics answers slowly, everything else quickly.
function lookUp(course) {
  const delay = course === 'statistics' ? 600 : 100
  return new Promise((resolve) => setTimeout(() => resolve(`notes for ${course}`), delay))
}

const course = ref('guitar')
const careless = ref('')
const careful = ref('')

watch(course, async (c) => {
  careless.value = await lookUp(c)
})

watch(course, async (c) => {
  let stale = false
  onWatcherCleanup(() => {
    stale = true
  })
  const answer = await lookUp(c)
  if (stale) {
    console.log(`dropped the answer for ${c}: a newer question was asked`)
    return
  }
  careful.value = answer
})
</script>

<template>
  <p id="careless">Without cleanup: {{ careless }}</p>
  <p id="careful">With cleanup: {{ careful }}</p>
  <button id="stats" @click="course = 'statistics'">Statistics</button>
  <button id="spanish" @click="course = 'spanish'">Spanish</button>
</template>
```

Choose statistics, then change your mind at once and choose Spanish, and wait for both answers:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=StaleAnswer' --do 'click #stats' --do 'click #spanish' --do 'wait 800'
[vite] connecting...
[vite] connected.
-- click #stats
-- click #spanish
-- wait 800
dropped the answer for statistics: a newer question was asked
== the text of #app
Without cleanup: notes for statistics

With cleanup: notes for spanish

StatisticsSpanish
```

**The careless watcher shows the notes for statistics, while the course chosen is Spanish.** Both
requests were in flight; Spanish answered after 100 milliseconds and was shown; statistics answered
500 milliseconds later and overwrote it. Nothing failed, and the screen is wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline from 0 to 700 milliseconds. At 0 the course becomes statistics and its request starts; it answers at 600. Almost at once the course becomes Spanish and its request starts; it answers about 100 milliseconds later. The careless watcher shows Spanish when it arrives, and then statistics at 600, which is wrong. The careful watcher&#x27;s cleanup marked the statistics run stale when Spanish was chosen, so at 600 it drops the answer and keeps Spanish.\"><line x1=\"150.0\" y1=\"220\" x2=\"710.0\" y2=\"220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"710.0,220.0 702.6,223.1 702.6,216.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"150.0\" y1=\"215\" x2=\"150.0\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"150.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><line x1=\"230.0\" y1=\"215\" x2=\"230.0\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"230.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms</text><line x1=\"630.0\" y1=\"215\" x2=\"630.0\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"630.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600 ms</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">statistics asked</text><rect x=\"150.0\" y=\"30\" width=\"480.0\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">slow answer</text><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanish asked</text><rect x=\"154.0\" y=\"65\" width=\"80.0\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">without cleanup</text><rect x=\"234.0\" y=\"113\" width=\"396.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">shows Spanish</text><rect x=\"630.0\" y=\"113\" width=\"80.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"670.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">statistics</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">with cleanup</text><rect x=\"234.0\" y=\"158\" width=\"476.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">shows Spanish</text><line x1=\"630.0\" y1=\"52\" x2=\"630.0\" y2=\"155\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"626.0\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">stale: dropped</text></svg>", "caption": "The answers arrive in the order the server finishes them, not the order they were asked. Only the cleanup knows which question is still current."}
```

## onWatcherCleanup

`onWatcherCleanup(fn)`, from Vue 3.5, registers a function that Vue calls **just before the watcher
runs again, and when it is stopped**. Called inside the callback, it belongs to that run. So when
Spanish was chosen, Vue first ran the cleanup of the statistics run, which set its `stale` flag, and
then started the Spanish run. When the statistics answer finally came, its run saw `stale` and threw
the answer away, and the console says so.

Two details matter:

- **Register the cleanup before the first `await`.** Like tracking in `watchEffect`, the cleanup is
  tied to the run while the callback is running synchronously; registered after an `await`, Vue
  cannot tell which run it belongs to, and warns.
- **Before 3.5**, and in code you will read, the same function arrives as the third argument of the
  callback: `watch(course, async (c, old, onCleanup) => { onCleanup(() => { stale = true }) … })`.
  It does the same thing.

## Cancelling for real

A flag ignores the late answer; the request still runs to the end. With `fetch`, an `AbortController`
stops it:

```javascript
watch(course, async (c) => {
  const controller = new AbortController()
  onWatcherCleanup(() => controller.abort())
  const response = await fetch(`/notes/${c}.json`, { signal: controller.signal })
  notes.value = await response.json()
})
```

`controller.abort()` makes the pending `fetch` reject with an `AbortError`, so the lines after it never
run for the stale course. Lesson 10 wraps exactly this into a composable, so that each component that
fetches does not write it again.
