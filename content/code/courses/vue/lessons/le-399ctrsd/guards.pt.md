---
title: Guards, e o endereço que não leva a lugar nenhum
version: 1
---

**Um navigation guard é uma função que o router chama durante uma navegação, e que pode deixá-la seguir,
mandá-la para outro lugar ou cancelá-la.** É o lugar do router para decisões que dependem de para onde o
aluno está indo: esta página é permitida, este curso existe, o título deve mudar. O planner usa dois
tipos, um antes de entrar numa rota e um depois de toda navegação.

## Antes de entrar: o curso existe?

`/courses/latin` casa perfeitamente com `/courses/:id`, e sem uma verificação a página do curso
desenharia um título dizendo `latin` sobre *Nothing planned this week.*, uma página que parece um curso sem nada
planejado. O guard `beforeEnter` da rota do curso pergunta antes:

```javascript
beforeEnter: async (to) => {
  if (!(await courseExists(to.params.id))) {
    return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') } }
  }
},
```

**O que um guard devolve decide a navegação**: nada, ou `true`, deixa seguir; um destino, como aqui,
redireciona para lá; `false` cancela e deixa o aluno onde estava. Um guard pode ser `async`, e o router
espera por ele, então ele pode buscar alguma coisa antes. O redirecionamento mantém o caminho que o aluno
digitou, para que a página de não encontrado possa dizer o que não foi encontrado:

```html
<!-- src/views/NotFound.vue -->
<script setup>
import { RouterLink, useRoute } from 'vue-router'

const route = useRoute()
</script>

<template>
  <h1>Not found</h1>
  <p>Nothing in the planner lives at {{ route.fullPath }}.</p>
  <p><RouterLink to="/">Back to this week</RouterLink></p>
</template>
```

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/latin --text main
[vite] connecting...
[vite] connected.
== the text of main
Not found

Nothing in the planner lives at /courses/latin.

Back to this week
```

E um endereço que não casa com rota nenhuma cai na mesma página, pela última rota, a que tem o caminho
que casa com tudo:

```
ana@dev:~/vue/planner$ look http://localhost:5173/nowhere/at/all --text '#app'
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

6 sessions, read from courses.json

Not found

Nothing in the planner lives at /nowhere/at/all.

Back to this week

Built with Vue 3.5.44
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três endereços à esquerda e onde cada um termina. /courses/spanish e /courses/latin casam com a rota /courses/:id, cujo guard beforeEnter pergunta se o curso existe. Para spanish existe, e a navegação segue para a página do curso. Para latin não existe, e o guard devolve a location de not-found, então a navegação é redirecionada para o NotFound.vue, que mantém o caminho digitado. /nowhere/at/all não casa com rota nenhuma além da última, cujo caminho casa com tudo, e chega ao mesmo NotFound.vue.\"><rect x=\"20\" y=\"36\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/spanish</text><rect x=\"20\" y=\"96\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/latin</text><rect x=\"20\" y=\"176\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/nowhere/at/all</text><rect x=\"220\" y=\"55\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/courses/:id</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">beforeEnter</text><text x=\"450\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o curso existe?</text><rect x=\"220\" y=\"170\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"370\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a última rota: o caminho dela casa com tudo</text><rect x=\"570\" y=\"24\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a página do curso</text><rect x=\"570\" y=\"140\" width=\"130\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">NotFound.vue</text><text x=\"635\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mantém o caminho digitado</text><line x1=\"172\" y1=\"51\" x2=\"216\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"216.0,68.0 208.0,68.3 210.2,62.4\" fill=\"var(--wire)\"></polygon><line x1=\"172\" y1=\"111\" x2=\"216\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"216.0,88.0 210.9,94.2 208.0,88.7\" fill=\"var(--wire)\"></polygon><line x1=\"352\" y1=\"77\" x2=\"376\" y2=\"77\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"376.0,77.0 368.6,80.1 368.6,73.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"60\" x2=\"566\" y2=\"44\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"566.0,44.0 560.1,49.4 558.0,43.6\" fill=\"var(--phosphor)\"></polygon><text x=\"536\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sim</text><line x1=\"522\" y1=\"96\" x2=\"590\" y2=\"137\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"590.0,137.0 582.1,135.9 585.3,130.5\" fill=\"var(--amber)\"></polygon><text x=\"548\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não: redireciona</text><line x1=\"172\" y1=\"191\" x2=\"216\" y2=\"191\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"216.0,191.0 208.6,194.1 208.6,187.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"191\" x2=\"566\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"566.0,180.0 559.6,184.8 558.1,178.8\" fill=\"var(--wire)\"></polygon></svg>", "caption": "O valor que o guard devolve decide a navegação; um endereço que nenhuma rota recebe acaba na mesma página."}
```

**Um endereço desconhecido nunca é mostrado como a semana.** Essa é a metade do router na regra que a
aula 2 encontrou no servidor de desenvolvimento: um endereço errado deve dizer que está errado, não
mostrar algo que parece certo.

## Depois de toda navegação: o título

O `router.afterEach` roda depois de toda navegação, inclusive uma que um guard cancelou ou
redirecionou, e recebe o que deu errado, se algo deu, como terceiro argumento. O planner o usa para
definir o título da aba a partir do `meta` da rota, e só quando nada deu errado:

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/spanish --html title --text -
[vite] connecting...
[vite] connected.
== the HTML of title
<title>Course · Study planner</title>
```

A aba do navegador diz qual página é, e o mesmo fazem a lista do histórico e um favorito; uma aplicação
que nunca atualiza o título é uma em que toda página tem o mesmo nome. Um leitor de tela lê o título
quando uma página carrega, mas uma mudança feita pelo router, sem carregar página nenhuma, não é
anunciada de forma confiável: avisar um aluno cego de que a página mudou exige mover o foco para o
título da página nova, ou uma região viva, e a aula 12 de `front-quality` trata das duas coisas.

## Os guards que você vai encontrar

| guard | roda | uso típico |
|---|---|---|
| `router.beforeEach(fn)` | antes de toda navegação | "precisa estar logado": redirecionar para uma página de login |
| `beforeEnter` numa rota | antes de entrar naquela rota, não quando só os params mudam | verificar que um parâmetro nomeia algo que existe |
| `router.afterEach(fn)` | depois de toda navegação, com a falha, se houver, como terceiro argumento | títulos, analytics, mover o foco para o título da página nova |
| `onBeforeRouteLeave` numa view | antes de sair daquela view | "você tem alterações não salvas": perguntar, e devolver `false` para ficar |

A segunda linha tem um porém com que o planner convive: ir de `/courses/spanish` para `/courses/latin`
por um link só muda um parâmetro, então o `beforeEnter` não roda. O planner só cria links para cursos
que existem, e um endereço digitado na barra é uma entrada nova, que roda o guard; uma aplicação que cria
links para valores digitados pelo usuário verificaria no `beforeEach`.

Código antigo escreve guards com um terceiro argumento, `next`, e chama `next()` para seguir. A versão 5
ainda o executa, com um aviso de obsoleto em desenvolvimento, e é fácil de errar, porque esquecer de chamá-lo deixa a navegação parada; devolver um valor faz
o mesmo trabalho, e é o que este curso escreve.

O guard daqui busca o `courses.json` uma segunda vez, ao lado da carga do próprio `App`, porque um guard
roda fora de qualquer componente e não consegue fazer `inject` dos dados do `App`. Essa duplicação é a
deixa para a aula 13: uma store é um módulo, que pode ser importado de um guard tanto quanto de um
componente.
