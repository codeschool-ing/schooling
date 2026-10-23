---
title: Mixins, and why composables replaced them
version: 1
---

**A mixin is an object of options that Vue merges into a component**: its `data`, `methods`,
`computed`, hooks and the rest are added to the component's own. It was Vue 2's way to share logic
between components, it still works in Vue 3, and the Vue documentation no longer recommends it. Two
mixins and a component show why.

```javascript
// src/demos/labelMixin.js: two mixins, written by two people, a year apart.
export const progressMixin = {
  data() {
    return { label: 'progress' }
  },
  methods: {
    describe() {
      return `progress: ${this.label}`
    },
  },
}

export const courseMixin = {
  data() {
    return { label: 'course' }
  },
  methods: {
    describe() {
      return `course: ${this.label}`
    },
  },
}
```

```html
<!-- src/demos/Mixins.vue -->
<script>
import { progressMixin, courseMixin } from './labelMixin.js'

export default {
  mixins: [progressMixin, courseMixin],
  mounted() {
    console.log(`label = ${this.label}; describe() = ${this.describe()}`)
  },
}
</script>

<template>
  <p>{{ describe() }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Mixins'
[vite] connecting...
[vite] connected.
label = course; describe() = course: course
== the text of #app
course: course
```

**Both mixins define `label` and `describe`, and the second one in the list won both**, silently. The
progress mixin's `describe` is gone; its `label` was overwritten. Nothing warned, because overwriting
is how merging works: for `data` and `methods` the later wins, and the component's own options win over
any mixin. Hooks are the exception, they are all kept and run in order, mixins first.

## Three problems, all of them about names

- **Collisions**, as above. Two mixins written a year apart by two people collide on an ordinary word,
  and the component quietly loses one of them.
- **Unclear origin.** In `Mixins.vue`, nothing says where `label` comes from. A component with four
  mixins has four places to look for every name on `this`, and the mixins can use each other's names
  too.
- **No parameters.** A mixin is an object, not a function, so it cannot be told anything. Two copies of
  the same logic with different settings need two mixins, or settings read from the component's `this`
  by agreement.

**A composable has none of the three.** It returns values the caller names: `const { label } =
useProgress()`, and a second one can be renamed on the way in, `const { label: courseLabel } =
useCourse()`. The origin of every name is the line that called the function. And it is a function, so it
takes arguments, as `useWeek('2026-10-19')` did. That is the reason mixins are now legacy: not that they
stopped working, but that composables do the same job without the three problems.

When you meet mixins in old code, leave the working ones alone; when you need to change one, it is
usually the moment to turn it into a composable and use it from the component's `setup()`, which is the
last section.
