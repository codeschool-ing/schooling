---
title: A directive of your own
version: 1
---

**A custom directive is an object of hooks that Vue calls on the element it sits on, and it exists for
the rare job that needs the real DOM element and nothing else.** Focusing a field when it appears is
the classic one. Most things that look like a directive are better as a component or a composable
(lesson 10), and the Vue documentation says so too; this section is so that you can read one and
write the small ones.

```html
<!-- src/demos/FocusDirective.vue -->
<script setup>
import { onMounted } from 'vue'

// A directive is an object of hooks. Named vSomething, it is used as v-something.
const vFocus = {
  mounted: (el) => el.focus(),
}

onMounted(() => console.log(`focus is on #${document.activeElement.id}`))
</script>

<template>
  <label>Course <input id="course" /></label>
  <label>Minutes <input id="minutes" v-focus /></label>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FocusDirective' --text -
[vite] connecting...
[vite] connected.
focus is on #minutes
```

**The focus went to the second field, `minutes`, because that is where `v-focus` sits**, not to the
first field on the page. That is the whole directive: once the element was put on the page, its
`mounted` hook ran with the element and called `focus()` on it.

## The hooks

A directive object may have any of these, each called with the element and a `binding` that carries the
value written after `=`:

| hook | when |
|---|---|
| `created` | before the element's attributes and listeners are applied |
| `beforeMount`, `mounted` | before and after the element is put on the page |
| `beforeUpdate`, `updated` | before and after the component around it redraws |
| `beforeUnmount`, `unmounted` | before and after the element is removed |

`mounted` and `updated` are most of what directives use, and when both do the same thing a directive
can be a plain function, which Vue calls for both: `const vColour = (el, binding) => { el.style.color =
binding.value }`, used as `v-colour="'#2f6f4e'"`.

## The naming rule

In `<script setup>`, **any variable whose name starts with `v` followed by a capital letter is
available as a directive**, `vFocus` as `v-focus`. Nothing has to be registered. A directive used
across the whole application is registered once in `main.js` instead, with `app.directive('focus',
vFocus)`.

## When focus belongs to a directive and when it does not

Moving focus is an accessibility decision as much as a convenience. Focusing the first field of a
form the student just opened helps; focusing a field on page load, before the student has done
anything, moves a screen-reader user away from the start of the page without telling them, which is
the opposite of help. Use it on something that appeared because the student asked for it.
