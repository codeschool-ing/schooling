---
title: When nobody provides it
version: 1
---

**An `inject` with no provider above it returns `undefined` and warns, and a second argument gives it a
default instead.** The question is worth asking for every injection: a component that injects
something has made a promise about where it will be used, and the default is what it does when that
promise is broken.

```html
<!-- src/demos/Orphan.vue -->
<script setup>
import { inject } from 'vue'
import { unitKey } from './keys.js'

const unit = inject(unitKey)
const unitOrDefault = inject(unitKey, 'minutes')
const made = inject('settings', () => ({ weekStartsOn: 'Monday' }), true)
</script>

<template>
  <p>No default: {{ String(unit) }}</p>
  <p>With a default: {{ unitOrDefault }}</p>
  <p>With a factory: {{ made.weekStartsOn }}</p>
</template>
```

The demo is opened on its own, with nothing above it providing anything:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Orphan'
[vite] connecting...
[vite] connected.
[warn] [Vue warn]: injection "Symbol(unit)" not found. 
  at <Orphan>
== the text of #app
No default: undefined

With a default: minutes

With a factory: Monday
```

- **No default: `undefined`, and a warning** naming the key, `injection "Symbol(unit)" not found`. The
  Symbol's description is what makes that message readable, which is a reason to give every key one.
- **With a default, `'minutes'`**, and no warning: a default says that being used without a provider is
  expected.
- **With a factory**: when the default is an object or an array, pass a function that makes it, and
  `true` as the third argument to say that the function is a factory rather than the value. Vue
  then calls it only when nothing provides the key, so a default that is costly to build is never built
  when a provider exists.

## Choosing the default

There are three honest answers, and each fits a different kind of value:

| the injected value is | when missing |
|---|---|
| a setting with an obvious usual value: a unit, a density | a default that is that usual value |
| something the component cannot work without: the form a field belongs to | no default, and a clear error. A field outside a form is a bug, and better found at once |
| a nice-to-have: a lookup that improves the display | a default that degrades visibly but correctly |

The planner's `SessionRow`, at the end of this lesson, is the third case: without the course titles it
shows the course's id, `statistics`, which is less friendly than `Statistics` and still true. A default
that hides the problem, an empty string where a title should be, would be the silent failure this
lesson keeps warning about.
