---
title: The options syntax, and $patch and $reset
version: 1
---

**A Pinia store can also be written as an object with `state`, `getters` and `actions`, the store's
version of lesson 11's Options API.** It is common in existing code, it is what most Pinia examples on
the web show, and it gives two things for free that a setup store has to write by hand.

```javascript
// src/demos/sessionsStore.js: one store, written in the options syntax.
import { defineStore } from 'pinia'

export const useSessionsStore = defineStore('sessions', {
  state: () => ({
    sessions: [
      { id: 's2', minutes: 45, done: true },
      { id: 's4', minutes: 60, done: false },
    ],
  }),
  getters: {
    planned: (state) => state.sessions.reduce((sum, s) => sum + s.minutes, 0),
    done: (state) => state.sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
  },
  actions: {
    toggle(id) {
      this.sessions = this.sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s))
    },
  },
})
```

- **`state` is a function returning the starting state**, like `data()` in a component, for the same
  reason: each application's container gets fresh state.
- **`getters` receive the state** as their argument, and are computed values.
- **`actions` use `this`** for the store, so they are written as methods, never arrows: lesson 11's trap
  applies here unchanged.

A component uses it exactly as it would a setup store:

```html
<!-- src/demos/OptionsStore.vue -->
<script setup>
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()
</script>

<template>
  <p id="totals">{{ store.done }} of {{ store.planned }} minutes done</p>
  <button id="toggle" @click="store.toggle('s4')">Toggle s4</button>
  <button id="patch" @click="store.$patch({ sessions: [] })">Empty it</button>
  <button id="reset" @click="store.$reset()">Reset</button>
</template>
```

Toggle the session that is not done:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OptionsStore' --do 'click #toggle' --text '#totals'
[vite] connecting...
[vite] connected.
-- click #toggle
== the text of #totals
105 of 105 minutes done
```

Then empty the store, and reset it:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OptionsStore' --do 'click #patch' --do 'click #reset' --text '#totals'
[vite] connecting...
[vite] connected.
-- click #patch
-- click #reset
== the text of #totals
45 of 105 minutes done
```

## The two things the options syntax gives

**`$patch` changes several pieces of state in one go**, recorded as one change. Given an object it
merges it in; given a function it calls it with the state to change. Every store has it, setup stores
included.

**`$reset()` puts the state back as `state()` first returned it**, which is why the second run shows 45
of 105 after the store had been emptied. Pinia can do that because `state` is a function it can call
again. **A setup store has no such function**, so `$reset()` on a setup store throws an error in
development, saying the store "does not implement $reset()", and does nothing in a production build. A
setup store that needs a reset writes its own action that sets each ref back.

## Which to write

Both are fully supported and both appear in real code. **This course writes setup stores**, for the
reason it writes `<script setup>`: one way of thinking for components, composables and stores, and the
freedom to use any composable inside a store. Read the options syntax by translating it, as lesson 11
did for components: `state` is refs, `getters` are computed values, `actions` are functions, and `this`
is the store.
