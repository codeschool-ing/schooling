---
title: Por que uma store
version: 1
---

**Uma store é estado que mora fora de todos os componentes, com uma cópia para a aplicação inteira,
que qualquer componente pode ler e alterar pelas funções da própria store.** A aula 10 terminou com o
motivo de o planner precisar de uma: um composable cria estado novo a cada chamada, então duas páginas
que chamassem `usePlannerData()` teriam duas listas de sessões. E o guard da aula 12 teve de buscar os
cursos uma segunda vez, porque um guard não é um componente e não consegue injetar o que o `App` provê.

O **Pinia** é a biblioteca de stores do Vue, escrita por um membro do time do Vue e recomendada pela
documentação do Vue. Ela substituiu o Vuex, que você vai encontrar em código mais antigo. Instale-o
primeiro no sandbox, com a versão fixada:

```
ana@dev:~/vue/sandbox$ npm install --save-exact pinia@4.1.0

added 8 packages, and audited 47 packages in 1s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Uma store, como o router, é instalada na aplicação, então o `main.js` do sandbox ganha um `use`:

```javascript
// src/main.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'

// Every file in src/demos is a demo, and ?demo=NAME picks one.
const demos = import.meta.glob('./demos/*.vue')
const name = new URLSearchParams(location.search).get('demo')
const load = demos[`./demos/${name}.vue`]

if (load) {
  // Each demo gets a store container of its own, from lesson 13 on.
  load().then((module) => createApp(module.default).use(createPinia()).mount('#app'))
} else {
  document.querySelector('#app').textContent = `No demo called ${name}. There are: ${Object.keys(demos).join(', ')}`
}
```

O `createPinia()` cria o contêiner que guarda o estado de todas as stores. Cada demo ganha o seu, para
que o estado de uma demo não vaze para a próxima.

## O mesmo contador, duas vezes

Um total de minutos, escrito como o composable da aula 10 e como uma store, lado a lado:

```javascript
// src/demos/tally.js: the same minutes counter, as a composable and as a store.
import { ref } from 'vue'
import { defineStore } from 'pinia'

export function useTally() {
  const minutes = ref(0)
  const add = (m) => (minutes.value += m)
  return { minutes, add }
}

export const useTallyStore = defineStore('tally', () => {
  const minutes = ref(0)
  const add = (m) => (minutes.value += m)
  return { minutes, add }
})
```

As duas definições diferem em uma linha: a função da store é passada para `defineStore('tally', …)` em
vez de ser exportada como está. Uma caixa que usa as duas, e uma demo com duas caixas:

```html
<!-- src/demos/TallyBox.vue -->
<script setup>
import { useTally, useTallyStore } from './tally.js'

const { name } = defineProps({ name: String })
const own = useTally()
const shared = useTallyStore()
</script>

<template>
  <p :id="name">{{ name }}: composable {{ own.minutes }}, store {{ shared.minutes }}</p>
  <button :id="`add-${name}`" @click="own.add(15), shared.add(15)">Add 15 here</button>
</template>
```

```html
<!-- src/demos/WhyAStore.vue -->
<script setup>
import TallyBox from './TallyBox.vue'
</script>

<template>
  <TallyBox name="week" />
  <TallyBox name="course" />
</template>
```

Clique em somar 15 duas vezes na primeira caixa e uma vez na segunda:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=WhyAStore' --do 'click #add-week' --do 'click #add-week' --do 'click #add-course'
[vite] connecting...
[vite] connected.
-- click #add-week
-- click #add-week
-- click #add-course
== the text of #app
week: composable 30, store 45

Add 15 here

course: composable 15, store 45

Add 15 here
```

**Os composables contaram separados, 30 e 15; a store contou uma vez só, 45, e as duas caixas mostram
isso.** O `useTally()` rodou a sua função em cada caixa e criou duas refs `minutes`. O `useTallyStore()`
rodou a sua função na primeira vez em que foi chamado, guardou o resultado no contêiner do Pinia sob o id
`'tally'` e entregou a mesma store a todos que chamaram depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Antes e depois da store. Antes: App é dono dos dados e os provê às views; a guarda do router fica fora da árvore de componentes, então busca o courses.json por conta própria, uma segunda requisição. Depois: a store do planner é dona dos dados, dentro do contêiner do Pinia; App, as views, as linhas de sessão e a guarda chamam usePlannerStore e chegam à mesma store, e o courses.json é buscado uma vez.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">aula 12: provide</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">aula 13: uma store</text><rect x=\"100\" y=\"34\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">App</text><rect x=\"30\" y=\"104\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HomeView</text><line x1=\"170\" y1=\"70\" x2=\"95\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,102.0 100.6,96.2 103.0,102.0\" fill=\"var(--wire)\"></polygon><rect x=\"190\" y=\"104\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseView</text><line x1=\"170\" y1=\"70\" x2=\"255\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"255.0,102.0 247.0,102.3 249.2,96.5\" fill=\"var(--wire)\"></polygon><text x=\"170\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provide</text><rect x=\"30\" y=\"168\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">beforeEnter</text><rect x=\"200\" y=\"168\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"265\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">courses.json</text><line x1=\"162\" y1=\"183\" x2=\"198\" y2=\"183\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,183.0 190.6,186.1 190.6,179.9\" fill=\"var(--amber)\"></polygon><text x=\"180\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma segunda requisição</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><rect x=\"470\" y=\"100\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">usePlannerStore</text><rect x=\"395\" y=\"25\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">App</text><line x1=\"450\" y1=\"56\" x2=\"545\" y2=\"98\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,98.0 537.0,97.9 539.5,92.2\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"600\" y=\"25\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HomeView</text><line x1=\"655\" y1=\"56\" x2=\"545\" y2=\"98\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,98.0 550.8,92.5 553.0,98.3\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"395\" y=\"175\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SessionRow</text><line x1=\"450\" y1=\"174\" x2=\"545\" y2=\"142\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,142.0 539.0,147.3 537.0,141.4\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"600\" y=\"175\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">beforeEnter</text><line x1=\"655\" y1=\"174\" x2=\"545\" y2=\"142\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,142.0 552.9,141.1 551.2,147.0\" fill=\"var(--phosphor-dim)\"></polygon></svg>", "caption": "Uma store se alcança por import, então uma guarda chega a ela tão fácil quanto um componente."}
```

## O que uma store acrescenta a uma ref compartilhada

Uma `ref` exportada de um módulo, como o `clock.js` da aula 4, também é uma cópia para todo mundo. O que o
Pinia acrescenta é o que torna o estado compartilhado administrável quando uma aplicação tem algumas
pessoas trabalhando nela:

- **um contêiner por aplicação**, para que a renderização no servidor (aula 19) e os testes (aula 21) comecem
  cada execução com estado novo, em vez do que a última deixou num módulo;
- **um nome e uma forma**: toda store tem um id, o seu estado, os seus getters e as suas actions, então
  todo mundo sabe de onde uma mudança pode vir;
- **as ferramentas de desenvolvimento**: a extensão do Vue mostra cada store, o seu estado e uma linha do
  tempo de cada mudança;
- **ganchos em cada mudança**, `$subscribe` e `$onAction`, a quinta seção desta aula.
