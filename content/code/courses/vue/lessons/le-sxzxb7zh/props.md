---
title: Props, what a component is given
version: 1
---

**A prop is a value a parent hands to a child component through an attribute, and the child declares
which props it accepts.** It is how one component is used in many places with different data: the
planner will draw one `CourseCard` per course, each given its own title and minutes. The declaration
is not paperwork. It is the child saying what it needs, and in development Vue checks every use
against it.

```html
<!-- src/demos/GoalBar.vue -->
<script setup>
const props = defineProps({
  label: { type: String, required: true },
  minutes: { type: Number, required: true },
  goal: { type: Number, default: 60 },
  unit: {
    type: String,
    default: 'minutes',
    validator: (value) => ['minutes', 'hours'].includes(value),
  },
})
console.log(`${props.label}: minutes is a ${typeof props.minutes}`)
</script>

<template>
  <p>{{ label }}: {{ minutes }} of {{ goal }} {{ unit }}</p>
</template>
```

`defineProps` is not imported. It is a compiler macro: the SFC compiler reads it and turns it into the
component's options, so it only works at the top level of `<script setup>`. It returns an object of
the props, which the script reads as `props.label`, and the template reads by name, `{{ label }}`.

Four uses, three of them wrong in a different way:

```html
<!-- src/demos/PropsBasics.vue -->
<script setup>
import GoalBar from './GoalBar.vue'
</script>

<template>
  <GoalBar label="Statistics" :minutes="45" :goal="180" />
  <GoalBar label="Spanish" minutes="30" />
  <GoalBar label="Guitar" :minutes="20" unit="days" />
  <GoalBar :minutes="10" />
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=PropsBasics'
[vite] connecting...
[vite] connected.
Statistics: minutes is a number
[warn] [Vue warn]: Invalid prop: type check failed for prop "minutes". Expected Number with value 30, got String with value "30". 
  at <GoalBar label="Spanish" minutes="30" > 
  at <PropsBasics>
Spanish: minutes is a string
[warn] [Vue warn]: Invalid prop: custom validator check failed for prop "unit". 
  at <GoalBar label="Guitar" minutes=20 unit="days" > 
  at <PropsBasics>
Guitar: minutes is a number
[warn] [Vue warn]: Missing required prop: "label" 
  at <GoalBar minutes=10 > 
  at <PropsBasics>
undefined: minutes is a number
== the text of #app
Statistics: 45 of 180 minutes

Spanish: 30 of 60 minutes

Guitar: 20 of 60 days

: 10 of 60 minutes
```

- **`minutes="30"` without a colon passed the string `"30"`.** A plain attribute is always text; only
  `:minutes="30"`, which is `v-bind`, evaluates the expression and passes the number. Vue warned, and
  then used the string anyway: the warnings are advice for you, never a refusal.
- **`unit="days"` failed the validator** the declaration wrote, and was used anyway.
- **The fourth bar has no `label`**, a required prop, and rendered with an empty one.
- **`goal` fell back to its default**, 60, wherever it was left out.

The declaration has three forms, from least to most said: an array of names, `defineProps(['label',
'minutes'])`; an object of types, `{ label: String, minutes: Number }`; and the full object above, with
`required`, `default` and `validator`. Lesson 16 adds a fourth, with TypeScript, where the types are
checked before the code runs instead of while it runs. **Use the full form for anything shared**: it is
the component's documentation, and it is checked.

## Props are reactive, even destructured

The parent's value can change, and the child's prop follows: a prop is reactive state the child reads
and does not own. Lesson 2 said that destructuring a reactive object loses the reactivity. **Props are
the one exception**, since Vue 3.5:

```javascript
const { done, goal } = defineProps({ done: Number, goal: Number })
const percent = computed(() => Math.round((done / goal) * 100))
```

The compiler sees that `done` came from `defineProps` and rewrites every use of it into `props.done`,
so the `computed` still reads through the proxy and still follows the parent. It works because the
compiler does it, and only for the variables destructured straight from `defineProps`; pass `done` into
a function of yours and the function receives a plain number, as in lesson 2. The planner's
`CourseCard`, at the end of this lesson, is written this way, and a default can then be written as
JavaScript's own: `const { planned = 0 } = defineProps(…)`.
