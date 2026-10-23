---
title: KeepAlive, and two more hooks
version: 1
---

**`<KeepAlive>` keeps a component alive when it is switched away, instead of destroying it, and brings
the same instance back when it is switched to again.** Its state survives, half-typed text included,
and two hooks of its own tell the component when it is put away and when it comes back.

A notes field per course, behind two tabs:

```html
<!-- src/demos/Draft.vue -->
<script setup>
import { ref, onMounted, onActivated, onDeactivated, onUnmounted } from 'vue'

const { name } = defineProps({ name: String })
const note = ref('')
onMounted(() => console.log(`${name}: mounted`))
onActivated(() => console.log(`${name}: activated`))
onDeactivated(() => console.log(`${name}: deactivated`))
onUnmounted(() => console.log(`${name}: unmounted`))
</script>

<template>
  <label>Notes for {{ name }} <input v-model="note" /></label>
  <p>{{ note.length }} characters</p>
</template>
```

```html
<!-- src/demos/KeptAlive.vue -->
<script setup>
import { ref } from 'vue'
import Draft from './Draft.vue'

const tab = ref('statistics')
</script>

<template>
  <button id="stats" @click="tab = 'statistics'">Statistics</button>
  <button id="spanish" @click="tab = 'spanish'">Spanish</button>
  <KeepAlive>
    <Draft :key="tab" :name="tab" />
  </KeepAlive>
</template>
```

Type a note for statistics, switch to Spanish, and switch back:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=KeptAlive' --do 'fill input verbs' --do 'click #spanish' --do 'click #stats'
[vite] connecting...
[vite] connected.
statistics: mounted
statistics: activated
-- fill input verbs
-- click #spanish
statistics: deactivated
spanish: mounted
spanish: activated
-- click #stats
spanish: deactivated
statistics: activated
== the text of #app
StatisticsSpanishNotes for statistics 

5 characters
```

**The statistics note came back with its 5 characters**, and the log says why: switching away
*deactivated* the statistics component instead of unmounting it, and switching back *activated* the
same one. Spanish was mounted once, the first time it was shown, and deactivated in turn. Without
`<KeepAlive>`, the `:key` change would have destroyed each component on the way out, and the note would
have been empty on return.

(The text of the field itself does not appear in the transcript, because `look` prints the text of the
page and a field's value is not text. The count below it is.)

## The two hooks

- **`onActivated`** runs when a kept component is shown, including the first time, right after
  `onMounted`.
- **`onDeactivated`** runs when it is put away.

They are where a kept component pauses and resumes what it was doing: stop a timer when deactivated,
since nobody is looking, and start it again when activated; refresh data that may have gone stale while
the tab was hidden. `onUnmounted` will not run for a kept component until the `<KeepAlive>` itself goes, or drops
it from its cache because of the `include`, `exclude` or `max` below.

## When to keep things alive

`<KeepAlive>` trades memory for state. Every kept component stays in memory with everything it holds,
so it fits a small number of views the student moves between often, like tabs of a form, and it takes
`include`, `exclude` and `max` to say which components and how many. For state that must survive
anyway, being kept in memory is a weak guarantee: a reload loses it. The planner keeps its sessions in
`localStorage` (lesson 4) and, from lesson 13, in a store, where switching views cannot touch them.
Lesson 12 uses `<KeepAlive>` around the router's views, where it is used most.
