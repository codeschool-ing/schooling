---
title: v-for, over anything that repeats
version: 1
---

**`v-for` repeats an element once for every item of a list, and gives each copy the item under a name
of your choosing.** It also repeats over the properties of an object and over a range of numbers, and
it is the one directive that has a rule about which other directive may sit beside it.

```html
<!-- src/demos/ForLoops.vue -->
<script setup>
const sessions = [
  { id: 's2', course: 'statistics', minutes: 45, done: true },
  { id: 's4', course: 'statistics', minutes: 60, done: false },
  { id: 's5', course: 'guitar', minutes: 20, done: false },
]
const goal = { course: 'statistics', minutes: 180 }
</script>

<template>
  <ol>
    <li v-for="(session, index) in sessions" :key="session.id">
      {{ index }}: {{ session.course }}, {{ session.minutes }} minutes
    </li>
  </ol>
  <p>
    <span v-for="(value, key) in goal" :key="key">{{ key }} = {{ value }}; </span>
  </p>
  <p><span v-for="n in 3" :key="n">{{ n }} </span></p>
  <ul>
    <template v-for="session in sessions" :key="session.id">
      <li v-if="session.done">{{ session.course }} is done</li>
    </template>
  </ul>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ForLoops'
[vite] connecting...
[vite] connected.
== the text of #app
0: statistics, 45 minutes
1: statistics, 60 minutes
2: guitar, 20 minutes

course = statistics; minutes = 180;

123

statistics is done
```

Four forms, in the order of the template:

- **`(session, index) in sessions`**: the item and its position, starting at 0.
- **`(value, key) in goal`**: over an object, the value first and the property name second, in the order
  `Object.keys` gives them.
- **`n in 3`**: a range, and it starts at **1**, not 0. It is the one place in Vue where counting
  starts at one, and the transcript shows `123`.
- **`<template v-for>`** repeats its contents with no wrapper element of its own, which is how a filter
  goes inside a loop. More on that below.

Every `v-for` above has a `:key`, which the next section is about.

## v-if and v-for on the same element

The tempting way to show only the sessions that are done is to put both directives on the `<li>`:

```html
<!-- src/demos/IfInsideFor.vue -->
<script setup>
const sessions = [
  { id: 's2', course: 'statistics', done: true },
  { id: 's4', course: 'statistics', done: false },
]
</script>

<template>
  <ul>
    <li v-for="session in sessions" v-if="session.done" :key="session.id">{{ session.course }}</li>
  </ul>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=IfInsideFor'
[vite] connecting...
[vite] connected.
[warn] [Vue warn]: Property "session" was accessed during render but is not defined on instance. 
  at <IfInsideFor>
[warn] [Vue warn]: Unhandled error during execution of render function 
  at <IfInsideFor>
Uncaught TypeError: Cannot read properties of undefined (reading 'done')
== the text of #app
```

**In Vue 3, `v-if` is evaluated before `v-for`** when both sit on one element, so `session` did not
exist yet when `v-if` asked for `session.done`. The page is empty and the console has the error. (Vue 2
did it the other way round, which is why old answers on the web suggest this pattern.)

Two correct ways, and the choice depends on whether the filter is a fact about the data:

- **A `computed` that filters**, and a plain `v-for` over it. When the filtered list means something,
  "the sessions that are done", it deserves a name, and lesson 3 says where derived values live.
- **`<template v-for>` with a `v-if` inside**, as the last list of the first demo does, when the filter
  is only about display.
