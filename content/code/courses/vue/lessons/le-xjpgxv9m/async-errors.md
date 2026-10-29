---
title: When the waiting fails
version: 1
---

**An async setup that throws, a request that fails or a JSON that does not parse, rejects; and a
rejection is caught by the nearest ancestor with `onErrorCaptured`.** `<Suspense>` itself has no error
slot, so the error state is a component's job: catch, remember, and draw something else instead of the
Suspense.

```html
<!-- src/demos/ErrorsDemo.vue -->
<script setup>
import { ref, onErrorCaptured } from 'vue'
import SlowCourse from './SlowCourse.vue'

const problem = ref('')
onErrorCaptured((error) => {
  problem.value = `The notes could not be loaded: ${error.message}`
  return false
})
</script>

<template>
  <p v-if="problem" role="alert">{{ problem }}</p>
  <Suspense v-else>
    <SlowCourse id="guitar" />
    <template #fallback><p>Loading the notes…</p></template>
  </Suspense>
</template>
```

Guitar has no notes file:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ErrorsDemo'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of #app
The notes could not be loaded: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

The address `/notes/guitar.json` does not exist, the dev server answered with the page, as lesson 2
showed, and `response.json()` failed on the `<`. The error travelled up from `SlowCourse`, through the
Suspense, to `ErrorsDemo`'s `onErrorCaptured`, which stored the message and returned `false`.

## What the hook receives and returns

`onErrorCaptured((error, instance, info) => …)` receives the error, the component that threw it, and a
short string saying where it was thrown, a setup function, a render, a watcher. It runs for errors in
any descendant, and **returning `false` stops the error from going further**: without it, the error would
continue up to the application's own handler, `app.config.errorHandler`, and be logged as uncaught as
well as handled.

Two habits make it work:

- **Put the boundary where the student can still do something**: around the part of the page that
  failed, so the rest keeps working, with a message that says what is missing. A boundary at the root
  turns any small failure into a blank application.
- **Show the error in a live region**, `role="alert"` as the demo does, so a screen reader announces it
  when it replaces the loading text.

React has the same idea under the name *error boundary*, and `react-ts` gives it a lesson of its own;
in Vue it is a hook any component can use, rather than a special kind of component.
