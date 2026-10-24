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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 235\" role=\"img\" aria-label=\"Uma visita a /demo/twice, em ordem de tempo da esquerda para a direita, em duas linhas. No servidor: primeiro o session-count do layout busca GET /api/courses; depois o $fetch da página busca GET /api/courses; depois o servidor desenha 6 sessions e envia o HTML. No navegador: o mesmo setup roda de novo para hidratar, e o mesmo $fetch, que não sabe nada de payloads, busca GET /api/courses uma terceira vez. O terminal do servidor imprime uma linha para cada uma das três.\"><text x=\"20\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">servidor</text><text x=\"20\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">navegador</text><rect x=\"90\" y=\"40\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"162\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET /api/courses</text><text x=\"162\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o session-count do layout</text><text x=\"162\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><rect x=\"240\" y=\"40\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"312\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET /api/courses</text><text x=\"312\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o $fetch da página</text><text x=\"312\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><rect x=\"390\" y=\"40\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">desenha 6 sessions</text><text x=\"462\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">envia o HTML</text><rect x=\"410\" y=\"140\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">roda o mesmo setup</text><text x=\"482\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">para hidratar</text><rect x=\"565\" y=\"140\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"637\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET /api/courses</text><text x=\"637\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o mesmo $fetch, de novo</text><text x=\"637\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3</text><line x1=\"462\" y1=\"88\" x2=\"462\" y2=\"136\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"462.0,136.0 458.9,128.6 465.1,128.6\" fill=\"var(--wire)\"></polygon><text x=\"472\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTML</text><line x1=\"557\" y1=\"163\" x2=\"561\" y2=\"163\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"561.0,163.0 553.6,166.1 553.6,159.9\" fill=\"var(--wire)\"></polygon><line x1=\"90\" y1=\"212\" x2=\"710\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"710.0,212.0 702.6,215.1 702.6,208.9\" fill=\"var(--wire)\"></polygon><text x=\"400\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma visita, três linhas de api: GET /api/courses no terminal do servidor</text></svg>", "caption": "Um $fetch simples no setup roda nos dois lados, então o navegador pede de novo o que o servidor já desenhou."}
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
