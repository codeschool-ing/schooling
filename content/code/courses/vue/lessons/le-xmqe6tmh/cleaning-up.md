---
title: Cleaning up, and the planner's clock
version: 1
---

**Whatever a component starts outside Vue, it must stop when it is removed.** A timer, a listener on
`window` or `document`, a connection to a server, an observer watching the page: none of them belong to
the component as far as the browser is concerned, and removing the component's elements does not stop
them. Vue cleans up what Vue created, its renders and the watchers made during setup (lesson 4), and
nothing else.

Two components with a timer each, one of which cleans up:

```html
<!-- src/demos/Ticker.vue -->
<script setup>
import { onMounted, onUnmounted } from 'vue'

const { name, tidy } = defineProps({ name: String, tidy: Boolean })
let timer

onMounted(() => {
  timer = setInterval(() => console.log(`${name} ticks`), 100)
})
if (tidy) {
  onUnmounted(() => clearInterval(timer))
}
</script>

<template>
  <p>{{ name }}</p>
</template>
```

```html
<!-- src/demos/Leak.vue -->
<script setup>
import { ref } from 'vue'
import Ticker from './Ticker.vue'

const shown = ref(true)
</script>

<template>
  <template v-if="shown">
    <Ticker name="careless" />
    <Ticker name="tidy" tidy />
  </template>
  <button @click="shown = false">Remove both</button>
</template>
```

Let them tick for a quarter of a second, remove both, and wait another quarter:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Leak' --do 'wait 250' --do 'click button' --do 'wait 250' --text -
[vite] connecting...
[vite] connected.
careless ticks
tidy ticks
careless ticks
tidy ticks
careless ticks
tidy ticks
careless ticks
tidy ticks
-- wait 250
careless ticks
tidy ticks
careless ticks
tidy ticks
careless ticks
tidy ticks
careless ticks
tidy ticks
-- click button
careless ticks
tidy ticks
careless ticks
-- wait 250
careless ticks
careless ticks
careless ticks
careless ticks
careless ticks
```

**After the removal, `careless` keeps ticking and `tidy` stops.** The careless component is gone from
the page and from Vue, and its interval still runs, every tenth of a second as the code asks (a browser busy loading a page
fits in a few more or a few less), holding on to the component's
`name` and everything else its function can reach. Show and hide a component like it a hundred times
and a hundred intervals are running. `javascript` lesson 19 called this a leak you cause, and this is
how it looks in a component.

## The rule

**Start it in `onMounted`, stop it in `onUnmounted`**, and keep whatever the stopping needs, the timer's
id, the listener function, in a variable both can see. The pairs to remember:

| started with | stopped with |
|---|---|
| `setInterval(fn, ms)` | `clearInterval(id)` |
| `window.addEventListener('resize', fn)` | `window.removeEventListener('resize', fn)`, the same `fn` |
| `new ResizeObserver(fn).observe(el)` | `observer.disconnect()` |
| a `fetch` still running | an `AbortController`'s `abort()`, lesson 4 |

Lesson 10 bundles a pair like this into a composable, so that a component asks for "the window's
width" and the starting and stopping come with it.

## The planner's clock

The planner has a value that changes without anybody touching it: today's date. It was read once, when
the page opened, and a planner left open overnight would go on calling yesterday today. So `App.vue`
keeps a `today` ref and refreshes it every minute with a timer it starts and stops:

```javascript
const today = ref(isoDate(new Date()))
let timer
onMounted(() => {
  timer = setInterval(() => {
    today.value = isoDate(new Date())
  }, 60_000)
})
onUnmounted(() => clearInterval(timer))
```

Those lines go right after `monday`, with `onMounted` and `onUnmounted` added to the import from `vue`
and `isoDate` to the import from `./planner.js`. Each row is then told whether it is today's, with
`:today="session.date === today"` beside `:session`, and `SessionRow` marks it:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { computed, inject } from 'vue'
import { formatDay } from '../planner.js'
import { titlesKey } from '../keys.js'

const { session, today } = defineProps({
  session: { type: Object, required: true },
  today: { type: Boolean, default: false },
})
const emit = defineEmits(['toggle'])

// The titles of every course, provided by App. Without a provider, the id is
// shown instead of the title, rather than nothing.
const titles = inject(titlesKey, null)
const title = computed(() => titles?.value[session.course] ?? session.course)
</script>

<template>
  <li :class="{ done: session.done, today }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
      <strong v-if="today">(today)</strong>
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
.today {
  background: #e6f0ea;
}
</style>
```

With the clock at Wednesday, 21 October:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text 'main section:nth-child(2) ul'
[vite] connecting...
[vite] connected.
== the text of main section:nth-child(2) ul
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

`App` is the root of the application and is only removed when the page is closed, so its
`onUnmounted` will rarely run. It is written anyway: lesson 21 mounts `App` in a test and unmounts it,
and lesson 10 moves these lines into a composable that any component may use, where the cleanup
matters every time.
