---
title: Vue
version: 1
---

**Vue is a framework for user interfaces whose components keep their script, their template and
their styles in one file, and whose reactivity tracks reads the way Angular's signals do.** Vite was
written by Vue's author, and a Vue project is made by its generator, at the same version as React's:

```
ana@dev:~/compare$ npm create vite@9.3.1 -- vue --template vue-ts --no-immediate

> npx
> cva vue --template vue-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/compare/vue...
│
└  Done. Now run:

  cd vue
  npm install
  npm run dev
```

```
ana@dev:~/compare/vue$ npm install

added 53 packages, and audited 54 packages in 4s

found 0 vulnerabilities
```

```
ana@dev:~/compare/vue$ npm install --save-exact vue@3.5.44 @vitejs/plugin-vue@6.0.10 @vue/tsconfig@0.9.1 @types/node@22.20.5 typescript@6.0.3 vite@8.3.5 vue-tsc@3.3.14

added 2 packages, changed 2 packages, and audited 56 packages in 2s

found 0 vulnerabilities
```

```
ana@dev:~/compare/vue$ rm -r src/App.vue src/components src/style.css
```

The card:

```schooling-example
{"language": "html", "file": "src/WeekCard.vue", "parts": [
 {"code": "<!-- src/WeekCard.vue: one course's week, the Vue way -->\n<script setup lang=\"ts\">\nimport { computed, ref } from 'vue';\n", "note": "A single-file component: script, template and, when there are any, styles, in one `.vue` file."},
 {"code": "console.log('Vue: setup runs');\nconst sessions = ref([\n  { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },\n  { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },\n]);\nconst planned = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0));\nconst done = computed(() => sessions.value.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));\n</script>\n", "note": "`<script setup>` runs once, when the component is created. `ref` is Vue's signal, read and written through `.value`; `computed` is the same word for the same idea as Angular's."},
 {"code": "<template>\n  <section>\n    <h2>JavaScript</h2>\n    <ul>\n      <li v-for=\"s in sessions\" :key=\"s.id\">\n        <label><input v-model=\"s.done\" type=\"checkbox\" /> {{ s.date }}, {{ s.minutes }} minutes</label>\n      </li>\n    </ul>\n    <p>{{ done }} of {{ planned }} minutes done</p>\n  </section>\n</template>", "note": "The template reads refs without `.value`. `v-for` is the loop, `:key` its `track`, and `v-model` binds the box both ways: ticking it writes `s.done` directly, which Vue sees because the list is reactive all the way down."}
]}
```

```typescript
// src/main.ts: the card, and nothing else, in the page's #app
import { createApp } from 'vue';
import WeekCard from './WeekCard.vue';

createApp(WeekCard).mount('#app');
```

```
ana@dev:~/compare/vue$ look http://localhost:5173/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
Vue: setup runs
[vite] connected.
-- check Sat 24 Oct, 50 minutes
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

**Once**, as in Angular. Vue's setup ran when the card was created, and the tick changed one field of
one session; the two `computed`s read that list, so they were marked stale, and only the parts of the
template that read them were drawn again. Stop the dev server.
