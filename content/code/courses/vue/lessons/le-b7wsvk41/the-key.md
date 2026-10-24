---
title: The key that matters
version: 1
---

**`:key` tells Vue which item each element belongs to, so that when the list changes it can move,
keep or remove the right elements.** Without it, or with the wrong one, Vue reuses elements by
position, and anything an element holds that did not come from the list, a typed value, a ticked box,
a component's own state, stays at the position while the items move past it.

Here is a row with state of its own, a star that only the row knows about:

```html
<!-- src/demos/StarRow.vue -->
<script setup>
import { ref } from 'vue'

defineProps(['course'])
const starred = ref(false)
</script>

<template>
  <li>
    {{ course }} {{ starred ? '*' : '' }}
    <button @click="starred = true">Star</button>
  </li>
</template>
```

And the same three courses drawn twice, once keyed by position and once by the course itself:

```html
<!-- src/demos/KeyMatters.vue -->
<script setup>
import { ref } from 'vue'
import StarRow from './StarRow.vue'

const courses = ref(['statistics', 'spanish', 'guitar'])
function removeFirst() {
  courses.value = courses.value.slice(1)
}
</script>

<template>
  <h2>key = index</h2>
  <ul id="by-index">
    <StarRow v-for="(course, i) in courses" :key="i" :course="course" />
  </ul>
  <h2>key = the course</h2>
  <ul id="by-id">
    <StarRow v-for="course in courses" :key="course" :course="course" />
  </ul>
  <button id="remove" @click="removeFirst">Remove the first course</button>
</template>
```

Star the first course in each list, which is statistics, then remove statistics:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=KeyMatters' --do 'click #by-index button' --do 'click #by-id button' --do 'click #remove'
[vite] connecting...
[vite] connected.
-- click #by-index button
-- click #by-id button
-- click #remove
== the text of #app
key = index
spanish * Star
guitar Star
key = the course
spanish Star
guitar Star
Remove the first course
```

**In the list keyed by index, the star moved to Spanish.** Spanish was never starred. What happened:
before the removal, key 0 was statistics with a star; after it, key 0 is Spanish. Vue saw that key 0
still exists, kept that component with its state, the star, and only changed its `course` prop. The
component that disappeared was key 2, which had held guitar and had nothing to do with statistics.

**In the list keyed by course, the starred row left with statistics.** Key `statistics` was gone, so
its component was removed, star and all; keys `spanish` and `guitar` were kept as they were.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two lists of three course rows, before and after statistics is removed. Keyed by index, the rows had keys 0, 1 and 2; afterwards keys 0 and 1 remain, so the component with key 0 is kept with its star and now shows Spanish, and key 2 is removed. Keyed by course, the rows had keys statistics, spanish and guitar; afterwards the statistics component is removed with its star, and the other two are kept.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">key = index</text><text x=\"90\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><text x=\"270\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after</text><rect x=\"20\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"152\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">statistics *</text><rect x=\"20\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"152\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish</text><rect x=\"20\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"152\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><rect x=\"200\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"208\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"332\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish *</text><rect x=\"200\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"208\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"332\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><rect x=\"200\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"208\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"332\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">removed</text><line x1=\"162\" y1=\"70\" x2=\"198\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,70.0 190.6,73.1 190.6,66.9\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"110\" x2=\"198\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,110.0 190.6,113.1 190.6,106.9\" fill=\"var(--wire)\"></polygon><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">key = the course</text><text x=\"450\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><text x=\"630\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after</text><rect x=\"380\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"388\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">stat…</text><text x=\"512\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">statistics *</text><rect x=\"380\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"388\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">span…</text><text x=\"512\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish</text><rect x=\"380\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"388\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">guit…</text><text x=\"512\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><rect x=\"560\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"568\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">stat…</text><text x=\"692\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">removed *</text><rect x=\"560\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"568\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">span…</text><text x=\"692\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish</text><rect x=\"560\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"568\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">guit…</text><text x=\"692\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><line x1=\"522\" y1=\"70\" x2=\"558\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,70.0 550.6,73.1 550.6,66.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"110\" x2=\"558\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,110.0 550.6,113.1 550.6,106.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"150\" x2=\"558\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,150.0 550.6,153.1 550.6,146.9\" fill=\"var(--wire)\"></polygon><text x=\"200\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the star stays at position 0</text><text x=\"560\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the star leaves with its course</text></svg>", "caption": "Vue keeps the components whose keys still exist. With an index, the key that survives is a position, and the state goes with the position."}
```

## What makes a good key

- **Stable**: the same item has the same key for as long as it exists. An index is not stable as soon
  as anything is inserted, removed or sorted.
- **Unique among its siblings.** Two equal keys in one list and Vue warns, and the patching goes wrong
  in ways that depend on the order of events.
- **A string or a number.** Not an object: two different objects are never equal, even with the same contents, so a key built as an object changes on every render.

The planner's data was written for this: every session has an `id` that never changes, `s1` to `s6`,
and lesson 3's `addSession` gives a new one the next number. **The rule of this codebase is the rule of
the whole catalogue you are studying in, applied to a list**: join by a stable id, never by position.

An index is acceptable as a key only when the list never changes order and its rows hold no state of
their own, such as a static list of labels. Even then, writing `:key="item.id"` costs nothing and
survives the day somebody adds sorting.
