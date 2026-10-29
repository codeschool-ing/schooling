---
title: The hooks, from creation to removal
version: 1
---

**A component has a life: it is created, put on the page, updated any number of times, and removed.
Vue calls a function of yours at each of those moments if you register one, and those functions are
the lifecycle hooks.** In the Composition API each hook is a function you import and call during setup,
`onMounted(() => …)`, and you have already used two of them, in lesson 5, only to print.

One component that announces every moment of its life:

```html
<!-- src/demos/Lifecycle.vue -->
<script setup>
import { ref, onBeforeMount, onMounted, onBeforeUpdate, onUpdated, onBeforeUnmount, onUnmounted } from 'vue'

const minutes = ref(30)
console.log('setup: the component is being created')
onBeforeMount(() => console.log('onBeforeMount: about to be put on the page'))
onMounted(() => console.log('onMounted: on the page'))
onBeforeUpdate(() => console.log(`onBeforeUpdate: the page still says ${document.querySelector('#minutes').textContent}`))
onUpdated(() => console.log(`onUpdated: the page now says ${document.querySelector('#minutes').textContent}`))
onBeforeUnmount(() => console.log('onBeforeUnmount: about to be removed'))
onUnmounted(() => console.log('onUnmounted: removed'))
</script>

<template>
  <p id="minutes">{{ minutes }}</p>
  <button id="more" @click="minutes += 15">15 more</button>
</template>
```

And a parent that can remove it:

```html
<!-- src/demos/Hooks.vue -->
<script setup>
import { ref } from 'vue'
import Lifecycle from './Lifecycle.vue'

const shown = ref(true)
</script>

<template>
  <Lifecycle v-if="shown" />
  <button id="remove" @click="shown = false">Remove it</button>
</template>
```

Add fifteen minutes, then remove it:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Hooks' --do 'click #more' --do 'click #remove' --text -
[vite] connecting...
[vite] connected.
setup: the component is being created
onBeforeMount: about to be put on the page
onMounted: on the page
-- click #more
onBeforeUpdate: the page still says 30
onUpdated: the page now says 45
-- click #remove
onBeforeUnmount: about to be removed
onUnmounted: removed
```

## Each moment, and what is true at it

| hook | when | the component's elements |
|---|---|---|
| (setup itself) | the component is being created | do not exist |
| `onBeforeMount` | it is about to render and be inserted for the first time | do not exist on the page yet |
| `onMounted` | it is on the page | exist; you can measure, focus, hand them to a library |
| `onBeforeUpdate` | state changed, and the redraw is about to happen | show the old values |
| `onUpdated` | the redraw happened | show the new values |
| `onBeforeUnmount` | it is about to be removed | still there, still working |
| `onUnmounted` | it has been removed | gone; anything you started must be stopped by now |

The transcript says it the same way: `onBeforeUpdate` read **30** from the page and `onUpdated` read
**45**, from the same element, one redraw apart.

## The three you will use

Most components use no hooks at all, and most that do use these three:

- **`onMounted`**, for work that needs the component's elements on the page: focusing a field (section
  04 of this lesson), measuring something, starting a chart or a map library that draws into an element.
- **`onUnmounted`**, for stopping what you started: a timer, a listener on `window`, a connection.
  Section 05 is about what happens when you forget.
- **`onBeforeUnmount`**, for the same, when the stopping still needs the elements: a library that must
  be told to let go of the element it was drawing in.

`onBeforeUpdate` and `onUpdated` are rarely the right tool. Code that should run after a value changes
is a watcher, lesson 4, with `flush: 'post'` if it needs the page; a hook that runs after *every*
redraw, for whatever reason, is a blunt instrument that a watcher on the right value makes precise.

There is no `onCreated`. In the Composition API, setup itself *is* creation: code at the top level of
`<script setup>` runs exactly where Vue 2's `created` hook ran. Lesson 11 meets `created` in the Options
API, where it still exists.
