---
title: A scoped slot is a render prop
version: 1
---

**If you have read React code, you have seen the scoped slot already, under the name *render prop*: a
prop whose value is a function that returns markup.** The two solve the same problem, letting a component
own behaviour while the parent owns the look, and the comparison shows the shape of each framework.

The same idea in both, a component that holds a week and lets the parent draw it. The React version is
shown for comparison and is not part of this course's project:

```jsx
// React: the parent passes a function as children, and the child calls it.
<WeekPager>
  {({ monday, previous, next }) => (
    <>
      <p>Week of {monday}</p>
      <button onClick={previous}>Previous</button>
    </>
  )}
</WeekPager>
```

In Vue the child passes the values to `<slot>` and the parent's template receives them. Here is that
child, with no markup of its own:

```html
<!-- src/demos/WeekPager.vue -->
<script setup>
import { ref } from 'vue'

// No markup of its own: it holds a week and hands it to whoever uses it.
const monday = ref('2026-10-19')
function move(days) {
  const [y, m, d] = monday.value.split('-').map(Number)
  const next = new Date(y, m - 1, d + days)
  // Swedish writes a date as YYYY-MM-DD, which is the format the planner uses.
  monday.value = next.toLocaleDateString('sv-SE')
}
</script>

<template>
  <slot :monday="monday" :previous="() => move(-7)" :next="() => move(7)" />
</template>
```

```html
<!-- src/demos/Renderless.vue -->
<script setup>
import WeekPager from './WeekPager.vue'
</script>

<template>
  <WeekPager v-slot="{ monday, previous, next }">
    <p>Week of {{ monday }}</p>
    <button id="back" @click="previous">Previous</button>
    <button id="on" @click="next">Next</button>
  </WeekPager>
</template>
```

Next twice, then back once:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Renderless' --do 'click #on' --do 'click #on' --do 'click #back'
[vite] connecting...
[vite] connected.
-- click #on
-- click #on
-- click #back
== the text of #app
Week of 2026-10-26

PreviousNext
```

From the 19th, two weeks on and one back: **the 26th**. `WeekPager` renders nothing but its slot. It
holds state, `monday`, and two functions that change it, and hands all three to whoever uses it. A
component like that is called **renderless**.

## Where the two models differ

| | React render prop | Vue scoped slot |
|---|---|---|
| what the parent passes | a function, called by the child on each render | a template, compiled once, given the slot props |
| where the content lives | in JSX, inside the parent's function | in the parent's template |
| how it is called | by the child, like any function | by Vue, where the child put `<slot>` |

Underneath they are closer than they look: Vue compiles each slot into a function, and the child calls
it with the slot props. The difference is in what you write, a template rather than a function, and in
what Vue can do with a template: it knows which parts are static, as lesson 1's compiled output showed.

## And why you will write few renderless components

They were the main way to share behaviour in Vue 2, and React moved away from render props for the same
reason Vue did: **sharing state and logic does not need a component at all.** A function that creates
refs and returns them, used inside any component's setup, does it with no extra layer in the tree and no
template. In Vue that function is a *composable*, and lesson 10 rewrites `WeekPager` as one. Scoped
slots stay the right tool when the shared part really is structure: the list, the table, the frame.
