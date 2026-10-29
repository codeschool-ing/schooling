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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The Mixins demo. On the left, two mixins in the order of the mixins list: progressMixin, with label progress and its own describe, and courseMixin, with label course and its own describe. On the right, what the component&#x27;s this ends up with: label is course and describe returns course: course. The arrow from progressMixin is dashed: both its label and its describe were overwritten, silently, because the later mixin in the list wins.\"><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">mixins: [progressMixin, courseMixin]</text><rect x=\"30\" y=\"40\" width=\"230\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"145\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">progressMixin</text><text x=\"145\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">label: 'progress'</text><text x=\"145\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">describe() → progress: …</text><rect x=\"30\" y=\"135\" width=\"230\" height=\"76\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">courseMixin</text><text x=\"145\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">label: 'course'</text><text x=\"145\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">describe() → course: …</text><line x1=\"262\" y1=\"78\" x2=\"446\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"446.0,112.0 438.2,113.7 439.3,107.6\" fill=\"var(--wire)\"></polygon><text x=\"345\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">overwritten</text><line x1=\"262\" y1=\"173\" x2=\"446\" y2=\"142\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"446.0,142.0 439.3,146.3 438.2,140.2\" fill=\"var(--phosphor)\"></polygon><text x=\"345\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">later in the list: wins</text><rect x=\"450\" y=\"78\" width=\"250\" height=\"96\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the component's this</text><text x=\"575\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">label = course</text><text x=\"575\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">describe() = course: course</text><text x=\"575\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nothing warned</text></svg>", "caption": "Merging mixins keeps one of each name, the later one, and says nothing about the other."}
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
