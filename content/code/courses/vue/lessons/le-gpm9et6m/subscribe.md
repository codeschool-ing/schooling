---
title: Watching a whole store with $subscribe
version: 1
---

**`store.$subscribe(callback)` calls the callback after every change to the store's state, with a
description of the change and the state after it.** It is a watcher on the whole store, with one thing
a watcher does not give: the *kind* of change.

```html
<!-- src/demos/Subscribe.vue -->
<script setup>
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()

store.$subscribe((mutation, state) => {
  console.log(`${mutation.type}: ${state.sessions.length} sessions, ${store.done} minutes done`)
})
</script>

<template>
  <button id="toggle" @click="store.toggle('s4')">Toggle s4</button>
  <button id="patch" @click="store.$patch({ sessions: [] })">Empty it</button>
  <button id="direct" @click="store.sessions = [{ id: 's9', minutes: 20, done: true }]">Replace directly</button>
</template>
```

An action, a patch, and a direct assignment:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Subscribe' --do 'click #toggle' --do 'click #patch' --do 'click #direct' --text -
[vite] connecting...
[vite] connected.
-- click #toggle
direct: 2 sessions, 105 minutes done
-- click #patch
patch object: 0 sessions, 0 minutes done
-- click #direct
direct: 1 sessions, 20 minutes done
```

`mutation.type` says how the state changed: **`patch object`** for `$patch` with an object (`patch
function` with a function), and **`direct`** for anything else, which includes the toggle. An action
is not a kind of change: inside it, `this.sessions = …` is a direct assignment like the third button's.
To see actions themselves, with their names and arguments, a store has `$onAction`.

## $subscribe or watch

| | `store.$subscribe(fn)` | `watch(() => store.sessions, fn)` |
|---|---|---|
| fires on | any change to any of the store's state | changes to what the getter reads |
| knows the kind of change | yes | no |
| a `$patch` of five fields | one call | one call too, because Vue batches watchers, if the getter read any of them |
| belongs to | the component that subscribed, unless `{ detached: true }` | the component that created it |

Two uses suit `$subscribe` well: saving a whole store somewhere, and logging every change while you
debug. **The planner's store saves only `sessions`, with a `watch` inside the store**: it is the one
piece worth keeping, and a watch inside the store runs for as long as the store exists, whichever
component is on screen, with nothing to subscribe from outside. A `$subscribe` called in a component
stops when that component is removed, unless it is detached, which is a quiet way to lose saving the
day a page is redesigned.
