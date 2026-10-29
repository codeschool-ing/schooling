---
title: useAsyncData, para tudo o que não é uma URL
version: 1
---

**`useFetch(url)` é um jeito curto de escrever `useAsyncData(key, () => $fetch(url))`.** O
`useAsyncData` é o geral: ele recebe um nome para os dados, a *chave*, e qualquer função que devolva
uma promise, e devolve os mesmos `data`, `status`, `error` e `refresh`. Tudo o que a seção anterior
disse sobre rodar uma vez e entregar o resultado é do `useAsyncData`; o `useFetch` só acrescenta que
faz a chave a partir da URL e chama o `$fetch` por você.

Então o `useAsyncData` serve para os casos em que os dados não são a resposta de uma URL: duas
requisições cujas respostas são combinadas, uma requisição cuja resposta é reduzida antes de a página
usá-la, ou algo que nem é uma requisição, lido de um módulo no servidor. O layout do planner ganha um
deles, uma linha no rodapé que conta todas as sessões planejadas:

```html
<!-- app/layouts/default.vue: the frame around every page. -->
<script setup lang="ts">
import { version } from 'vue'

// The reader's time zone, as their browser reports it. The server has its own.
const zone = () => Intl.DateTimeFormat().resolvedOptions().timeZone

// How many sessions the planner holds, in every course and every week.
const { data: planned } = await useAsyncData('session-count', () => $fetch('/api/courses'), {
  transform: (planner) => planner.sessions.length,
})
</script>

<template>
  <header>
    <p class="brand"><NuxtLink to="/">Study planner</NuxtLink></p>
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <p>{{ planned }} sessions planned in all. Built with Vue {{ version }}, by Nuxt</p>
    <ClientOnly>
      <p>Days are counted in {{ zone() }}</p>
      <template #fallback>
        <p>Days are counted in your browser's time zone</p>
      </template>
    </ClientOnly>
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

O `transform` roda sobre a resposta antes de ela ser guardada, então `planned` é um número e não os
dados inteiros do planner; a próxima seção mostra por que isso importa. O `useFetch` também aceita
`transform`. Reinicie o servidor de desenvolvimento, para que o terminal mostre só o que esta seção
pede, e abra a página:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text '#__nuxt > footer'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of #__nuxt > footer
6 sessions planned in all. Built with Vue 3.5.44, by Nuxt

Days are counted in America/Sao_Paulo
```

## Duas requisições onde poderia haver uma

O terminal do servidor tem duas linhas novas para aquela única página:

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
✔ Vite server built in 15ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1345ms
◆ Ready in 2.57s  → http://localhost:3000/
  config 229ms · modules 63ms · app 326ms · types 327ms · bundle 197ms · server 1.43s
(node:29444) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
api: GET /api/courses
api: GET /api/courses
```

**O `useFetch('/api/courses')` da página e o `useAsyncData('session-count', …)` do layout são duas
chaves, então são dois dados, buscados duas vezes.** Para duas chamadas pequenas num servidor só, isso
não é nada, e manter o número do layout separado vale a pena; a seção sobre chaves mostra o caso em
que compartilhar uma chave seria o erro. Quando duas partes de uma página realmente precisam da mesma
resposta, a cura simples é buscá-la numa delas, a página, e passá-la à outra como prop, para que haja
uma chamada para ler e uma requisição para contar.
