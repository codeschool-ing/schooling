---
title: A composable, extracted
version: 1
---

**A composable is a function that uses Vue's reactivity, refs, computed values, watchers and lifecycle
hooks, and returns some of them for a component to use.** It is the Composition API's unit of reuse.
The name is a convention, not a feature: there is nothing to import or register, only a function whose
name starts with `use`, called during a component's setup.

Lesson 7 left a renderless component, `WeekPager`, which held a week and lent it to its slot, and said
that lesson 10 would rewrite it as a composable. Here it is, the same state and the same two moves,
with no template and no component:

```javascript
// src/demos/useWeek.js: the week WeekPager held, as a composable.
import { ref, computed } from 'vue'

export function useWeek(start) {
  const monday = ref(start)

  function move(days) {
    const [y, m, d] = monday.value.split('-').map(Number)
    // Swedish writes a date as YYYY-MM-DD, which is the format the planner uses.
    monday.value = new Date(y, m - 1, d + days).toLocaleDateString('sv-SE')
  }

  return {
    monday,
    sunday: computed(() => {
      const [y, m, d] = monday.value.split('-').map(Number)
      return new Date(y, m - 1, d + 6).toLocaleDateString('sv-SE')
    }),
    previous: () => move(-7),
    next: () => move(7),
  }
}
```

A component that uses it twice, for two independent weeks:

```html
<!-- src/demos/TwoWeeks.vue -->
<script setup>
import { useWeek } from './useWeek.js'

const plan = useWeek('2026-10-19')
const { monday, sunday, next } = useWeek('2026-10-19')
</script>

<template>
  <p id="plan">Plan: {{ plan.monday }} to {{ plan.sunday }}</p>
  <p id="review">Review: {{ monday }} to {{ sunday }}</p>
  <button @click="next">Next week, for the review only</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TwoWeeks' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
Plan: 2026-10-19 to 2026-10-25

Review: 2026-10-26 to 2026-11-01

Next week, for the review only
```

**The review moved to the 26th and the plan stayed on the 19th.** Each call to `useWeek` ran the
function again and made a new `monday` ref, so each caller has a week of its own. That is the first
thing to understand about a composable: **it is a function, and every call makes fresh state.** It is
not a shared store; lesson 13 is about the thing that is.

## What the extraction bought

Compared with `WeekPager`, the composable:

- adds **no component to the tree**, and no template the caller has to fill in a particular shape;
- can be called **more than once in one component**, which a renderless component can only do by being
  written twice in the template;
- returns **whatever it likes**, a `computed` for Sunday included, and the caller takes the pieces it
  needs by destructuring, which is safe here because every piece is a ref or a function (the next
  section says why that matters);
- can be **tested as a function**, without mounting anything, which lesson 21 does.

The first call in the demo keeps the result in one object, `plan`, and reads `plan.monday` in the
template; the second destructures it. Both work. A ref read as a property of a plain object in the
template is unwrapped when it is the last thing printed, which lesson 2 showed, and `{{ plan.monday }}`
is exactly that.
