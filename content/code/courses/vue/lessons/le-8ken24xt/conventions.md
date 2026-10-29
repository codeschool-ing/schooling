---
title: The conventions
version: 1
---

**Composables are only a convention, so the conventions are what make one predictable to use.** Three
of them do most of the work: the name starts with `use`; the inputs may be refs, getters or plain
values; the result is a plain object of refs.

## Inputs: accept a ref, a getter or a value

A composable that computes something from its input should follow the input when it changes. If it is
given a ref, it should read the ref inside a `computed` or a watcher; if a getter, call it there; if a
plain value, use it. `toValue()` does all three, so the composable does not have to care which it got:

```javascript
// src/demos/useHours.js: minutes as hours, from a ref, a getter or a plain number.
import { computed, toValue } from 'vue'

export function useHours(minutes) {
  return computed(() => (toValue(minutes) / 60).toFixed(2))
}
```

```html
<!-- src/demos/Conventions.vue -->
<script setup>
import { ref } from 'vue'
import { useHours } from './useHours.js'

const minutes = ref(90)
const fromRef = useHours(minutes)
const fromGetter = useHours(() => minutes.value * 2)
const fromNumber = useHours(minutes.value)
</script>

<template>
  <p>From the ref: {{ fromRef }}</p>
  <p>From a getter: {{ fromGetter }}</p>
  <p>From a number: {{ fromNumber }}</p>
  <button @click="minutes += 30">30 more</button>
</template>
```

The page opens with 90 minutes, and one click adds 30:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Conventions' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
From the ref: 2.00

From a getter: 4.00

From a number: 1.50

30 more
```

**The ref and the getter followed the click; the number did not.** `useHours(minutes.value)` passed 90,
a plain number, and a number cannot change, so the hours stayed at 1.50. That is lesson 2's rule again,
at a composable's door: pass the ref, or a getter, and the composable can follow it.

## Output: a plain object of refs

Return `{ data, error, loading }`, each a ref, rather than `reactive({ data, error, loading })`. A
plain object of refs can be destructured, `const { data } = useFetchJson(…)`, and each piece stays
reactive, because each piece *is* a ref. A reactive object loses its reactivity on destructuring, as
lesson 2 showed, which would make every caller remember not to.

## The rest, briefly

| convention | why |
|---|---|
| the name starts with `use` | a reader knows it must be called during setup |
| called at the top level of setup, never in a handler or a callback that runs later | its watchers and hooks are tied to the component being set up (lesson 4, and the lifecycle section of this lesson) |
| one file per composable, in `src/composables` | they are found, and imported, by name |
| it cleans up whatever it starts | the caller should not have to know that a timer exists |

The library **VueUse** is a collection of some two hundred composables written to these conventions:
the window's size, the mouse, local storage, the network, the clock. Before writing a general one, look
there; for one that knows about your application, like the planner's data, write your own.
