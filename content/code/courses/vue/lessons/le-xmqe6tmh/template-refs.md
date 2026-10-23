---
title: Template refs, a hand on the element
version: 1
---

**A template ref gives your script the real DOM element, or the child component instance, that a tag in
the template became.** It is the escape hatch from describing the page to touching it, for the few
things a description cannot say: put the focus here, measure this, give this element to a library.

`useTemplateRef('name')`, from Vue 3.5, returns a ref that Vue fills with the element whose `ref`
attribute is `"name"`:

```html
<!-- src/demos/TemplateRefs.vue -->
<script setup>
import { ref, nextTick, useTemplateRef, onMounted } from 'vue'

const adding = ref(false)
const minutesField = useTemplateRef('minutes')
const rows = useTemplateRef('rows')

console.log(`during setup the field is ${minutesField.value}`)
onMounted(() => console.log(`mounted: ${rows.value.length} rows in the list`))

async function startAdding() {
  adding.value = true
  console.log(`before nextTick the field is ${minutesField.value}`)
  await nextTick()
  minutesField.value.focus()
  console.log(`after nextTick, focus is on #${document.activeElement.id}`)
}
</script>

<template>
  <ul>
    <li v-for="c in ['statistics', 'spanish', 'guitar']" :key="c" ref="rows">{{ c }}</li>
  </ul>
  <button @click="startAdding">Add a session</button>
  <label v-if="adding">Minutes <input id="new-minutes" ref="minutes" type="number" /></label>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TemplateRefs' --do 'click button' --text -
[vite] connecting...
[vite] connected.
during setup the field is null
mounted: 3 rows in the list
-- click button
before nextTick the field is null
after nextTick, focus is on #new-minutes
```

Four moments, and the refs are full only at the second and the fourth:

- **During setup, the field is `null`.** Nothing has been rendered; the element does not exist.
- **In `onMounted`, `rows` holds 3 elements.** A `ref` inside a `v-for` collects every element of the
  loop into an array. The order of the array is not guaranteed to match the list's, so look items up by
  something on the element rather than by position.
- **Right after `adding.value = true`, the field is still `null`.** The `v-if` has not been re-rendered
  yet: lesson 2's queue.
- **After `await nextTick()`, it exists**, and `focus()` put the cursor in it, which is what the student
  who pressed *Add a session* expects.

That last pattern, show something and then focus it, is the most common use of a template ref, and it
is also an accessibility rule: a field that appears because the student asked for it should receive the
focus, or a keyboard user is left on the button with no idea where the field went.

## The older spelling

Before 3.5 a template ref was a plain `ref` whose variable name matched the attribute:

```javascript
const minutes = ref(null)   // filled by <input ref="minutes">
```

It still works, and most code you read is written that way. `useTemplateRef` says what the ref is for,
and lets the variable have a different name from the attribute, which the demo uses: the variable is
`minutesField`, the attribute `minutes`.

## On a component

A `ref` on a child component gives the component's instance, not an element. With `<script setup>`, an
instance exposes nothing to its parent unless it says so with `defineExpose({ focus })`. That is
deliberate: the parent reaching into a child's internals is the coupling that props and events exist
to avoid, so the child decides the few methods it offers, like `focus()` on a custom input.
