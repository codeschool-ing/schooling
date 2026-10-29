---
title: v-model, two-way binding
version: 1
---

**`v-model` joins a form field to a ref in both directions: the field shows the ref's value, and
typing into the field writes to the ref.** It is shorthand for two things you could write by hand, a
binding of the field's value and a listener for its input event, and lesson 14 opens it up and builds
it into a component of your own.

```html
<!-- src/demos/ModelBasics.vue -->
<script setup>
import { ref } from 'vue'

const note = ref('')
const done = ref(false)
const kinds = ref([])
</script>

<template>
  <label>Note <input id="note" v-model="note" /></label>
  <label><input id="done" type="checkbox" v-model="done" /> Done</label>
  <label><input id="reading" type="checkbox" value="reading" v-model="kinds" /> Reading</label>
  <label><input id="exercises" type="checkbox" value="exercises" v-model="kinds" /> Exercises</label>
  <p id="state">note = "{{ note }}", done = {{ done }}, kinds = {{ kinds }}</p>
</template>
```

Type a note, tick `Done` and tick `Exercises`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ModelBasics' --do 'fill #note verbs' --do 'check #done' --do 'check #exercises' --text '#state'
[vite] connecting...
[vite] connected.
-- fill #note verbs
-- check #done
-- check #exercises
== the text of #state
note = "verbs", done = true, kinds = [ "exercises" ]
```

The same directive did three different things, chosen by the kind of field:

| field | the value it reads and writes | the event it listens to |
|---|---|---|
| text input, `<textarea>` | the text, as a string | `input`, on every keystroke |
| a lone checkbox | `true` or `false` | `change` |
| several checkboxes with one array | the array of the `value`s that are ticked | `change` |
| radio buttons | the `value` of the one chosen | `change` |
| `<select>` | the `value` of the option chosen (an array with `multiple`) | `change` |

**The ref is the truth, and the field's own `value` attribute in the HTML is ignored.** If you write
`<input v-model="note" value="hello">`, the field shows whatever `note` holds and the
`value` attribute is ignored. Initial values go in the ref.

## A text field gives you a string

A field hands back what it holds, which is text: typing `45` into an ordinary `<input v-model="minutes">`
gives `minutes` the value `"45"`, and `"45" + 15` is `"4515"`. Vue makes one exception on its own: on
an `<input type="number">`, `v-model` converts the text to a number before writing it. Anywhere else,
the `.number` modifier asks for the same conversion; `.trim` removes spaces at the ends; `.lazy`
updates on `change` instead of every keystroke. Lesson 14 is about forms, and shows them at work.

## Where v-model does not fit

`v-model` writes into the ref, in place. That suits a field that *is* the state, like a note being
typed. It does not suit the planner's sessions, because lesson 3 decided that the list is replaced
through `toggleDone` rather than changed in place; a `v-model` on `session.done` would flip the
property inside the list behind the rules' back. The last section of this lesson ticks sessions off
with the two halves written out instead, which is exactly what `v-model` would have expanded into.
