---
title: Route rules, um modo por página
version: 1
---

**O `routeRules` no `nuxt.config.ts` dá a cada endereço a sua forma de ser renderizado, num projeto
só.** A semana do planner precisa do servidor toda vez, a página `about` seria o mesmo arquivo para
todo leitor para sempre, e as páginas de curso ficam no meio: mudam quando uma sessão é marcada, e
ninguém se importa se passar um minuto antes. O planner ganha uma página `about`:

```html
<!-- app/pages/about.vue: the page at /about, the same for everybody -->
<template>
  <h1>About the planner</h1>
  <p>
    The study planner keeps the sessions of three courses, a week at a time. It is the project of the
    vue course, built twice: once with Vite and Vue Router, once with Nuxt.
  </p>
</template>
```

e três regras, uma de cada tipo:

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
    // Drawn by the server at most once a minute; the copy is served meanwhile.
    '/courses/**': { swr: 60 },
    // No cache between the server and the browser may keep an answer of the API.
    '/api/**': { headers: { 'cache-control': 'no-store' } },
  },
})
```

`prerender: true` é a geração estática da última seção, para uma página, dentro de um build normal.
`swr: 60` é *stale-while-revalidate*: o servidor renderiza a página uma vez, guarda o HTML e, pelos
sessenta segundos seguintes, responde com essa cópia; a primeira requisição depois disso ainda recebe
a cópia velha, na hora, e faz o servidor renderizar uma nova em segundo plano. O `isr` do Nuxt,
*incremental static regeneration*, é a mesma ideia executada pelos hosts que a suportam, que guardam a
cópia na própria rede em vez de no servidor. `headers` define cabeçalhos da resposta, aqui um que diz a
todo cache no caminho para não guardar o que a API responde. Faça o build:

```
ana@dev:~/vue/planner-nuxt$ npm run build 2>&1 | grep -i prerender
[nitro] ℹ Initializing prerenderer
[nitro] ℹ Prerendering 1 routes
[nitro] ℹ Prerendered 2 routes in 1.688 seconds
ana@dev:~/vue/planner-nuxt$ ls .output/public
_nuxt
about
favicon.ico
robots.txt
```

**`about` agora é uma pasta de `.output/public`**, um arquivo que um host estático ou uma CDN manda sem
perguntar ao servidor. As outras regras são executadas pelo servidor em tempo de execução. Suba-o e leia
os cabeçalhos:

```
ana@dev:~/vue/planner-nuxt$ curl -s -D - -o /dev/null http://localhost:3000/api/courses | grep -i cache-control
cache-control: no-store
ana@dev:~/vue/planner-nuxt$ curl -s -D - -o /dev/null http://localhost:3000/courses/spanish | grep -i cache-control
cache-control: s-maxage=60, stale-while-revalidate
```

A API diz `no-store`, e a página de curso `s-maxage=60, stale-while-revalidate`, a instrução que deixa
um cache na frente do servidor, o de uma CDN, fazer a mesma guarda.

## Sessenta segundos da página velha

Conte as caixas marcadas na página de espanhol, marque a outra sessão dela e conte de novo:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
1
ana@dev:~/vue/planner-nuxt$ curl -s -w '\n' -X PATCH http://localhost:3000/api/sessions/s6
{"id":"s6","course":"spanish","date":"2026-10-23","minutes":40,"done":true}
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
1
```

**Continua uma.** A marcação está nos dados do servidor, e a página veio da cópia renderizada antes
dela. Depois que o minuto passa:

```
ana@dev:~/vue/planner-nuxt$ sleep 60
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
1
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l
2
```

**A primeira requisição depois do minuto recebeu a cópia velha, e a segunda a nova**: a primeira
disparou a nova renderização e não esperou por ela. Essa é a troca que o `swr` faz de propósito, uma
resposta rápida com no máximo um minuto e uma requisição de atraso, e é a troca errada para uma página
cujo leitor acabou de mudá-la. Um estudante que marca uma sessão na página do curso e a recarrega vê a
marcação sumir; a cópia do próprio navegador, hidratada e atualizada pelo `useFetch`, está certa, mas o
HTML não. No planner, o `swr` é para páginas que muitos leem e poucos mudam, e as páginas de curso não
são assim. A regra fica pelo resto desta aula, para ser discutida na última seção.

## Uma regra não é uma tranca

As route rules decidem como uma página é renderizada e guardada em cache. **Não são o lugar de nada que
precise se sustentar**. O Nuxt publicou um alerta de segurança, o GHSA-vjh5-4x84-xrqp, de que as route
rules, incluindo as dos tipos `headers` e `redirect`, eram ignoradas quando um endereço era escrito com
outras maiúsculas, `/API/courses` em vez de `/api/courses`, em servidores que tratam os dois como um só;
ele cobre todo Nuxt até a 4.6.1, o que é mais um motivo para a aula 18 ter instalado a 4.6.2.
A lição a guardar é a geral: um cabeçalho que protege alguma coisa, um redirecionamento para longe de
uma página privada, precisa ser garantido pelo código que serve a coisa, ou pelo host, e não só por um
padrão que casa com o endereço dela.

`ssr: false` é a última regra que vale conhecer: aquele endereço é mandado como uma casca vazia e
desenhado no navegador, do jeito do planner do Vite, para uma página que não tem nada a ganhar com o
servidor.
