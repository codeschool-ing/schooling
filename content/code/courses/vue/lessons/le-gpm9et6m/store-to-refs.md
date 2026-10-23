---
title: storeToRefs, and the destructuring trap again
version: 1
---

**A store is a reactive object, so destructuring it hands out plain values that never change.**
`const { done } = store` reads `store.done` once. To take pieces out of a store and keep them reactive,
`storeToRefs(store)` returns a ref for every piece of state and every getter, and those can be
destructured safely.

```html
<!-- src/demos/LostRefs.vue -->
<script setup>
import { storeToRefs } from 'pinia'
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()
const { done } = store
const { done: doneRef, planned } = storeToRefs(store)
const { toggle } = store
</script>

<template>
  <p id="plain">Destructured: {{ done }}</p>
  <p id="refs">With storeToRefs: {{ doneRef }} of {{ planned }}</p>
  <button @click="toggle('s4')">Toggle s4</button>
</template>
```

Toggle the session that is not done:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LostRefs' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
Destructured: 45

With storeToRefs: 105 of 105

Toggle s4
```

**The destructured `done` stayed at 45; the one from `storeToRefs` moved to 105.** It is lesson 2's
first trap, in a new place, and the reason the planner's views write their first two lines the way they
do:

```javascript
const planner = usePlannerStore()
const { sessions } = storeToRefs(planner)
const { toggle } = planner
```

## Why actions come straight from the store

`storeToRefs` skips actions, because an action is a function and a function needs no ref: it is the
same function forever, and calling it always works on the current state. So **state and getters go
through `storeToRefs`, and actions are destructured from the store itself**, as `toggle` is above. The
demo does the same with `toggle`, and its button worked.

## Or do not destructure

`planner.sessions` in the template, and `planner.toggle(id)` in the script, need no `storeToRefs` at
all: reading through the store is always reactive. `App.vue` in the last section of this lesson writes
`planner.error` and `planner.courses.length` in its template and destructures nothing. Destructure when a
view uses a piece often enough that `planner.` everywhere would be noise, and then use `storeToRefs`.
