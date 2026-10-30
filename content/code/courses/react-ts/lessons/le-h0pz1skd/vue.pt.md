---
title: Vue, um template e uma ref
version: 1
---

**O Vue é um framework de um time só, construído em torno de uma linguagem de template e de valores
reativos.** O `create-vite` tem um template para ele também:

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

Um componente Vue é um **single-file component**, um arquivo `.vue` com até três partes: um `<script>`,
um `<template>` e um `<style>`. `src/components/Sessions.vue`:

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

- O **`<script setup>`** é o código do componente, e roda **uma vez**, quando o componente é criado. Não é
  uma função que roda a cada renderização, e essa é a primeira diferença em relação ao React.
- O **`ref`** cria um valor reativo. O código o lê e escreve pelo `.value`; o template o desembrulha
  sozinho, e é por isso que o template diz `sessions` e o script diz `sessions.value`.
- O **`computed`** é um valor calculado a partir de outros. O Vue registra que valores reativos ele leu, e
  só o calcula de novo quando um desses muda.
- **O `toggle` muda a sessão no lugar.** O `ref` envolveu o array e cada objeto dele num proxy, então
  escrever `session.done` é algo que o Vue vê. A mesma linha no React mudaria o objeto e não desenharia
  nada.
- No template, **`v-for`** repete um elemento, `:key` é o `key` do React, **`:aria-pressed`** liga um
  atributo a um valor, e **`@click`** escuta um evento. `{{ }}` põe um valor no texto.

O `src/App.vue` o desenha:

```html
<script setup lang="ts">
import Sessions from './components/Sessions.vue'
</script>

<template>
  <Sessions />
</template>
```

O mesmo build e os mesmos dois cliques:

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

**A página é a mesma, e `Sessions ran` aparece uma vez.** Os dois cliques mudaram as sessões, o Vue
calculou `done` de novo e desenhou o texto novo e os dois atributos. O código do `<script setup>` nunca
rodou de novo, porque o Vue sabia, pelos proxies, que partes da página tinham lido o que mudou. O que o Vue
roda de novo é o **template**, que ele compilou numa função de render própria e compara do jeito que o
React compara, mas o código que você escreveu em volta dele fica onde estava.

Repare no script de build, `vue-tsc -b && vite build`. O `tsc` comum não lê um arquivo `.vue`, então o Vue
traz o próprio verificador de tipos, e ele confere também as expressões dentro do template.
