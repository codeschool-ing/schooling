---
title: Layouts, a moldura em volta das páginas
version: 1
---

**Um layout é um componente com um `<slot />` onde a página entra, guardado em `app/layouts/`.** O
`App.vue` do planner do Vite desenhava um cabeçalho, o `<RouterView>` e um rodapé, e toda página
aparecia dentro dessa moldura. No Nuxt a moldura é um layout, o `app.vue` diz onde os layouts são
desenhados, e uma página pode escolher outro. O `app/layouts/default.vue` é o que toda página recebe, a
menos que peça outro:

```html
<!-- app/layouts/default.vue: the frame around every page. -->
<script setup lang="ts">
import { version } from 'vue'
</script>

<template>
  <header>
    <p class="brand"><NuxtLink to="/">Study planner</NuxtLink></p>
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <p>Built with Vue {{ version }}, by Nuxt</p>
  </footer>
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
.brand {
  font-size: 1.5rem;
  font-weight: 700;
}
footer p {
  color: #666;
  font-size: 0.875rem;
}
</style>
```

O `version` continua importado: as importações automáticas cobrem as funções do Nuxt e as funções de
composição do próprio Vue, `ref`, `computed` e as demais, mas não todo nome que o pacote `vue` exporta. O
`app.vue` põe a página dentro do layout:

```html
<!-- app/app.vue -->
<template>
  <NuxtRouteAnnouncer />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text body
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Study planner

Study planner

This week
Statistics
Spanish
Guitar

Built with Vue 3.5.44, by Nuxt
```

**O cabeçalho e o rodapé vieram do layout, o título e a lista vieram da página**; o primeiro *Study
planner* é o anunciador de rotas da seção anterior. Uma página que quer outra moldura a nomeia,
`definePageMeta({ layout: 'print' })` para um `layouts/print.vue`, e `layout: false` para nenhuma. O
planner só precisa de uma.

## A página de erro

Quando falta uma rota, ou uma página lança um erro, o Nuxt desenha o `app/error.vue` no lugar da
página, no servidor e no navegador, e com o status HTTP certo. Ele é um componente à parte, fora das
páginas, então não recebe o layout a menos que o peça com `<NuxtLayout>`:

```html
<!-- app/error.vue: what Nuxt draws in place of a page that does not exist or failed. -->
<script setup lang="ts">
import type { NuxtError } from '#app'

const { error } = defineProps<{ error: NuxtError }>()
</script>

<template>
  <NuxtLayout>
    <h1>{{ error.statusCode === 404 ? 'Nothing here' : 'Something went wrong' }}</h1>
    <p>{{ error.statusMessage }}</p>
    <p><button @click="clearError({ redirect: '/' })">Back to this week</button></p>
  </NuxtLayout>
</template>
```

O `#app` é o módulo de tipos e funções do próprio Nuxt, onde mora o `NuxtError`. O `clearError` é
importado automaticamente, e ele é um botão e não um link de propósito: ele encerra o estado de erro além
de sair do endereço, para que a próxima página seja desenhada normalmente. Peça a página que falta de
novo:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/courses/spanish/extra --text body
[error] Failed to load resource: the server responded with a status of 404 (Page not found: /courses/spanish/extra)
[vite] connecting...
[vite] connected.
[warn] [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
[warn] [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Study planner

Nothing here

Page not found: /courses/spanish/extra

Back to this week

Built with Vue 3.5.44, by Nuxt
```

**A moldura do próprio planner, em volta da mensagem que o Nuxt escreveu para a rota que falta**, e ainda um `404` por
baixo.
