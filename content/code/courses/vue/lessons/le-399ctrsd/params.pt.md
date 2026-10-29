---
title: Parâmetros, um curso por endereço
version: 1
---

**Um segmento de caminho escrito como `:id` é um parâmetro: casa com o que estiver naquela posição e o
entrega à view.** `/courses/:id` casa com `/courses/spanish` e com `/courses/guitar`, e a view fica sabendo
qual com `id` valendo `spanish` ou `guitar`. Uma rota, um componente, tantas páginas quantos forem os
cursos.

```html
<!-- src/views/CourseView.vue -->
<script setup>
import { computed, inject } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { plannerKey } from '../keys.js'

// The route's :id arrives as a prop, because the route says `props: true`.
const { id } = defineProps({ id: { type: String, required: true } })
const { courses } = inject(plannerKey)

const course = computed(() => courses.value.find((c) => c.id === id))
</script>

<template>
  <h1>{{ course?.title ?? id }}</h1>
  <p v-if="course">Goal: {{ course.goal }} minutes a week</p>
  <nav aria-label="Sessions">
    <RouterLink :to="{ name: 'course-week', params: { id } }">This week</RouterLink> ·
    <RouterLink :to="{ name: 'course-all', params: { id } }">All sessions</RouterLink>
  </nav>
  <RouterView :course="id" />
</template>

<style scoped>
.router-link-exact-active {
  font-weight: 700;
}
</style>
```

Abra a semana e clique no primeiro link que diz Spanish, que é o título do card do curso:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --text main
[vite] connecting...
[vite] connected.
-- click text=Spanish >> nth=0
== the text of main
Spanish

Goal: 120 minutes a week

This week · All sessions
 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

`text=Spanish >> nth=0` é o jeito do Playwright de dizer "o primeiro elemento cujo texto é Spanish". A
página mudou para o curso sem recarregar: o cabeçalho e o rodapé ficaram, e só o que está dentro do
`<RouterView>` foi substituído.

## Dois jeitos de ler um parâmetro

A rota diz `props: true`, então o router passa `params.id` para a view **como prop**, e a view a declara
como qualquer prop. O outro jeito é perguntar ao router:

```javascript
import { useRoute } from 'vue-router'
const route = useRoute()
// route.params.id, route.query, route.path, route.name, route.meta
```

**Prefira a prop.** Uma view que recebe `id` como prop pode ser usada, e testada na aula 21, dando a ela
um `id`; uma view que chama `useRoute()` precisa de um router inteiro em volta para funcionar. O
`useRoute()` é o certo para o que não é parâmetro, como a query string, ou para a página que trata do
próprio endereço, como a `NotFound` na seção sobre guards.

## A mesma view, um parâmetro novo

Vá de `/courses/spanish` para `/courses/guitar` e o router não destrói a `CourseView` para criar outra: a
rota é a mesma, então ele **reaproveita o componente e muda a prop**. Isso é rápido, e significa que
qualquer código que rodou uma vez no setup com o `id` antigo não roda de novo. A `CourseView` foi escrita
para isso: `course` é um `computed` de `id`, então acompanha. Uma view que buscasse os dados do curso uma
vez, no setup, continuaria mostrando Spanish num endereço de Guitar. Se uma view precisa reagir à troca,
observe a prop, `watch(() => id, …)`, a forma com getter da aula 4, ou use `onBeforeRouteUpdate` do Vue
Router.
