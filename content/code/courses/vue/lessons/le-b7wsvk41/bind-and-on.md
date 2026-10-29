---
title: v-bind and v-on, and their modifiers
version: 1
---

**`v-bind` sets an attribute or property from an expression, and `v-on` listens for an event.** They
are the two directives you will type most, so both have a shorthand: **`:`** for `v-bind` and **`@`**
for `v-on`. `:key="session.id"` is `v-bind:key`, and `@click="count++"` is `v-on:click`.

```html
<!-- src/demos/BindAndOn.vue -->
<script setup>
import { ref } from 'vue'

const done = ref(false)
const minutes = ref(45)
const field = { id: 'minutes', name: 'minutes', min: 5, max: 240 }

function submitted() {
  console.log(`submitted ${minutes.value} minutes, and the page stayed`)
}
</script>

<template>
  <p :class="{ done, long: minutes >= 60 }" :style="{ opacity: done ? 0.6 : 1 }">Statistics</p>
  <form @submit.prevent="submitted">
    <input v-bind="field" type="number" v-model="minutes" @keyup.enter="console.log('Enter pressed')" />
    <button>Save</button>
  </form>
  <button id="done" @click="done = !done">Toggle done</button>
</template>
```

Toggle done, type 60 into the field and press Enter, then print the paragraph:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=BindAndOn' --do 'click #done' --do 'fill #minutes 60' --do 'press Enter' --html p --text -
[vite] connecting...
[vite] connected.
-- click #done
-- fill #minutes 60
-- press Enter
submitted 60 minutes, and the page stayed
Enter pressed
== the HTML of p
<p class="done long" style="opacity: 0.6;">Statistics</p>
```

## Three things v-bind does that HTML cannot

- **`:class` takes an object**, and each key whose value is true becomes a class. `{ done, long:
  minutes >= 60 }` gave `class="done long"`: `done` is shorthand for `done: done`, as in any
  JavaScript object. It also takes an array, and it merges with a plain `class` attribute on the same
  element rather than replacing it.
- **`:style` takes an object** of CSS properties, written in camelCase or quoted kebab-case. Units
  are yours to write: `{ width: '40px' }`, not `{ width: 40 }`.
- **`v-bind` with no argument takes a whole object of attributes**, as the input shows: `v-bind="field"`
  set `id`, `name`, `min` and `max` in one go. It is how a component passes a group of attributes on
  without naming them, and lesson 6 meets it again.

A bound value of `null` or `undefined` removes the attribute; `false` removes a boolean attribute such
as `disabled`. So `:disabled="saving"` is the idiom for a button that waits.

## Modifiers on v-on

**`@submit.prevent` called `event.preventDefault()`** before the handler, and the transcript says "the
page stayed": without it, submitting a form makes the browser load the form's address, which with no
address is the same page, from scratch, losing every ref. Every form in a Vue application has
`.prevent` on its submit, or calls `preventDefault()` itself.

**`@keyup.enter`** runs only when the key released was Enter. Notice the order in the transcript: the
form was submitted first, on the key going *down*, which is when a browser submits a form; the `keyup`
handler ran after, when it came back up.

| modifier | what it adds |
|---|---|
| `.prevent` | `event.preventDefault()` |
| `.stop` | `event.stopPropagation()`: the event does not bubble to the parents |
| `.self` | only if the event happened on this element, not a child |
| `.once` | the listener is removed after the first time |
| `.enter`, `.esc`, `.space`, `.tab`, `.up`, `.down` | only for that key |
| `.ctrl`, `.shift`, `.alt`, `.meta` | only while that key is held |

Modifiers chain, and in order: `@click.stop.prevent`. They exist so that a handler can be about what
the component does, not about the browser's defaults.

## A handler is a name or a statement

`@click="toggle"` passes the function, and Vue calls it with the event. `@click="toggle(session.id)"`
is a statement Vue wraps in a function, so you can pass what you like; the event is still there as
`$event` if you need it. `@click="done = !done"` is a statement too. Keep statements to one short
line; anything longer belongs in a function in the script, where it has a name.
