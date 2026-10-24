---
title: O que o Nuxt acrescenta ao Vue
version: 1
---

**O Nuxt é Vue, Vite e um servidor, juntados por um conjunto de convenções sobre onde ficam os
arquivos.** Toda aula até aqui escreveu à mão algo que o Nuxt faz a partir do nome de uma pasta. A aula
12 escreveu o `router.ts`, uma lista de rotas, cada uma com um endereço e um componente para importar.
Todo componente desde a aula 6 começa com linhas de `import` nomeando os componentes e as funções que
usa. A aula 17 configurou o Vite. Num projeto Nuxt:

| você escreve | o Nuxt faz disso |
| --- | --- |
| um arquivo em `app/pages/` | uma rota, com o endereço tirado do caminho do arquivo: `pages/courses/[id].vue` é `/courses/:id` |
| um arquivo em `app/layouts/` | uma moldura dentro da qual as páginas são desenhadas, o cabeçalho e o rodapé que o `App.vue` do planner desenhava |
| um arquivo em `app/components/` | um componente que todo template pode usar sem importar |
| uma função em `app/composables/`, `app/utils/` ou `shared/utils/` | uma função que todo script pode chamar sem importar |
| um arquivo em `server/api/` | um endpoint de um servidor HTTP de verdade, `server/api/courses.get.ts` respondendo `GET /api/courses` |

Ainda há um router por baixo, o Vue Router 5, o mesmo que a aula 12 usou, e o Vite continua sendo o
servidor de desenvolvimento e o build. O que muda é que a lista de rotas é gerada, e que o projeto agora
tem um servidor próprio, chamado **Nitro**, que serve a API e, por padrão, **renderiza toda página no
servidor antes de o navegador recebê-la**.

Essa última é a maior mudança, e a aula 19 trata dela. Uma página do planner até aqui chegava como um
`<div id="app">` vazio e era desenhada pelo JavaScript no navegador; uma página do Nuxt chega com o HTML
já dentro, e a cópia do Vue no navegador então assume os elementos que recebeu. A aula 20 trata da parte
que vem disso, buscar dados num componente que roda duas vezes, uma no servidor e uma no navegador.

## O que esta aula constrói

Um segundo planner, `~/vue/planner-nuxt`, ao lado do primeiro. O primeiro fica como a aula 17 o deixou,
porque a aula 21 o testa. O do Nuxt reaproveita as regras dele, o `planner.ts`, sem mudança, e três dos
componentes com algumas linhas a menos, e pega os dados do próprio servidor em vez de um arquivo em
`public`. No fim da aula ele mostra a semana e um curso, e marcar uma sessão é um pedido ao servidor, que
guarda a mudança enquanto está rodando.

A aula 2 de `front-performance` volta a isso pelo outro lado, com Next, SvelteKit e a renderização no
servidor do Angular ao lado do Nuxt. Esta aula e as duas seguintes são o Nuxt a fundo; aquela é a
comparação.
