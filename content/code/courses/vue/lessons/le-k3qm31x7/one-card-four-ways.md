---
title: One card, four ways
version: 1
---

**This lesson builds one small thing four times, in Vue, React, Angular and Svelte, and puts the four
side by side.** The thing is a card of the planner's: one course's week, its sessions with a box to
tick, and a line that adds up the minutes. Small enough to read in each framework at once, and it
has the three parts every framework has to answer for: **state** that changes (the sessions),
**derived values** that follow it (the two totals), and a **template** that draws both and sends
the tick back.

Each version is a project of its own, made by its framework's own tool, in a folder beside the
planner, `~/vue/compare`. Stop any dev server that is running, then the Vue one first, made by
`create-vite`, which lesson 17 met through its list of templates:

```
ana@dev:~/vue/compare$ npm create vite@9.3.1 -- vue --template vue-ts --no-immediate

> npx
> cva vue --template vue-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/vue/compare/vue...
│
└  Done. Now run:

  cd vue
  npm install
  npm run dev
```

`--no-immediate` stops it from installing and starting on its own. Install, pin Vue to the planner's
version, and remove the template's example:

```
ana@dev:~/vue/compare/vue$ npm install

added 48 packages, and audited 49 packages in 4s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/vue$ npm install --save-exact vue@3.5.44

added 2 packages, and audited 51 packages in 803ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/vue$ rm -r src/App.vue src/components src/style.css
```

The card, with everything this course has used, a `ref`, two `computed`s and a `v-model`, and one line
more than it needs, a `console.log` at the top of the setup, which the comparison section reads:

```html
<!-- src/WeekCard.vue: one course's week, the Vue way -->
<script setup lang="ts">
import { ref, computed } from 'vue'

console.log('Vue: setup runs')
const sessions = ref([
  { id: 's3', date: '19 October', minutes: 30, done: true },
  { id: 's6', date: '23 October', minutes: 40, done: false },
])
const planned = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0))
const done = computed(() =>
  sessions.value.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
)
</script>

<template>
  <section>
    <h2>Spanish</h2>
    <ul>
      <li v-for="s in sessions" :key="s.id">
        <label><input v-model="s.done" type="checkbox" /> {{ s.date }}, {{ s.minutes }} minutes</label>
      </li>
    </ul>
    <p>{{ done }} of {{ planned }} minutes done</p>
  </section>
</template>
```

and the entry file, which mounts nothing but the card:

```typescript
// src/main.ts: the card, and nothing else, in the page's #app.
import { createApp } from 'vue'
import WeekCard from './WeekCard.vue'

createApp(WeekCard).mount('#app')
```

Start it with `npm run dev`, and tick the second session:

```
ana@dev:~/vue/compare/vue$ look http://localhost:5173/ --do 'check text=23 October' --text body
[vite] connecting...
Vue: setup runs
[vite] connected.
-- check text=23 October
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

**70 of 70, and the setup ran once**, before the page was drawn, and not again when the box was ticked.
The tick changed `s.done` in a reactive list, the two `computed`s that read it were marked stale, and
only the parts of the template that use them were redrawn. That is lesson 2 and lesson 3, the whole
model in one line of console. The next three sections are the same card, and the same test of it, in the
three other frameworks.
