---
title: Vue, a template and a ref
version: 1
---

**Vue is a framework from one team, built around a template language and reactive values.** `create-vite`
has a template for it too:

```
ana@dev:~$ npm create vite@9.3.1 sessions-vue -- --template vue-ts --no-interactive > /dev/null && cd sessions-vue && npm config set save-exact true --location=project && npm install --silent vue@3.5.44 && npm install --silent --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-vue@6.0.10 @vue/tsconfig@0.9.1 @types/node@22.20.5 vue-tsc@3.3.13 && rm src/components/HelloWorld.vue && ls src src/components
src:
App.vue
assets
components
main.ts
style.css

src/components:
```

A Vue component is a **single-file component**, a `.vue` file with up to three parts: a `<script>`, a
`<template>` and a `<style>`. `src/components/Sessions.vue`:

```html
<script setup lang="ts">
import { computed, ref } from 'vue'

type Session = { id: string; course: string; minutes: number; done: boolean }

const sessions = ref<Session[]>([
  { id: 's1', course: 'Statistics', minutes: 40, done: true },
  { id: 's2', course: 'Python', minutes: 35, done: false },
  { id: 's3', course: 'Statistics', minutes: 45, done: false },
])
const done = computed(() =>
  sessions.value.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
)
const total = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0))
console.log('Sessions ran')

function toggle(session: Session) {
  session.done = !session.done
}
</script>

<template>
  <section>
    <h1>This week</h1>
    <p>{{ done }} of {{ total }} minutes done</p>
    <ul>
      <li v-for="s in sessions" :key="s.id">
        <button :aria-pressed="s.done" @click="toggle(s)">
          {{ s.course }} · {{ s.minutes }} min
        </button>
      </li>
    </ul>
  </section>
</template>
```

- **`<script setup>`** is the component's code, and it runs **once**, when the component is created. It
  is not a function that runs on every render, which is the first difference from React.
- **`ref`** makes a reactive value. The code reads and writes it through `.value`; the template unwraps it
  on its own, which is why the template says `sessions` and the script says `sessions.value`.
- **`computed`** is a value worked out from others. Vue records which reactive values it read, and works
  it out again only when one of those changes.
- **`toggle` changes the session in place.** `ref` wrapped the array and every object in it in a proxy,
  so writing `session.done` is something Vue sees. The same line in React would change the object and
  render nothing.
- In the template, **`v-for`** repeats an element, `:key` is React's `key`, **`:aria-pressed`** binds an
  attribute to a value, and **`@click`** listens for an event. `{{ }}` puts a value into the text.

`src/App.vue` draws it:

```html
<script setup lang="ts">
import Sessions from './components/Sessions.vue'
</script>

<template>
  <Sessions />
</template>
```

The same build and the same two clicks:

```
ana@dev:~/sessions-vue$ npm run build

> sessions-vue@0.0.0 build
> vue-tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 14 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.46 kB │ gzip:  0.29 kB
dist/assets/index-CsUDhMuy.css   4.10 kB │ gzip:  1.46 kB
dist/assets/index-B2F0ejrR.js   63.72 kB │ gzip: 25.12 kB

✓ built in 368ms
ana@dev:~/sessions-vue$ look http://localhost:4173/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
-- click button Statistics · 45 min
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**The page is the same, and `Sessions ran` appears once.** The two clicks changed the sessions, Vue
worked out `done` again, and drew the new text and the two attributes. The code in `<script setup>`
never ran again, because Vue knew from the proxies which parts of the page had read what changed. What Vue
does run again is the **template**, which it has compiled into a render function of its own and compares
the way React compares, but the code you wrote around it stays where it was.

Note the build script, `vue-tsc -b && vite build`. Plain `tsc` cannot read a `.vue` file, so Vue ships
its own type checker, and it checks the expressions inside the template as well.
