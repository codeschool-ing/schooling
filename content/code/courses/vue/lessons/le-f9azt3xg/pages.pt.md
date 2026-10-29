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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Arquivos em app/pages à esquerda e os endereços que eles viram à direita. index.vue é a rota /. about.vue, tracejado porque o planner não tem um, seria /about. courses/[id].vue é /courses/:id, com os colchetes fazendo de id um parâmetro, e ele responde a /courses/statistics, /courses/spanish e assim por diante. Embaixo, /courses/spanish/extra não tem arquivo, então não há página, e o servidor responde com um 404 de verdade.\"><text x=\"130\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">app/pages/</text><text x=\"405\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a rota</text><rect x=\"40\" y=\"36\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">index.vue</text><rect x=\"330\" y=\"36\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">/</text><line x1=\"222\" y1=\"52\" x2=\"326\" y2=\"52\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"326.0,52.0 318.6,55.1 318.6,48.9\" fill=\"var(--wire)\"></polygon><rect x=\"40\" y=\"86\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">about.vue</text><rect x=\"330\" y=\"86\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/about</text><line x1=\"222\" y1=\"102\" x2=\"326\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"326.0,102.0 318.6,105.1 318.6,98.9\" fill=\"var(--wire)\"></polygon><rect x=\"40\" y=\"136\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">courses/[id].vue</text><rect x=\"330\" y=\"136\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">/courses/:id</text><line x1=\"222\" y1=\"152\" x2=\"326\" y2=\"152\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"326.0,152.0 318.6,155.1 318.6,148.9\" fill=\"var(--wire)\"></polygon><text x=\"274\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seria</text><rect x=\"540\" y=\"118\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/statistics</text><line x1=\"482\" y1=\"152\" x2=\"536\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"536.0,132.0 530.2,137.5 528.0,131.6\" fill=\"var(--wire)\"></polygon><rect x=\"540\" y=\"158\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/spanish</text><line x1=\"482\" y1=\"152\" x2=\"536\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"536.0,172.0 528.0,172.4 530.2,166.5\" fill=\"var(--wire)\"></polygon><text x=\"130\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhum arquivo para ele</text><rect x=\"300\" y=\"204\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">/courses/spanish/extra</text><line x1=\"482\" y1=\"218\" x2=\"526\" y2=\"218\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"526.0,218.0 518.6,221.1 518.6,214.9\" fill=\"var(--amber)\"></polygon><rect x=\"530\" y=\"204\" width=\"170\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">404 do servidor</text></svg>", "caption": "O caminho de um arquivo em pages/ é o seu endereço; colchetes fazem um parâmetro."}
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
