---
title: Suspense, e um setup que espera
version: 1
---

**Um componente cujo `<script setup>` usa `await` no nível mais alto é um *componente assíncrono*: ele
não pode ser desenhado antes de o setup terminar. O `<Suspense>` é o componente que espera todos os
componentes assíncronos dentro dele, mostra um fallback enquanto isso e põe o conteúdo de verdade no
lugar quando todos estão prontos.** Ele deixa um componente carregar os próprios dados com um `await`
simples, em vez dos flags de carregamento do `useFetchJson` da aula 10.

As notas de um curso, carregadas no nível mais alto do componente:

```html
<!-- src/demos/SlowCourse.vue -->
<script setup>
import { onMounted } from 'vue'

const { id } = defineProps({ id: String })

// A top-level await: this component's setup is asynchronous.
const response = await fetch(`/notes/${id}.json`)
const notes = await response.json()

// Registered after the await, and still attached to this component.
onMounted(() => console.log(`${id}: mounted with ${notes.notes.length} notes`))
</script>

<template>
  <p>{{ notes.course }}: {{ notes.notes.join(', ') }}</p>
</template>
```

Um fallback que se anuncia, e a demo que usa os dois:

```html
<!-- src/demos/LoadingNote.vue -->
<script setup>
import { onMounted, onUnmounted } from 'vue'

onMounted(() => console.log('fallback shown'))
onUnmounted(() => console.log('fallback removed'))
</script>

<template>
  <p>Loading the notes…</p>
</template>
```

```html
<!-- src/demos/SuspenseDemo.vue -->
<script setup>
import SlowCourse from './SlowCourse.vue'
import LoadingNote from './LoadingNote.vue'
</script>

<template>
  <Suspense @resolve="console.log('every async child is ready')">
    <div>
      <SlowCourse id="statistics" />
      <SlowCourse id="spanish" />
    </div>
    <template #fallback>
      <LoadingNote />
    </template>
  </Suspense>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SuspenseDemo'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
fallback shown
every async child is ready
statistics: mounted with 3 notes
spanish: mounted with 2 notes
fallback removed
== the text of #app
statistics: mean, median, variance

spanish: ser and estar, the subjunctive
```

A ordem das linhas é o mecanismo: **o fallback apareceu primeiro; depois os dois cursos se resolveram,
e o evento `resolve` avisou; depois os dois foram montados, e o fallback saiu.** As duas requisições
rodaram em paralelo, e o `<Suspense>` esperou a mais lenta antes de mostrar qualquer uma, então a
página nunca mostrou um curso com um buraco onde o outro estaria.

A primeira linha do console é uma mensagem que o Vue imprime como informação, e é o Vue sendo honesto: **o Suspense ainda está marcado como
experimental**, anos depois de ter chegado, e a API dele pode mudar. Ele é muito usado, e o Nuxt se
apoia nele (aula 20); escreva sabendo disso.

## O await que mantém o componente

A aula 10 disse que um composable ou um hook chamado depois de um `await` pode perder o componente, e
que o `<script setup>` é poupado disso. O `SlowCourse` registra o `onMounted` depois de dois `await`s, e
a transcrição mostra que ele rodou. Pergunte ao servidor de dev o que o compilador fez do script:

```
ana@dev:~/vue/sandbox$ curl -s 'http://localhost:5173/src/demos/SlowCourse.vue' | grep -n withAsyncContext
1:import { createHotContext as __vite__createHotContext } from "/@vite/client";import.meta.hot = __vite__createHotContext("/src/demos/SlowCourse.vue");import { withAsyncContext as _withAsyncContext } from "/node_modules/.vite/deps/vue.js?v=cfa4ec68"
17:  ([__temp,__restore] = _withAsyncContext(() => fetch(`/notes/${__props.id}.json`))),
23:  ([__temp,__restore] = _withAsyncContext(() => response.json())),
```

**Cada `await` foi envolvido em `_withAsyncContext`**, uma função que guarda qual componente está sendo
montado antes do `await` e o recoloca depois. É por isso que o `onMounted` achou o componente dele. Uma
função `async setup()` escrita à mão não tem compilador para fazer isso, e esse é o caso que o aviso da
aula 10 descreveu.

## Quando usar

O Suspense serve para dados sem os quais um componente não consegue desenhar nada útil, carregados uma
vez: os dados principais de uma página, uma tela de detalhe. Ele não serve para dados que mudam enquanto
o estudante digita, porque um Suspense que já se resolveu não mostra, por padrão, o fallback de novo
numa atualização; isso é trabalho para um watcher e um flag de carregamento, aula 10. E todo componente
assíncrono precisa de um `<Suspense>` acima dele: sem um, o Vue avisa que nenhuma fronteira de Suspense
foi encontrada, e o componente não desenha nada.
