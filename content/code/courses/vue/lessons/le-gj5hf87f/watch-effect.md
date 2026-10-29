---
title: watchEffect, which finds its own sources
version: 1
---

**`watchEffect` runs a function at once, records every reactive value it read, and runs it again
whenever one of them changes.** There is no source argument: the function is the source. It is the
same tracking a render and a `computed` use, applied to a side effect.

```html
<!-- src/demos/EffectTracking.vue -->
<script setup>
import { ref, watchEffect } from 'vue'

const course = ref('statistics')
const minutes = ref(45)
const note = ref('')

// No list of sources: whatever the function reads is a source.
watchEffect(() => {
  console.log(`effect: ${course.value}, ${minutes.value} minutes`)
})

// Only what is read before the first await is tracked.
watchEffect(async () => {
  const c = course.value
  await Promise.resolve()
  console.log(`async effect: ${c}, note "${note.value}"`)
})
</script>

<template>
  <button id="course" @click="course = 'spanish'">Spanish</button>
  <button id="minutes" @click="minutes += 15">15 more</button>
  <button id="note" @click="note = 'verbs'">Add a note</button>
</template>
```

Click `15 more`, then `Add a note`, then `Spanish`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=EffectTracking' --do 'click #minutes' --do 'click #note' --do 'click #course' --text -
[vite] connecting...
[vite] connected.
effect: statistics, 45 minutes
async effect: statistics, note ""
-- click #minutes
effect: statistics, 60 minutes
-- click #note
-- click #course
effect: spanish, 60 minutes
async effect: spanish, note "verbs"
```

Both effects ran when the page opened; a `watchEffect` is always immediate, because running it is how
it finds out what to watch. Then:

- **`15 more`** re-ran the first effect, which had read `minutes`, and not the second, which had not.
- **`Add a note` re-ran nothing.** The async effect does read `note`, but only after `await`, and by
  then Vue had stopped recording. Tracking happens while the function runs synchronously; once it
  pauses at an `await`, the rest of it runs later, outside the window, and its reads count for nothing.
- **`Spanish`** re-ran both, because both read `course` before anything else. The async one printed
  `note "verbs"`, the value it happened to find, though a change to the note on its own could never
  have woken it.

That second bullet is the trap of `watchEffect`, and it is silent: the code reads the value, the
value is correct when it is printed, and the effect still does not follow it. **In an async effect,
read every source you depend on before the first `await`**, into local constants, as the demo does
with `course`. Or use `watch` and name the sources outright.

## watch or watchEffect

| | `watch` | `watchEffect` |
|---|---|---|
| sources | named by you | whatever the function read on its last run |
| first run | on the first change, unless `immediate` | at once |
| gives you the old value | yes | no |
| when it is clearer | the trigger and the work are different things: "when the course changes, fetch its notes" | the work *is* the reading: "keep the page title equal to the course and the minutes" |

When in doubt, `watch`. Naming the sources costs a line and states the intent, and a source named
outright cannot be lost behind an `await`.
