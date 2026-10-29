---
title: useFetch, e onde a requisição é feita
version: 1
---

**O `useFetch(url)` busca os dados de que uma página precisa, uma vez, no lado que renderiza a página
primeiro, e entrega o resultado ao outro lado.** Essa é a primeira linha das duas páginas do planner
desde a aula 18, e a aula 19 mostrou o que ela comprou: uma página que chega desenhada, e um navegador
que nunca pede `/api/courses` quando a página é carregada pela primeira vez. Esta aula a desmonta, e o primeiro passo é ver cada requisição que
chega à API. Um arquivo em `server/middleware/` roda antes de toda rota do servidor, e este só
imprime:

```typescript
// server/middleware/log.ts: a line in the server's terminal for every request to the API.
export default defineEventHandler((event) => {
  if (event.path.startsWith('/api/')) console.log(`api: ${event.method} ${event.path}`)
})
```

Ele não devolve nada, então a requisição segue para a sua rota como antes. Mais uma mudança antes: a
aula 19 deixou o `swr` nas páginas de curso e argumentou contra ele, e ele sai agora, porque uma página
em cache esconderia requisições que esta aula quer contar. O `nuxt.config.ts` sem ele:

```typescript
// nuxt.config.ts: the study planner, made by Nuxt.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  // Off, as lesson 1 left Vue's: a button and requests of their own in every page.
  devtools: { enabled: false },
  css: ['~/assets/main.css'],
  app: {
    head: { htmlAttrs: { lang: 'en' }, title: 'Study planner' },
  },
  routeRules: {
    // Drawn once, by the build: nothing on it changes between two deploys.
    '/about': { prerender: true },
    // No cache between the server and the browser may keep an answer of the API.
    '/api/**': { headers: { 'cache-control': 'no-store' } },
  },
})
```

Suba o servidor de desenvolvimento, abra a semana e liste o que o navegador pede à API:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --text - | grep '/api/'
```

**Nada.** E o terminal do servidor, no fim das linhas de inicialização:

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
✔ Vite client built in 48ms
✔ Vite server built in 18ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1322ms
◆ Ready in 2.63s  → http://localhost:3000/
  config 230ms · modules 81ms · app 349ms · types 358ms · bundle 204ms · server 1.41s
(node:29149) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
api: GET /api/courses
```

**Uma requisição, feita pelo servidor enquanto renderizava a página.** O navegador recebeu a resposta
dentro da página, no payload, e o `useFetch` no navegador a achou lá em vez de perguntar. Agora clique
num curso, uma navegação dentro da página em execução:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --do 'click text=Spanish' --text - | grep '/api/'
net  GET /api/courses  200
```

**Desta vez o navegador perguntou.** Nenhum servidor renderiza uma página que o router troca no lugar,
então o `useFetch` da página do curso roda no navegador, e o navegador faz a requisição. De um jeito
ou de outro, ela acontece uma vez por página mostrada, que é todo o trabalho da função.

## O que ele devolve

```typescript
const { data, status, error, refresh } = await useFetch('/api/courses')
```

- `data` é um ref com o JSON já interpretado, `undefined` até ele chegar. O tipo dele vem da rota do
  servidor: o Nuxt lê o que o `courses.get.ts` devolve, então `data.value?.sessions` é uma lista de
  `Session` sem nada declarado deste lado.
- `status` é `'idle'`, `'pending'`, `'success'` ou `'error'`.
- `error` guarda o erro quando a requisição falhou, e a seção sobre erros o usa.
- `refresh()` pergunta de novo, como o planner faz depois de cada marcação.

O `await` importa. No servidor, a renderização espera por ele, então o HTML é desenhado com os dados;
sem ele, o servidor mandaria a página antes de a resposta voltar. O `<Suspense>` da aula 15 é o que
permite que o setup de uma página seja `async`, e o Nuxt envolve cada página num deles.
