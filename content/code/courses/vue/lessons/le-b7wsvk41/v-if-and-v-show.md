---
title: v-if and v-show
version: 1
---

**A directive is an attribute starting with `v-` that tells the template compiler to do something with
the element it sits on.** You have used three already: `v-for` in lesson 1, `v-if` and `v-else` in
lesson 2. This lesson is the directives you will write every day, and the one mistake each of them
invites.

`v-if` and `v-show` both hide an element, and they do it in completely different ways:

- **`v-if` decides whether the element exists.** False, and the element and everything inside it is
  removed from the page, components destroyed included. True again, and it is built again from nothing.
- **`v-show` decides whether the element is visible.** The element is always there; Vue only sets
  `display: none` on it.

The difference is easy to see with a component that announces its own life. It uses two things later
lessons explain, `defineProps` (lesson 6) and the hooks `onMounted` and `onUnmounted` (lesson 9); here
they only print:

```html
<!-- src/demos/Noisy.vue -->
<script setup>
import { onMounted, onUnmounted } from 'vue'

const props = defineProps(['name'])
console.log(`${props.name}: created`)
onMounted(() => console.log(`${props.name}: on the page`))
onUnmounted(() => console.log(`${props.name}: removed`))
</script>

<template>
  <p>{{ name }}</p>
</template>
```

```html
<!-- src/demos/IfAndShow.vue -->
<script setup>
import { ref } from 'vue'
import Noisy from './Noisy.vue'

const open = ref(true)
</script>

<template>
  <div id="panels">
    <Noisy v-if="open" name="with v-if" />
    <Noisy v-show="open" name="with v-show" />
  </div>
  <button @click="open = !open">Toggle</button>
</template>
```

Toggle three times, and print the HTML of the two panels at the end:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=IfAndShow' --do 'click button' --do 'click button' --do 'click button' --html '#panels' --text -
[vite] connecting...
[vite] connected.
with v-if: created
with v-show: created
with v-if: on the page
with v-show: on the page
-- click button
with v-if: removed
-- click button
with v-if: created
with v-if: on the page
-- click button
with v-if: removed
== the HTML of #panels
<div id="panels"><!--v-if--><p style="display: none;">with v-show</p></div>
```

**The `v-if` component was created twice and removed twice; the `v-show` one was created once and is
still there.** In the final HTML, where the `v-if` paragraph was there is only a comment, `<!--v-if-->`,
which Vue leaves as a placeholder to know where to put the element back. The `v-show` paragraph is
present, with `style="display: none;"`.

## Which to use

| | `v-if` | `v-show` |
|---|---|---|
| hidden means | not on the page at all | on the page, not displayed |
| cost of the first render when hidden | nothing | the whole thing is built anyway |
| cost of each toggle | build or destroy everything inside | change one style |
| state inside it, a half-typed field for instance | lost when hidden | kept |
| works with `v-else` and `<template>` | yes | no |

**Default to `v-if`**: most things that are hidden stay hidden, and building nothing is cheapest. Use
`v-show` for something toggled often, like a panel the student opens and closes many times, or when
the state inside must survive being hidden.

`v-else-if` and `v-else` must follow a `v-if` or `v-else-if` element immediately, with nothing between
them, or the compiler refuses them. To hide several elements under one condition without adding a
wrapper to the page, put the `v-if` on a `<template>` element, which renders its children and nothing
of itself.

A screen reader does not read an element with `display: none`, nor one removed by `v-if`, so for
accessibility the two are the same: hidden is hidden. Text that should be read but not seen needs a
visually-hidden class instead, which neither directive provides.
