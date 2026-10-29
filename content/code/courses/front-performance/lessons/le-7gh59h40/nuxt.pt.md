---
title: Nuxt
version: 1
---

**No Nuxt um arquivo em `app/pages/` é um endereço.** `app/pages/index.vue` atende `/`, e
`app/pages/courses/[slug].vue` atende `/courses/` seguido de qualquer coisa, com `slug` como
parâmetro. Uma página é um componente Vue comum; o Nuxt a renderiza no servidor na primeira
requisição e a hidrata no navegador. Os dados que o servidor fornece ficam numa pasta à parte,
`server/`, que nunca chega ao navegador.

Os dados são um endpoint do próprio servidor do projeto. Salve isto como `server/api/plan.get.ts`;
a pasta faz dele `/api/plan`, e o `.get` faz ele responder só a `GET`:

```typescript
// server/api/plan.get.ts: the planner's data, read on the server, at /api/plan.
import { readFile } from "node:fs/promises";

export default defineEventHandler(async () => JSON.parse(await readFile("courses.json", "utf8")));
```

`defineEventHandler` não é importado: o Nuxt importa as suas próprias funções para você, no
servidor e nas páginas. A página em volta de toda rota substitui o `app/app.vue` do criador, e
`<NuxtPage />` é onde entra a página do endereço:

```html
<!-- app/app.vue: the page around every route. -->
<template>
  <main>
    <NuxtPage />
  </main>
</template>
```

A página inicial, num `app/pages/index.vue` novo. **`useFetch` é a linha que decide como esta
página renderiza**: no servidor ele chama `/api/plan` diretamente, sem passar pela rede, e põe o
resultado na página que manda; no navegador ele acha esse resultado já lá e não busca de novo:

```html
<!-- app/pages/index.vue: the address /. -->
<script setup lang="ts">
const { data: plan } = await useFetch("/api/plan");
</script>

<template>
  <h1>Study planner</h1>
  <ul>
    <li v-for="c in plan.courses" :key="c.slug">
      <NuxtLink :to="`/courses/${c.slug}`">{{ c.title }}</NuxtLink> ·
      {{ plan.sessions.filter((s) => s.course === c.slug).length }} sessions
    </li>
  </ul>
</template>
```

E um curso, em `app/pages/courses/[slug].vue`. `createError` com status 404 faz o servidor responder
a um curso desconhecido com uma página 404:

```html
<!-- app/pages/courses/[slug].vue: the address /courses/<slug>. -->
<script setup lang="ts">
const slug = useRoute().params.slug as string;
const { data: plan } = await useFetch("/api/plan");
const course = plan.value.courses.find((c) => c.slug === slug);
if (!course) throw createError({ statusCode: 404 });
</script>

<template>
  <p><NuxtLink to="/">All courses</NuxtLink></p>
  <h1>{{ course.title }}</h1>
  <ul>
    <li v-for="s in plan.sessions.filter((s) => s.course === slug)" :key="s.id">
      {{ s.date }} · {{ s.minutes }} min{{ s.done ? " · done" : "" }}
    </li>
  </ul>
</template>
```

Por último, a configuração, no lugar do `nuxt.config.ts`, que dá a toda página o mesmo título e a
mesma língua do planner:

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  app: { head: { title: "Study planner", htmlAttrs: { lang: "en" } } },
});
```

`compatibilityDate` veio do criador e fica. Ele diz ao Nuxt e ao seu servidor qual comportamento
manter quando uma versão posterior muda um padrão, para que o projeto se comporte como no dia em que
foi criado até alguém mudar a data.

## Build e servidor

`npm run build` escreve tudo em `.output/`: os arquivos do navegador em `.output/public` e um
servidor em `.output/server`. Ele imprime uma lista longa dos arquivos que escreveu, que não está
reproduzida aqui, então este build a manda para lugar nenhum e olha o que ele fez:

```
ana@dev:~/meta/nuxt$ npm run build >/dev/null 2>&1; ls .output .output/server
.output:
nitro.json
public
server

.output/server:
chunks
index.mjs
index.mjs.map
node_modules
package.json
```

**O servidor construído leva os poucos pacotes de que precisa num `node_modules` só dele**, uns
poucos megabytes, então `.output` pode ser copiado para outro computador como está, sem os 200 MB
que o projeto instalou. **O Nuxt renderiza no servidor a cada requisição, por padrão**; nada aqui
foi renderizado no build, e a seção "Modo de renderização, por rota" mostra a chave que muda isso.
Ligue-o no segundo terminal:

```sh
PORT=3002 node .output/server/index.mjs
```
