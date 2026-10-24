---
title: A busca dupla, e a primeira renderização vazia
version: 1
---

**O setup de um componente roda no servidor e de novo no navegador, então uma requisição escrita nele
com um `$fetch` simples é feita duas vezes.** É o erro que todo iniciante em renderização no servidor
comete uma vez, porque o código se parece com o que o planner do Vite tinha. Uma página para mostrar
isso, numa pasta de demonstrações que esta seção apaga no fim:

```html
<!-- app/pages/demo/twice.vue: $fetch in setup, the way not to do it -->
<script setup lang="ts">
const data = ref()
data.value = await $fetch('/api/courses')
</script>

<template>
  <p>{{ data.sessions.length }} sessions</p>
</template>
```

Reinicie o servidor de desenvolvimento, para o terminal começar limpo, e abra a demonstração:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/demo/twice --network --text main | grep -v '^net  GET /_nuxt'
net  GET /demo/twice  200
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
net  GET /api/courses  200
== the text of main
6 sessions
```

**O próprio navegador pediu `/api/courses`**, embora a página tenha chegado com o número desenhado. O
servidor rodou o setup, buscou, desenhou *6 sessions* e mandou o HTML; o navegador rodou o mesmo setup
para hidratar, e o `$fetch` não sabe nada de payloads, então buscou de novo. O terminal do servidor
concorda:

```
ana@dev:~/vue/planner-nuxt$ npm run dev

> dev
> nuxt dev

● Starting Nuxt...
● Nuxt 4.6.2 (with Nitro 2.13.5, Vite 8.3.5 and Vue 3.5.44)

  ➜ Local:    http://localhost:3000/
  ➜ Network:  use --host to expose

● Setting up modules
● Preparing app
● Generating types
● Bundling app
✔ Vite client built in 56ms
✔ Vite server built in 22ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1279ms
◆ Ready in 2.68s  → http://localhost:3000/
  config 304ms · modules 62ms · app 358ms · types 350ms · bundle 234ms · server 1.37s
(node:29744) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
api: GET /api/courses
api: GET /api/courses
api: GET /api/courses
```

Três linhas para uma visita: o `session-count` do layout, buscado pelo servidor; o `$fetch` da página,
feito pelo servidor; e o mesmo `$fetch` de novo, feito pelo navegador. No planner o custo é uma
requisição; numa página cujos dados mudaram nos milissegundos entre as duas, é também uma divergência
de hidratação, a resposta do servidor desenhada e a do navegador esperada. O `useFetch` e o
`useAsyncData` existem para que seja uma só.

## Buscando no onMounted, em vez disso

O outro hábito do código do lado do cliente é buscar no `onMounted`, que roda só no navegador:

```html
<!-- app/pages/demo/mounted.vue: fetched in the browser only -->
<script setup lang="ts">
const data = ref()
onMounted(async () => {
  data.value = await $fetch('/api/courses')
})
</script>

<template>
  <p v-if="data">{{ data.sessions.length }} sessions</p>
  <p v-else>Loading…</p>
</template>
```

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/demo/mounted | grep -o '<p>[^<]*</p>'
<p>Loading…</p>
```

**O servidor manda *Loading…***, e o número só chega depois que o navegador rodou a página e fez a
requisição ele mesmo. Isso é renderização no cliente dentro de uma aplicação Nuxt, com tudo o que a
aula 19 disse contra ela. Está certo para dados que pertencem ao navegador, como o `today` da aula 19,
e errado para dados que o servidor poderia ter buscado.

Apague as demonstrações:

```
ana@dev:~/vue/planner-nuxt$ rm -r app/pages/demo
```
