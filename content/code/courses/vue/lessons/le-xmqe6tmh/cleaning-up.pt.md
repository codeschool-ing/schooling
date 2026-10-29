---
title: Limpando, e o relógio do planner
version: 1
---

**O que um componente começa fora do Vue, ele precisa parar quando é removido.** Um timer, um listener
em `window` ou `document`, uma conexão com um servidor, um observer vigiando a página: para o navegador,
nenhum deles pertence ao componente, e remover os elementos do componente não os para. O Vue limpa o que
o Vue criou, as renderizações e os watchers criados durante o setup (aula 4), e nada mais.

Dois componentes com um timer cada, e só um deles limpa:

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

Deixe-os tiquetaquear por um quarto de segundo, remova os dois e espere mais um quarto:

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

**Depois da remoção, o `careless` continua tiquetaqueando e o `tidy` para.** O componente careless
sumiu da página e do Vue, e o intervalo dele ainda roda, a cada décimo de segundo como o código pede (um navegador ocupado
carregando uma página encaixa alguns a mais ou a menos), segurando o `name` do
componente e tudo o mais que a função dele alcança. Mostre e esconda um componente assim cem vezes e
cem intervalos estarão rodando. A aula 19 de `javascript` chamou isso de vazamento que você mesmo causa,
e é assim que ele aparece num componente.

## A regra

**Comece no `onMounted`, pare no `onUnmounted`**, e guarde o que a parada precisa, o id do timer, a
função do listener, numa variável que os dois enxerguem. Os pares para lembrar:

| começado com | parado com |
|---|---|
| `setInterval(fn, ms)` | `clearInterval(id)` |
| `window.addEventListener('resize', fn)` | `window.removeEventListener('resize', fn)`, com a mesma `fn` |
| `new ResizeObserver(fn).observe(el)` | `observer.disconnect()` |
| um `fetch` ainda em andamento | o `abort()` de um `AbortController`, aula 4 |

A aula 10 empacota um par assim num composable, para que um componente peça "a largura da janela" e o
começo e o fim venham junto.

## O relógio do planner

O planner tem um valor que muda sem ninguém mexer nele: a data de hoje. Ela era lida uma vez, quando a
página abria, e um planner deixado aberto durante a noite continuaria chamando ontem de hoje. Então o
`App.vue` mantém um ref `today` e o atualiza a cada minuto com um timer que ele começa e para:

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

Essas linhas vão logo depois de `monday`, com `onMounted` e `onUnmounted` acrescentados ao import de
`vue` e `isoDate` ao import de `./planner.js`. Cada linha então fica sabendo se é a de hoje, com
`:today="session.date === today"` ao lado de `:session`, e o `SessionRow` a marca:

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

Com o relógio na quarta-feira, 21 de outubro:

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

O `App` é a raiz da aplicação e só é removido quando a página fecha, então o `onUnmounted` dele
raramente vai rodar. Ele é escrito mesmo assim: a aula 21 monta o `App` num teste e o desmonta, e a aula
10 leva essas linhas para um composable que qualquer componente pode usar, onde a limpeza importa toda
vez.
