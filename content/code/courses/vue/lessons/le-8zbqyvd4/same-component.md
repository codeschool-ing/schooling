---
title: The same component, written the other way
version: 1
---

**The Options API is the way Vue components were written before the Composition API, and it is still
fully supported: a component is an object whose properties, `data`, `computed`, `methods`, `props`,
`mounted` and the rest, each hold one kind of thing.** Almost all Vue 2 code is written this way (the
Composition API reached Vue 2 only in its last version, 2.7), and a great deal of Vue 3 code too. You
will meet it in your first job before you write any, so this lesson is about reading it, translating it,
and knowing why the planner is not written in it.

Here is a card, written twice, once in each API. The Options version:

```html
<!-- src/demos/OptionsCard.vue -->
<script>
export default {
  name: 'OptionsCard',
  props: {
    title: { type: String, required: true },
    goal: { type: Number, required: true },
    done: { type: Number, default: 0 },
  },
  emits: ['more'],
  data() {
    return { clicks: 0 }
  },
  computed: {
    percent() {
      return Math.round((this.done / this.goal) * 100)
    },
  },
  methods: {
    ask() {
      this.clicks++
      this.$emit('more', 15)
    },
  },
  mounted() {
    console.log(`${this.title}: mounted at ${this.percent}%`)
  },
}
</script>

<template>
  <h3>{{ title }}</h3>
  <p>{{ done }} of {{ goal }} minutes, {{ percent }}% ({{ clicks }} requests)</p>
  <button @click="ask">15 more</button>
</template>
```

The Composition version, which is the style of the rest of this course:

```html
<!-- src/demos/CompositionCard.vue -->
<script setup>
import { ref, computed, onMounted } from 'vue'

const { title, goal, done } = defineProps({
  title: { type: String, required: true },
  goal: { type: Number, required: true },
  done: { type: Number, default: 0 },
})
const emit = defineEmits(['more'])

const clicks = ref(0)
const percent = computed(() => Math.round((done / goal) * 100))

function ask() {
  clicks.value++
  emit('more', 15)
}

onMounted(() => console.log(`${title}: mounted at ${percent.value}%`))
</script>

<template>
  <h3>{{ title }}</h3>
  <p>{{ done }} of {{ goal }} minutes, {{ percent }}% ({{ clicks }} requests)</p>
  <button @click="ask">15 more</button>
</template>
```

And both, side by side, sharing one count of minutes:

```html
<!-- src/demos/TwoApis.vue -->
<script setup>
import { ref } from 'vue'
import OptionsCard from './OptionsCard.vue'
import CompositionCard from './CompositionCard.vue'

const done = ref(45)
</script>

<template>
  <OptionsCard title="Options" :goal="180" :done="done" @more="(m) => (done += m)" />
  <CompositionCard title="Composition" :goal="180" :done="done" @more="(m) => (done += m)" />
</template>
```

Press the first card's button once:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TwoApis' --do 'click button'
[vite] connecting...
[vite] connected.
Options: mounted at 25%
Composition: mounted at 25%
-- click button
== the text of #app
Options

60 of 180 minutes, 33% (1 requests)

15 more
Composition

60 of 180 minutes, 33% (0 requests)

15 more
```

**They behave identically**: both mounted at 25%, both moved to 33% when the shared count went from 45
to 60, and only the clicked card counted a request, because `clicks` is each card's own state. The two
APIs are two ways of writing to the same runtime; the reactivity underneath is the one of lesson 2.

## How to read the difference

Put the two files side by side and the shape is the lesson:

| | Options API | Composition API |
|---|---|---|
| the component is | an object exported with `export default` | the top level of `<script setup>` |
| code is grouped by | kind: all state in `data`, all derived values in `computed`, all functions in `methods` | concern: whatever belongs together sits together |
| state is reached through | `this`: `this.clicks`, `this.percent`, `this.done` | variables: `clicks.value`, `percent.value`, `done` |
| the template sees | everything in `props`, `data`, `computed` and `methods` | every top-level name of the script |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The same component in two columns. On the left, the Options API groups code by kind: data, computed, watch, mounted and beforeUnmount, and the pieces of two concerns, the week and the timer, are scattered across all five. On the right, the Composition API groups code by concern: everything about the week sits together, and everything about the timer sits together.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Options API: by kind</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Composition API: by concern</text><rect x=\"30\" y=\"32\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data</text><rect x=\"160\" y=\"39\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">week</text><rect x=\"240\" y=\"39\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timer</text><rect x=\"30\" y=\"74\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">computed</text><rect x=\"160\" y=\"81\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">week</text><rect x=\"30\" y=\"116\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">watch</text><rect x=\"160\" y=\"123\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">week</text><rect x=\"30\" y=\"158\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mounted</text><rect x=\"160\" y=\"165\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timer</text><rect x=\"30\" y=\"200\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">beforeUnmount</text><rect x=\"160\" y=\"207\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timer</text><rect x=\"390\" y=\"32\" width=\"300\" height=\"98\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the week</text><text x=\"540\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ref</text><text x=\"540\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">computed</text><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">watch</text><rect x=\"390\" y=\"140\" width=\"300\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the timer</text><text x=\"540\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ref</text><text x=\"540\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onMounted</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onBeforeUnmount</text></svg>", "caption": "Changing the timer means visiting three options on the left, and one block on the right."}
```

The second row is why the Composition API exists. In a small card, grouping by kind is tidy. In a
component of five hundred lines doing four things, the state of one thing is in `data`, its derived
values a hundred lines down in `computed`, its watcher further down and its cleanup in
`beforeUnmount`, and changing that one thing means visiting four places. The Composition API lets the
four pieces sit together, and lesson 10's composables let them leave the component altogether.

Neither is wrong, and the Vue documentation still offers both. New code in this course is Composition;
the rest of this lesson is the Options API you will be asked to read.
