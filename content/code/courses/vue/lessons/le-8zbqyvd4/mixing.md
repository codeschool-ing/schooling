---
title: Both APIs in one component
version: 1
---

**An Options API component can have a `setup()` option, which runs first and whose returned values join
`this`.** It is how a codebase moves from one API to the other a piece at a time: an old component
starts using a new composable without being rewritten, and the rest of its options keep working.

```html
<!-- src/demos/Mixing.vue -->
<script>
import { useWeek } from './useWeek.js'

export default {
  setup() {
    // A composable, used from an Options API component.
    const { monday, next } = useWeek('2026-10-19')
    return { monday, next }
  },
  data() {
    return { moves: 0 }
  },
  methods: {
    forward() {
      this.next()
      this.moves++
    },
  },
}
</script>

<template>
  <p>Week of {{ monday }}, after {{ moves }} moves</p>
  <button @click="forward">Next week</button>
</template>
```

Lesson 10's `useWeek` is in the sandbox already. Two clicks:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Mixing' --do 'click button' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
-- click button
== the text of #app
Week of 2026-11-02, after 2 moves

Next week
```

**The method `forward` called `this.next()`, which the composable returned through `setup()`, and
counted its own `moves` in `data`.** The week moved two weeks on, to 2 November, and the count says 2.
The two APIs meet on `this`: what `setup()` returns is on it, unwrapped, beside everything else.

`setup()` is the long form that `<script setup>` compiles to. Inside it there is no `this`: it runs
before the instance's options are set up, and it receives `props` as its first argument instead. What it
returns is what the template and the other options may use.

## Moving a component across

A component is not rewritten in one go, it is moved:

1. Leave it working. Add `setup()` and use new composables from it, as above.
2. Move one concern at a time into `setup()`: its state from `data`, its derived values from
   `computed`, its watcher, its hooks, all together, because they belong together.
3. When nothing is left outside `setup()`, change `<script>` to `<script setup>`, remove the `return`,
   and replace `export default` with `defineProps` and `defineEmits`.

There is nothing to gain from step 3 on a component nobody needs to change. **The planner stays as it
is in this lesson**, written in the Composition API from the start: the skill this lesson leaves you is
reading the other one, and translating between the two when a job asks you to.
