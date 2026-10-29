---
title: computed, a value worked out from others
version: 1
---

**A computed property is a value defined by a function of other reactive values, and Vue keeps it
correct for you.** You write how to work it out; Vue runs the function when the value is first needed,
remembers the result, and runs it again only after one of the values it read has changed. You never
assign to it and you never remind it to update.

Lesson 2 ended with a list of ways to hold a stale copy, and the last row was a total worked out once
in the script. This is its fix:

```html
<!-- src/demos/ComputedTotal.vue -->
<script setup>
import { ref, computed } from 'vue'

const sessions = ref([
  { course: 'statistics', minutes: 45 },
  { course: 'spanish', minutes: 30 },
])

const total = computed(() => {
  console.log('computing total')
  return sessions.value.reduce((sum, s) => sum + s.minutes, 0)
})

function totalByHand() {
  console.log('totalByHand called')
  return sessions.value.reduce((sum, s) => sum + s.minutes, 0)
}

function addGuitar() {
  sessions.value.push({ course: 'guitar', minutes: 20 })
}
</script>

<template>
  <p>Planned: {{ total }} minutes</p>
  <p>That is {{ total / 60 }} hours, {{ total % 60 }} minutes over the hour.</p>
  <p>By hand: {{ totalByHand() }}, {{ totalByHand() }}, {{ totalByHand() }}</p>
  <button @click="addGuitar">Add guitar</button>
</template>
```

Start the sandbox's dev server in a second terminal, as in lesson 2, and click the button once:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ComputedTotal' --do 'click button'
[vite] connecting...
[vite] connected.
computing total
totalByHand called
totalByHand called
totalByHand called
-- click button
computing total
totalByHand called
totalByHand called
totalByHand called
== the text of #app
Planned: 95 minutes

That is 1.5833333333333333 hours, 35 minutes over the hour.

By hand: 95, 95, 95

Add guitar
```

`computed()` returned a ref, and like any top-level ref it is unwrapped in the template: `{{ total }}`,
not `{{ total.value }}`. In the script it is `total.value`, read-only. When the button pushed a third
session, the total went from 75 to 95 without a line of code saying so, because the function had read
`sessions.value` and the push changed it.

## What a computed is for

Anything the screen shows that is **derived** rather than **owned**. The planner owns the list of
sessions: they came from a file and the student edits them. It does not own the week's total, which is
a fact about the sessions. Storing the total as a second piece of state means two places that can
disagree, and the rest of this lesson is about what goes wrong when they do.

| owned: a `ref` | derived: a `computed` |
|---|---|
| the sessions | the week's total |
| the Monday being shown | the sessions inside that week |
| the text typed in a search box | the courses whose title matches it |

A useful habit is to ask of every new `ref`: **could this be worked out from what I already have?** If
yes, it is a `computed`.

## A computed in the template, or a function

The demo also has `totalByHand()`, an ordinary function that adds the same numbers, called three times
from the template. Both show 95. The transcript shows the difference: **`computing total` was printed
once per change, and `totalByHand called` three times per render**, because a function in the template
is called every time the template runs, and the template runs on every change to anything it reads.
For adding two numbers that cost nothing. For filtering and sorting a few thousand sessions on every
keystroke, it is the difference between a page that keeps up and one that does not. The next section
is about that cache.
