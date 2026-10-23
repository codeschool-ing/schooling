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
