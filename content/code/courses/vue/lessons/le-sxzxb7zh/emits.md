---
title: Emits, what a component says back
version: 1
---

**A child tells its parent that something happened by emitting an event, and the parent decides what
to do about it.** It is the other half of one-way flow: data goes down as props, and news comes up as
events. The child does not change the parent's state; it reports, with whatever detail the parent will
need, and the parent's listener changes its own state.

```html
<!-- src/demos/DoneButton.vue -->
<script setup>
const props = defineProps({ id: String, minutes: Number })
const emit = defineEmits({
  // An event with a check: Vue warns when it returns false.
  done: (id, minutes) => typeof id === 'string' && minutes > 0,
  // An event with no check.
  undo: null,
})
</script>

<template>
  <button class="done" @click="emit('done', id, minutes)">Done ({{ minutes }} minutes)</button>
  <button class="undo" @click="emit('undo', id)">Undo</button>
</template>
```

```html
<!-- src/demos/Emits.vue -->
<script setup>
import { ref } from 'vue'
import DoneButton from './DoneButton.vue'

const log = ref([])
function onDone(id, minutes) {
  log.value.push(`${id} done, ${minutes} minutes`)
}
</script>

<template>
  <DoneButton id="s4" :minutes="60" @done="onDone" @undo="(id) => log.push(`${id} undone`)" />
  <DoneButton id="s9" :minutes="0" @done="onDone" />
  <ul>
    <li v-for="(line, i) in log" :key="i">{{ line }}</li>
  </ul>
</template>
```

Click the first `Done`, its `Undo`, and then the second `Done`, whose session has 0 minutes:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Emits' --do 'click .done' --do 'click .undo' --do 'click :nth-match(.done, 2)'
[vite] connecting...
[vite] connected.
-- click .done
-- click .undo
-- click :nth-match(.done, 2)
[warn] [Vue warn]: Invalid event arguments: event validation failed for event "done".
== the text of #app
Done (60 minutes)UndoDone (0 minutes)Undo
s4 done, 60 minutes
s4 undone
s9 done, 0 minutes
```

`defineEmits` is a compiler macro like `defineProps`, and returns the `emit` function. `emit('done', id,
minutes)` calls the parent's listener with `id` and `minutes` as its arguments. In the parent,
`@done="onDone"` passes them to `onDone`, and `@undo="(id) => log.push(…)"` shows the inline form.
(The `log.push` in the template works because the template unwraps `log`; in the script it would be
`log.value.push`.)

**The check on `done` failed for 0 minutes, and Vue warned and delivered the event anyway**, as it did
for props. A validator is there to catch your own mistakes in development; it is not a filter, and a
production build skips it.

## Declaring them

Like props, emits have a list form, `defineEmits(['done', 'undo'])`, and an object form with checks.
Declare every event, even in the list form, for two reasons that are not style:

- **It documents the component.** A reader sees everything the component can say in one place, rather
  than hunting for `emit(` calls.
- **It changes what a listener attaches to.** An event that is *not* declared is treated as a
  fallthrough attribute (next section): `@click` on a component that does not declare `click` attaches
  a native click listener to the component's root element. Declared, it is only the component's own
  event. A component that emits `click` itself, without declaring it, can fire its parent's handler
  twice for one click.

## Naming

Emit in camelCase, `emit('weekChanged')`, and listen in kebab-case or camelCase,
`@week-changed` or `@weekChanged`; Vue matches them. **Name an event after what happened, not after
what the parent should do**: `toggle`, `done`, `remove-requested`, rather than `update-total` or
`save-to-storage`. The child knows what the student did; only the parent knows what that means.
