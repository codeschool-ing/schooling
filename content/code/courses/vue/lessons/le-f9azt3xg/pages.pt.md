---
title: Páginas, rotas a partir de arquivos
version: 1
---

**Um arquivo `.vue` em `app/pages/` é uma rota, e o caminho dele nessa pasta é o endereço.** Não há
lista para manter: `pages/index.vue` é `/`, `pages/about.vue` seria `/about`, e uma parte do nome entre
colchetes é um parâmetro, então `pages/courses/[id].vue` é `/courses/:id`, a rota que a aula 12 escreveu
à mão. Primeiro o `app.vue` troca a página de boas-vindas pelo `<NuxtPage />`, o `<RouterView>` do Nuxt,
onde a página do endereço atual é desenhada:

```html
<!-- app/app.vue -->
<template>
  <NuxtRouteAnnouncer />
  <NuxtPage />
</template>
```

O `<NuxtRouteAnnouncer>` já estava no template, e fica: ele é uma região que um leitor de tela lê em voz
alta, com o título da página, para que uma navegação que troca a página sem carregar uma nova seja
anunciada, o trabalho que a aula 12 fazia definindo o `document.title` no `afterEach`. Depois as duas
páginas, curtas por enquanto; a última seção da aula as completa:

```html
<!-- app/pages/index.vue: the page at / -->
<template>
  <h1>This week</h1>
  <ul>
    <li><NuxtLink to="/courses/statistics">Statistics</NuxtLink></li>
    <li><NuxtLink to="/courses/spanish">Spanish</NuxtLink></li>
    <li><NuxtLink to="/courses/guitar">Guitar</NuxtLink></li>
  </ul>
</template>
```

```html
<!-- app/pages/courses/[id].vue: the page at /courses/statistics, /courses/spanish and so on -->
<script setup lang="ts">
const route = useRoute()
</script>

<template>
  <h1>The course {{ route.params.id }}</h1>
  <p><NuxtLink to="/">Back to the week</NuxtLink></p>
</template>
```

Nenhum `import` em lugar nenhum: `NuxtLink` e `useRoute` estão lá sem um, que é a seção de importações
automáticas. O `<NuxtLink>` é o `<RouterLink>` com mais coisas, e a segunda transcrição abaixo diz quais.

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text body
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Study planner
This week
Statistics
Spanish
Guitar
```

O *Study planner* acima do título é o anunciador de rotas: ele fica escondido da vista, mas não do
`innerText`.

## Navegando, e o que já tinha sido buscado

Clique num curso e observe os pedidos, deixando de fora os módulos do próprio Nuxt e do Vue:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --do 'click text=Spanish' --text body | grep -v '^net  GET /_nuxt/@'
net  GET /  200
net  GET /_nuxt/home/ana/vue/planner-nuxt/node_modules/nuxt/dist/app/entry.async.js  200
[vite] connecting...
[vite] connected.
net  GET /_nuxt/app.vue  200
net  GET /_nuxt/pages/index.vue  200
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
net  GET /_nuxt/pages/courses/[id].vue  200
== the text of body
Study planner
The course spanish

Back to the week
```

**O clique pediu um arquivo, o código da própria página, `pages/courses/[id].vue`, e nenhum documento
novo**: não há um segundo `GET /`, porque o router trocou a página no lugar, como fazia o do planner do
Vite. Cada página é um chunk próprio, carregado na primeira vez que é preciso. Um `<NuxtLink>` também
tenta chegar antes do clique: quando o navegador fica ocioso, ele busca o código de toda página para a
qual aponta um link visível, o que o Nuxt chama de *prefetching*. O `look` clicou antes de o navegador
ter um momento ocioso, então aqui o pedido vem depois de `-- click`. Uma pessoa lendo a página dá esse
momento ao navegador muito antes de clicar, então para ela o pedido vem primeiro, e o clique não tem
mais nada para esperar.

## O HTML vem do servidor

O mesmo endereço pedido com `curl`, que não roda JavaScript nenhum:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<h1>[^<]*</h1>'
<h1>The course spanish</h1>
```

**O título está no HTML que o servidor mandou.** No planner do Vite, o `curl` de uma página de curso
teria encontrado um `<div id="app">` vazio e mais nada, porque o título era desenhado pelo JavaScript no
navegador. Aqui o servidor rodou o componente da página e mandou o que ele desenhou. A aula 19 trata do
que isso traz e do que custa; esta seção só precisa saber que acontece.

## Um endereço sem página

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
404
Page not found: /courses/spanish/extra

Page not found: /courses/spanish/extra

Go back home
```

**Um 404 de verdade, do servidor**, a primeira linha da transcrição, antes de qualquer script rodar, o
que o planner do Vite não conseguia fazer: o servidor dele mandava o `index.html` para todo endereço, e a
rota catch-all da aula 12 desenhava uma página de *não encontrado* num `200`. O Nuxt conhece suas rotas
no servidor, então responde com o status certo. O Vue Router avisa que nenhuma rota corresponde, no
console do navegador e no terminal do servidor, e a página é a página de erro do próprio Nuxt, que a
próxima seção substitui.

O terminal do servidor de desenvolvimento conta como ele recebeu a mudança:

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
✔ Vite client built in 53ms
✔ Vite server built in 26ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1357ms
◆ Ready in 2.76s  → http://localhost:3000/
  config 255ms · modules 68ms · app 333ms · types 313ms · bundle 247ms · server 1.54s
(node:9550) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
ℹ hmr update /app.vue
[nuxt] ℹ Pages enabled
[nuxt] ℹ Pages enabled
(node:9693) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use `node --trace-warnings ...` to show where the warning was created)
ℹ Nuxt requested a restart. Reloading Nuxt...
ℹ Re-optimizing dependencies because vite config has changed
✔ Vite client built in 26ms
✔ Vite server built in 21ms
[nitro] ✔ Nuxt Nitro server built in 903ms
(node:9550) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
WARN  [VUE_ROUTER_R0004] No match found for location with path "/courses/spanish/extra"
├▶ fix: Add a route matching this path or check for typos in the location.
╰▶ see: https://router.vuejs.org/guide/essentials/dynamic-matching.html#Catch-all-404-Not-found-Route
```

`hmr update /app.vue` e então, quando a pasta `pages` apareceu, **`Pages enabled` e um reinício**: um
projeto sem `pages/` não tem router nenhum, e acrescentar a pasta muda o que o Nuxt monta, então ele
recomeça sozinho.
