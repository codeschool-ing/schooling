---
title: Um card, de quatro jeitos
version: 1
---

**Esta aula constrói uma coisa pequena quatro vezes, em Vue, React, Angular e Svelte, e põe as quatro
lado a lado.** A coisa é um card do planner: a semana de um curso, as sessões dela com uma caixa para
marcar, e uma linha que soma os minutos. Pequeno o bastante para ser lido em cada framework de uma vez,
e com as três partes que todo framework precisa resolver: **estado** que muda (as sessões),
**valores derivados** que o acompanham (os dois totais), e um **template** que desenha os dois e manda
a marcação de volta.

Cada versão é um projeto próprio, feito pela ferramenta do próprio framework, numa pasta ao lado do
planner, `~/vue/compare`. Pare qualquer servidor de desenvolvimento que estiver rodando, e comece pelo
Vue, feito pelo `create-vite`, que a aula 17 conheceu pela sua lista de templates:

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

O `--no-immediate` impede que ele instale e inicie por conta própria. Instale, fixe o Vue na versão do
planner, e remova o exemplo do template:

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

O card, com tudo o que este curso usou, um `ref`, dois `computed`s e um `v-model`, e uma linha a mais
do que precisa, um `console.log` no topo do setup, que a seção da comparação lê:

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

e o arquivo de entrada, que não monta nada além do card:

```typescript
// src/main.ts: the card, and nothing else, in the page's #app.
import { createApp } from 'vue'
import WeekCard from './WeekCard.vue'

createApp(WeekCard).mount('#app')
```

Inicie com `npm run dev`, e marque a segunda sessão:

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

**70 de 70, e o setup rodou uma vez**, antes de a página ser desenhada, e não de novo quando a caixa foi
marcada: a marcação mudou `s.done` numa lista reativa, os dois `computed`s que a leem foram marcados como
desatualizados, e só as partes do template que os usam foram redesenhadas. É a aula 2 e a aula 3, o
modelo inteiro numa linha de console. As próximas três seções são o mesmo card, e o mesmo teste dele,
nos outros três frameworks.
