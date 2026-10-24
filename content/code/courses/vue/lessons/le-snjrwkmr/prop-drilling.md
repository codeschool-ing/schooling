---
title: Prop drilling
version: 1
---

**Prop drilling is passing a value through components that do not use it, only so that a component
further down can.** Every layer in between gains a prop it does not care about, has to name it, pass
it on, and change when it changes. In a tree three levels deep it is a nuisance; in one eight levels
deep it is the reason a simple change touches eight files.

Here it is at its smallest: a parent wants the leaves to show hours, and the middle component, which
draws the list, is made to carry the unit along.

```html
<!-- src/demos/DrillLeaf.vue -->
<script setup>
defineProps({ minutes: Number, unit: String })
</script>

<template>
  <li>{{ unit === 'hours' ? minutes / 60 : minutes }} {{ unit }}</li>
</template>
```

```html
<!-- src/demos/DrillMiddle.vue -->
<script setup>
import DrillLeaf from './DrillLeaf.vue'

// This component never uses `unit`. It only passes it on.
defineProps({ sessions: Array, unit: String })
</script>

<template>
  <ul>
    <DrillLeaf v-for="s in sessions" :key="s.id" :minutes="s.minutes" :unit="unit" />
  </ul>
</template>
```

```html
<!-- src/demos/PropDrilling.vue -->
<script setup>
import DrillMiddle from './DrillMiddle.vue'

const sessions = [
  { id: 's2', minutes: 45 },
  { id: 's4', minutes: 60 },
]
</script>

<template>
  <DrillMiddle :sessions="sessions" unit="hours" />
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=PropDrilling'
[vite] connecting...
[vite] connected.
== the text of #app
0.75 hours
1 hours
```

It works, and the leaves show 0.75 and 1 hours. **The cost is in `DrillMiddle`**: its comment says it
never uses `unit`, and yet `unit` is in its props and in its template, and anybody reading it has to
work out that it is only passing through. Add a second setting the leaves need, a date format say, and
the middle grows another prop it does not use.

## Drilling is often fine

The word sounds like an accusation, and most of the time it is not one. Props are explicit: reading
`DrillMiddle` you can see exactly what it receives and what it hands down, and a test can give it any
unit it likes. Two or three levels of passing a value on is the normal cost of a clear data flow, and
lesson 6 called that flow the contract.

It becomes a problem when the value is **ambient**, needed by many components at many depths and set in
one place for all of them:

- a setting that applies to a whole part of the tree: a unit, a locale, a theme, a density;
- a service every component in a feature uses: the current user, a form's state, a set of lookups such
  as the planner's course titles;
- something a library's components share among themselves: a tab group and its tabs, a form and its
  fields.

For those, Vue has a way to skip the layers in between, which is the next section.
