---
title: A composable that fetches
version: 1
---

**A fetching composable takes an address, which may change, and returns the data, the error and
whether it is loading, as refs; when the address changes it cancels the old request and starts a new
one.** It is lesson 4's careful watcher, wrapped once so that no component has to write it again.

```javascript
// src/demos/useFetchJson.js: fetch JSON from an address that may change.
import { ref, watchEffect, toValue, onWatcherCleanup } from 'vue'

export function useFetchJson(url) {
  const data = ref(null)
  const error = ref(null)
  const loading = ref(false)

  watchEffect(async () => {
    const address = toValue(url)
    const controller = new AbortController()
    onWatcherCleanup(() => controller.abort())
    loading.value = true
    error.value = null
    try {
      const response = await fetch(address, { signal: controller.signal })
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)
      data.value = await response.json()
    } catch (e) {
      if (e.name === 'AbortError') {
        console.log(`gave up on ${address}: a newer address was asked for`)
        return
      }
      error.value = e.message
    }
    loading.value = false
  })

  return { data, error, loading }
}
```

It is a `watchEffect`, so it runs at once and again whenever what it read before the first `await`
changes. That is only `toValue(url)`, read on the first line, on purpose: the address is the one input,
and everything after the `await` is outside the tracking window anyway. The cleanup aborts the request
of the previous run, and an aborted request is not an error the user should see, so it is logged and
dropped.

The sandbox needs something to fetch. Two small files, in its `public/notes` folder:

```json
{ "course": "statistics", "notes": ["mean", "median", "variance"] }
```

saved as `public/notes/statistics.json`, and

```json
{ "course": "spanish", "notes": ["ser and estar", "the subjunctive"] }
```

saved as `public/notes/spanish.json`. Then a component that asks for the notes of the chosen course:

```html
<!-- src/demos/FetchDemo.vue -->
<script setup>
import { ref } from 'vue'
import { useFetchJson } from './useFetchJson.js'

const course = ref('statistics')
const { data, error, loading } = useFetchJson(() => `/notes/${course.value}.json`)
</script>

<template>
  <button id="spanish" @click="course = 'spanish'">Spanish</button>
  <button id="nope" @click="course = 'nope'">A course with no notes</button>
  <p v-if="loading">Loading…</p>
  <p v-else-if="error">Could not load: {{ error }}</p>
  <p v-else-if="data">{{ data.course }}: {{ data.notes.join(', ') }}</p>
</template>
```

Three runs: as it opens, after choosing Spanish, and after choosing a course that has no notes.

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FetchDemo'
[vite] connecting...
[vite] connected.
== the text of #app
SpanishA course with no notes

statistics: mean, median, variance
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FetchDemo' --do 'click #spanish'
[vite] connecting...
[vite] connected.
-- click #spanish
== the text of #app
SpanishA course with no notes

spanish: ser and estar, the subjunctive
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FetchDemo' --do 'click #nope'
[vite] connecting...
[vite] connected.
-- click #nope
== the text of #app
SpanishA course with no notes

Could not load: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

The component has no `fetch`, no `watch` and no cleanup in it. It names its input, as a getter, and
draws the three refs it got back. **The third run is lesson 2's lesson in a new place**: the address
does not exist, the dev server answered with the page, and the composable reported the JSON error it
caused. The composable cannot tell a missing file from a broken one; only a server that answers 404
for a missing file could.

## Two improvements it does not make

A real application would want more, and each is a reason to reach for a library rather than grow this
one by hand:

- **A cache.** Two components asking for the same address make two requests. Libraries such as
  TanStack Query and Pinia Colada keep answers by address and share them.
- **A retry, and a refresh on demand.** A `refresh()` returned beside the data, as lesson 20's Nuxt
  composables do.

For the planner, which loads one file once, neither is needed. The planner's own data composable, at
the end of this lesson, is simpler still.
