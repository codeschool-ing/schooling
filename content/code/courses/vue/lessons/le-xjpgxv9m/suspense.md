---
title: Suspense, and a setup that waits
version: 1
---

**A component whose `<script setup>` uses `await` at the top level is an *async component*: it cannot be
drawn until its setup has finished. `<Suspense>` is the component that waits for every async component
inside it, shows a fallback meanwhile, and swaps in the real content when all of them are ready.** It
lets a component load its own data with a plain `await`, instead of the loading flags of lesson 10's
`useFetchJson`.

A course's notes, loaded at the top level of the component:

```html
<!-- src/demos/SlowCourse.vue -->
<script setup>
import { onMounted } from 'vue'

const { id } = defineProps({ id: String })

// A top-level await: this component's setup is asynchronous.
const response = await fetch(`/notes/${id}.json`)
const notes = await response.json()

// Registered after the await, and still attached to this component.
onMounted(() => console.log(`${id}: mounted with ${notes.notes.length} notes`))
</script>

<template>
  <p>{{ notes.course }}: {{ notes.notes.join(', ') }}</p>
</template>
```

A fallback that announces itself, and the demo that uses both:

```html
<!-- src/demos/LoadingNote.vue -->
<script setup>
import { onMounted, onUnmounted } from 'vue'

onMounted(() => console.log('fallback shown'))
onUnmounted(() => console.log('fallback removed'))
</script>

<template>
  <p>Loading the notes…</p>
</template>
```

```html
<!-- src/demos/SuspenseDemo.vue -->
<script setup>
import SlowCourse from './SlowCourse.vue'
import LoadingNote from './LoadingNote.vue'
</script>

<template>
  <Suspense @resolve="console.log('every async child is ready')">
    <div>
      <SlowCourse id="statistics" />
      <SlowCourse id="spanish" />
    </div>
    <template #fallback>
      <LoadingNote />
    </template>
  </Suspense>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SuspenseDemo'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
fallback shown
every async child is ready
statistics: mounted with 3 notes
spanish: mounted with 2 notes
fallback removed
== the text of #app
statistics: mean, median, variance

spanish: ser and estar, the subjunctive
```

The order of the lines is the mechanism: **the fallback was shown first; then both courses resolved,
and the `resolve` event said so; then both were mounted, and the fallback removed.** The two requests ran
in parallel, and `<Suspense>` waited for the slower before showing either, so the page never showed one
course with a gap where the other would be.

The first line of the console is a message Vue prints as information, and it is Vue being honest: **Suspense is still marked
experimental**, years after it arrived, and its API may change. It is widely used, and Nuxt builds on it
(lesson 20); write it knowing that.

## The await that keeps its component

Lesson 10 said that a composable or a hook called after an `await` can lose its component, and that
`<script setup>` is spared. `SlowCourse` registers `onMounted` after two `await`s, and the transcript
shows it ran. Ask the dev server what the compiler made of the script:

```
ana@dev:~/vue/sandbox$ curl -s 'http://localhost:5173/src/demos/SlowCourse.vue' | grep -n withAsyncContext
1:import { createHotContext as __vite__createHotContext } from "/@vite/client";import.meta.hot = __vite__createHotContext("/src/demos/SlowCourse.vue");import { withAsyncContext as _withAsyncContext } from "/node_modules/.vite/deps/vue.js?v=cfa4ec68"
17:  ([__temp,__restore] = _withAsyncContext(() => fetch(`/notes/${__props.id}.json`))),
23:  ([__temp,__restore] = _withAsyncContext(() => response.json())),
```

**Each `await` was wrapped in `_withAsyncContext`**, a function that saves which component is being set
up before the `await` and puts it back after it. That is why the `onMounted` found its component. A
hand-written `async setup()` function has no compiler to do this, and that is the case the warning of
lesson 10 described.

## When to use it

Suspense suits data a component cannot draw anything useful without, loaded once: a page's main data, a
detail view. It does not suit data that changes as the student types, because a Suspense that has
resolved does not, by default, show its fallback again for an update; that is a job for a watcher and a loading flag,
lesson 10. And every async component needs a `<Suspense>` above it: without one, Vue warns that no Suspense
boundary was found, and the component draws nothing.
